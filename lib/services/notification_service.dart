import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/event.dart';
import 'package:intl/intl.dart';

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
  }

  void _handleNotificationTap(NotificationResponse response) {
    // TODO: 实现通知点击后的导航逻辑
    // 可以通过 response.payload 获取传递的数据
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MM月dd日 HH:mm').format(dateTime);
  }

  Future<void> scheduleNotification(CalendarEvent event) async {
    // 取消该事件之前的所有通知
    await cancelEventNotifications(event);

    // 为每个提醒时间创建通知
    for (int minutes in event.reminderMinutes) {
      final scheduledTime = tz.TZDateTime.from(
        event.startTime.subtract(Duration(minutes: minutes)), 
        tz.local,
      );

      //如果提醒时间已经过去，则跳过
      if (scheduledTime.isBefore(DateTime.now())) {
      continue;
      }

      //构建通知内容
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
        styleInformation: BigTextStyleInformation(notificationBody),  // 使用大文本样式显示长文本
      );
      
      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: _formatDateTime(event.startTime),  // iOS 通知副标题显示开始时间
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // 生成唯一的通知ID
      final notificationId = '${event.hashCode}_$minutes'.hashCode;

      await _notifications.zonedSchedule(notificationId,
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
  }

  Future<void> cancelEventNotifications(CalendarEvent event) async {
    // 取消该事件的所有提醒通知
    for (int minutes in event.reminderMinutes) {
      final notificationId = '${event.hashCode}_$minutes'.hashCode;
      await _notifications.cancel(notificationId);
    }
  }
}