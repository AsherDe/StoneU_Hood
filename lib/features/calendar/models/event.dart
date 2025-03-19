import 'package:uuid/uuid.dart';
class CalendarEvent {
  final String title;
  final String notes;
  final DateTime startTime;
  final DateTime endTime;
  final List<int> reminderMinutes;
  final String color;
  final String id;

  CalendarEvent({
    String? id,
    required this.title,
    this.notes = '',
    required this.startTime,
    required this.endTime,
    required this.reminderMinutes,
    this.color = '#FF2D55', // 默认使用苹果日历红色
  }) : id = id ?? Uuid().v4();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.title == title &&
        other.startTime.isAtSameMomentAs(startTime) &&
        other.endTime.isAtSameMomentAs(endTime);
  }

  @override
  int get hashCode => Object.hash(title, startTime, endTime);
}
