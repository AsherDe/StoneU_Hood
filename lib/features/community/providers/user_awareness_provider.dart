// lib/features/community/providers/user_awareness_provider.dart
import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_activity.dart';
import '../models/memory_item.dart';

/// UserAwarenessProvider implements an AI-powered awareness system that:
/// 1. Tracks user activities and state changes
/// 2. Uses importance judgment to filter which changes trigger responses
/// 3. Maintains a memory stream of user activities
/// 4. Updates user knowledge model in real-time
class UserAwarenessProvider with ChangeNotifier {
  // Memory stream (FIFO queue with limited size)
  final Queue<MemoryItem> _memoryStream = Queue<MemoryItem>();
  final int _maxMemorySize = 100; // Maximum items in memory stream
  
  // User knowledge model (persistent)
  Map<String, dynamic> _userKnowledge = {};
  
  // Current state tracking
  bool _isProcessingHighPriority = false;
  DateTime _lastNotificationTime = DateTime.now().subtract(Duration(minutes: 5));
  
  // User activity stats for personalization
  int _totalActivities = 0;
  Map<ActivityType, int> _activityFrequency = {};
  
  // Getters
  Queue<MemoryItem> get memoryStream => Queue.from(_memoryStream);
  Map<String, dynamic> get userKnowledge => Map.from(_userKnowledge);
  bool get isProcessingHighPriority => _isProcessingHighPriority;
  
  // Stream controller for important state changes
  final _importantStateController = StreamController<UserActivity>.broadcast();
  Stream<UserActivity> get importantStateChanges => _importantStateController.stream;

  UserAwarenessProvider() {
    _loadUserKnowledge();
  }
  
  /// Loads saved user knowledge from SharedPreferences
  Future<void> _loadUserKnowledge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_knowledge');
      if (userDataString != null && userDataString.isNotEmpty) {
        _userKnowledge = Map<String, dynamic>.from(
          Map<String, dynamic>.from({'data': userDataString})
        );
      }
    } catch (e) {
      print('Error loading user knowledge: $e');
    }
  }
  
  /// Saves current user knowledge to SharedPreferences
  Future<void> _saveUserKnowledge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_knowledge', _userKnowledge.toString());
    } catch (e) {
      print('Error saving user knowledge: $e');
    }
  }
  
  /// Add a new user activity to the awareness system
  /// Returns true if this activity triggers an immediate response
  Future<bool> addUserActivity(UserActivity activity) async {
    // Add to activity stats
    _totalActivities++;
    _activityFrequency[activity.type] = 
        (_activityFrequency[activity.type] ?? 0) + 1;
    
    // Add to memory stream, maintaining max size
    _memoryStream.addFirst(MemoryItem(
      activity: activity,
      timestamp: DateTime.now(),
      hasBeenProcessed: false,
    ));
    
    while (_memoryStream.length > _maxMemorySize) {
      _memoryStream.removeLast();
    }
    
    // Determine importance level
    final importanceLevel = _judgeImportance(activity);
    
    // Update user knowledge if needed
    if (activity.metadata != null && activity.metadata!.isNotEmpty) {
      if (activity.type == ActivityType.userInfo || 
          activity.type == ActivityType.preference) {
        await _updateUserKnowledge(activity.metadata!);
      }
    }
    
    // Handle based on importance level
    if (importanceLevel == ImportanceLevel.high) {
      // For high importance, trigger immediate notification
      _isProcessingHighPriority = true;
      notifyListeners();
      
      // Add to important state changes stream
      _importantStateController.add(activity);
      
      // Reset processing flag after a short delay
      Timer(Duration(seconds: 3), () {
        _isProcessingHighPriority = false;
        notifyListeners();
      });
      
      // Mark current time
      _lastNotificationTime = DateTime.now();
      
      return true; // Indicate immediate response is needed
    } else if (importanceLevel == ImportanceLevel.medium) {
      // For medium importance, only notify if no recent notifications
      final timeSinceLastNotification = 
          DateTime.now().difference(_lastNotificationTime);
      
      if (timeSinceLastNotification > Duration(minutes: 10)) {
        _importantStateController.add(activity);
        _lastNotificationTime = DateTime.now();
        return true;
      }
    }
    
    // For low importance or throttled medium importance
    return false; // No immediate response needed
  }
  
  /// Judge the importance level of a user activity
  ImportanceLevel _judgeImportance(UserActivity activity) {
    // High priority activities
    if (activity.type == ActivityType.error || 
        activity.type == ActivityType.securityEvent ||
        activity.type == ActivityType.upcomingEvent ||
        activity.type == ActivityType.alarm) {
      return ImportanceLevel.high;
    }
    
    // Medium priority activities
    if (activity.type == ActivityType.search ||
        activity.type == ActivityType.calendarChange ||
        activity.type == ActivityType.messageReceived) {
      return ImportanceLevel.medium;
    }
    
    // Check for conversational context that might increase priority
    if (activity.type == ActivityType.conversation) {
      // If user asks a question, it might be medium priority
      if (activity.description.contains('?') || 
          _containsQuestionWords(activity.description)) {
        return ImportanceLevel.medium;
      }
      
      // If conversation contains certain urgent keywords
      if (_containsUrgentKeywords(activity.description)) {
        return ImportanceLevel.high;
      }
    }
    
    // All other activities are low priority by default
    return ImportanceLevel.low;
  }
  
  /// Checks if text contains common question words
  bool _containsQuestionWords(String text) {
    final questionWords = ['什么', '为什么', '怎么', '如何', '哪里', '何时', 
                         '谁', '哪个', '是否', '能否', '可不可以'];
    
    final lowerText = text.toLowerCase();
    return questionWords.any((word) => lowerText.contains(word));
  }
  
  /// Checks if text contains urgent keywords
  bool _containsUrgentKeywords(String text) {
    final urgentWords = ['紧急', '立即', '马上', '快', '帮帮', '救命', 
                       '重要', '必须', '赶紧', '急需'];
    
    final lowerText = text.toLowerCase();
    return urgentWords.any((word) => lowerText.contains(word));
  }
  
  /// Updates the user knowledge model with new information
  Future<void> _updateUserKnowledge(Map<String, dynamic> newData) async {
    // Merge new data with existing knowledge
    newData.forEach((key, value) {
      // Special handling for certain knowledge types
      if (_userKnowledge.containsKey(key) && 
          _userKnowledge[key] is List && 
          value is List) {
        // For lists, add new items avoiding duplicates
        final existingList = List.from(_userKnowledge[key]);
        for (var item in value) {
          if (!existingList.contains(item)) {
            existingList.add(item);
          }
        }
        _userKnowledge[key] = existingList;
      } else if (_userKnowledge.containsKey(key) && 
                _userKnowledge[key] is Map && 
                value is Map) {
        // For maps, recursively merge
        _userKnowledge[key] = {..._userKnowledge[key], ...value};
      } else {
        // For simple values, just replace
        _userKnowledge[key] = value;
      }
    });
    
    // Save updated knowledge
    await _saveUserKnowledge();
    notifyListeners();
  }
  
  /// Process all unprocessed memories in background
  Future<void> processMemories() async {
    // Find unprocessed memory items
    final List<MemoryItem> unprocessedItems = _memoryStream
        .where((item) => !item.hasBeenProcessed)
        .toList();
    
    if (unprocessedItems.isEmpty) return;
    
    // Mark all as processed
    for (var i = 0; i < _memoryStream.length; i++) {
      final item = _memoryStream.elementAt(i);
      if (!item.hasBeenProcessed) {
        final updatedItem = MemoryItem(
          activity: item.activity,
          timestamp: item.timestamp,
          hasBeenProcessed: true,
        );
        
        // Replace in the queue
        _memoryStream.remove(item);
        _memoryStream.add(updatedItem);
      }
    }
    
    // Extract knowledge from memories
    final consolidatedKnowledge = _extractKnowledgeFromMemories(unprocessedItems);
    if (consolidatedKnowledge.isNotEmpty) {
      await _updateUserKnowledge(consolidatedKnowledge);
    }
    
    notifyListeners();
  }
  
  /// Extract knowledge from a set of memory items
  Map<String, dynamic> _extractKnowledgeFromMemories(List<MemoryItem> memories) {
    final Map<String, dynamic> extractedKnowledge = {};
    
    // Process conversation memories to extract structured knowledge
    // This is a simple implementation - in a real system, this might use NLP
    for (var memory in memories) {
      final activity = memory.activity;
      
      if (activity.type == ActivityType.conversation) {
        // Extract potential user information from conversation
        _extractUserInfoFromText(activity.description, extractedKnowledge);
      } else if (activity.type == ActivityType.search) {
        // Track search interests
        if (!extractedKnowledge.containsKey('interests')) {
          extractedKnowledge['interests'] = [];
        }
        extractedKnowledge['interests'].add(activity.description);
      } else if (activity.type == ActivityType.navigation) {
        // Track navigation patterns
        if (!extractedKnowledge.containsKey('navigation_patterns')) {
          extractedKnowledge['navigation_patterns'] = {};
        }
        final navPatterns = extractedKnowledge['navigation_patterns'] as Map<String, dynamic>;
        navPatterns[activity.description] = (navPatterns[activity.description] ?? 0) + 1;
      }
      
      // Include metadata if available
      if (activity.metadata != null && activity.metadata!.isNotEmpty) {
        activity.metadata!.forEach((key, value) {
          extractedKnowledge[key] = value;
        });
      }
    }
    
    return extractedKnowledge;
  }
  
  /// Simple text analysis to extract user information from conversations
  void _extractUserInfoFromText(String text, Map<String, dynamic> knowledge) {
    // Name extraction
    final nameMatch = RegExp(r'我叫([\u4e00-\u9fa5a-zA-Z]+)|我是([\u4e00-\u9fa5a-zA-Z]+)|我的名字是([\u4e00-\u9fa5a-zA-Z]+)')
        .firstMatch(text);
    if (nameMatch != null) {
      final name = nameMatch.group(1) ?? nameMatch.group(2) ?? nameMatch.group(3);
      if (name != null) {
        knowledge['user_name'] = name;
      }
    }
    
    // Major extraction
    final majorMatch = RegExp(r'我学的是([\u4e00-\u9fa5a-zA-Z]+)|我的专业是([\u4e00-\u9fa5a-zA-Z]+)')
        .firstMatch(text);
    if (majorMatch != null) {
      final major = majorMatch.group(1) ?? majorMatch.group(2);
      if (major != null) {
        knowledge['user_major'] = major;
      }
    }
    
    // Interest extraction
    final interestMatch = RegExp(r'我喜欢([\u4e00-\u9fa5a-zA-Z]+)|我的爱好是([\u4e00-\u9fa5a-zA-Z]+)')
        .firstMatch(text);
    if (interestMatch != null) {
      final interest = interestMatch.group(1) ?? interestMatch.group(2);
      if (interest != null) {
        if (!knowledge.containsKey('user_interests')) {
          knowledge['user_interests'] = [];
        }
        if (knowledge['user_interests'] is List && 
            !knowledge['user_interests'].contains(interest)) {
          knowledge['user_interests'].add(interest);
        }
      }
    }
    
    // Year extraction
    final yearMatch = RegExp(r'我是大(一|二|三|四)')
        .firstMatch(text);
    if (yearMatch != null) {
      final year = yearMatch.group(1);
      if (year != null) {
        knowledge['user_year'] = year;
      }
    }
    
    // Hometown extraction
    final hometownMatch = RegExp(r'我来自([\u4e00-\u9fa5]+)|我的家乡是([\u4e00-\u9fa5]+)')
        .firstMatch(text);
    if (hometownMatch != null) {
      final hometown = hometownMatch.group(1) ?? hometownMatch.group(2);
      if (hometown != null) {
        knowledge['user_hometown'] = hometown;
      }
    }
  }
  
  /// Get a summary of recent user activities (for AI context)
  String getActivitySummary({int maxItems = 5}) {
    if (_memoryStream.isEmpty) {
      return "无最近活动";
    }
    
    final buffer = StringBuffer("最近的用户活动：\n");
    int count = 0;
    
    for (var item in _memoryStream) {
      if (count >= maxItems) break;
      
      final timeAgo = DateTime.now().difference(item.timestamp);
      String timeDescription;
      
      if (timeAgo.inMinutes < 1) {
        timeDescription = "刚刚";
      } else if (timeAgo.inHours < 1) {
        timeDescription = "${timeAgo.inMinutes}分钟前";
      } else if (timeAgo.inDays < 1) {
        timeDescription = "${timeAgo.inHours}小时前";
      } else {
        timeDescription = "${timeAgo.inDays}天前";
      }
      
      buffer.writeln("- ${item.activity.description} ($timeDescription)");
      count++;
    }
    
    return buffer.toString();
  }
  
  /// Get user knowledge as a formatted string (for AI context)
  String getUserKnowledgeSummary() {
    if (_userKnowledge.isEmpty) {
      return "没有用户知识信息";
    }
    
    final buffer = StringBuffer("用户知识模型：\n");
    
    // Format user basic info first
    final basicInfoKeys = [
      'user_name', 'user_major', 'user_year', 'user_hometown'
    ];
    
    for (var key in basicInfoKeys) {
      if (_userKnowledge.containsKey(key) && 
          _userKnowledge[key] != null) {
        String label = key.replaceAll('user_', '').replaceAll('_', ' ');
        switch (key) {
          case 'user_name':
            label = "姓名";
            break;
          case 'user_major':
            label = "专业";
            break;
          case 'user_year':
            label = "年级";
            break;
          case 'user_hometown':
            label = "家乡";
            break;
        }
        buffer.writeln("- $label: ${_userKnowledge[key]}");
      }
    }
    
    // Then add other knowledge
    _userKnowledge.forEach((key, value) {
      if (!basicInfoKeys.contains(key)) {
        String label = key.replaceAll('_', ' ');
        String valueStr = value is List ? value.join(', ') : value.toString();
        buffer.writeln("- $label: $valueStr");
      }
    });
    
    return buffer.toString();
  }
  
  /// Get personalized AI response mode based on user patterns
  /// This tells the AI how to adjust its responses to this user
  String getPersonalizationHints() {
    final buffer = StringBuffer("个性化响应提示：\n");
    
    // Based on activity frequency, determine user interaction style
    if (_totalActivities > 0) {
      final searchRatio = (_activityFrequency[ActivityType.search] ?? 0) / _totalActivities;
      final messageRatio = (_activityFrequency[ActivityType.conversation] ?? 0) / _totalActivities;
      
      if (searchRatio > 0.4) {
        buffer.writeln("- 用户倾向于信息查询，偏好直接的事实性回答");
      }
      
      if (messageRatio > 0.6) {
        buffer.writeln("- 用户倾向于对话交流，偏好友好的对话式回答");
      }
      
      // Check for interests to add personalization
      if (_userKnowledge.containsKey('user_interests') && 
          _userKnowledge['user_interests'] is List && 
          (_userKnowledge['user_interests'] as List).isNotEmpty) {
        buffer.writeln("- 用户兴趣包括: ${(_userKnowledge['user_interests'] as List).join(', ')}，可以适当引用这些领域的例子");
      }
    } else {
      buffer.writeln("- 尚无足够数据生成个性化提示");
    }
    
    return buffer.toString();
  }

  @override
  void dispose() {
    _importantStateController.close();
    super.dispose();
  }
}

/// Importance levels for user activities
enum ImportanceLevel {
  low,     // No immediate response needed
  medium,  // Response may be needed if not too frequent
  high     // Immediate response required
}