class CalendarEvent {
  final String title;
  final String notes;
  final DateTime startTime;
  final DateTime endTime;
  final List<int> reminderMinutes;
  final String color;

  CalendarEvent({
    required this.title,
    this.notes = '',
    required this.startTime,
    required this.endTime,
    List<int>? reminderMinutes,
    this.color = '#FF2D55',  // 默认使用苹果日历红色
  }):reminderMinutes = reminderMinutes ?? [20];
}
