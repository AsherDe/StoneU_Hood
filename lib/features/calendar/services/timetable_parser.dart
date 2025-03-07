// lib/services/timetable_parser.dart
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/event.dart';

class TimetableParser {
  /// 解析HTML内容并提取课程
  static List<CalendarEvent> parseTimetable(
    String htmlContent,
    DateTime semesterStart,
  ) {
    htmlContent = htmlContent
        .replaceAll("\\u003C", '<')
        .replaceAll("\\u003E", '>');
    List<CalendarEvent> events = [];
    // for (var i = 0; i < htmlContent.length - 200; i += 200)
    //   print(htmlContent.substring(i, i + 200));
    // 解析HTML文档
    final document = html_parser.parse(htmlContent);

    // 寻找ID为"timetable"的表格 - 这是石河子大学课表的主要标识
    final timetableElement = document.getElementById('timetable');

    if (timetableElement == null) {
      print('无法找到课程表元素 (id="timetable")');
      return [];
    }

    // 获取所有行
    final rows = timetableElement.querySelectorAll('tr');
    if (rows.length <= 1) {
      print('课程表行数不足: ${rows.length}');
      return []; // 只有表头行，没有数据
    }

    // 解析时间槽
    Map<int, TimeSlot> timeSlots = {};

    // 从第二行开始解析时间槽（跳过表头）
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final timeCells = row.querySelectorAll('th');

      if (timeCells.isNotEmpty) {
        final timeCell = timeCells.first;
        final timeSlot = _parseTimeSlot(timeCell.text, i);
        if (timeSlot != null) {
          timeSlots[i] = timeSlot;
        }
      }
    }

    // 遍历每一行（跳过表头行）
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final timeSlot = timeSlots[rowIndex];
      if (timeSlot == null) continue;

      // 遍历每天的单元格（跳过第一个时间列）
      final cells = row.querySelectorAll('td');
      for (
        int dayIndex = 0;
        dayIndex < cells.length && dayIndex < 7;
        dayIndex++
      ) {
        final dayCell = cells[dayIndex];
        final day = dayIndex + 1; // 1 = 周一, 2 = 周二, 等等

        // 查找课程内容div - 使用class="kbcontent"的div
        final courseDivs = dayCell.querySelectorAll('div.kbcontent');

        for (final courseDiv in courseDivs) {
          // 跳过空单元格
          if (courseDiv.text.trim().isEmpty ||
              courseDiv.text.trim() == '&nbsp;') {
            continue;
          }

          // 检查单元格内是否有多个课程（用-----分隔）
          String cellContent = courseDiv.innerHtml;
          List<String> courseBlocks = cellContent.split(
            '---------------------',
          );

          for (String courseBlock in courseBlocks) {
            if (courseBlock.trim().isEmpty) continue;

            // 创建临时元素来解析单个课程块
            final tempDiv = dom.Element.tag('div');
            tempDiv.innerHtml = courseBlock;

            // 解析课程信息
            final courseEvents = _parseCourseCell(
              tempDiv,
              day,
              timeSlot,
              semesterStart,
            );
            events.addAll(courseEvents);
          }
        }
      }
    }

    return events;
  }

  /// 从时间列解析时间槽
  static TimeSlot? _parseTimeSlot(String text, int rowIndex) {
    // 格式: "第一二节 (01,02小节) 10:00-11:40"
    final timeRegex = RegExp(r'(\d+:\d+)-(\d+:\d+)');
    final match = timeRegex.firstMatch(text);

    if (match != null) {
      final startTime = match.group(1)!;
      final endTime = match.group(2)!;

      return TimeSlot(
        index: rowIndex,
        startTime: _parseTimeString(startTime),
        endTime: _parseTimeString(endTime),
      );
    }
    return null;
  }

  /// 解析时间字符串 (HH:MM) 为 DateTime
  static DateTime _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  /// 解析课程单元格并提取课程信息
  static List<CalendarEvent> _parseCourseCell(
    dom.Element courseDiv,
    int dayOfWeek,
    TimeSlot timeSlot,
    DateTime semesterStart,
  ) {
    List<CalendarEvent> events = [];

    // 提取课程名称、教师、周次、地点
    String courseTitle = '';
    String instructor = '';
    String location = '';
    List<WeekRange> weekRanges = [];
    String notes = '';

    // 寻找所有font标签，按顺序解析
    final fontElements = courseDiv.querySelectorAll('font');

    for (int i = 0; i < fontElements.length; i++) {
      final font = fontElements[i];
      final text = font.text.trim();

      // 跳过空元素
      if (text.isEmpty) continue;

      // 检查title属性或根据索引确定内容类型
      final title = font.attributes['title'] ?? '';

      if (i == 0 || title == '课程') {
        courseTitle = text;
      } else if (title == '教师') {
        instructor = text;
      } else if (title.contains('周次') ||
          text.contains('周') && text.contains('[')) {
        weekRanges = _parseWeekRanges(text);
      } else if (title == '教室') {
        location = text;
      } else if (title == '教学备注') {
        notes = text.replaceAll('教学备注：', '');
      }
    }

    // 寻找特定的教师信息
    dom.Element? teacherElement = courseDiv.querySelector('font[title="教师"]');
    if (teacherElement != null) {
      instructor = teacherElement.text.trim();
    }

    // 特殊处理周次信息
    dom.Element? weekElement = courseDiv.querySelector('font[title="周次(节次)"]');
    if (weekElement != null) {
      weekRanges = _parseWeekRanges(weekElement.text);
    }

    // 特殊处理教室信息
    dom.Element? roomElement = courseDiv.querySelector('font[title="教室"]');
    if (roomElement != null) {
      location = roomElement.text.trim();
    }

    // 如果没有找到必要的信息，尝试更广泛的搜索
    if (courseTitle.isEmpty && fontElements.isNotEmpty) {
      courseTitle = fontElements[0].text.trim();
    }

    // 如果找不到周次信息，查找包含"周"的元素
    if (weekRanges.isEmpty) {
      for (final font in fontElements) {
        if (font.text.contains('周')) {
          weekRanges = _parseWeekRanges(font.text);
          if (weekRanges.isNotEmpty) break;
        }
      }
    }

    // 如果仍然没有周次信息，使用默认值(1-16周)
    if (weekRanges.isEmpty) {
      weekRanges = [WeekRange(1, 16)];
    }

    // 为每个周次范围创建事件
    for (final weekRange in weekRanges) {
      for (int week = weekRange.start; week <= weekRange.end; week++) {
        // 创建事件
        final event = _createEvent(
          courseTitle,
          instructor,
          location,
          notes,
          week,
          dayOfWeek,
          timeSlot,
          semesterStart,
        );
        events.add(event);
      }
    }

    return events;
  }

  /// 从类似 "1-8(周)[01-02节]" 或 "1,3,5-7(周)" 的文本解析周次范围
  static List<WeekRange> _parseWeekRanges(String text) {
    List<WeekRange> ranges = [];

    // 提取周次信息，例如 "1-8(周)[01-02节]"
    final weekPattern = RegExp(
      r'(\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)\s*(?:\(周\)|\(周\)|\(周\))',
    );
    final weekMatch = weekPattern.firstMatch(text);

    if (weekMatch != null) {
      String weekText = weekMatch.group(1) ?? '';

      // 分割逗号分隔的部分
      List<String> parts = weekText.split(',');

      for (String part in parts) {
        if (part.contains('-')) {
          // 处理范围，如 "1-8"
          List<String> range = part.split('-');
          if (range.length == 2) {
            int start = int.tryParse(range[0]) ?? 1;
            int end = int.tryParse(range[1]) ?? start;
            ranges.add(WeekRange(start, end));
          }
        } else {
          // 处理单个值，如 "3"
          int week = int.tryParse(part) ?? 0;
          if (week > 0) {
            ranges.add(WeekRange(week, week));
          }
        }
      }
    } else {
      // 尝试匹配更简单的格式，例如 "1-8周" 或 "1,3,5-7周"
      final simplePattern = RegExp(r'(\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)周');
      final simpleMatch = simplePattern.firstMatch(text);

      if (simpleMatch != null) {
        String weekText = simpleMatch.group(1) ?? '';
        List<String> parts = weekText.split(',');

        for (String part in parts) {
          if (part.contains('-')) {
            List<String> range = part.split('-');
            if (range.length == 2) {
              int start = int.tryParse(range[0]) ?? 1;
              int end = int.tryParse(range[1]) ?? start;
              ranges.add(WeekRange(start, end));
            }
          } else {
            int week = int.tryParse(part) ?? 0;
            if (week > 0) {
              ranges.add(WeekRange(week, week));
            }
          }
        }
      }
    }

    // 如果没有解析到任何周次，使用默认值 1-16周
    if (ranges.isEmpty) {
      ranges.add(WeekRange(1, 16));
    }

    return ranges;
  }

  /// 为特定课程创建 CalendarEvent
  static CalendarEvent _createEvent(
    String title,
    String instructor,
    String location,
    String notes,
    int week,
    int dayOfWeek,
    TimeSlot timeSlot,
    DateTime semesterStart,
  ) {
    // 计算这个特定课程的日期
    final eventDate = semesterStart.add(
      Duration(days: (week - 1) * 7 + dayOfWeek - 1),
    );

    // 创建开始和结束时间
    final startTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      timeSlot.startTime.hour,
      timeSlot.startTime.minute,
    );

    final endTime = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      timeSlot.endTime.hour,
      timeSlot.endTime.minute,
    );

    // 构建备注字符串
    String fullNotes = '';
    if (instructor.isNotEmpty) {
      fullNotes += '教师: $instructor\n';
    }
    if (location.isNotEmpty) {
      fullNotes += '地点: $location\n';
    }
    if (notes.isNotEmpty) {
      fullNotes += notes + '\n';
    }
    fullNotes += '第${week}周 周${_getDayName(dayOfWeek)}';

    // 创建事件
    return CalendarEvent(
      title: title,
      notes: fullNotes.trim(),
      startTime: startTime,
      endTime: endTime,
      reminderMinutes: [20], // 默认提醒
      color: _getCourseColor(title), // 根据课程名称生成一致的颜色
    );
  }

  // 获取星期几的中文名称
  static String _getDayName(int day) {
    const dayNames = ['一', '二', '三', '四', '五', '六', '日'];
    if (day >= 1 && day <= 7) {
      return dayNames[day - 1];
    }
    return day.toString();
  }

  /// 根据课程名称生成一致的颜色
  static String _getCourseColor(String courseName) {
    // 日历颜色列表
    final colors = [
      '#DBAF47',
      '#FF9786',
      '#2DBCCC',
      '#D67250',
      '#A67664',
      '#0077a6', 
    ];

    // 从课程名称生成哈希码
    final hash = courseName.hashCode.abs();
    // 使用哈希选择颜色
    return colors[hash % colors.length];
  }
}

/// 表示课表中的时间槽
class TimeSlot {
  final int index;
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({
    required this.index,
    required this.startTime,
    required this.endTime,
  });
}

/// 表示一个周次范围（例如，第1-8周）
class WeekRange {
  final int start;
  final int end;

  WeekRange(this.start, this.end);
}
