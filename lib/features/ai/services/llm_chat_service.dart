import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../calendar/services/event_repository.dart';
import '../../calendar/models/event.dart';
import 'llm_status.dart';

class AgentTools {
  // 获取未来一周的课程
  static Future<List<CalendarEvent>> getNextWeekCourses() async {
    try {
      final now = DateTime.now();
      final nextWeekEnd = now.add(const Duration(days: 7));

      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      return allEvents.where((event) {
          return event.startTime.isAfter(now) &&
              event.startTime.isBefore(nextWeekEnd);
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      print('获取下周课程失败: $e');
      return [];
    }
  }

  // 获取特定日期的课程
  static Future<List<CalendarEvent>> getCoursesForDate(DateTime date) async {
    try {
      final targetDate = DateTime(date.year, date.month, date.day);

      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      return allEvents.where((event) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );

          return eventDate.isAtSameMomentAs(targetDate);
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      print('获取指定日期课程失败: $e');
      return [];
    }
  }

  // 格式化课程信息为易读的文本
  static String formatCoursesInfo(List<CalendarEvent> courses) {
    if (courses.isEmpty) {
      return "没有找到课程安排。";
    }

    final buffer = StringBuffer();
    buffer.writeln("找到 ${courses.length} 门课程：");

    for (var i = 0; i < courses.length; i++) {
      final course = courses[i];
      final startTime = DateFormat('HH:mm').format(course.startTime);
      final endTime = DateFormat('HH:mm').format(course.endTime);
      final date = DateFormat('MM月dd日').format(course.startTime);
      final weekday = DateFormat('E', 'zh_CN').format(course.startTime);

      buffer.writeln();
      buffer.writeln("${i + 1}. ${course.title}");
      buffer.writeln("   时间: $date ($weekday) $startTime-$endTime");

      // 仅提取和显示地点信息，不显示完整备注
      if (course.notes.isNotEmpty) {
        final locationMatch = RegExp(
          r'地点: (.+?)(?:\n|$)',
        ).firstMatch(course.notes);
        if (locationMatch != null) {
          buffer.writeln("   地点: ${locationMatch.group(1)}");
        }
      }
    }

    return buffer.toString();
  }

  // 新增事件
  static Future<String> addEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String notes = '',
    String color = '#FF2D55',
    List<int> reminderMinutes = const [20],
  }) async {
    try {
      final event = CalendarEvent(
        title: title,
        notes: notes,
        startTime: startTime,
        endTime: endTime,
        reminderMinutes: reminderMinutes,
        color: color,
      );

      await EventRepository().insertEvent(event);
      return "已成功添加课程：${event.title}（${DateFormat('MM月dd日 HH:mm').format(event.startTime)}-${DateFormat('HH:mm').format(event.endTime)}）";
    } catch (e) {
      return "添加课程失败: $e";
    }
  }

  // 查找匹配事件，用于删除或修改
  static Future<Map<String, dynamic>> findMatchingEvents({
    String? title,
    DateTime? date,
    String? weekday,
    String? timeRange,
  }) async {
    try {
      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      if (allEvents.isEmpty) {
        return {'success': false, 'message': '没有找到任何课程或事件。'};
      }

      // 按开始时间排序
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      // 用于收集匹配的事件
      List<CalendarEvent> matchedEvents = [];

      // 1. 基于标题过滤 (如果提供)
      if (title != null && title.isNotEmpty) {
        matchedEvents =
            allEvents.where((event) {
              return event.title.toLowerCase().contains(title.toLowerCase());
            }).toList();
      } else {
        matchedEvents = List.from(allEvents);
      }

      // 2. 基于日期过滤 (如果提供)
      if (date != null) {
        final targetDate = DateTime(date.year, date.month, date.day);
        matchedEvents =
            matchedEvents.where((event) {
              final eventDate = DateTime(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              return eventDate.isAtSameMomentAs(targetDate);
            }).toList();
      }

      // 3. 基于星期几过滤 (如果提供)
      if (weekday != null && weekday.isNotEmpty) {
        final weekdayMap = {
          '周一': 1,
          '星期一': 1,
          '一': 1,
          'Monday': 1,
          '周二': 2,
          '星期二': 2,
          '二': 2,
          'Tuesday': 2,
          '周三': 3,
          '星期三': 3,
          '三': 3,
          'Wednesday': 3,
          '周四': 4,
          '星期四': 4,
          '四': 4,
          'Thursday': 4,
          '周五': 5,
          '星期五': 5,
          '五': 5,
          'Friday': 5,
          '周六': 6,
          '星期六': 6,
          '六': 6,
          'Saturday': 6,
          '周日': 7,
          '星期日': 7,
          '日': 7,
          'Sunday': 7,
        };

        final targetWeekday = weekdayMap[weekday];
        if (targetWeekday != null) {
          matchedEvents =
              matchedEvents.where((event) {
                return event.startTime.weekday == targetWeekday;
              }).toList();
        }
      }

      // 4. 基于时间范围过滤 (如果提供)
      if (timeRange != null && timeRange.isNotEmpty) {
        // 尝试匹配时间范围格式 (例如: "8:00-10:00")
        final timePattern = RegExp(
          r'(\d{1,2}):?(\d{0,2})?\s*[-~到至]\s*(\d{1,2}):?(\d{0,2})?',
        );
        final match = timePattern.firstMatch(timeRange);

        if (match != null) {
          final startHour = int.parse(match.group(1) ?? '0');
          final startMinute = int.parse(match.group(2) ?? '0');


          matchedEvents =
              matchedEvents.where((event) {
                final eventStartHour = event.startTime.hour;
                final eventStartMinute = event.startTime.minute;

                // 判断时间是否重叠
                // 简化版：只检查开始时间是否接近
                return (eventStartHour == startHour &&
                        (eventStartMinute - startMinute).abs() < 30) ||
                    // 或者检查小时是否匹配
                    (eventStartHour == startHour);
              }).toList();
        }
      }

      // 如果没有匹配的事件
      if (matchedEvents.isEmpty) {
        return {'success': false, 'message': '没有找到匹配的课程或事件。'};
      }

      // 如果只找到一个匹配项
      if (matchedEvents.length == 1) {
        final event = matchedEvents.first;
        return {
          'success': true,
          'events': [event],
          'message':
              '找到1个匹配的事件：${event.title}（${DateFormat('MM月dd日 E', 'zh_CN').format(event.startTime)} ${DateFormat('HH:mm').format(event.startTime)}-${DateFormat('HH:mm').format(event.endTime)}）',
          'needConfirmation': true,
        };
      }

      // 如果找到多个匹配项
      final buffer = StringBuffer();
      buffer.writeln('找到 ${matchedEvents.length} 个匹配的事件：');

      for (var i = 0; i < matchedEvents.length; i++) {
        final event = matchedEvents[i];
        final date = DateFormat('MM月dd日', 'zh_CN').format(event.startTime);
        final weekday = DateFormat('E', 'zh_CN').format(event.startTime);
        final time =
            '${DateFormat('HH:mm').format(event.startTime)}-${DateFormat('HH:mm').format(event.endTime)}';

        buffer.writeln('${i + 1}. ${event.title}（$date $weekday $time）');

        // 如果备注中有地点信息，也显示出来
        if (event.notes.isNotEmpty) {
          final locationMatch = RegExp(
            r'地点: (.+?)(?:\n|$)',
          ).firstMatch(event.notes);
          if (locationMatch != null) {
            buffer.writeln('   地点: ${locationMatch.group(1)}');
          }
        }
      }

      return {
        'success': true,
        'events': matchedEvents,
        'message': buffer.toString(),
        'needConfirmation': true,
        'requireSelection': matchedEvents.length > 1,
      };
    } catch (e) {
      return {'success': false, 'message': '查找事件失败: $e'};
    }
  }

  // 删除事件 - 增强版，支持按描述查找
  static Future<Map<String, dynamic>> findAndDeleteEvent({
    String? title,
    DateTime? date,
    String? weekday,
    String? timeRange,
    String? eventId,
  }) async {
    try {
      // 如果直接提供了eventId，则直接删除
      if (eventId != null) {
        final repository = EventRepository();
        final events = await repository.getEvents();

        try {
          final eventToDelete = events.firstWhere(
            (event) => event.id == eventId,
          );

          await repository.deleteEvent(eventToDelete);

          return {
            'success': true,
            'message':
                "已删除课程：${eventToDelete.title}（${DateFormat('MM月dd日 E', 'zh_CN').format(eventToDelete.startTime)} ${DateFormat('HH:mm').format(eventToDelete.startTime)}-${DateFormat('HH:mm').format(eventToDelete.endTime)}）",
            'event': eventToDelete,
          };
        } catch (e) {
          return {'success': false, 'message': "未找到ID为 $eventId 的课程"};
        }
      }

      // 否则通过描述查找事件
      final matchResult = await findMatchingEvents(
        title: title,
        date: date,
        weekday: weekday,
        timeRange: timeRange,
      );

      if (!matchResult['success']) {
        return matchResult; // 返回查找失败的消息
      }

      final events = matchResult['events'] as List<CalendarEvent>;

      // 如果需要用户选择，则返回匹配结果，不执行删除
      if (matchResult['requireSelection'] == true) {
        return {
          'success': true,
          'message': matchResult['message'],
          'events': events,
          'needConfirmation': true,
          'requireSelection': true,
        };
      }

      // 如果只有一个匹配项，且需要确认
      if (matchResult['needConfirmation'] == true) {
        return {
          'success': true,
          'message':
              "是否确认删除：${events[0].title}（${DateFormat('MM月dd日 E', 'zh_CN').format(events[0].startTime)} ${DateFormat('HH:mm').format(events[0].startTime)}-${DateFormat('HH:mm').format(events[0].endTime)}）",
          'events': events,
          'needConfirmation': true,
          'eventToDelete': events[0],
        };
      }

      return matchResult;
    } catch (e) {
      return {'success': false, 'message': "查找或删除事件时出错：$e"};
    }
  }

  // 确认删除事件
  static Future<String> confirmDeleteEvent(CalendarEvent event) async {
    try {
      final repository = EventRepository();
      await repository.deleteEvent(event);

      return "已成功删除课程：${event.title}（${DateFormat('MM月dd日 E', 'zh_CN').format(event.startTime)} ${DateFormat('HH:mm').format(event.startTime)}-${DateFormat('HH:mm').format(event.endTime)}）";
    } catch (e) {
      return "删除课程失败: $e";
    }
  }

  // 删除事件 - 基础版，直接通过ID删除
  static Future<String> deleteEvent(String eventId) async {
    try {
      final repository = EventRepository();
      final events = await repository.getEvents();
      final eventToDelete = events.firstWhere(
        (event) => event.id == eventId,
        orElse: () => throw Exception("未找到指定ID的课程"),
      );

      await repository.deleteEvent(eventToDelete);
      return "已成功删除课程：${eventToDelete.title}（${DateFormat('MM月dd日 HH:mm').format(eventToDelete.startTime)}）";
    } catch (e) {
      return "删除课程失败: $e";
    }
  }

  // 寻找具有相同时间的重复事件（用于批量操作）
  static Future<List<CalendarEvent>> findRecurringEvents(
    CalendarEvent sourceEvent,
  ) async {
    try {
      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      // 根据标题和时间匹配重复事件
      return allEvents.where((event) {
        // 比较标题
        if (event.title != sourceEvent.title) return false;

        // 比较星期几
        final isSameWeekday =
            event.startTime.weekday == sourceEvent.startTime.weekday;

        // 比较时间（小时和分钟）
        final isSameTime =
            event.startTime.hour == sourceEvent.startTime.hour &&
            event.startTime.minute == sourceEvent.startTime.minute &&
            event.endTime.hour == sourceEvent.endTime.hour &&
            event.endTime.minute == sourceEvent.endTime.minute;

        return isSameWeekday && isSameTime;
      }).toList();
    } catch (e) {
      print('查找重复事件失败: $e');
      return [];
    }
  }

  // 批量删除重复事件
  static Future<String> batchDeleteEvents(List<String> eventIds) async {
    if (eventIds.isEmpty) {
      return "没有指定要删除的事件";
    }

    try {
      final repository = EventRepository();
      final events = await repository.getEvents();

      int successCount = 0;
      for (final id in eventIds) {
        final eventToDelete = events.firstWhere(
          (event) => event.id == id,
          orElse: () => throw Exception("未找到ID为 $id 的课程"),
        );

        await repository.deleteEvent(eventToDelete);
        successCount++;
      }

      return "已成功删除 $successCount 个课程";
    } catch (e) {
      return "批量删除课程失败: $e";
    }
  }

  // 获取事件列表，返回事件ID和基本信息
  static Future<String> listEventsForSelection() async {
    try {
      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      if (allEvents.isEmpty) {
        return "没有找到任何课程";
      }

      // 按日期和时间排序
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      final buffer = StringBuffer();
      buffer.writeln("课程列表：");

      // 按星期几分组
      Map<int, List<CalendarEvent>> eventsByWeekday = {};
      for (var event in allEvents) {
        final weekday = event.startTime.weekday;
        if (!eventsByWeekday.containsKey(weekday)) {
          eventsByWeekday[weekday] = [];
        }
        eventsByWeekday[weekday]!.add(event);
      }

      // 定义星期几的名称
      final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

      // 按星期几顺序输出
      for (var i = 1; i <= 7; i++) {
        if (eventsByWeekday.containsKey(i) && eventsByWeekday[i]!.isNotEmpty) {
          buffer.writeln("\n${weekdayNames[i]}课程：");

          // 对该星期几的课程按时间排序
          eventsByWeekday[i]!.sort(
            (a, b) => a.startTime.compareTo(b.startTime),
          );

          for (var j = 0; j < eventsByWeekday[i]!.length; j++) {
            final event = eventsByWeekday[i]![j];
            final time =
                DateFormat('HH:mm-').format(event.startTime) +
                DateFormat('HH:mm').format(event.endTime);

            buffer.writeln("${j + 1}. ${event.title} ($time)");

            // 仅提取和显示地点信息
            if (event.notes.isNotEmpty) {
              final locationMatch = RegExp(
                r'地点: (.+?)(?:\n|$)',
              ).firstMatch(event.notes);
              if (locationMatch != null) {
                buffer.writeln("   地点: ${locationMatch.group(1)}");
              }
            }
          }
        }
      }

      buffer.writeln("\n您可以通过指定星期几、课程名称和时间来操作课程，例如：");
      buffer.writeln("- 删除周三下午的高等数学课");
      buffer.writeln("- 取消明天上午8点的课");

      return buffer.toString();
    } catch (e) {
      return "获取课程列表失败: $e";
    }
  }

  // 获取事件列表，带索引和ID映射（用于通过序号操作）
  static Future<Map<String, dynamic>> listEventsWithIndex() async {
    try {
      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      if (allEvents.isEmpty) {
        return {
          'success': false,
          'message': "没有找到任何课程",
          'events': [],
          'indexToIdMap': {},
        };
      }

      // 按日期和时间排序
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      final buffer = StringBuffer();
      buffer.writeln("课程列表：请使用序号来选择要操作的课程");

      // 创建索引到ID的映射表
      Map<int, String> indexToIdMap = {};

      // 按星期几分组
      Map<int, List<CalendarEvent>> eventsByWeekday = {};
      for (var event in allEvents) {
        final weekday = event.startTime.weekday;
        if (!eventsByWeekday.containsKey(weekday)) {
          eventsByWeekday[weekday] = [];
        }
        eventsByWeekday[weekday]!.add(event);
      }

      // 定义星期几的名称
      final weekdayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

      // 累计索引
      int globalIndex = 1;

      // 按星期几顺序输出
      for (var i = 1; i <= 7; i++) {
        if (eventsByWeekday.containsKey(i) && eventsByWeekday[i]!.isNotEmpty) {
          buffer.writeln("\n${weekdayNames[i]}课程：");

          // 对该星期几的课程按时间排序
          eventsByWeekday[i]!.sort(
            (a, b) => a.startTime.compareTo(b.startTime),
          );

          for (var j = 0; j < eventsByWeekday[i]!.length; j++) {
            final event = eventsByWeekday[i]![j];
            final time =
                DateFormat('HH:mm-').format(event.startTime) +
                DateFormat('HH:mm').format(event.endTime);

            buffer.writeln("${globalIndex}. ${event.title} ($time)");

            // 将序号映射到ID
            indexToIdMap[globalIndex] = event.id;
            globalIndex++;

            // 仅提取和显示地点信息
            if (event.notes.isNotEmpty) {
              final locationMatch = RegExp(
                r'地点: (.+?)(?:\n|$)',
              ).firstMatch(event.notes);
              if (locationMatch != null) {
                buffer.writeln("   地点: ${locationMatch.group(1)}");
              }
            }
          }
        }
      }

      buffer.writeln("\n请告诉我您想要删除哪一个课程的序号。例如：删除第3个课程");

      return {
        'success': true,
        'message': buffer.toString(),
        'events': allEvents,
        'indexToIdMap': indexToIdMap,
      };
    } catch (e) {
      return {
        'success': false,
        'message': "获取课程列表失败: $e",
        'events': [],
        'indexToIdMap': {},
      };
    }
  }

  // 通过序号删除事件
  static Future<String> deleteEventByIndex(int index) async {
    try {
      // 首先获取带索引的事件列表
      final listResult = await listEventsWithIndex();

      if (!listResult['success']) {
        return listResult['message'];
      }

      final indexToIdMap = listResult['indexToIdMap'] as Map<int, String>;

      // 检查索引是否有效
      if (!indexToIdMap.containsKey(index)) {
        return "无效的课程序号: $index。请使用有效的序号。";
      }

      // 获取对应的事件ID并删除
      final eventId = indexToIdMap[index];

      // 调用现有的删除方法
      final repository = EventRepository();
      final events = await repository.getEvents();
      final eventToDelete = events.firstWhere(
        (event) => event.id == eventId,
        orElse: () => throw Exception("未找到指定序号的课程"),
      );

      await repository.deleteEvent(eventToDelete);
      return "已成功删除课程：${eventToDelete.title}（${DateFormat('MM月dd日 E', 'zh_CN').format(eventToDelete.startTime)} ${DateFormat('HH:mm').format(eventToDelete.startTime)}-${DateFormat('HH:mm').format(eventToDelete.endTime)}）";
    } catch (e) {
      return "删除课程失败: $e";
    }
  }
}

class ApiService {
  // 替换为你的后端API地址
  final String baseUrl = 'http://127.0.0.1:8081/api';

  // 发送聊天请求到你的后端服务器
  Future<Map<String, dynamic>> sendChatRequest(
    String message, {
    List<Map<String, String>>? previousMessages,
    Map<String, dynamic>? userKnowledge,
    String? additionalContext,
    String? toolResponse, // 工具响应作为上下文
    String? toolAction, // 执行的工具动作类型
  }) async {
    try {
      // 构建消息列表
      final List<Map<String, String>> messages = [];

      // 使用改进的系统指令，引导LLM使用更严格的JSON格式
      messages.add({
        'role': 'system',
        'content': '''你是一位名为"石大助手"的AI助手，专注于为石河子大学的学生提供帮助。请严格遵循以下输出格式要求:

## 输出格式规范
- 当你需要执行工具操作时，你的回复必须以JSON代码块形式提供，使用```json和```包裹
- JSON必须严格遵循格式，不得添加额外注释或内容
- 始终使用双引号作为JSON的键和字符串值
- 所有日期格式必须为ISO 8601标准: YYYY-MM-DDTHH:MM:SS
- 永远不要在单个回复中混合普通文本和JSON指令
- 如果你需要执行工具操作，整个回复必须只包含一个JSON代码块
- 如果你不需要执行工具操作，不要使用JSON代码块格式

## 内容组织模式
1. 记忆：记住用户关键信息，如姓名、日程、喜好等，存储在用户知识库中
2. 思考：基于记忆和当前情境分析如何最好地帮助用户
3. 行动：执行相应操作(回答问题、提供建议、查询或修改课程)

## 可用工具及正确JSON格式
1. 网络搜索:
```json
{
  "action": "webSearch",
  "query": "搜索内容"
}
```

2. 查询课程信息:
```json
{
  "action": "getNextWeekCourses"
}
```
或
```json
{
  "action": "getCoursesForDate",
  "date": "YYYY-MM-DD"
}
```

3. 管理课程:
```json
{
  "action": "listEventsForSelection"
}
```
或
```json
{
  "action": "addEvent",
  "title": "课程名称",
  "startTime": "YYYY-MM-DDTHH:MM:SS",
  "endTime": "YYYY-MM-DDTHH:MM:SS",
  "notes": "备注信息",
  "color": "#FF2D55"
}
```
或
```json
{
  "action": "deleteEvent",
  "eventId": "事件ID"
}
```
或
```json
{
  "action": "batchDeleteEvents",
  "eventIds": ["ID1", "ID2"],
  "needConfirmation": true
}
```

4. 用户知识库操作:
```json
{
  "action": "updateUserKnowledge",
  "key": "键名",
  "value": "值"
}
```
或
```json
{
  "action": "getUserKnowledge",
  "key": "键名"
}
```

5. 信息提取（使用关键词匹配）:
在与用户对话时，请注意并提取以下类型的信息：
- 用户姓名：关注"我叫..."、"我是..."、"我的名字是..."等表达
- 专业信息：关注"我学的是..."、"我的专业是..."等表达
- 兴趣爱好：关注"我喜欢..."、"我的爱好是..."等表达
- 年级信息：关注"我是大一/大二..."等表达
- 家乡信息：关注"我来自..."、"我的家乡是..."等表达
提取到这些信息后，在对话中自然使用，无需特殊格式标记。

6. 思考过程(仅在需要时使用):
```json
{
  "ai_thinking": "你的思考内容",
  "requires_action": true
}
```

7. 总结记忆:
```json
{
  "action": "summarizeMemories",
  "summary": "记忆总结内容"
}
```

完成工具操作后，等待工具执行结果再继续对话。不要以文本形式解释你将要执行的操作。对于石河子大学的地理位置，默认使用新疆石河子市进行天气查询。''',
      });

      // 添加用户知识库信息
      if (userKnowledge != null && userKnowledge.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': '用户知识库信息：${jsonEncode(userKnowledge)}',
        });
      }

      // 添加记忆流上下文（如果有）
      if (additionalContext != null && additionalContext.isNotEmpty) {
        messages.add({'role': 'system', 'content': additionalContext});
      }

      // 添加工具响应上下文（如果有）
      if (toolResponse != null && toolAction != null) {
        messages.add({
          'role': 'system',
          'content': '''工具执行结果：
执行的工具：$toolAction
返回的信息：
$toolResponse

请分析上述工具返回的结果，并以恰当的格式回复用户。如果需要执行额外操作，记住使用正确的JSON格式。''',
        });
      }

      // 添加之前的消息历史
      if (previousMessages != null && previousMessages.isNotEmpty) {
        messages.addAll(previousMessages);
      }

      // 添加当前用户消息
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'glm-4',
          'messages': messages,
          'temperature': 0.7,
          'top_p': 0.9,
          'tools': [
            {
              'type': 'function',
              'function': {
                'name': 'webSearch',
                'description': '使用网络搜索获取实时信息',
                'parameters': {
                  'type': 'object',
                  'properties': {
                    'query': {'type': 'string', 'description': '搜索内容'},
                  },
                  'required': ['query'],
                },
              },
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'API请求失败，状态码: ${response.statusCode}, 响应: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('请求过程中发生错误: $e');
    }
  }

  // 发送网络搜索请求
  Future<Map<String, dynamic>> searchWeb(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/web_search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query, 'search_engine': 'search_std'}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('网络搜索请求失败：${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络搜索出错: $e');
    }
  }

  // 获取天气信息（专用方法）
  Future<Map<String, dynamic>> getWeather({String location = '石河子市'}) async {
    try {
      final response = await searchWeb('$location 今日天气实时预报');
      return response;
    } catch (e) {
      throw Exception('获取天气信息失败: $e');
    }
  }

  // 获取后端服务器状态信息
  Future<Map<String, dynamic>> getServerStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取状态失败：${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取状态请求出错: $e');
    }
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentModel = "未知";
  int _currentTokens = 0;
  bool _isThresholdAlert = false;

  List<Map<String, String>> _getMessageHistory() {
    return _messages
        .map(
          (msg) => {
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.message,
          },
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchServerStats();
    Timer.periodic(Duration(minutes: 1), (timer) {
      _fetchServerStats();
    });
  }

  void _fetchServerStats() async {
    try {
      final stats = await _apiService.getServerStats();
      setState(() {
        _currentModel = stats['current_model'] ?? "未知";
        _currentTokens = stats['current_window_tokens'] ?? 0;
        _isThresholdAlert = stats['is_threshold_alert'] ?? false;
      });
    } catch (e) {
      print('获取服务器状态失败: $e');
    }
  }

  void _openStatsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApiStatsScreen(
          serverUrl: _apiService.baseUrl.replaceAll('/api', ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 聊天'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isThresholdAlert ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentModel} (${_currentTokens} tokens)',
                  style: TextStyle(
                    color: _isThresholdAlert ? Colors.deepOrange : Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.insights),
            onPressed: _openStatsScreen,
            tooltip: '查看统计数据',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchServerStats,
            tooltip: '刷新服务器状态',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(message: userMessage, isUser: true));
      _isLoading = true;
      _messageController.clear();
    });
    try {
      final messageHistory = _getMessageHistory();
      if (messageHistory.isNotEmpty) {
        messageHistory.removeLast();
      }
      final response = await _apiService.sendChatRequest(
        userMessage,
        previousMessages: messageHistory.length > 6 ? messageHistory.sublist(messageHistory.length - 6) : messageHistory,
      );
      final aiResponse = response['choices'][0]['message']['content'] as String;
      // 只处理一次LLM决策，不再递归调用LLM
      try {
        final jsonResponse = jsonDecode(aiResponse);
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('action')) {
          final action = jsonResponse['action'];
          String toolResponse = "";
          setState(() {
            _messages.add(ChatMessage(message: "正在处理...", isUser: false, isTemporary: true));
          });
          switch (action) {
            case 'getNextWeekCourses':
              final courses = await AgentTools.getNextWeekCourses();
              toolResponse = AgentTools.formatCoursesInfo(courses);
              break;
            case 'getCoursesForDate':
              if (jsonResponse.containsKey('date')) {
                try {
                  final date = DateTime.parse(jsonResponse['date']);
                  final courses = await AgentTools.getCoursesForDate(date);
                  toolResponse = AgentTools.formatCoursesInfo(courses);
                } catch (e) {
                  toolResponse = "日期格式有误，无法查询课程信息。";
                }
              } else {
                toolResponse = "缺少日期参数，无法查询课程信息。";
              }
              break;
            case 'listEventsForSelection':
              toolResponse = await AgentTools.listEventsForSelection();
              break;
            case 'addEvent':
              if (jsonResponse.containsKey('title') && jsonResponse.containsKey('startTime') && jsonResponse.containsKey('endTime')) {
                try {
                  final title = jsonResponse['title'];
                  final startTime = DateTime.parse(jsonResponse['startTime']);
                  final endTime = DateTime.parse(jsonResponse['endTime']);
                  final notes = jsonResponse['notes'] ?? '';
                  final color = jsonResponse['color'] ?? '#FF2D55';
                  final reminderMinutes = jsonResponse.containsKey('reminderMinutes') && jsonResponse['reminderMinutes'] is List ? List<int>.from(jsonResponse['reminderMinutes']) : [20];
                  toolResponse = await AgentTools.addEvent(
                    title: title,
                    startTime: startTime,
                    endTime: endTime,
                    notes: notes,
                    color: color,
                    reminderMinutes: reminderMinutes,
                  );
                } catch (e) {
                  toolResponse = "添加课程失败: $e";
                }
              } else {
                toolResponse = "缺少必要参数，无法添加课程。";
              }
              break;
            case 'deleteEvent':
              if (jsonResponse.containsKey('eventId')) {
                final eventId = jsonResponse['eventId'];
                toolResponse = await AgentTools.deleteEvent(eventId);
              } else {
                toolResponse = "缺少事件ID，无法删除课程。";
              }
              break;
            case 'batchDeleteEvents':
              if (jsonResponse.containsKey('eventIds') && jsonResponse['eventIds'] is List) {
                final eventIds = List<String>.from(jsonResponse['eventIds']);
                toolResponse = await AgentTools.batchDeleteEvents(eventIds);
              } else {
                toolResponse = "缺少事件ID列表，无法批量删除课程。";
              }
              break;
            case 'webSearch':
              if (jsonResponse.containsKey('query')) {
                final query = jsonResponse['query'] as String;
                try {
                  final searchResult = await _apiService.searchWeb(query);
                  if (searchResult.containsKey('results') && searchResult['results'] is List && searchResult['results'].isNotEmpty) {
                    final results = searchResult['results'] as List;
                    toolResponse = "搜索\"$query\"的结果:\n\n";
                    for (var i = 0; i < results.length && i < 3; i++) {
                      final result = results[i] as Map<String, dynamic>;
                      final title = result['title'] as String? ?? '未知标题';
                      final content = result['content'] as String? ?? '无内容';
                      toolResponse += "${i + 1}. $title\n$content\n\n";
                    }
                  } else {
                    toolResponse = "无法找到\"$query\"的搜索结果";
                  }
                } catch (e) {
                  toolResponse = "搜索出错: $e";
                }
              } else {
                toolResponse = "缺少搜索关键词，无法执行搜索";
              }
              break;
            default:
              toolResponse = "暂不支持的操作类型: $action";
          }
          setState(() {
            _messages.removeWhere((msg) => msg.isTemporary);
            _messages.add(ChatMessage(message: toolResponse, isUser: false));
            _isLoading = false;
          });
          _fetchServerStats();
          return;
        }
      } catch (e) {
        // 不是JSON或无action，按普通文本回复
      }
      setState(() {
        _messages.add(ChatMessage(message: aiResponse, isUser: false));
        _isLoading = false;
      });
      _fetchServerStats();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(message: '发生错误: $e', isUser: false, isError: true));
        _isLoading = false;
      });
    }
  }
}

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isError;
  final bool isTemporary;

  const ChatMessage({
    required this.message,
    required this.isUser,
    this.isError = false,
    this.isTemporary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: isError ? Colors.red : Colors.blue,
              child: Icon(
                isError ? Icons.error : Icons.smart_toy,
                color: Colors.white,
              ),
            ),
          SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color:
                    isUser
                        ? Colors.blue[100]
                        : (isError ? Colors.red[100] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(message),
            ),
          ),
          SizedBox(width: 8.0),
          if (isUser)
            CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
