import 'package:StoneU_Hood/features/ai/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/llm_chat_service.dart';
import '../services/ai_agent_tools.dart';
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
  final EventRepository _eventRepository = EventRepository();
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialGreetingSent = false;
  Map<String, dynamic> _userKnowledge = {};
  bool _isProcessingAction = false;

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
    
    try {
      // 先检查是否有缓存的问候语
      final cachedGreeting = await _knowledgeService.getCachedGreeting();
      
      if (cachedGreeting != null) {
        // 使用缓存的问候语
        setState(() {
          _messages.add(ChatMessage(message: cachedGreeting['text'], isUser: false));
          _isLoading = false;
          _isInitialGreetingSent = true;
        });
        return;
      }
      
      // 没有缓存或缓存已过期，生成新的问候语
      
      // 获取今日天气
      Map<String, dynamic>? weatherData;
      try {
        final weatherService = WeatherService();
        weatherData = await weatherService.getRealTimeWeather();
      } catch (e) {
        print('获取天气信息失败: $e');
      }
      
      // 获取今日课程
      final todayClasses = await _getTodayClasses();
      
      // 获取用户名
      final userName = await _getUserName();
      
      // 存储用户信息到知识库
      if (userName != '同学') {
        await _knowledgeService.setValue('user_name', userName);
      }
      
      // 使用内置工具生成基本问候语
      String greeting = await AIAgentTools.generateGreeting(
        userKnowledge: _userKnowledge,
        todayEvents: todayClasses,
        weatherData: weatherData,
      );
      
      // 获取最新帖子
      try {
        final recentPosts = await AIAgentTools.getRecentPosts(limit: 3);
        if (recentPosts != "没有找到相关帖子。") {
          greeting += "\n\n**最新校园动态：**\n" + recentPosts;
        }
      } catch (e) {
        print('获取最新帖子失败: $e');
      }
      
      // 缓存问候语
      await _knowledgeService.cacheGreeting(greeting);
      
      // 显示问候语
      setState(() {
        _messages.add(ChatMessage(message: greeting, isUser: false));
        _isLoading = false;
        _isInitialGreetingSent = true;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            message: "欢迎使用 AI 助手！很抱歉，我在获取您的信息时遇到了一些问题。",
            isUser: false,
          ),
        );
        _isLoading = false;
        _isInitialGreetingSent = true;
      });
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

      final allEvents = await _eventRepository.getEvents();

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
  
  // 发送消息与AI交互，并执行相应操作
  void _sendMessage() async {
    if (_isLoading || _messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(message: userMessage, isUser: true));
      _isLoading = true;
    });

    try {
      // 保存用户输入到记忆流
      await _knowledgeService.addUserInput(userMessage);
      
      // 处理特定关键词
      if (_handleSpecialCommands(userMessage)) {
        return;
      }

      // 获取消息历史
      final messageHistory = _getMessageHistory();
      if (messageHistory.isNotEmpty) {
        messageHistory.removeLast(); // 移除刚添加的用户消息，因为会在请求中单独添加
      }

      // 向API发送请求
      final response = await _apiService.sendChatRequest(
        userMessage,
        previousMessages: messageHistory,
        userKnowledge: _userKnowledge,
      );

      final aiResponse = response['choices'][0]['message']['content'] as String;
      
      // 保存AI回复到记忆流
      await _knowledgeService.addAIResponse(aiResponse);
      
      // 尝试解析JSON响应
      try {
        if (aiResponse.contains('```json') && aiResponse.contains('```')) {
          // 提取JSON部分
          final jsonStartIndex = aiResponse.indexOf('```json') + 7;
          final jsonEndIndex = aiResponse.lastIndexOf('```');
          final jsonStr = aiResponse.substring(jsonStartIndex, jsonEndIndex).trim();

          final parsedJson = json.decode(jsonStr);
          
          // 处理动作
          if (parsedJson is Map<String, dynamic> && parsedJson.containsKey('action')) {
            await _processAction(parsedJson);
            return;
          }
        }
      } catch (e) {
        print('JSON解析错误：$e');
        // 如果解析失败，按普通文本处理
      }

      // 直接显示响应文本
      setState(() {
        _messages.add(ChatMessage(message: aiResponse, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          message: "抱歉，处理您的请求时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  // 处理特殊命令
  bool _handleSpecialCommands(String message) {
    final lowerMessage = message.toLowerCase();

    // 处理天气查询
    if (lowerMessage.contains('天气') && 
        (lowerMessage.contains('石河子') || lowerMessage.contains('怎么样') || 
         lowerMessage.contains('查询') || lowerMessage.contains('如何'))) {
      _processWeatherQuery();
      return true;
    }
    
    // 显示最新帖子
    if (lowerMessage.contains('最新帖子') || lowerMessage.contains('社区动态') || 
        (lowerMessage.contains('帖子') && lowerMessage.contains('最近'))) {
      _processRecentPosts();
      return true;
    }
    
    // 处理课程查询
    if ((lowerMessage.contains('课') || lowerMessage.contains('课程') || lowerMessage.contains('课表')) && 
        (lowerMessage.contains('今天') || lowerMessage.contains('明天') || 
         lowerMessage.contains('下周') || lowerMessage.contains('周') || 
         lowerMessage.contains('星期') || RegExp(r'\d+月\d+日').hasMatch(lowerMessage))) {
      _processScheduleQuery(message);
      return true;
    }
    
    // 处理课程添加
    if ((lowerMessage.contains('添加') || lowerMessage.contains('新增') || lowerMessage.contains('创建')) && 
        (lowerMessage.contains('课程') || lowerMessage.contains('课'))) {
      _processAddEvent(message);
      return true;
    }
    
    // 处理课程删除
    if ((lowerMessage.contains('删除') || lowerMessage.contains('取消') || lowerMessage.contains('移除')) && 
        (lowerMessage.contains('课程') || lowerMessage.contains('课'))) {
      _processDeleteEvent(message);
      return true;
    }

    return false;
  }

  // 处理天气查询
  Future<void> _processWeatherQuery() async {
    setState(() {
      _messages.add(ChatMessage(
        message: "正在为您查询天气信息...",
        isUser: false,
        isTemporary: true,
      ));
    });

    try {
      final weatherInfo = await AIAgentTools.getWeather();
      
      // 移除临时消息
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(message: weatherInfo, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          message: "抱歉，获取天气信息时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  // 处理最新帖子查询
  Future<void> _processRecentPosts() async {
    setState(() {
      _messages.add(ChatMessage(
        message: "正在为您获取最新社区帖子...",
        isUser: false,
        isTemporary: true,
      ));
    });

    try {
      final postsInfo = await AIAgentTools.getRecentPosts(limit: 5);
      
      // 移除临时消息
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(message: postsInfo, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          message: "抱歉，获取最新帖子时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }
  
  // 处理课程查询
  Future<void> _processScheduleQuery(String query) async {
    setState(() {
      _messages.add(ChatMessage(
        message: "正在查询您的课程安排...",
        isUser: false,
        isTemporary: true,
      ));
    });

    try {
      final scheduleInfo = await AIAgentTools.getCoursesForNaturalLanguageDate(query);
      
      // 移除临时消息
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(message: scheduleInfo, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          message: "抱歉，查询课程信息时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }
  
  // 处理添加课程
  Future<void> _processAddEvent(String query) async {
    setState(() {
      _messages.add(ChatMessage(
        message: "正在添加课程...",
        isUser: false,
        isTemporary: true,
      ));
    });

    try {
      final resultMessage = await AIAgentTools.addEventFromNaturalLanguage(query);
      
      // 移除临时消息
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(message: resultMessage, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          message: "抱歉，添加课程时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }
  
  // 处理删除课程
  Future<void> _processDeleteEvent(String query) async {
    setState(() {
      _messages.add(ChatMessage(
        message: "正在处理删除课程请求...",
        isUser: false,
        isTemporary: true,
      ));
    });

    try {
      // 处理删除数字的情况（来自多个课程选择列表）
      final deleteNumberRegex = RegExp(r'删除(\d+)');
      final deleteMatch = deleteNumberRegex.firstMatch(query);
      
      if (deleteMatch != null && deleteMatch.group(1) != null) {
        final index = int.parse(deleteMatch.group(1)!) - 1;
        
        // 获取临时存储的课程列表
        final prefs = await SharedPreferences.getInstance();
        final eventsJson = prefs.getString('temp_delete_events');
        
        if (eventsJson != null) {
          final events = List<Map<String, dynamic>>.from(
            (json.decode(eventsJson) as List).map((e) => Map<String, dynamic>.from(e))
          );
          
          if (index >= 0 && index < events.length) {
            final event = events[index];
            final eventId = event['id'];
            
            final resultMessage = await AgentTools.deleteEvent(eventId);
            
            // 删除临时存储
            await prefs.remove('temp_delete_events');
            
            // 移除临时消息
            setState(() {
              _messages.removeWhere((msg) => msg.isTemporary);
              _messages.add(ChatMessage(message: resultMessage, isUser: false));
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      // 常规删除处理
      final resultMessage = await AIAgentTools.deleteEventByNaturalLanguage(query);
      
      // 移除临时消息
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(message: resultMessage, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.removeWhere((msg) => msg.isTemporary);
        _messages.add(ChatMessage(
          message: "抱歉，删除课程时出错：$e",
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  // 处理AI助手返回的动作
  Future<void> _processAction(Map<String, dynamic> action) async {
    if (_isProcessingAction) return;
    
    _isProcessingAction = true;

    // 显示处理中消息
    setState(() {
      _messages.add(ChatMessage(
        message: "正在处理您的请求...",
        isUser: false,
        isTemporary: true,
      ));
    });

    String resultMessage = "";
    
    try {
      final actionType = action['action'] as String;
      
      switch (actionType) {
        case 'getWeather':
          final city = action['city'] as String? ?? '石河子市';
          resultMessage = await AIAgentTools.getWeatherByCity(city);
          break;
        
        case 'getRecentPosts':
          final limit = action['limit'] as int? ?? 5;
          resultMessage = await AIAgentTools.getRecentPosts(limit: limit);
          break;
          
        case 'searchPosts':
          final query = action['query'] as String?;
          final category = action['category'] as String?;
          final limit = action['limit'] as int? ?? 5;
          resultMessage = await AIAgentTools.searchPosts(
            query: query,
            category: category,
            limit: limit,
          );
          break;
          
        case 'createPost':
          final title = action['title'] as String? ?? '无标题';
          final content = action['content'] as String? ?? '无内容';
          final category = action['category'] as String? ?? '闲聊';
          List<String> tags = [];
          
          if (action.containsKey('tags') && action['tags'] is List) {
            tags = List<String>.from(action['tags']);
          }
          
          resultMessage = await AIAgentTools.createPost(
            title: title,
            content: content,
            category: category,
            tags: tags,
          );
          break;
          
        case 'getRecommendedPosts':
          List<String> interests = [];
          
          if (action.containsKey('interests') && action['interests'] is List) {
            interests = List<String>.from(action['interests']);
          } else {
            // 从用户知识库获取兴趣
            final userInterests = await _knowledgeService.getValue('interests');
            if (userInterests != null) {
              interests = (json.decode(userInterests) as List).cast<String>();
            } else {
              interests = ['学习', '生活', '石大'];
            }
          }
          
          resultMessage = await AIAgentTools.getRecommendedPosts(
            userInterests: interests,
            limit: action['limit'] as int? ?? 5,
          );
          break;
          
        case 'enhancePostContent':
          final title = action['title'] as String? ?? '无标题';
          final content = action['content'] as String? ?? '无内容';
          final category = action['category'] as String? ?? '闲聊';
          
          resultMessage = await AIAgentTools.enhancePostContent(
            title: title,
            content: content,
            category: category,
          );
          break;
          
        case 'getEnvironmentInfo':
          resultMessage = await AIAgentTools.getEnvironmentInfo();
          break;
          
        case 'getCurrentDateInfo':
          resultMessage = AIAgentTools.getCurrentDateInfo();
          break;
          
        case 'getImportantDates':
          resultMessage = AIAgentTools.getImportantDates();
          break;
          
        // 日程管理工具转发到原有的AgentTools
        case 'getNextWeekCourses':
          final courses = await AgentTools.getNextWeekCourses();
          resultMessage = AgentTools.formatCoursesInfo(courses);
          break;
          
        case 'getCoursesForDate':
          if (action.containsKey('date')) {
            final date = DateTime.parse(action['date']);
            final courses = await AgentTools.getCoursesForDate(date);
            resultMessage = AgentTools.formatCoursesInfo(courses);
          } else {
            resultMessage = "缺少日期参数，无法查询课程信息。";
          }
          break;
          
        case 'addEvent':
          if (action.containsKey('title') && action.containsKey('startTime') && action.containsKey('endTime')) {
            final title = action['title'];
            final startTime = DateTime.parse(action['startTime']);
            final endTime = DateTime.parse(action['endTime']);
            final notes = action['notes'] ?? '';
            
            resultMessage = await AgentTools.addEvent(
              title: title,
              startTime: startTime,
              endTime: endTime,
              notes: notes,
            );
          } else {
            resultMessage = "缺少必要参数，无法添加课程。";
          }
          break;
          
        case 'listEventsForSelection':
          resultMessage = await AgentTools.listEventsForSelection();
          break;
          
        case 'deleteEvent':
          if (action.containsKey('eventId')) {
            resultMessage = await AgentTools.deleteEvent(action['eventId']);
          } else {
            resultMessage = "缺少事件ID，无法删除课程。";
          }
          break;
          
        case 'updateUserKnowledge':
          if (action.containsKey('key') && action.containsKey('value')) {
            final key = action['key'];
            final value = action['value'];
            
            await _knowledgeService.setValue(key, value);
            _userKnowledge = await _knowledgeService.getAllKnowledge();
            
            resultMessage = "已更新您的信息。";
          } else {
            resultMessage = "缺少必要参数，无法更新用户信息。";
          }
          break;
          
        default:
          resultMessage = "无法处理的动作类型: $actionType";
      }
    } catch (e) {
      resultMessage = "处理请求时出错: $e";
    } finally {
      _isProcessingAction = false;
    }

    // 移除临时消息并显示结果
    setState(() {
      _messages.removeWhere((msg) => msg.isTemporary);
      _messages.add(ChatMessage(
        message: resultMessage,
        isUser: false,
        isError: resultMessage.contains('出错') || resultMessage.contains('失败'),
      ));
      _isLoading = false;
    });

    // 生成后续回复，提示用户下一步操作
    _generateFollowUp(action);
  }

  // 生成后续提示
  Future<void> _generateFollowUp(Map<String, dynamic> action) async {
    // 根据不同的动作类型提供不同的后续提示
    String followUpMessage = "";
    final actionType = action['action'] as String;
    
    if (actionType == 'getWeather') {
      followUpMessage = "您还想了解其他城市的天气，或者有其他需要我帮助的吗？";
    } else if (actionType == 'createPost') {
      followUpMessage = "帖子已发布成功！您是否想查看最新的社区动态？";
    } else if (actionType == 'getRecentPosts' || actionType == 'searchPosts' || actionType == 'getRecommendedPosts') {
      followUpMessage = "您对哪个帖子感兴趣？我可以帮您查看详情或者创建新帖子。";
    } else if (actionType.contains('Event') || actionType.contains('Courses')) {
      followUpMessage = "您需要对课程做其他操作吗？比如添加新课程或查询特定日期的课程。";
    }
    
    if (followUpMessage.isNotEmpty) {
      // 添加短暂延迟，让用户有时间阅读前一条消息
      await Future.delayed(Duration(milliseconds: 800));
      
      setState(() {
        _messages.add(ChatMessage(message: followUpMessage, isUser: false));
      });
    }
  }

  // 打开知识面板
  void _openKnowledgePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => _buildKnowledgePanel(scrollController),
      ),
    );
  }

  // 构建知识面板界面
  Widget _buildKnowledgePanel(ScrollController scrollController) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(bottom: 16),
            ),
          ),
          Text(
            'AI助手记忆库',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '以下是AI助手记住的关于您的信息，这些信息帮助它更好地为您服务。',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _userKnowledge.isEmpty
                ? Center(
                    child: Text(
                      'AI助手目前没有存储任何关于您的信息。',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _userKnowledge.length,
                    itemBuilder: (context, index) {
                      final key = _userKnowledge.keys.elementAt(index);
                      final value = _userKnowledge[key];
                      
                      return Card(
                        elevation: 1,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            _formatKnowledgeKey(key),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            _formatKnowledgeValue(value),
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                            onPressed: () => _deleteKnowledge(key),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 格式化知识键名
  String _formatKnowledgeKey(String key) {
    final Map<String, String> keyNames = {
      'user_name': '姓名',
      'major': '专业',
      'grade': '年级',
      'interests': '兴趣爱好',
      'hometown': '家乡',
      'favorite_subjects': '喜欢的科目',
      'preferred_study_time': '学习时间偏好',
    };
    
    return keyNames[key] ?? key;
  }

  // 格式化知识值
  String _formatKnowledgeValue(dynamic value) {
    if (value is List) {
      return value.join(', ');
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else {
      return value.toString();
    }
  }

  // 删除知识项
  void _deleteKnowledge(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定要删除"${_formatKnowledgeKey(key)}"信息吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _knowledgeService.removeValue(key);
      setState(() {
        _userKnowledge.remove(key);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${_formatKnowledgeKey(key)} 信息')),
      );
    }
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
