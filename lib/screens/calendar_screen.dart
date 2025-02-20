// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/event.dart';
import '../constants/theme_constants.dart';
import '../widgets/week_view.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late ScrollController _scrollController;
  List<CalendarEvent> _events = [];
  Timer? _timer;
  bool _isInitialScroll = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _scrollController = ScrollController();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateInitialScrollOffset() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return (minutes / 60) * WeekView.HOUR_HEIGHT - 
        (MediaQuery.of(context).size.height / 2);
  }

  List<DateTime> _getWeekDays() {
    DateTime startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  int _getCurrentWeekNumber() {
    final firstDayOfYear = DateTime(_selectedDate.year, 1, 1);
    final daysFromStart = _selectedDate.difference(firstDayOfYear).inDays;
    return (daysFromStart / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_calculateInitialScrollOffset());
        _isInitialScroll = false;
      });
    }

    final weekDays = _getWeekDays();
    final now = DateTime.now();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              DateFormat('yyyy年M月').format(_selectedDate),
              style: TextStyle(color: ThemeConstants.currentColor),
            ),
            SizedBox(width: 8),
            Text(
              '第${_getCurrentWeekNumber()}周',
              style: TextStyle(
                color: ThemeConstants.upcomingColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: ThemeConstants.currentColor),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 星期标题行
          Container(
            padding: EdgeInsets.only(left: WeekView.TIME_COLUMN_WIDTH, right: 8, top: 10, bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: ThemeConstants.gridLineColor,
                  width: ThemeConstants.gridLineWidth,
                ),
              ),
            ),
            child: Row(
              children: weekDays.map((date) {
                final isToday = date.year == now.year && 
                               date.month == now.month && 
                               date.day == now.day;
                final isPast = date.isBefore(
                  DateTime(now.year, now.month, now.day),
                );
                
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E', 'zh_CN').format(date),
                        style: isPast
                            ? ThemeConstants.getPastTextStyle()
                            : isToday
                                ? ThemeConstants.getCurrentTextStyle()
                                : ThemeConstants.getUpcomingTextStyle(),
                      ),
                      SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: isPast
                            ? ThemeConstants.getPastTextStyle()
                            : isToday
                                ? ThemeConstants.getCurrentTextStyle()
                                : ThemeConstants.getUpcomingTextStyle(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          
          // 日历主体
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: WeekView.TOTAL_HEIGHT,
                child: WeekView(
                  weekDays: weekDays,
                  events: _events,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    // 保持原有的添加事件对话框逻辑
  }
}
