// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import '../services/calendar_sync_service.dart';
import '../services/event_repository.dart';
import '../../../core/constants/calendar_theme.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CalendarSyncService _syncService = CalendarSyncService();
  final EventRepository _eventRepository = EventRepository();

  bool _isSyncEnabled = false;
  String? _selectedCalendarId;
  List<Calendar> _availableCalendars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    await _syncService.initialize();
    _isSyncEnabled = _syncService.isSyncEnabled();
    _selectedCalendarId = _syncService.getSelectedCalendarId();

    try {
      _availableCalendars = await _syncService.getAvailableCalendars();
    } catch (e) {
      print('获取日历列表失败: $e');
      // 显示错误信息
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('获取系统日历失败，请确认已授予日历权限')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleSync(bool value) async {
    // 如果开启同步但没有选择日历，则先选择日历
    if (value &&
        _selectedCalendarId == null &&
        _availableCalendars.isNotEmpty) {
      _showCalendarSelectDialog();
      return;
    }

    // 如果没有可用日历，则提示用户
    if (value && _availableCalendars.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('没有可用的系统日历，请先在系统中创建日历')));
      return;
    }

    setState(() {
      _isSyncEnabled = value;
    });

    await _syncService.setSyncEnabled(value);

    // 如果开启同步，执行一次全量同步
    if (value) {
      final syncCount = await _eventRepository.syncAllUnsyncedEvents();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已同步 $syncCount 个事件到系统日历')));
    }
  }

  Future<void> _selectCalendar(String calendarId) async {
    setState(() {
      _selectedCalendarId = calendarId;
    });

    await _syncService.setSelectedCalendar(calendarId);

    // 如果已开启同步，重新执行一次全量同步
    if (_isSyncEnabled) {
      final syncCount = await _eventRepository.syncAllUnsyncedEvents();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已同步 $syncCount 个事件到新选择的日历')));
    }
  }

  void _showCalendarSelectDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('选择系统日历'),
            content:
                _availableCalendars.isEmpty
                    ? Text('没有找到可用的系统日历，请先创建一个系统日历')
                    : Container(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableCalendars.length,
                        itemBuilder: (context, index) {
                          final calendar = _availableCalendars[index];
                          return ListTile(
                            title: Text(calendar.name ?? '未命名日历'),
                            subtitle: Text(calendar.accountName ?? ''),
                            selected: calendar.id == _selectedCalendarId,
                            leading: Icon(
                              Icons.calendar_today,
                              color:
                                  calendar.color is int
                                      ? Color(calendar.color as int)
                                      : Color(
                                        int.parse(
                                          (calendar.color as String? ??
                                                  '#FF2D55')
                                              .replaceAll('#', '0xFF'),
                                        ),
                                      ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              if (calendar.id != null) {
                                _selectCalendar(calendar.id!);
                              }
                            },
                          );
                        },
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        backgroundColor: Colors.white,
        foregroundColor: ThemeConstants.currentColor,
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  SwitchListTile(
                    title: Text('同步到系统日历'),
                    subtitle: Text('将事件同步到设备的系统日历，以便系统接管推送服务'),
                    value: _isSyncEnabled,
                    onChanged: _toggleSync,
                    activeColor: ThemeConstants.currentColor,
                  ),
                  if (_isSyncEnabled) Divider(),
                  if (_isSyncEnabled)
                    ListTile(
                      title: Text('选择系统日历'),
                      subtitle: Text(
                        _availableCalendars
                                .firstWhere(
                                  (cal) => cal.id == _selectedCalendarId,
                                  orElse: () => Calendar(),
                                )
                                .name ??
                            '未选择日历',
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showCalendarSelectDialog,
                    ),
                  Divider(),
                  ListTile(
                    title: Text('关于日历同步'),
                    subtitle: Text('系统日历同步使您能够在原生日历应用中查看所有事件，并利用系统通知'),
                    onTap: () => _showAboutDialog(),
                  ),
                ],
              ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('关于日历同步'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('日历同步功能可以让您：'),
                SizedBox(height: 8),
                Text('• 在系统日历应用中查看所有事件'),
                Text('• 利用系统通知提醒您即将到来的事件'),
                Text('• 在不打开石大日历应用的情况下获取提醒'),
                SizedBox(height: 8),
                Text('注意事项：'),
                Text('• 同步操作可能需要一些时间'),
                Text('• 对事件的修改将同时在两处更新'),
                Text('• 如果在系统日历中删除事件，石大日历中的事件不会受影响'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('了解'),
              ),
            ],
          ),
    );
  }
}
