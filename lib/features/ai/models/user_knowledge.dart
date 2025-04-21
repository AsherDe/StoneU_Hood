// lib/features/ai/models/user_knowledge.dart
import 'dart:convert';
import 'package:StoneU_Hood/features/ai/services/llm_chat_service.dart';
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
  
  // 缓存问候语
  Future<bool> cacheGreeting(String greeting) async {
    final greetingData = {
      'text': greeting,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return await setValue('cached_greeting', greetingData);
  }
  
  // 获取缓存的问候语，如果过期或不存在则返回null
  Map<String, dynamic>? getCachedGreeting({Duration expiration = const Duration(hours: 6)}) {
    if (!containsKey('cached_greeting')) return null;
    
    final greetingData = getValue('cached_greeting');
    if (greetingData == null) return null;
    
    final timestamp = DateTime.parse(greetingData['timestamp']);
    final now = DateTime.now();
    
    if (now.difference(timestamp) > expiration) {
      // 问候语已过期
      return null;
    }
    
    return greetingData;
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
    
    // 检查记忆流大小，超过阈值时触发知识提取
    final size = await getMemoryFlowSize();
    if (size > 25) {
      await extractKnowledgeFromMemories();
    }
    
    // 分析用户输入以提取关键信息
    await _analyzeUserInput(userInput);
  }
  
  // 分析用户输入以提取关键信息
  Future<void> _analyzeUserInput(String userInput) async {
    // 提取用户名
    final nameRegex = RegExp(r'我(?:是|叫|的名字是)\s*([^\s,，。.!！?？]+)');
    final nameMatch = nameRegex.firstMatch(userInput);
    if (nameMatch != null && nameMatch.group(1) != null) {
      final name = nameMatch.group(1)!;
      await setValue('user_name', name);
    }
    
    // 提取专业信息
    final majorRegex = RegExp(r'我(?:学习|的专业是|是|读的是)\s*([^\s,，。.!！?？]+专业|[^\s,，。.!！?？]+系)');
    final majorMatch = majorRegex.firstMatch(userInput);
    if (majorMatch != null && majorMatch.group(1) != null) {
      await setValue('major', majorMatch.group(1));
    }
    
    // 提取年级信息
    final gradeRegex = RegExp(r'(?:我是|我|读|上|在)(?:大学)?([一二三四五六七八九十\d]+年级|大[一二三四])');
    final gradeMatch = gradeRegex.firstMatch(userInput);
    if (gradeMatch != null && gradeMatch.group(1) != null) {
      await setValue('grade', gradeMatch.group(1));
    }
  }
  
  // 缓存问候语
  Future<bool> cacheGreeting(String greeting) async {
    await _ensureInitialized();
    return await _userKnowledge.cacheGreeting(greeting);
  }
  
  // 获取缓存的问候语，如果过期或不存在则返回null
  Future<Map<String, dynamic>?> getCachedGreeting({Duration expiration = const Duration(hours: 6)}) async {
    await _ensureInitialized();
    return _userKnowledge.getCachedGreeting(expiration: expiration);
  }
  
  // 从记忆流中提取知识并存储到知识库
  Future<void> extractKnowledgeFromMemories() async {
    await _ensureInitialized();
    
    // 获取最近的记忆用于分析
    final memories = await getRecentMemories(25);
    if (memories.isEmpty) return;
    
    // 构建分析请求
    final userInputs = memories
        .where((m) => m.type == 'user_input')
        .map((m) => m.content)
        .join('\n');
    
    final aiResponses = memories
        .where((m) => m.type == 'ai_response')
        .map((m) => m.content)
        .join('\n');
    
    if (userInputs.isEmpty) return;
    
    try {
      // 调用LLM服务进行知识提取
      final apiService = ApiService();
      final extractionPrompt = """
分析以下用户输入和AI响应，提取关于用户的关键信息:

用户输入:
$userInputs

AI响应:
$aiResponses

从上述对话中提取用户信息，包括但不限于:
- 姓名
- 学校/专业/年级
- 兴趣爱好
- 家乡
- 课程偏好
- 学习习惯
- 其他显著特征

以JSON格式返回，例如:
{
  "user_name": "姓名",
  "major": "专业",
  "grade": "年级",
  "interests": ["兴趣1", "兴趣2"],
  "hometown": "家乡",
  "favorite_subjects": ["科目1", "科目2"],
  "preferred_study_time": "晚上"
}
如果无法确定某个字段，请不要在JSON中包含该字段。
      """;
      
      final response = await apiService.sendChatRequest(
        extractionPrompt,
        previousMessages: [],
      );
      
      final aiResponse = response['choices'][0]['message']['content'] as String;
      
      // 解析JSON响应
      try {
        // 提取JSON部分
        String jsonStr = aiResponse;
        if (aiResponse.contains('```json')) {
          final jsonStartIndex = aiResponse.indexOf('```json') + 7;
          final jsonEndIndex = aiResponse.lastIndexOf('```');
          jsonStr = aiResponse.substring(jsonStartIndex, jsonEndIndex).trim();
        }
        
        final extractedInfo = json.decode(jsonStr) as Map<String, dynamic>;
        
        // 更新知识库
        for (final entry in extractedInfo.entries) {
          if (entry.value != null) {
            await setValue(entry.key, entry.value);
          }
        }
        
        // 记录提取的信息
        final memory = MemoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'knowledge_extraction',
          content: '从记忆流中提取用户信息',
          timestamp: DateTime.now(),
          metadata: {'extracted_info': extractedInfo},
        );
        await _memoryFlow.addMemory(memory);
        
        // 添加思考记录
        await addAIThinking(
          '已从用户记忆中提取信息并更新知识库: ${extractedInfo.keys.join(', ')}',
        );
        
        // 触发记忆流总结
        await summarizeMemories('已从过去的对话中提取用户信息，并更新知识库');
      } catch (e) {
        print('解析提取的知识出错: $e');
      }
    } catch (e) {
      print('知识提取失败: $e');
    }
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