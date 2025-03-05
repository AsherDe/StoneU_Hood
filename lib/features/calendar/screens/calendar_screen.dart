// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/event.dart';
import '../services/event_repository.dart';
import '../../../core/constants/theme_constants.dart';
import '../widgets/week_view.dart';
import '../widgets/reminder_select.dart';
import '../widgets/semester_settings_dialog.dart';
import '../services/timetable_webview.dart';
import '../services/notification_service.dart';
import '../utils/scroll_state_manager.dart';
import '../widgets/week_indicator.dart';
import 'donation_page.dart';
import 'settings_screen.dart';
import '../services/calendar_sync_service.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  DateTime? _startDate;
  late ScrollController _scrollController;
  late PageController _pageController;
  late ScrollStateManager _scrollStateManager;
  List<CalendarEvent> _events = [];
  Timer? _timer;
  bool _isInitialScroll = true;
  int _currentPage =
      500; // Start with a large value to allow scrolling in both directions
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStartDate();
    _scrollController = ScrollController();
    _pageController = PageController(initialPage: _currentPage);
    _scrollStateManager = ScrollStateManager(_scrollController);
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
    _checkSemesterSettings();
    _notificationService.initialize();

    // 加载事件
    _initializeData();
  }

  Future<void> _loadEvents() async {
    final events = await EventRepository().getEvents();
    setState(() {
      _events = events;
    });
  }

  Future<void> _loadStartDate() async {
    final startDate = await EventRepository().getActiveFirstWeekDate();
    setState(() {
      _startDate = startDate;
    });
  }

  Future<void> _setStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      // 将日期调整到那一周的周一
      final monday = date.subtract(Duration(days: date.weekday - 1));
      await EventRepository().setFirstWeekDate(monday);
      setState(() {
        _startDate = monday;
      });
    }
  }

  Future<void> _initializeData() async {
    // Load start date first
    await _loadStartDate();

    // Then check semester settings
    await _checkSemesterSettings();

    // Finally load events
    await _loadEvents();

    if (mounted) {
      setState(() {
        // Update UI once all data is loaded
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkSemesterSettings() async {
    final isFirstLaunch = await EventRepository().isFirstLaunch();
    final firstWeekDate = await EventRepository().getActiveFirstWeekDate();

    if (isFirstLaunch || firstWeekDate == null) {
      await Future.delayed(Duration(milliseconds: 300));

      _showSemesterSettingsDialog(isFirstTime: true);
      return;
    }

    // 检查是否已经过了20周
    final now = DateTime.now();
    final weeksPassed = now.difference(firstWeekDate).inDays ~/ 7;

    if (weeksPassed >= 20) {
      _showSemesterSettingsDialog();
    }
  }

  Future<void> _showSemesterSettingsDialog({bool isFirstTime = false}) async {
    final currentFirstWeek = await EventRepository().getActiveFirstWeekDate();

    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false, // 防止误点击对话框外部关闭对话框
      builder:
          (context) => SemesterSettingsDialog(
            currentFirstWeek: currentFirstWeek,
            isFirstTime: isFirstTime,
          ),
    );

    if (result != null) {
      await EventRepository().setFirstWeekDate(result);
      await _loadStartDate();
      setState(() {
        // 刷新界面
      });
    } else if (isFirstTime) {
      _showSemesterSettingsDialog(isFirstTime: true);
    }
  }

  void _handleEventTap(CalendarEvent event) {
    _showEditEventDialog(event);
  }

  double _calculateInitialScrollOffset() {
    final now = DateTime.now();
    final weekDays = _getWeekDaysForPage(_currentPage);
    final events = _getEventsForWeek(weekDays);

    // First check if we have any events in early hours
    Map<int, bool> hoursWithEvents = {};
    for (int hour = 0; hour < 24; hour++) {
      hoursWithEvents[hour] = false;
    }

    // Mark hours that have events
    for (final event in events) {
      if (weekDays.any(
        (day) =>
            day.year == event.startTime.year &&
            day.month == event.startTime.month &&
            day.day == event.startTime.day,
      )) {
        int startHour = event.startTime.hour;
        int endHour = event.endTime.hour;
        if (event.endTime.minute == 0 && endHour > startHour) {
          endHour--;
        }

        for (int hour = startHour; hour <= endHour; hour++) {
          hoursWithEvents[hour] = true;
        }
      }
    }

    // Calculate position
    double position = 0;
    for (int hour = 0; hour < now.hour; hour++) {
      if (hour >= 0 && hour < 8) {
        position +=
            hoursWithEvents[hour]!
                ? WeekView.STANDARD_HOUR_HEIGHT
                : WeekView.COMPRESSED_HOUR_HEIGHT;
      } else {
        position += WeekView.STANDARD_HOUR_HEIGHT;
      }
    }

    // Add current minute offset
    position += (now.minute / 60.0) * WeekView.STANDARD_HOUR_HEIGHT;

    // Center in screen
    return position - (MediaQuery.of(context).size.height / 2);
  }

  // Get the date for a specific page index
  DateTime _getDateForPage(int page) {
    final difference = page - _currentPage;
    final today = DateTime.now();
    return today.add(Duration(days: difference * 7));
  }

  // Get week days for a specific page
  List<DateTime> _getWeekDaysForPage(int page) {
    final date = _getDateForPage(page);
    return _getWeekDays(date);
  }

  // Modified to accept a date parameter
  List<DateTime> _getWeekDays([DateTime? date]) {
    DateTime targetDate = date ?? _selectedDate;
    DateTime startOfWeek = targetDate.subtract(
      Duration(days: targetDate.weekday - 1),
    );
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // Handle page changes
  void _onPageChanged(int page) {
    // Save the scroll position of the previous page
    _scrollStateManager.savePage(_currentPage);

    setState(() {
      _currentPage = page;
      _selectedDate = _getDateForPage(page);
    });

    // Restore the scroll position for this page
    _scrollStateManager.restoreScrollPosition(page);

    // Preload events for this page and adjacent pages
    _preloadEventsForVisibleRange();
  }

  int _getCurrentWeekNumber() {
    if (_startDate == null) return 0;

    // Get the date for the current page instead of using _selectedDate
    final DateTime currentPageDate = _getDateForPage(_currentPage);

    // Calculate the difference from the start date
    final DateTime mondayOfCurrentPage = currentPageDate.subtract(
      Duration(days: currentPageDate.weekday - 1),
    );
    final DateTime mondayOfStartDate = _startDate!.subtract(
      Duration(days: _startDate!.weekday - 1),
    );

    // Calculate the week number based on the number of weeks between the dates
    final int difference =
        mondayOfCurrentPage.difference(mondayOfStartDate).inDays;
    final int weekNumber = (difference / 7).floor() + 1;

    // Ensure week number is within 1-20 range
    if (weekNumber < 1) return 1;
    if (weekNumber > 20) return 20;
    return weekNumber;
  }

  // Get current week number based on a specific date
  int _getWeekNumberForDate(DateTime date) {
    if (_startDate == null) return 0;

    final difference = date.difference(_startDate!).inDays;
    final weekNumber = (difference / 7).floor() + 1;

    // Ensure week number is within reasonable bounds
    if (weekNumber < 1) return 1;
    if (weekNumber > 52) return 52; // Changed from 20 to 52 for full year view
    return weekNumber;
  }

  bool _hasTimeConflict(
    DateTime start,
    DateTime end, [
    CalendarEvent? excludeEvent,
  ]) {
    return _events.any((event) {
      // 如果是正在编辑的事件，跳过冲突检查
      if (excludeEvent != null && event.id == excludeEvent.id) {
        return false;
      }

      // 检查是否有重叠
      return (start.isBefore(event.endTime) && end.isAfter(event.startTime)) ||
          (event.startTime.isBefore(end) && event.endTime.isAfter(start));
    });
  }

  // 获取下一个事件
  CalendarEvent? _getNextEvent() {
    final now = DateTime.now();

    // 过滤出未来的事件
    final futureEvents =
        _events.where((event) => event.startTime.isAfter(now)).toList();

    if (futureEvents.isEmpty) return null;

    // 按开始时间排序
    futureEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    // 返回最近的一个事件
    return futureEvents.first;
  }

  // Filter events for the current week only
  List<CalendarEvent> _getEventsForWeek(List<DateTime> weekDays) {
    if (weekDays.isEmpty) return [];

    final startOfWeek = DateTime(
      weekDays.first.year,
      weekDays.first.month,
      weekDays.first.day,
    );

    final endOfWeek = DateTime(
      weekDays.last.year,
      weekDays.last.month,
      weekDays.last.day,
      23,
      59,
      59,
    );

    return _events.where((event) {
      return (event.startTime.isAfter(startOfWeek) ||
              event.startTime.isAtSameMomentAs(startOfWeek)) &&
          (event.startTime.isBefore(endOfWeek) ||
              event.startTime.isAtSameMomentAs(endOfWeek));
    }).toList();
  }

  // Add preloading capability for events
  Future<void> _preloadEventsForVisibleRange() async {
    // This method could be called when page changes to preload events for adjacent weeks
    // For now we're loading all events at once, but in a real app with many events,
    // you might want to load events for each visible range as needed
    await _loadEvents();
  }

  // Enhanced build method with week indicator
  Widget _buildWeekIndicator() {
    final weekDays = _getWeekDaysForPage(_currentPage);
    if (weekDays.isEmpty) return SizedBox.shrink();

    final startOfWeek = weekDays.first;
    final endOfWeek = weekDays.last;
    final weekNumber = _getWeekNumberForDate(startOfWeek);
    final isCurrentWeek = _isCurrentWeek(startOfWeek);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          WeekIndicator(
            startOfWeek: startOfWeek,
            endOfWeek: endOfWeek,
            weekNumber: weekNumber,
            isCurrentWeek: isCurrentWeek,
            onTap: _showWeekSelectorDialog,
          ),
        ],
      ),
    );
  }

  bool _isCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = date;
    final endOfWeek = date.add(Duration(days: 6));

    return today.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
        today.isBefore(endOfWeek.add(Duration(days: 1)));
  }

  // Show week selector dialog
  void _showWeekSelectorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('选择周次'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 52, // Show full year of weeks
              itemBuilder: (context, index) {
                final weekNum = index + 1;
                final weekStart = _startDate?.add(Duration(days: index * 7));
                final weekEnd = weekStart?.add(Duration(days: 6));
                final isCurrent = _getCurrentWeekNumber() == weekNum;

                if (weekStart == null || weekEnd == null)
                  return SizedBox.shrink();

                return ListTile(
                  title: Text('第$weekNum周'),
                  subtitle: Text(
                    '${DateFormat('MM/dd').format(weekStart)}-${DateFormat('MM/dd').format(weekEnd)}',
                  ),
                  tileColor:
                      isCurrent
                          ? ThemeConstants.currentColor.withOpacity(0.1)
                          : null,
                  onTap: () {
                    Navigator.pop(context);

                    // Calculate the target page
                    final currentWeekNum = _getCurrentWeekNumber();
                    final weekDifference = weekNum - currentWeekNum;
                    final targetPage = _currentPage + weekDifference;

                    // Set the current page immediately to update UI
                    setState(() {
                      _currentPage = targetPage;
                      _selectedDate = _getDateForPage(targetPage);
                    });
                    // Animate to the selected week
                    _pageController.animateToPage(
                      targetPage,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('使用帮助'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 点击页面上方的"第x周"可以设置学期第一周的日期。(记得一定先设置这个)'),
                SizedBox(height: 8),
                Text('2. 点击下方的"第x周"可以快速跳转到指定周次。'),
                SizedBox(height: 8),
                Text('3. 点击右上角的上传按钮可以导入教务系统课表。'),
                SizedBox(height: 8),
                Text('4. 点击日历上的事件可以编辑或删除。'),
                SizedBox(height: 10),
                Text('随时点击上方的问号查看此提示'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('了解了'),
              ),
            ],
          ),
    );
  }

  double _calculateAppropriateHeight() {
    final weekDays = _getWeekDaysForPage(_currentPage);
    final events = _getEventsForWeek(weekDays);

    // Track which hours have events
    Map<int, bool> hoursWithEvents = {};
    for (int hour = 0; hour < 24; hour++) {
      hoursWithEvents[hour] = false;
    }

    // Mark hours that have events
    for (final event in events) {
      if (weekDays.any(
        (day) =>
            day.year == event.startTime.year &&
            day.month == event.startTime.month &&
            day.day == event.startTime.day,
      )) {
        int startHour = event.startTime.hour;
        int endHour = event.endTime.hour;
        if (event.endTime.minute == 0 && endHour > startHour) {
          endHour--;
        }

        for (int hour = startHour; hour <= endHour; hour++) {
          hoursWithEvents[hour] = true;
        }
      }
    }

    // Calculate total height
    double totalHeight = 0;
    for (int hour = 0; hour < 24; hour++) {
      if (hour >= 0 && hour < 24) {
        totalHeight +=
            hoursWithEvents[hour]!
                ? WeekView.STANDARD_HOUR_HEIGHT
                : WeekView.COMPRESSED_HOUR_HEIGHT;
      } else {
        totalHeight += WeekView.STANDARD_HOUR_HEIGHT;
      }
    }

    // Add 60 pixels of padding at the bottom
    return totalHeight + 60;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_calculateInitialScrollOffset());
        _isInitialScroll = false;
      });
    }

    final now = DateTime.now();

    // 获取下一个事件
    final nextEvent = _getNextEvent();

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
            GestureDetector(
              onTap: _setStartDate,
              child: Row(
                children: [
                  Text(
                    '第${_getCurrentWeekNumber()}周',
                    style: TextStyle(
                      color: ThemeConstants.upcomingColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Add navigation buttons for quick week jumping
          // IconButton(
          //   icon: Icon(Icons.arrow_back_ios, color: ThemeConstants.currentColor),
          //   onPressed: () {
          //     _pageController.previousPage(
          //       duration: Duration(milliseconds: 300),
          //       curve: Curves.easeInOut,
          //     );
          //   },
          //   tooltip: '上一周',
          // ),
          // IconButton(
          //   icon: Icon(Icons.arrow_forward_ios, color: ThemeConstants.currentColor),
          //   onPressed: () {
          //     _pageController.nextPage(
          //       duration: Duration(milliseconds: 300),
          //       curve: Curves.easeInOut,
          //     );
          //   },
          //   tooltip: '下一周',
          // ),
          IconButton(
            icon: Icon(Icons.help_outline, color: ThemeConstants.currentColor),
            onPressed: _showHelpDialog,
            tooltip: '使用帮助',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: ThemeConstants.currentColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              ).then((_) {
                // 返回后刷新数据
                _loadEvents();
              });
            },
            tooltip: '设置',
          ),
          IconButton(
            icon: Icon(Icons.add, color: ThemeConstants.currentColor),
            onPressed: _showAddEventDialog,
            tooltip: '添加事件',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: ThemeConstants.currentColor),
            tooltip: '更多选项',
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _handleImport();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
                case 'donate':
                  _navigateToDonationPage();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_upload,
                          color: ThemeConstants.currentColor,
                        ),
                        SizedBox(width: 8),
                        Text('导入课表'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'donate',
                    child: Row(
                      children: [
                        Icon(Icons.coffee, color: ThemeConstants.currentColor),
                        SizedBox(width: 8),
                        Text('请作者喝杯奶茶'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ThemeConstants.currentColor,
                        ),
                        SizedBox(width: 8),
                        Text('关于'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Week indicator
              _buildWeekIndicator(),

              // PageView for horizontal week scrolling
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const PageScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemBuilder: (context, index) {
                    final weekDays = _getWeekDaysForPage(index);

                    return Column(
                      children: [
                        // 星期标题行
                        Container(
                          padding: EdgeInsets.only(
                            left: WeekView.TIME_COLUMN_WIDTH,
                            right: 8,
                            top: 10,
                            bottom: 10,
                          ),
                          child: Row(
                            children:
                                weekDays.map((date) {
                                  final isToday =
                                      date.year == now.year &&
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
                                          style:
                                              isPast
                                                  ? ThemeConstants.getPastTextStyle()
                                                  : isToday
                                                  ? ThemeConstants.getCurrentTextStyle()
                                                  : ThemeConstants.getUpcomingTextStyle(),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          date.day.toString(),
                                          style:
                                              isPast
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

                        // Week progress indicator
                        Container(
                          height: 4,
                          margin: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeConstants.upcomingColor.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: index,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ThemeConstants.currentColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Expanded(flex: 1000 - index, child: Container()),
                            ],
                          ),
                        ),

                        // 日历主体
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: SizedBox(
                              height: _calculateAppropriateHeight(),
                              child: WeekView(
                                weekDays: weekDays,
                                events: _getEventsForWeek(weekDays),
                                onEventTap: _handleEventTap,
                              ),
                            ),
                          ),
                        ),
                        // 底部的下一个事件提示
                        if (nextEvent != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '下一个事件',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'MM月dd日 HH:mm',
                                        ).format(nextEvent.startTime),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    nextEvent.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (nextEvent.notes.isNotEmpty)
                                    SizedBox(height: 2),
                                  if (nextEvent.notes.isNotEmpty)
                                    Text(
                                      nextEvent.notes,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    _showEditEventDialog(null);
  }

  void _showEditEventDialog(CalendarEvent? eventToEdit) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(
      text: eventToEdit?.title ?? '',
    );
    final _notesController = TextEditingController(
      text: eventToEdit?.notes ?? '',
    );
    DateTime _startTime = eventToEdit?.startTime ?? DateTime.now();
    DateTime _endTime =
        eventToEdit?.endTime ?? DateTime.now().add(Duration(hours: 1));
    String _selectedColor = eventToEdit?.color ?? '#FF2D55';
    List<int> _selectedReminders = eventToEdit?.reminderMinutes ?? [20];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
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
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? '请输入标题' : null,
                        ),
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(labelText: '备注'),
                          maxLines: 3,
                        ),
                        ListTile(
                          title: Text('开始时间'),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(_startTime),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startTime,
                              firstDate: DateTime.now().subtract(
                                Duration(days: 365),
                              ),
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
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(_endTime),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endTime,
                              firstDate: DateTime.now().subtract(
                                Duration(days: 365),
                              ),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12.0,
                                  bottom: 8.0,
                                ),
                                child: Text(
                                  '事件颜色',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children:
                                    [
                                          '#FF2D55',
                                          '#FF9500',
                                          '#FFCC00',
                                          '#4CD964',
                                          '#5856D6',
                                          '#007AFF',
                                        ]
                                        .map(
                                          (color) => GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedColor = color;
                                              });
                                            },
                                            child: Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Color(
                                                  int.parse(
                                                    color.replaceAll(
                                                      '#',
                                                      '0xFF',
                                                    ),
                                                  ),
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color:
                                                      _selectedColor == color
                                                          ? Colors.black
                                                          : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (eventToEdit != null)
                    TextButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 4),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('删除事件'),
                                content: Text('确定要删除"${eventToEdit.title}"吗？'),
                                actions: [
                                  TextButton(
                                    child: Text('取消'),
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: Text('删除'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          try {
                            await EventRepository().deleteEvent(eventToEdit);
                            // Cancel associated notifications
                            await _notificationService.cancelEventNotifications(
                              eventToEdit,
                            );

                            await _loadEvents();

                            setState(() {
                              _events.remove(eventToEdit);
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('操作失败: ${e.toString()}')),
                            );
                          }
                          // Handle navigation more carefully
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(
                              context,
                            ).pop(); // Close confirmation dialog
                          }
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Close edit dialog
                          }
                        }
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

                        // 检查时间冲突，但排除正在编辑的事件
                        if (_hasTimeConflict(
                          _startTime,
                          _endTime,
                          eventToEdit,
                        )) {
                          final shouldProceed = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('时间冲突'),
                                  content: Text('当前时间段已有其他事件，是否继续保存？'),
                                  actions: [
                                    TextButton(
                                      child: Text('取消'),
                                      onPressed:
                                          () =>
                                              Navigator.of(context).pop(false),
                                    ),
                                    TextButton(
                                      child: Text('继续'),
                                      onPressed:
                                          () => Navigator.of(context).pop(true),
                                    ),
                                  ],
                                ),
                          );

                          if (shouldProceed != true) return;
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
                          // Cancel old notifications
                          await _notificationService.cancelEventNotifications(
                            eventToEdit,
                          );

                          await EventRepository().updateEvent(event);
                          setState(() {
                            final index = _events.indexWhere(
                              (e) => e.hashCode == eventToEdit.id,
                            );
                            if (index != -1) {
                              _events[index] = event;
                            }
                          });
                        } else {
                          await EventRepository().insertEvent(event);
                          setState(() {
                            _events.add(event);
                            _preloadEventsForVisibleRange();
                          });
                        }

                        // Schedule notifications
                        await _notificationService.scheduleNotification(event);

                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  void _handleImport() async {
    //处理数据导入
    try {
      // Show the timetable import dialog
      final List<CalendarEvent>? importedEvents =
          await showDialog<List<CalendarEvent>>(
            context: context,
            builder:
                (context) => TimetableWebView(
                  onEventsImported: (events) {
                    Navigator.of(context).pop(events);
                  },
                ),
          );

      // If no events were imported or dialog was dismissed, return early
      if (importedEvents == null || importedEvents.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('没有导入任何课程')));
        return;
      }

      // Show confirmation dialog with event count
      final bool? shouldImport = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('确认导入'),
              content: Text(
                '发现 ${importedEvents.length} 个课程，是否导入？\n注意：导入可能需要一些时间。',
              ),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('导入'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
      );

      if (shouldImport != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Insert events into database
      final eventRepository = EventRepository();
      for (final event in importedEvents) {
        await eventRepository.insertEvent(event);
        // Schedule notifications for each event
        await _notificationService.scheduleNotification(event);
      }

      // Close loading indicator
      Navigator.of(context).pop();

      // Refresh events list
      await _loadEvents();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 ${importedEvents.length} 个课程')),
      );
    } catch (e) {
      // Close loading indicator if it's showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败：${e.toString()}')));
    }

    final syncService = CalendarSyncService();
    if (syncService.isSyncEnabled()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text('正在同步到系统日历'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在将课程同步到系统日历，请稍候...'),
                ],
              ),
            ),
      );

      // 执行同步
      final syncCount = await EventRepository().syncAllUnsyncedEvents();

      // 关闭进度对话框
      Navigator.of(context).pop();

      // 显示同步结果
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已同步 $syncCount 个课程到系统日历')));
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('关于石大日历'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('石大日历是为石河子大学本科生设计的日程管理应用。现在整合到了石大时光圈。'),
                SizedBox(height: 8),
                Text('版本: 1.0.0'),
                SizedBox(height: 8),
                Text('功能:'),
                Text('• 课程表导入与显示'),
                Text('• 自定义事件管理'),
                Text('• 事件提醒'),
                Text('• 周次与日期管理'),
                SizedBox(height: 16),
                Text('商业合作/引流请联系我'),
                Text('开发者: 吉育德'),
                Text('联系方式: asher.ji@icloud.com'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('关闭'),
              ),
            ],
          ),
    );
  }

  void _navigateToDonationPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => DonationPage()));
  }
}
