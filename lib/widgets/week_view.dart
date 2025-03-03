// lib/widgets/week_view.dart
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import '../models/event.dart';
import '../constants/theme_constants.dart';

class WeekView extends StatefulWidget {
  final List<DateTime> weekDays;
  final List<CalendarEvent> events;
  final Function(CalendarEvent)? onEventTap;

  static const double STANDARD_HOUR_HEIGHT = 60.0;
  static const double COMPRESSED_HOUR_HEIGHT = 20.0;
  static const double TOTAL_HEIGHT = STANDARD_HOUR_HEIGHT * 24;
  static const double TIME_COLUMN_WIDTH = 50.0;
  static const double VERTICAL_LINE_WIDTH = 1.0;
  static const double TODAY_LINE_WIDTH = 2.0;

  // 用户的早晨不活跃时间段
  static final List<int> EARLY_HOURS = List.generate(24, (index) => index);

  const WeekView({
    super.key,
    required this.weekDays,
    required this.events,
    this.onEventTap,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  // Map to track which hours have events
  late Map<int, bool> _hoursWithEvents;

  // Map to store position of each hour
  late Map<int, double> _hourPositions;

  // Total calculated height
  late double _totalHeight;

  @override
  void initState() {
    super.initState();
    _prepareHourData();
  }

  @override
  void didUpdateWidget(WeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events ||
        widget.weekDays != oldWidget.weekDays) {
      _prepareHourData();
    }
  }

  //提前计算哪些时间有事件并计算事件位置
  void _prepareHourData() {
    _hoursWithEvents = {};
    _hourPositions = {};

    // Initialize all hours as having no events
    for (int hour = 0; hour < 24; hour++) {
      _hoursWithEvents[hour] = false;
    }

    // Check which hours have events
    for (final event in widget.events) {
      final dayIndex = widget.weekDays.indexWhere(
        (day) =>
            day.year == event.startTime.year &&
            day.month == event.startTime.month &&
            day.day == event.startTime.day,
      );

      if (dayIndex >= 0) {
        // Mark all hours that this event spans
        int startHour = event.startTime.hour;
        int endHour = event.endTime.hour;

        // If event ends at xx:00, don't mark that hour
        if (event.endTime.minute == 0 && endHour > startHour) {
          endHour--;
        }

        // Mark all hours between start and end
        for (int hour = startHour; hour <= endHour; hour++) {
          _hoursWithEvents[hour] = true;
        }
      }
    }

    // Calculate position for each hour
    double position = 0;
    for (int hour = 0; hour < 24; hour++) {
      _hourPositions[hour] = position;
      position += _getHeightForHour(hour);
    }

    _totalHeight = position;
  }

  // Get the appropriate height for a specific hour
  double _getHeightForHour(int hour) {
    // Early hours (0-7) get compressed if empty
    if (WeekView.EARLY_HOURS.contains(hour)) {
      return _hoursWithEvents[hour] == true
          ? WeekView.STANDARD_HOUR_HEIGHT
          : WeekView.COMPRESSED_HOUR_HEIGHT;
    }
    // Regular hours always use standard height
    return WeekView.STANDARD_HOUR_HEIGHT;
  }

  // Calculate vertical position for a specific time
  double _calculateTimePosition(DateTime time) {
    // Get base position for the hour
    final hourPosition = _hourPositions[time.hour] ?? 0;

    // Add minute offset within that hour
    final minuteRatio = time.minute / 60.0;
    final minuteOffset = minuteRatio * _getHeightForHour(time.hour);

    return hourPosition + minuteOffset;
  }

  // Determine color for an event based on its time
  Color getEventColor(CalendarEvent event) {
    final now = DateTime.now();
    if (event.endTime.isBefore(now)) {
      return ThemeConstants.pastColor;
    }
    if (event.startTime.isBefore(now) && event.endTime.isAfter(now)) {
      return ThemeConstants.currentColor;
    }
    return Color(int.parse(event.color.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final dayWidth = (screenWidth - WeekView.TIME_COLUMN_WIDTH) / 7;

    final todayIndex = widget.weekDays.indexWhere(
      (date) =>
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day,
    );

    return SizedBox(
      height: _totalHeight,
      child: Stack(
        children: [
          // 时间轴背景网格
          Column(
            children: List.generate(24, (hour) {
              final hourHeight = _getHeightForHour(hour);
              return SizedBox(
                height: hourHeight,
                child: Row(
                  children: [
                    // 时间列
                    SizedBox(
                      width: WeekView.TIME_COLUMN_WIDTH,
                      child: Padding(
                        padding: EdgeInsets.only(right: 8, top: 0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            '$hour:00',
                            style: ThemeConstants.getUpcomingTextStyle().copyWith(
                              // Make early morning hours with no events slightly lighter
                              color: WeekView.EARLY_HOURS.contains(hour) && 
                                    !_hoursWithEvents[hour]! 
                                ? ThemeConstants.getUpcomingTextStyle().color!.withOpacity(0.6)
                                : ThemeConstants.getUpcomingTextStyle().color
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: List.generate(8, (index) {
                          // 计算是否是今天，若是加粗两条分割线
                          final shouldBeBold =
                              index == todayIndex || index == todayIndex + 1;

                          return Positioned(
                            left: dayWidth * index,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: shouldBeBold ? WeekView.TODAY_LINE_WIDTH : WeekView.VERTICAL_LINE_WIDTH,
                              color: ThemeConstants.gridLineColor,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // 事件层
          ...widget.events.map((event) {
            final dayIndex = widget.weekDays.indexWhere((day) =>
              day.year == event.startTime.year &&
              day.month == event.startTime.month &&
              day.day == event.startTime.day
            );
            
            if (dayIndex == -1) return Container(); // Skip if not in current week

            final left = WeekView.TIME_COLUMN_WIDTH + (dayIndex * dayWidth);
            final top = _calculateTimePosition(event.startTime);
            final bottom = _calculateTimePosition(event.endTime);
            final height = bottom - top;

            return Positioned(
              left: left,
              top: top,
              width: dayWidth,
              height: height,
              child: GestureDetector(
                onTap: () {
                  if (widget.onEventTap != null) widget.onEventTap!(event);
                },
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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // if (height > 40) // Only show time in taller events
                      //   Text(
                      //     '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                      //     style: TextStyle(
                      //       color: Colors.white.withOpacity(0.8),
                      //       fontSize: 10,
                      //     ),
                      //   ),
                      if (height > 80 && event.notes.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            event.notes,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: (height > 100) ? 3 : 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        )
                    ],
                  ),
                ),
              )
            );
          }).toList(),

          // 时间指示器（红色）
          if (todayIndex >= 0)
            Positioned(
              left: WeekView.TIME_COLUMN_WIDTH + (todayIndex * dayWidth),
              width: dayWidth,
              top: _calculateTimePosition(now),
              child: Container(
                height: ThemeConstants.timeIndicatorHeight,
                color: const Color.fromARGB(255, 255, 0, 0),
              ),
            ),
        ],
      ),
    );
  }
}