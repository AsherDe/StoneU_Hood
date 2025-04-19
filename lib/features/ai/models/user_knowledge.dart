// lib/features/ai/models/user_knowledge.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户知识库模型 - 用于AI助手存储和检索用户相关信息
class UserKnowledge {
  Map<String, dynamic> _data = {};
  
  // 加载用户知识库
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user_knowledge');
    if (jsonString != null) {
      try {
        _data = Map<String, dynamic>.from(jsonDecode(jsonString));
      } catch (e) {
        print('加载用户知识库出错: $e');
        _data = {};
      }
    }
  }
  
  // 保存用户知识库
  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_knowledge', jsonEncode(_data));
    } catch (e) {
      print('保存用户知识库出错: $e');
      return false;
    }
  }
  
  // 获取整个知识库
  Map<String, dynamic> getAllKnowledge() {
    return Map<String, dynamic>.from(_data);
  }
  
  // 获取特定键的值
  dynamic getValue(String key) {
    return _data[key];
  }
  
  // 设置特定键的值
  Future<bool> setValue(String key, dynamic value) async {
    _data[key] = value;
    return await save();
  }
  
  // 删除特定键
  Future<bool> removeValue(String key) async {
    _data.remove(key);
    return await save();
  }
  
  // 清空整个知识库
  Future<bool> clear() async {
    _data.clear();
    return await save();
  }
  
  // 知识库是否包含特定键
  bool containsKey(String key) {
    return _data.containsKey(key);
  }
  
  // 更新多个值
  Future<bool> updateValues(Map<String, dynamic> values) async {
    _data.addAll(values);
    return await save();
  }
}

/// 记忆流条目 - 表示AI助手记忆流中的单个记忆项
class MemoryItem {
  final String id;
  final String type; // 'user_input', 'ai_response', 'ai_thinking', 'action'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  MemoryItem({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

/// 记忆流模型 - 管理AI助手的记忆流
class MemoryFlow {
  List<MemoryItem> _memories = [];
  final int _maxUnsummarizedMemories; // 在进行总结之前的最大记忆数量
  
  MemoryFlow({int maxUnsummarizedMemories = 20}) 
      : _maxUnsummarizedMemories = maxUnsummarizedMemories;
  
  // 从持久化存储加载记忆流
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('ai_memory_flow');
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _memories = jsonList.map((item) => MemoryItem.fromJson(item)).toList();
      } catch (e) {
        print('加载记忆流出错: $e');
        _memories = [];
      }
    }
  }
  
  // 保存记忆流到持久化存储
  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _memories.map((item) => item.toJson()).toList();
      return await prefs.setString('ai_memory_flow', jsonEncode(jsonList));
    } catch (e) {
      print('保存记忆流出错: $e');
      return false;
    }
  }
  
  // 添加新的记忆
  Future<void> addMemory(MemoryItem memory) async {
    _memories.add(memory);
    await save();
    
    // 检查是否需要总结记忆
    if (_memories.length >= _maxUnsummarizedMemories) {
      // 此处的实际总结会在服务层处理
      print('记忆数量达到阈值：${_memories.length}，需要总结');
    }
  }
  
  // 获取所有记忆
  List<MemoryItem> getAllMemories() {
    return List<MemoryItem>.from(_memories);
  }
  
  // 获取最近的N条记忆
  List<MemoryItem> getRecentMemories(int count) {
    if (_memories.length <= count) {
      return getAllMemories();
    }
    return _memories.sublist(_memories.length - count);
  }
  
  // 清除记忆流
  Future<bool> clear() async {
    _memories.clear();
    return await save();
  }
  
  // 替换记忆流中的记忆（用于总结后替换）
  Future<bool> replaceMemories(List<MemoryItem> newMemories) async {
    _memories = newMemories;
    return await save();
  }
  
  // 获取记忆流大小
  int get size => _memories.length;
  
  // 获取特定类型的记忆
  List<MemoryItem> getMemoriesByType(String type) {
    return _memories.where((memory) => memory.type == type).toList();
  }
  
  // 获取待执行的行动（用于AI主动行为）
  List<MemoryItem> getPendingActions() {
    return _memories.where((memory) => 
      memory.type == 'ai_thinking' && 
      memory.metadata != null && 
      memory.metadata!['requires_action'] == true && 
      memory.metadata!['completed'] != true
    ).toList();
  }
}

/// 用户知识库服务 - 管理用户知识库的单例服务
class UserKnowledgeService {
  static final UserKnowledgeService _instance = UserKnowledgeService._internal();
  
  factory UserKnowledgeService() {
    return _instance;
  }
  
  UserKnowledgeService._internal();
  
  final UserKnowledge _userKnowledge = UserKnowledge();
  final MemoryFlow _memoryFlow = MemoryFlow();
  bool _isInitialized = false;
  
  // 初始化知识库
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _userKnowledge.load();
      await _memoryFlow.load();
      _isInitialized = true;
    }
  }
  
  // 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  
  // 获取整个知识库
  Future<Map<String, dynamic>> getAllKnowledge() async {
    await _ensureInitialized();
    return _userKnowledge.getAllKnowledge();
  }
  
  // 获取特定键的值
  Future<dynamic> getValue(String key) async {
    await _ensureInitialized();
    return _userKnowledge.getValue(key);
  }
  
  // 设置特定键的值
  Future<bool> setValue(String key, dynamic value) async {
    await _ensureInitialized();
    return await _userKnowledge.setValue(key, value);
  }
  
  // 删除特定键
  Future<bool> removeValue(String key) async {
    await _ensureInitialized();
    return await _userKnowledge.removeValue(key);
  }
  
  // 清空整个知识库
  Future<bool> clear() async {
    await _ensureInitialized();
    return await _userKnowledge.clear();
  }
  
  // 知识库是否包含特定键
  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _userKnowledge.containsKey(key);
  }
  
  // 更新多个值
  Future<bool> updateValues(Map<String, dynamic> values) async {
    await _ensureInitialized();
    return await _userKnowledge.updateValues(values);
  }
  
  // ----- 记忆流方法 -----
  
  // 添加用户输入到记忆流
  Future<void> addUserInput(String userInput) async {
    await _ensureInitialized();
    final memory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'user_input',
      content: userInput,
      timestamp: DateTime.now(),
    );
    await _memoryFlow.addMemory(memory);
  }
  
  // 添加AI响应到记忆流
  Future<void> addAIResponse(String aiResponse, {Map<String, dynamic>? extractedInfo}) async {
    await _ensureInitialized();
    final memory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'ai_response',
      content: aiResponse,
      timestamp: DateTime.now(),
      metadata: extractedInfo != null ? {'extracted_info': extractedInfo} : null,
    );
    await _memoryFlow.addMemory(memory);
  }
  
  // 添加AI思考到记忆流
  Future<void> addAIThinking(String thinking, {bool requiresAction = false}) async {
    await _ensureInitialized();
    final memory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'ai_thinking',
      content: thinking,
      timestamp: DateTime.now(),
      metadata: {
        'requires_action': requiresAction,
        'completed': false,
      },
    );
    await _memoryFlow.addMemory(memory);
  }
  
  // 添加AI执行的行动到记忆流
  Future<void> addAction(String action, String thinkingId) async {
    await _ensureInitialized();
    
    // 将对应的思考标记为已完成
    final memories = _memoryFlow.getAllMemories();
    final newMemories = memories.map((memory) {
      if (memory.id == thinkingId) {
        return MemoryItem(
          id: memory.id,
          type: memory.type,
          content: memory.content,
          timestamp: memory.timestamp,
          metadata: {
            ...?memory.metadata,
            'completed': true,
          },
        );
      }
      return memory;
    }).toList();
    
    await _memoryFlow.replaceMemories(newMemories);
    
    // 添加行动记录
    final memory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'action',
      content: action,
      timestamp: DateTime.now(),
      metadata: {
        'thinking_id': thinkingId,
      },
    );
    await _memoryFlow.addMemory(memory);
  }
  
  // 获取所有记忆
  Future<List<MemoryItem>> getAllMemories() async {
    await _ensureInitialized();
    return _memoryFlow.getAllMemories();
  }
  
  // 获取最近的记忆
  Future<List<MemoryItem>> getRecentMemories(int count) async {
    await _ensureInitialized();
    return _memoryFlow.getRecentMemories(count);
  }
  
  // 获取待执行的行动
  Future<List<MemoryItem>> getPendingActions() async {
    await _ensureInitialized();
    return _memoryFlow.getPendingActions();
  }
  
  // 清空记忆流
  Future<bool> clearMemoryFlow() async {
    await _ensureInitialized();
    return await _memoryFlow.clear();
  }
  
  // 获取记忆流大小
  Future<int> getMemoryFlowSize() async {
    await _ensureInitialized();
    return _memoryFlow.size;
  }
  
  // 总结记忆流
  Future<void> summarizeMemories(String summary) async {
    await _ensureInitialized();
    
    final memories = _memoryFlow.getAllMemories();
    
    // 创建总结记忆
    final summaryMemory = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'summary',
      content: summary,
      timestamp: DateTime.now(),
      metadata: {
        'summarized_count': memories.length,
      },
    );
    
    // 保留最近的10条记忆和总结记忆
    final recentMemories = memories.length > 10 
        ? memories.sublist(memories.length - 10) 
        : memories;
    
    final newMemories = [summaryMemory, ...recentMemories];
    await _memoryFlow.replaceMemories(newMemories);
  }
}