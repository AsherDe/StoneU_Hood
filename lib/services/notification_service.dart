import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();  // 初始化时区数据

    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings(  // 使用新的 DarwinInitializationSettings
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    
    final initSettings = InitializationSettings(android: android, iOS: iOS);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 处理通知点击事件
      },
    );

    // 请求 iOS 通知权限
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNotification(CalendarEvent event) async {
    final scheduledTime = tz.TZDateTime.from(
      event.startTime.subtract(Duration(minutes: event.reminderMinutes)),
      tz.local,
    );
    
    final androidDetails = AndroidNotificationDetails(
      'calendar_events',
      '日历提醒',
      channelDescription: '日历事件提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    final darwinDetails = DarwinNotificationDetails();  // 使用新的 DarwinNotificationDetails
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notifications.zonedSchedule(
      event.hashCode,
      '事件提醒',
      '${event.title} 将在 ${event.reminderMinutes} 分钟后开始',
      scheduledTime,
      details,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exact, // Add the required parameter
    );
  }
}