// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/event.dart';
import '../services/event_repository.dart';
import '../constants/theme_constants.dart';
import '../widgets/week_view.dart';
import '../widgets/reminder_select.dart';

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

    // 加载事件
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await EventRepository().getEvents();
    setState(() {
      _events = events;
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

  bool _hasTimeConflict(DateTime start, DateTime end) {
    return _events.any((event) {
      // 检查是否有重叠
      return (start.isBefore(event.endTime) && end.isAfter(event.startTime)) ||
             (event.startTime.isBefore(end) && event.endTime.isAfter(start));
    });
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
            icon: Icon(Icons.file_upload, color: ThemeConstants.currentColor),
            onPressed: _handleImport,
          ),
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

  void _showAddEventDialog([CalendarEvent? eventToEdit]) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(text: eventToEdit?.title);
    final _notesController = TextEditingController(text: eventToEdit?.notes);
    DateTime _startTime = eventToEdit?.startTime ?? DateTime.now();
    DateTime _endTime = eventToEdit?.endTime ?? DateTime.now().add(Duration(hours: 1));
    String _selectedColor = eventToEdit?.color ?? '#FF2D55';
    List<int> _selectedReminders = eventToEdit?.reminderMinutes ?? [20];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(eventToEdit == null ? '添加事件' : '编辑事件'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: '标题'),
                  validator: (value) => value?.isEmpty ?? true ? '请输入标题' : null,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: '备注'),
                  maxLines: 3,
                ),
                ListTile(
                  title: Text('开始时间'),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_startTime)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_startTime),
                      );
                      if (time != null) {
                        setState(() {
                          _startTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text('结束时间'),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(_endTime)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endTime,
                      firstDate: _startTime,
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_endTime),
                      );
                      if (time != null) {
                        setState(() {
                          _endTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                // 添加提醒选择
                ReminderMultiSelect(
                  initialValue: _selectedReminders,
                  onChanged: (List<int> value) {
                    setState(() {
                      _selectedReminders = value;
                    });
                  },
                ),
                // 添加颜色选择
                Wrap(
                  spacing: 8,
                  children: [
                    '#FF2D55',
                    '#FF9500',
                    '#FFCC00',
                    '#4CD964',
                    '#5856D6',
                    '#FF2D55',
                  ].map((color) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color 
                            ? Colors.black 
                            : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (eventToEdit != null)
            TextButton(
              child: Text('删除'),
              onPressed: () async {
                await EventRepository().deleteEvent(eventToEdit);
                Navigator.of(context).pop();
                setState(() {
                  _events.remove(eventToEdit);
                });
              },
            ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('保存'),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                if (_endTime.isBefore(_startTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('结束时间不能早于开始时间')),
                  );
                  return;
                }
                
                if (_hasTimeConflict(_startTime, _endTime)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('当前时间段已有其他事件')),
                  );
                  return;
                }

                final event = CalendarEvent(
                  title: _titleController.text,
                  notes: _notesController.text,
                  startTime: _startTime,
                  endTime: _endTime,
                  reminderMinutes: _selectedReminders,
                  color: _selectedColor,
                );

                if (eventToEdit != null) {
                  await EventRepository().updateEvent(event);
                  setState(() {
                    _events[_events.indexOf(eventToEdit)] = event;
                  });
                } else {
                  await EventRepository().insertEvent(event);
                  setState(() {
                    _events.add(event);
                  });
                }
                
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }
  void _handleImport() {
    //处理导入请求
  }
}