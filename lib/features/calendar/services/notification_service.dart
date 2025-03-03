import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();  // 初始化时区数据

      final android = const AndroidInitializationSettings('@mipmap/ic_launcher');
      final iOS = const DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );
      
      final initSettings = InitializationSettings(android: android, iOS: iOS);

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // 处理通知点击事件
          _handleNotificationTap(response);
        },
      );

      // 请求 iOS 通知权限
      await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          
      _isInitialized = true;
    } catch (e) {
      debugPrint('初始化通知服务失败: $e');
      _isInitialized = false;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    // TODO: 实现通知点击后的导航逻辑
    // 可以通过 response.payload 获取传递的数据
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MM月dd日 HH:mm').format(dateTime);
  }

  Future<void> scheduleNotification(CalendarEvent event) async {
    if (!_isInitialized) {
      debugPrint('通知服务未初始化，跳过创建通知');
      return;
    }

    try {
      // 尝试取消该事件之前的所有通知
      await cancelEventNotifications(event);

      // 为每个提醒时间创建通知
      for (int minutes in event.reminderMinutes) {
        final scheduledTime = tz.TZDateTime.from(
          event.startTime.subtract(Duration(minutes: minutes)), 
          tz.local,
        );

        // 如果提醒时间已经过去，则跳过
        if (scheduledTime.isBefore(DateTime.now())) {
          continue;
        }

        // 构建通知内容
        String notificationTitle = event.title;
        String notificationBody = '';

        if (minutes >= 1440) {  // 1天或更长
          notificationBody = '将于明天 ${_formatDateTime(event.startTime)} 开始';
        } else if (minutes >= 60) {  // 1小时或更长
          notificationBody = '将于 ${minutes ~/ 60} 小时后开始（${_formatDateTime(event.startTime)}）';
        } else {
          notificationBody = '将于 $minutes 分钟后开始（${_formatDateTime(event.startTime)}）';
        }

        if (event.notes.isNotEmpty) {
          notificationBody += '\n ${event.notes}';
        }

        final androidDetails = AndroidNotificationDetails(
          'calendar_events',
          '日历提醒',
          channelDescription: '日历事件提醒',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(notificationBody),
        );
        
        final darwinDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: _formatDateTime(event.startTime),
        );
        
        final details = NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        );

        // 生成唯一的通知ID - 使用正整数值
        final notificationId = '${event.hashCode}_$minutes'.hashCode.abs();

        await _notifications.zonedSchedule(
          notificationId,
          notificationTitle, 
          notificationBody, 
          scheduledTime, 
          details, 
          uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime, 
          androidScheduleMode: AndroidScheduleMode.exact,
          payload: event.title,
        );
      }
    } catch (e) {
      debugPrint('创建通知失败: $e');
      // 继续执行，不要因通知失败而阻止其他功能
    }
  }

  Future<void> cancelEventNotifications(CalendarEvent event) async {
    if (!_isInitialized) {
      debugPrint('通知服务未初始化，跳过取消通知');
      return;
    }

    try {
      // 取消该事件的所有提醒通知
      for (int minutes in event.reminderMinutes) {
        final notificationId = '${event.hashCode}_$minutes'.hashCode.abs();
        await _notifications.cancel(notificationId);
      }
    } catch (e) {
      debugPrint('取消通知失败: $e');
      // 继续执行，不要因通知失败而阻止其他功能
    }
  }
}