import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/llm_chat_service.dart';
import '../models/user_knowledge.dart';
import '../../calendar/services/event_repository.dart';
import '../../calendar/models/event.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final ApiService _apiService = ApiService();
  final UserKnowledgeService _knowledgeService = UserKnowledgeService();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialGreetingSent = false;
  Map<String, dynamic> _userKnowledge = {};

  @override
  void initState() {
    super.initState();
    _initUserKnowledge();
  }

  // 初始化用户知识库并发送初始问候
  Future<void> _initUserKnowledge() async {
    await _knowledgeService.initialize();
    _userKnowledge = await _knowledgeService.getAllKnowledge();

    setState(() {});

    _sendInitialGreeting();
  }

  Future<void> _sendInitialGreeting() async {
    if (_isInitialGreetingSent) return;

    setState(() {
      _isLoading = true;
    });

    // 获取今日课程
    final todayClasses = await _getTodayClasses();

    // 获取用户名
    final userName = await _getUserName();

    // 获取天气信息
    String weatherInfo = "";
    try {
      final weatherResponse = await _apiService.getWeather();
      weatherInfo = _extractWeatherInfo(weatherResponse);
    } catch (e) {
      print('获取天气失败: $e');
      weatherInfo = "（天气信息获取失败）";
    }

    // 存储用户信息到知识库
    if (userName != '同学') {
      await _knowledgeService.setValue('user_name', userName);
    }

    // 构建初始问候语
    final now = DateTime.now();
    final greeting = _getTimeBasedGreeting(now);
    String initialMessage = "$greeting $userName！";

    // 添加天气信息
    if (weatherInfo.isNotEmpty) {
      initialMessage += "\n\n石河子今日天气: $weatherInfo";
    }

    if (todayClasses.isEmpty) {
      initialMessage += "\n\n今天没有安排课程，您可以好好休息或处理其他事务。";
    } else {
      initialMessage += "\n\n今天您有 ${todayClasses.length} 节课：\n\n";

      for (var i = 0; i < todayClasses.length; i++) {
        final event = todayClasses[i];
        final startTime = DateFormat('HH:mm').format(event.startTime);
        final endTime = DateFormat('HH:mm').format(event.endTime);
        initialMessage +=
            "${i + 1}. **${event.title}** (${startTime}-${endTime})";

        if (event.notes.isNotEmpty) {
          // 提取地点信息，如果有的话
          final locationMatch = RegExp(
            r'地点: (.+?)(?:\n|$)',
          ).firstMatch(event.notes);
          if (locationMatch != null) {
            initialMessage += " - 地点: ${locationMatch.group(1)}";
          }
        }

        initialMessage += "\n";
      }

      initialMessage += "\n有什么我可以帮您的吗？";
    }

    try {
      setState(() {
        _messages.add(ChatMessage(message: initialMessage, isUser: false));
        _isLoading = false;
        _isInitialGreetingSent = true;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            message: "欢迎使用 AI 助手！很抱歉，我在获取您的日程时遇到了一些问题。",
            isUser: false,
          ),
        );
        _isLoading = false;
        _isInitialGreetingSent = true;
      });
    }
  }

  String _extractWeatherInfo(Map<String, dynamic> weatherResponse) {
    try {
      // 提取天气信息（根据您的API返回格式进行调整）
      if (weatherResponse.containsKey('results') &&
          weatherResponse['results'] is List &&
          weatherResponse['results'].isNotEmpty) {
        final results = weatherResponse['results'];

        // 简单提取第一个结果中的温度和天气状况
        // 实际应用中需要根据您的API返回格式调整
        return results[0]['content'] ?? "天气信息获取成功，但解析失败";
      }
      return "天气信息获取成功，但格式异常";
    } catch (e) {
      print('解析天气信息出错: $e');
      return "天气信息解析失败";
    }
  }

  String _getTimeBasedGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 6) {
      return "凌晨好";
    } else if (hour < 9) {
      return "早上好";
    } else if (hour < 12) {
      return "上午好";
    } else if (hour < 14) {
      return "中午好";
    } else if (hour < 18) {
      return "下午好";
    } else if (hour < 22) {
      return "晚上好";
    } else {
      return "夜深了";
    }
  }

  Future<String> _getUserName() async {
    // 首先检查知识库
    String? name = await _knowledgeService.getValue('user_name');
    if (name != null) {
      return name;
    }

    // 回退到共享首选项
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? '同学';
  }

  Future<List<CalendarEvent>> _getTodayClasses() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final repository = EventRepository();
      final allEvents = await repository.getEvents();

      return allEvents.where((event) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );

          return eventDate.isAtSameMomentAs(today);
        }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      print('获取今日课程失败: $e');
      return [];
    }
  }

  // 保存消息历史以便发送到API
  List<Map<String, String>> _getMessageHistory() {
    final messages =
        _messages
            .map(
              (msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.message,
              },
            )
            .toList();

    return messages.length > 10
        ? messages.sublist(messages.length - 10)
        : messages;
  }

  // 显示确认对话框
  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('确认'),
              ),
            ],
          ),
    );

    return result ?? false;
  }

  // 处理用户知识库操作
  Future<void> _handleUserKnowledgeAction(
    Map<String, dynamic> actionData,
  ) async {
    final action = actionData['action'];
    String toolResponse = "";

    setState(() {
      _messages.add(
        ChatMessage(message: "正在处理...", isUser: false, isTemporary: true),
      );
    });

    try {
      switch (action) {
        case 'updateUserKnowledge':
          if (actionData.containsKey('key') &&
              actionData.containsKey('value')) {
            final key = actionData['key'];
            final value = actionData['value'];
            await _knowledgeService.setValue(key, value);
            _userKnowledge = await _knowledgeService.getAllKnowledge();
            toolResponse = "已更新用户知识库: $key = $value";
          } else {
            toolResponse = "缺少键或值，无法更新知识库。";
          }
          break;

        case 'getUserKnowledge':
          if (actionData.containsKey('key')) {
            final key = actionData['key'];
            final value = await _knowledgeService.getValue(key);
            if (value != null) {
              toolResponse = "用户知识库 $key = $value";
            } else {
              toolResponse = "知识库中不存在键 '$key'";
            }
          } else {
            // 返回整个知识库
            _userKnowledge = await _knowledgeService.getAllKnowledge();
            if (_userKnowledge.isEmpty) {
              toolResponse = "用户知识库为空";
            } else {
              toolResponse = "用户知识库内容:\n${jsonEncode(_userKnowledge)}";
            }
          }
          break;

        default:
          toolResponse = "不支持的知识库操作: $action";
      }
    } catch (e) {
      toolResponse = "执行知识库操作时发生错误: $e";
    }

    // 移除临时加载消息，显示工具响应结果
    setState(() {
      // 移除临时消息
      _messages.removeWhere((msg) => msg.isTemporary);

      // 添加工具响应
      _messages.add(ChatMessage(message: toolResponse, isUser: false));
      _isLoading = false;
    });
  }

  // 处理网络搜索操作
  Future<void> _handleWebSearchAction(Map<String, dynamic> actionData) async {
    setState(() {
      _messages.add(
        ChatMessage(message: "正在搜索...", isUser: false, isTemporary: true),
      );
    });

    String searchResponse = "";
    try {
      if (actionData.containsKey('query')) {
        final query = actionData['query'] as String?;
        if (query == null) {
          searchResponse = "搜索关键词不能为空";
        } else {
          final response = await _apiService.searchWeb(query);

          if (response.containsKey('results') &&
              response['results'] is List &&
              response['results'].isNotEmpty) {
            // 提取搜索结果
            final results = response['results'] as List;
            searchResponse = "搜索结果:\n\n";

            for (var i = 0; i < results.length && i < 3; i++) {
              final result = results[i] as Map<String, dynamic>;
              final title = result['title'] as String? ?? '未知标题';
              final content = result['content'] as String? ?? '无内容';
              searchResponse += "**${i + 1}. $title**\n";
              searchResponse += "$content\n\n";
            }
          } else {
            searchResponse = "无法找到关于\"$query\"的搜索结果";
          }
        }
      } else {
        searchResponse = "缺少搜索关键词，无法执行搜索";
      }
    } catch (e) {
      print('执行网络搜索时发生错误: $e');
      searchResponse = "执行网络搜索时发生错误: $e";
    }

    // 移除临时加载消息，显示搜索结果
    setState(() {
      // 移除临时消息
      _messages.removeWhere((msg) => msg.isTemporary);

      // 添加搜索响应
      _messages.add(ChatMessage(message: searchResponse, isUser: false));
      _isLoading = false;
    });
  }

  // 处理课程事件操作
  Future<void> _handleCalendarAction(Map<String, dynamic> actionData) async {
    final action = actionData['action'];
    String toolResponse = "";

    setState(() {
      _messages.add(
        ChatMessage(message: "正在处理...", isUser: false, isTemporary: true),
      );
    });

    try {
      switch (action) {
        case 'getNextWeekCourses':
          final courses = await AgentTools.getNextWeekCourses();
          toolResponse = AgentTools.formatCoursesInfo(courses);
          break;

        case 'getCoursesForDate':
          if (actionData.containsKey('date')) {
            try {
              final date = DateTime.parse(actionData['date']);
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
          if (actionData.containsKey('title') &&
              actionData.containsKey('startTime') &&
              actionData.containsKey('endTime')) {
            try {
              final title = actionData['title'];
              final startTime = DateTime.parse(actionData['startTime']);
              final endTime = DateTime.parse(actionData['endTime']);
              final notes = actionData['notes'] ?? '';
              final color = actionData['color'] ?? '#FF2D55';
              final reminderMinutes =
                  actionData.containsKey('reminderMinutes') &&
                          actionData['reminderMinutes'] is List
                      ? List<int>.from(actionData['reminderMinutes'])
                      : [20];

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

        case 'findAndDeleteEvent':
          // 使用增强版的删除方法，支持通过描述查找事件
          final result = await AgentTools.findAndDeleteEvent(
            title: actionData['title'],
            date:
                actionData.containsKey('date')
                    ? DateTime.parse(actionData['date'])
                    : null,
            weekday: actionData['weekday'],
            timeRange: actionData['timeRange'],
            eventId: actionData['eventId'],
          );

          if (result['success']) {
            if (result.containsKey('events') &&
                result.containsKey('requireSelection') &&
                result['requireSelection'] == true) {
              // 多个匹配，需要用户选择
              toolResponse = result['message'];
              setState(() {
                _messages.removeWhere((msg) => msg.isTemporary);
                _messages.add(
                  ChatMessage(message: toolResponse, isUser: false),
                );
              });

              // 更新用户记忆，表示正在删除事件，需要选择
              await _knowledgeService.setValue(
                'pending_action',
                'delete_event_selection',
              );
              await _knowledgeService.setValue(
                'pending_events',
                jsonEncode(
                  (result['events'] as List<CalendarEvent>)
                      .map((e) => e.id)
                      .toList(),
                ),
              );

              // 提前返回，等待用户选择
              setState(() {
                _isLoading = false;
              });
              return;
            } else if (result.containsKey('eventToDelete') &&
                result.containsKey('needConfirmation') &&
                result['needConfirmation'] == true) {
              // 单个匹配，但需要确认
              final event = result['eventToDelete'] as CalendarEvent;

              toolResponse = result['message'];

              // 显示确认对话框
              final confirmed = await _showConfirmationDialog(
                "删除确认",
                toolResponse,
              );

              if (confirmed) {
                toolResponse = await AgentTools.confirmDeleteEvent(event);
              } else {
                toolResponse = "已取消删除操作。";
              }
            } else {
              // 直接返回结果
              toolResponse = result['message'];
            }
          } else {
            toolResponse = result['message']; // 显示错误消息
          }
          break;

        case 'deleteEvent':
          if (actionData.containsKey('eventId')) {
            final eventId = actionData['eventId'];
            toolResponse = await AgentTools.deleteEvent(eventId);
          } else if (actionData.containsKey('eventIndex') &&
              actionData.containsKey('pendingEvents')) {
            // 从待选列表中选择事件删除
            try {
              final pendingEvents =
                  jsonDecode(
                        await _knowledgeService.getValue('pending_events') ??
                            '[]',
                      )
                      as List;
              if (pendingEvents.isEmpty) {
                toolResponse = "没有待选的事件可供删除。";
                break;
              }

              final index = actionData['eventIndex'] as int;
              if (index < 0 || index >= pendingEvents.length) {
                toolResponse = "选择的序号无效。";
                break;
              }

              final eventId = pendingEvents[index];
              toolResponse = await AgentTools.deleteEvent(eventId as String);

              // 清除待处理状态
              await _knowledgeService.removeValue('pending_action');
              await _knowledgeService.removeValue('pending_events');
            } catch (e) {
              toolResponse = "删除选定事件失败: $e";
            }
          } else {
            toolResponse = "缺少事件ID或选择索引，无法删除课程。";
          }
          break;

        case 'batchDeleteEvents':
          if (actionData.containsKey('eventIds') &&
              actionData['eventIds'] is List) {
            final eventIds = List<String>.from(actionData['eventIds']);
            final needConfirmation = actionData['needConfirmation'] == true;

            if (needConfirmation) {
              // 构建确认内容
              final confirmContent = StringBuffer("确定要删除以下课程吗？\n\n");

              try {
                final repository = EventRepository();
                final events = await repository.getEvents();

                for (final id in eventIds) {
                  try {
                    final event = events.firstWhere((e) => e.id == id);
                    final date = DateFormat(
                      'MM月dd日(E)',
                      'zh_CN',
                    ).format(event.startTime);
                    final time =
                        DateFormat('HH:mm-').format(event.startTime) +
                        DateFormat('HH:mm').format(event.endTime);

                    confirmContent.writeln("- ${event.title} ($date $time)");
                  } catch (e) {
                    confirmContent.writeln("- ID为 $id 的课程(未找到详情)");
                  }
                }

                setState(() {
                  _messages.removeWhere((msg) => msg.isTemporary);
                });

                final confirmed = await _showConfirmationDialog(
                  "批量删除确认",
                  confirmContent.toString(),
                );

                if (confirmed) {
                  toolResponse = await AgentTools.batchDeleteEvents(eventIds);
                } else {
                  toolResponse = "已取消批量删除操作。";
                }
              } catch (e) {
                // Ignore any errors when building confirmation dialog content
                // as we'll still attempt to show the dialog with available information
              }
            } else {
              // 不需要确认，直接删除
              toolResponse = await AgentTools.batchDeleteEvents(eventIds);
            }
          } else {
            toolResponse = "缺少事件ID列表，无法批量删除课程。";
          }
          break;

        case 'webSearch':
          // 重定向到网络搜索处理方法
          await _handleWebSearchAction(actionData);
          return; // 已处理搜索，直接返回

        default:
          toolResponse = "不支持的操作类型: $action";
      }
    } catch (e) {
      toolResponse = "执行操作时发生错误: $e";
    }

    // 移除临时加载消息，显示工具响应结果
    setState(() {
      // 移除临时消息
      _messages.removeWhere((msg) => msg.isTemporary);

      // 添加工具响应
      _messages.add(ChatMessage(message: toolResponse, isUser: false));
      _isLoading = false;
    });

    // 开始链式反应：将工具结果发送回LLM进行处理
    try {
      final messageHistory = _getMessageHistory();
      // 保留最近的几条消息作为上下文
      final contextMessages =
          messageHistory.length > 6
              ? messageHistory.sublist(messageHistory.length - 6)
              : messageHistory;

      // 发送工具执行结果给LLM请求链式反应
      final chainResponse = await _apiService.sendChatRequest(
        "请处理这些课程信息", // 使用简单提示，因为主要依赖系统消息和工具响应内容
        previousMessages: contextMessages,
        userKnowledge: _userKnowledge,
        additionalContext: await _getMemoryContext(),
        toolResponse: toolResponse,
        toolAction: action,
      );

      // 提取LLM的后续响应
      final aiResponse =
          chainResponse['choices'][0]['message']['content'] as String;

      // 尝试解析返回的JSON，看是否需要执行后续操作
      try {
        final responseData = jsonDecode(aiResponse);

        // 如果LLM返回的是另一个工具调用，则继续执行
        if (responseData.containsKey('action')) {
          // 根据action类型分发到不同的处理器
          if (responseData['action'] == 'webSearch' ||
              responseData['action'] == 'searchWeb') {
            await _handleWebSearchAction(responseData);
          } else if (responseData['action'] == 'updateUserKnowledge' ||
              responseData['action'] == 'getUserKnowledge') {
            await _handleUserKnowledgeAction(responseData);
          } else if (responseData['action'] == 'summarizeMemories') {
            // 处理记忆总结请求
            final summary = responseData['summary'] as String?;
            if (summary != null && summary.isNotEmpty) {
              await _knowledgeService.summarizeMemories(summary);
            }

            setState(() {
              _messages.add(
                ChatMessage(message: "我已经整理了我对我们对话的记忆。", isUser: false),
              );
            });
          } else {
            // 默认作为日历操作处理 - 递归调用自身处理后续行动
            await _handleCalendarAction(responseData);
          }
          return;
        }

        // 如果包含memory_extraction字段，处理知识提取
        if (responseData.containsKey('memory_extraction')) {
          final extractedInfo =
              responseData['memory_extraction'] as Map<String, dynamic>?;
          if (extractedInfo != null && extractedInfo.isNotEmpty) {
            await _knowledgeService.addAIResponse(
              aiResponse,
              extractedInfo: {'extracted_data': extractedInfo},
            );
          } else {
            await _knowledgeService.addAIResponse(aiResponse);
          }
        } else {
          await _knowledgeService.addAIResponse(aiResponse);
        }

        // 显示LLM生成的响应
        setState(() {
          _messages.add(ChatMessage(message: aiResponse, isUser: false));
        });
      } catch (e) {
        // JSON解析失败，按普通文本处理
        print('解析链式响应失败: $e');

        // 将AI响应添加到记忆流
        await _knowledgeService.addAIResponse(aiResponse);

        // 显示LLM生成的响应
        setState(() {
          _messages.add(ChatMessage(message: aiResponse, isUser: false));
        });
      }
    } catch (e) {
      print('链式反应处理失败: $e');
    }
  }

  // 获取记忆上下文
  Future<String> _getMemoryContext() async {
    final recentMemories = await _knowledgeService.getRecentMemories(10);
    if (recentMemories.isEmpty) {
      return "";
    }

    final memoryContext =
        "记忆流上下文:\n" +
        recentMemories
            .map(
              (m) =>
                  "${m.type == 'summary'
                      ? '总结'
                      : m.type == 'user_input'
                      ? '用户'
                      : m.type == 'ai_response'
                      ? 'AI'
                      : m.type == 'ai_thinking'
                      ? '思考'
                      : '行动'}: ${m.content.substring(0, m.content.length > 100 ? 100 : m.content.length)}...",
            )
            .join("\n");

    return memoryContext;
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(message: userMessage, isUser: true));
      _isLoading = true; // 设置加载状态，阻止用户再次发送消息
      _messageController.clear();
    });

    try {
      // 将用户消息添加到记忆流
      await _knowledgeService.addUserInput(userMessage);

      // 检查记忆流中是否有需要完成的思考行动
      final pendingActions = await _knowledgeService.getPendingActions();
      if (pendingActions.isNotEmpty) {
        // 提取第一个待执行的思考行动
        final pendingAction = pendingActions.first;
        await _knowledgeService.addAction(
          "用户响应: $userMessage",
          pendingAction.id,
        );
      }

      // 检查记忆流大小，如果过大则请求LLM总结
      final memorySize = await _knowledgeService.getMemoryFlowSize();
      if (memorySize > 40) {
        await _summarizeMemories();
      }

      // 确保知识库是最新的
      _userKnowledge = await _knowledgeService.getAllKnowledge();

      // 获取最近的记忆用于上下文
      final recentMemories = await _knowledgeService.getRecentMemories(10);

      // 准备发送记忆流上下文
      final memoryContext =
          "记忆流上下文:\n" +
          recentMemories
              .map(
                (m) =>
                    "${m.type == 'summary'
                        ? '总结'
                        : m.type == 'user_input'
                        ? '用户'
                        : m.type == 'ai_response'
                        ? 'AI'
                        : m.type == 'ai_thinking'
                        ? '思考'
                        : '行动'}: ${m.content.substring(0, m.content.length > 100 ? 100 : m.content.length)}...",
              )
              .join("\n");

      final response = await _apiService.sendChatRequest(
        userMessage,
        previousMessages: _getMessageHistory(),
        userKnowledge: _userKnowledge,
        additionalContext: memoryContext,
      );

      // 提取LLM的响应内容
      final aiResponse = response['choices'][0]['message']['content'] as String;

      // 尝试解析可能包含的JSON块
      Map<String, dynamic>? jsonData = _extractJsonFromText(aiResponse);

      if (jsonData != null) {
        // 处理信息提取 - 如果JSON中包含memory_extraction字段
        if (jsonData.containsKey('memory_extraction')) {
          final extractedMemory = jsonData['memory_extraction'];
          // 把提取到的关键信息存储到知识库中
          if (extractedMemory is Map<String, dynamic>) {
            await _knowledgeService.updateValues(extractedMemory);
            _userKnowledge = await _knowledgeService.getAllKnowledge();
          }
        }

        // 处理AI思考 - 如果JSON中包含ai_thinking字段
        if (jsonData.containsKey('ai_thinking')) {
          final thinking = jsonData['ai_thinking'] as String?;
          final requiresAction = jsonData['requires_action'] as bool? ?? false;

          if (thinking != null && thinking.isNotEmpty) {
            await _knowledgeService.addAIThinking(
              thinking,
              requiresAction: requiresAction,
            );
          }
        }

        // 如果成功解析为JSON，检查action字段决定调用哪个工具
        if (jsonData.containsKey('action')) {
          final actionType = jsonData['action'];

          // 设置一个临时信息，告诉用户正在处理
          setState(() {
            _messages.add(
              ChatMessage(
                message: "正在处理请求...",
                isUser: false,
                isTemporary: true,
              ),
            );
          });

          // 根据action类型分发到不同的处理器
          if (actionType == 'webSearch' || actionType == 'searchWeb') {
            await _handleWebSearchAction(jsonData);
          } else if (actionType == 'updateUserKnowledge' ||
              actionType == 'getUserKnowledge') {
            await _handleUserKnowledgeAction(jsonData);
          } else if (actionType == 'summarizeMemories') {
            // 处理记忆总结请求
            final summary = jsonData['summary'] as String?;
            if (summary != null && summary.isNotEmpty) {
              await _knowledgeService.summarizeMemories(summary);
            }
            setState(() {
              _messages.removeWhere((msg) => msg.isTemporary);
              _messages.add(
                ChatMessage(message: "我已经整理了我对我们对话的记忆。", isUser: false),
              );
              _isLoading = false;
            });
            return;
          } else {
            // 默认作为日历操作处理
            await _handleCalendarAction(jsonData);
          }
          return; // 已处理工具调用，结束函数
        }

        // 如果包含user_response字段，表示需要向用户提问或引导对话
        if (jsonData.containsKey('user_response') &&
            jsonData.containsKey('ai_response')) {
          final aiResponseText = jsonData['ai_response'] as String?;

          if (aiResponseText != null && aiResponseText.isNotEmpty) {
            setState(() {
              _messages.add(
                ChatMessage(message: aiResponseText, isUser: false),
              );
              _isLoading = false;
            });

            // 将AI响应添加到记忆流
            await _knowledgeService.addAIResponse(
              aiResponseText,
              extractedInfo:
                  jsonData.containsKey('memory_extraction')
                      ? {'extracted_data': jsonData['memory_extraction']}
                      : null,
            );
          }
          return;
        }
      }

      // 将AI响应添加到记忆流
      await _knowledgeService.addAIResponse(aiResponse);

      // 如果不是JSON或没有action字段，作为普通回答显示
      setState(() {
        _messages.add(ChatMessage(message: aiResponse, isUser: false));
        _isLoading = false;
      });

      // 分析回答中是否包含可以添加到知识库的信息
      _analyzeResponseForKnowledgeExtraction(aiResponse);
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(message: '发生错误: $e', isUser: false, isError: true),
        );
        _isLoading = false;
      });
    }
  }

  // 从LLM响应中提取JSON块
  // 从LLM响应中提取JSON块
  Map<String, dynamic>? _extractJsonFromText(String text) {
    try {
      // 首先尝试将整个文本作为JSON解析
      return jsonDecode(text);
    } catch (e) {
      // 查找JSON代码块
      final codeBlockPattern = RegExp(
        r'```json\s*([\s\S]*?)\s*```',
        multiLine: true,
      );
      final codeMatch = codeBlockPattern.firstMatch(text);

      if (codeMatch != null && codeMatch.groupCount >= 1) {
        final jsonText = codeMatch.group(1);
        if (jsonText != null && jsonText.trim().isNotEmpty) {
          try {
            return jsonDecode(jsonText.trim());
          } catch (e) {
            print('代码块中的JSON解析失败: $e');
          }
        }
      }

      // 使用更通用的方法查找任何JSON对象
      final jsonPattern = RegExp(
        r'\{(?:[^{}]|(?:\{(?:[^{}]|(?:\{[^{}]*\}))*\}))*\}',
      );
      final matches = jsonPattern.allMatches(text);

      for (final match in matches) {
        final jsonText = match.group(0);
        if (jsonText != null && jsonText.trim().isNotEmpty) {
          try {
            final parsed = jsonDecode(jsonText.trim());

            // 验证解析出的JSON是否包含action字段或其他关键字段
            if (parsed is Map<String, dynamic> &&
                (parsed.containsKey('action') ||
                    parsed.containsKey('memory_extraction') ||
                    parsed.containsKey('ai_thinking'))) {
              return parsed;
            }
          } catch (e) {
            // 继续尝试下一个匹配项
            print('JSON对象解析尝试失败: $e');
          }
        }
      }

      print('无法从文本中提取有效的JSON');
      return null;
    }
  }

  // 请求LLM总结记忆
  Future<void> _summarizeMemories() async {
    try {
      // 获取所有记忆
      final memories = await _knowledgeService.getAllMemories();

      // 构建记忆摘要请求
      final memoryTexts = memories
          .map((m) => "${m.type}: ${m.content}")
          .join("\n\n");

      // 请求LLM总结记忆
      final response = await _apiService.sendChatRequest(
        "请总结以下对话记忆，提取关键信息用于长期记忆:\n\n$memoryTexts",
        previousMessages: [],
        userKnowledge: _userKnowledge,
      );

      final summaryResponse =
          response['choices'][0]['message']['content'] as String;

      // 存储总结
      await _knowledgeService.summarizeMemories(summaryResponse);

      print('记忆总结完成: $summaryResponse');
    } catch (e) {
      print('记忆总结失败: $e');
    }
  }

  // 分析AI回答中的信息，提取可能的用户知识
  void _analyzeResponseForKnowledgeExtraction(String response) async {
    // 这里可以添加更复杂的信息提取逻辑
    // 简单示例：检测回答中是否提到用户名字、兴趣爱好等

    // 提取名字
    final namePattern = RegExp(r'我叫(\S+)|我是(\S+)|我的名字是(\S+)');
    final nameMatch = namePattern.firstMatch(response);
    if (nameMatch != null) {
      final name =
          nameMatch.group(1) ?? nameMatch.group(2) ?? nameMatch.group(3);
      if (name != null && name.length > 1 && name.length < 20) {
        await _knowledgeService.setValue('user_name', name);
        _userKnowledge = await _knowledgeService.getAllKnowledge();
      }
    }

    // 可以扩展更多的知识提取规则...
  }

  // 打开知识库面板
  void _openKnowledgePanel() async {
    await _knowledgeService.initialize();
    _userKnowledge = await _knowledgeService.getAllKnowledge();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('用户知识库'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _userKnowledge.isEmpty
                      ? Center(child: Text('知识库为空'))
                      : ListView.builder(
                        itemCount: _userKnowledge.keys.length,
                        itemBuilder: (context, index) {
                          final key = _userKnowledge.keys.elementAt(index);
                          final value = _userKnowledge[key];
                          return ListTile(
                            title: Text(key),
                            subtitle: Text(value.toString()),
                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                await _knowledgeService.removeValue(key);
                                Navigator.pop(context);
                                _openKnowledgePanel(); // 刷新面板
                              },
                            ),
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('关闭'),
              ),
              TextButton(
                onPressed: () async {
                  final confirm = await _showConfirmationDialog(
                    '清空确认',
                    '确定要清空整个知识库吗？这将删除AI助手对您的所有记忆。',
                  );

                  if (confirm) {
                    await _knowledgeService.clear();
                    Navigator.pop(context);
                    setState(() {
                      _userKnowledge = {};
                    });
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('清空知识库'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 助手'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
        actions: [
          // 知识库按钮
          IconButton(
            icon: Icon(Icons.psychology),
            onPressed: _isLoading ? null : _openKnowledgePanel, // 加载时禁用
            tooltip: '查看AI记忆',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                if (message.isTemporary) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            message.message,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _buildChatBubble(message);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2.0),
                  SizedBox(width: 12),
                  Text(
                    "AI 助手正在思考...",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 2,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isLoading ? '请等待AI助手回复...' : '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          _isLoading ? Colors.grey[200] : Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    enabled: !_isLoading, // 加载时禁用输入框
                  ),
                ),
                SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage, // 加载时禁用发送按钮
                  child: Icon(Icons.send),
                  mini: true,
                  backgroundColor: _isLoading ? Colors.grey : null, // 加载时变灰
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? Colors.blue[100]
                  : (message.isError ? Colors.red[100] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            message.isUser
                ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(message.message),
                )
                : MarkdownBody(
                  data: message.message,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 14),
                    h1: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    h2: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    h3: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    blockquote: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    tableBody: TextStyle(fontSize: 12),
                  ),
                  selectable: true,
                ),
      ),
    );
  }
}

class ChatMessage {
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
}
