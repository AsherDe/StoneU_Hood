// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../widgets/day_column.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  List<CalendarEvent> _events = [];  // 假设这里存储事件数据

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // 添加示例事件
    _events.add(
      CalendarEvent(
        title: '开发会议',
        startTime: DateTime.now().add(Duration(hours: 1)),
        endTime: DateTime.now().add(Duration(hours: 2)),
      ),
    );
  }

  List<DateTime> _getWeekDays() {
    DateTime startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          DateFormat('yyyy年M月').format(_selectedDate),
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.blue),
            onPressed: _showAddEventDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 星期标题行
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: weekDays.map((date) {
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E', 'zh_CN').format(date),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: date.day == DateTime.now().day 
                              ? Colors.blue 
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // 日历主体
          Expanded(
            child: Row(
              children: weekDays.map((date) {
                return Expanded(
                  child: DayColumn(
                    date: date,
                    events: _events.where((event) =>
                      event.startTime.day == date.day).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    // 实现添加事件的对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加新事件'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '事件标题',
              ),
            ),
            // 这里可以添加更多输入字段
          ],
        ),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('保存'),
            onPressed: () {
              // 实现保存逻辑
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
