// lib/services/calendar_sync_service.dart
import 'package:device_calendar/device_calendar.dart';
import '../models/event.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarSyncService {
  static final CalendarSyncService _instance = CalendarSyncService._internal();
  factory CalendarSyncService() => _instance;

  late DeviceCalendarPlugin _deviceCalendarPlugin;
  String? _selectedCalendarId;
  bool _isSyncEnabled = false;

  // 存储事件ID映射关系 (本地事件hashCode -> 系统日历事件ID)
  final Map<String, String> _eventIdMap = {};

  CalendarSyncService._internal() {
    _deviceCalendarPlugin = DeviceCalendarPlugin();
    _loadPreferences();
  }

  // 初始化服务并加载用户首选项
  Future<void> initialize() async {
    await _loadPreferences();
    await _loadEventIdMap();
    await _requestPermissions();
  }

  // 加载用户首选项
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isSyncEnabled = prefs.getBool('sync_calendar_enabled') ?? false;
    _selectedCalendarId = prefs.getString('selected_calendar_id');
  }

  // 加载事件ID映射
  Future<void> _loadEventIdMap() async {
    final prefs = await SharedPreferences.getInstance();
    final mappingJson = prefs.getString('event_id_mapping') ?? '{}';

    try {
      // 使用dart:convert库解析JSON字符串为Map
      final Map<String, dynamic> mappingData = jsonDecode(mappingJson);

      _eventIdMap.clear();
      // 将解析的数据加载到_eventIdMap中
      mappingData.forEach((localId, systemId) {
        _eventIdMap[localId] = systemId.toString();
      });

      print('已加载 ${_eventIdMap.length} 个事件ID映射');
    } catch (e) {
      print('加载事件ID映射时出错: $e');
      _eventIdMap.clear();
    }
  }

  // 保存事件ID映射
  Future<void> _saveEventIdMap() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 将_eventIdMap转换为JSON字符串
      final String mappingJson = jsonEncode(_eventIdMap);

      // 保存到SharedPreferences
      await prefs.setString('event_id_mapping', mappingJson);

      print('已保存 ${_eventIdMap.length} 个事件ID映射');
    } catch (e) {
      print('保存事件ID映射时出错: $e');
    }
  }

  // 请求日历访问权限
  Future<bool> _requestPermissions() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess &&
        (permissionsGranted.data == null || !permissionsGranted.data!)) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      return permissionsGranted.isSuccess &&
          permissionsGranted.data != null &&
          permissionsGranted.data!;
    }
    return permissionsGranted.isSuccess &&
        permissionsGranted.data != null &&
        permissionsGranted.data!;
  }

  // 获取可用的系统日历列表
  Future<List<Calendar>> getAvailableCalendars() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return [];
    }

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    return calendarsResult.isSuccess && calendarsResult.data != null
        ? calendarsResult.data!
        : [];
  }

  // 设置选中的日历ID
  Future<void> setSelectedCalendar(String calendarId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_calendar_id', calendarId);
    _selectedCalendarId = calendarId;
  }

  // 获取选中的日历ID
  String? getSelectedCalendarId() {
    return _selectedCalendarId;
  }

  // 设置同步开关
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_calendar_enabled', enabled);
    _isSyncEnabled = enabled;
  }

  // 获取同步开关状态
  bool isSyncEnabled() {
    return _isSyncEnabled;
  }

  // 将应用内事件同步到系统日历
  Future<bool> syncEventToSystem(CalendarEvent event) async {
    if (!_isSyncEnabled || _selectedCalendarId == null) {
      return false;
    }

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      return false;
    }

    // 创建系统事件对象
    final eventToCreate = Event(
      _selectedCalendarId!,
      title: event.title,
      description: event.notes,
      start: TZDateTime.from(event.startTime, local),
      end: TZDateTime.from(event.endTime, local),
    );

    // 设置提醒
    List<Reminder> reminders = [];
    for (var minutes in event.reminderMinutes) {
      reminders.add(Reminder(minutes: minutes));
    }
    eventToCreate.reminders = reminders;

    // 检查事件是否已存在
    final eventId = _eventIdMap[event.hashCode.toString()];
    Result<String>? result;

    if (eventId != null) {
      // 更新现有事件
      eventToCreate.eventId = eventId;
      result = await _deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);
    } else {
      // 创建新事件
      result = await _deviceCalendarPlugin.createOrUpdateEvent(eventToCreate);
      if (result != null && result.isSuccess && result.data != null) {
        // 保存映射关系
        _eventIdMap[event.hashCode.toString()] = result.data!;
        await _saveEventIdMap();
      }
    }

    return result?.isSuccess ?? false;
  }

  // 从系统日历删除事件
  Future<bool> deleteEventFromSystem(CalendarEvent event) async {
    if (!_isSyncEnabled || _selectedCalendarId == null) {
      return false;
    }

    final eventId = _eventIdMap[event.hashCode.toString()];
    if (eventId == null) {
      return false;
    }

    final result = await _deviceCalendarPlugin.deleteEvent(
      _selectedCalendarId!,
      eventId,
    );

    if (result.isSuccess) {
      _eventIdMap.remove(event.hashCode.toString());
      await _saveEventIdMap();
      return true;
    }
    return false;
  }

  // 批量同步多个事件
  Future<int> syncMultipleEvents(List<CalendarEvent> events) async {
    if (!_isSyncEnabled || _selectedCalendarId == null) {
      return 0;
    }

    int successCount = 0;
    for (final event in events) {
      final success = await syncEventToSystem(event);
      if (success) {
        successCount++;
      }
    }
    return successCount;
  }
}
