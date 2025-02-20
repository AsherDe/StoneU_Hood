// lib/widgets/week_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../constants/theme_constants.dart';

class WeekView extends StatelessWidget {
  final List<DateTime> weekDays;
  final List<CalendarEvent> events;
  static const double HOUR_HEIGHT = 60.0;
  static const double TOTAL_HEIGHT = HOUR_HEIGHT * 24;
  static const double TIME_COLUMN_WIDTH = 50.0;

  const WeekView({
    super.key,
    required this.weekDays,
    required this.events,
  });

  Color getEventColor(CalendarEvent event) {
    final now = DateTime.now();
    if (event.endTime.isBefore(now)) {
      return ThemeConstants.pastColor;
    }
    if (event.startTime.isBefore(now) && event.endTime.isAfter(now)) {
      return ThemeConstants.currentColor;
    }
    return ThemeConstants.upcomingColor;
  }

  double _calculateEventPosition(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    return (minutes / 60) * HOUR_HEIGHT;
  }

  double _calculateEventHeight(DateTime start, DateTime end) {
    // 确保结束时间不超过当天的23:59:59
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    final adjustedEnd = end.isAfter(endOfDay) ? endOfDay : end;
    final duration = adjustedEnd.difference(start).inMinutes;
    return (duration / 60) * HOUR_HEIGHT;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - TIME_COLUMN_WIDTH) / 7;

    return Stack(
      children: [
        // 时间轴背景网格
        Column(
          children: List.generate(24, (hour) {
            return Container(
              height: HOUR_HEIGHT,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ThemeConstants.gridLineColor,
                    width: ThemeConstants.gridLineWidth,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 时间列
                  SizedBox(
                    width: TIME_COLUMN_WIDTH,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$hour:00',
                          style: ThemeConstants.getUpcomingTextStyle(),
                        ),
                      ),
                    ),
                  ),
                  // 每小时的横向网格线
                  ...List.generate(7, (index) => 
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: ThemeConstants.gridLineColor,
                              width: ThemeConstants.gridLineWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        // 事件层
        ...events.map((event) {
          final dayIndex = weekDays.indexWhere((day) =>
            day.year == event.startTime.year &&
            day.month == event.startTime.month &&
            day.day == event.startTime.day
          );
          
          if (dayIndex == -1) return Container(); // 如果事件不在当前周，则不显示

          final left = TIME_COLUMN_WIDTH + (dayIndex * dayWidth);
          final top = _calculateEventPosition(event.startTime);
          final height = _calculateEventHeight(event.startTime, event.endTime);

          return Positioned(
            left: left,
            top: top,
            width: dayWidth,
            height: height,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: getEventColor(event),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (height > 40) // 只在足够高的事件中显示时间
                    Text(
                      '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),

        // 当前时间指示器
        Positioned(
          left: TIME_COLUMN_WIDTH + (weekDays.indexWhere((day) =>
          day.year == now.year &&
          day.month == now.month &&
          day.day == now.day
        ) * dayWidth),
          width: dayWidth,
          top: _calculateEventPosition(now),
          child: Container(
            height: ThemeConstants.timeIndicatorHeight,
            color: ThemeConstants.currentColor,
          ),
        ),
      ],
    );
  }
}