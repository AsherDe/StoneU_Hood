class CalendarEvent {
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int reminderMinutes;
  final String color;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.reminderMinutes = 20,
    this.color = '#FF2D55',  // 默认使用苹果日历红色
  });
}
