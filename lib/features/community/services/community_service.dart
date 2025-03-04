// lib/features/community/services/community_service.dart
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart' hide MaterialType;
import '../models/marketplace_item.dart';
import '../models/study_material.dart';
import '../../calendar/models/event.dart';
import 'package:http/http.dart' as http;


// User Profile Model
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String department;
  final String grade;
  
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.department,
    required this.grade,
  });
}

// Chat Models
class ChatConversation {
  final String id;
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String? userAvatar;
  
  ChatConversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.userAvatar,
  });
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
  });
  
  bool get isMe => senderId == 'user_1'; // Current user ID hardcoded for demo
}

class CommunityService {
  // Singleton pattern for the service
  // static final CommunityService _instance = CommunityService._internal();
  final String baseUrl = 'http://localhost:3000/api';

  // 单例模式
  static final CommunityService _instance = CommunityService._internal();
  
  factory CommunityService() {
    return _instance;
  }
  
  CommunityService._internal();
  
  String? _authToken;
  String? _currentUserId;
  final Map<String, UserProfile> _users = {
    'user_1': UserProfile(
      id: 'user_1',
      name: '张三',
      email: 'zhang@edu.cn',
      avatar: null,
      department: '计算机科学与技术',
      grade: '大三',
    ),
    'user_2': UserProfile(
      id: 'user_2',
      name: '李四',
      email: 'li@edu.cn',
      avatar: null,
      department: '电子信息工程',
      grade: '大二',
    ),
  };

  // In a real app, these would fetch from a backend API
  Future<List<MarketplaceItem>> getMarketplaceItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/marketplace-items'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MarketplaceItem.fromJson(item)).toList();
      } else {
        throw Exception('获取物品失败: ${response.statusCode}');
      }
    } catch (e) {
      // 如果API调用失败，可以返回模拟数据（备选方案）
      print('API调用失败，使用模拟数据: $e');
      return _generateMockMarketplaceItems();
    }
  }

  
  Future<List<MarketplaceItem>> getFeaturedMarketplaceItems() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 600));
    
    // Return mock featured items
    final allItems = _generateMockMarketplaceItems();
    allItems.shuffle();
    return allItems.take(5).toList();
  }
  
  Future<List<StudyMaterial>> getStudyMaterials() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 700));
    
    // Return mock data
    return _generateMockStudyMaterials();
  }
  
  Future<List<StudyMaterial>> getTrendingStudyMaterials() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // Return top 3 materials by rating
    final allMaterials = _generateMockStudyMaterials();
    allMaterials.sort((a, b) => b.rating.compareTo(a.rating));
    return allMaterials.take(3).toList();
  }
  
  // User Authentication Methods
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _currentUserId = data['user']['id'];
          _authToken = data['token']; // 如果服务器返回token
          
          // 保存登录状态
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('current_user_id', _currentUserId!);
          if (_authToken != null) {
            await prefs.setString('auth_token', _authToken!);
          }
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('登录失败: $e');
      // 测试期间可使用模拟逻辑作为备选
      if (email == 'zhang@edu.cn' && password == 'password') {
        _currentUserId = 'user_1';
        return true;
      }
      return false;
    }
  }
  
  Future<bool> checkLoggedIn() async {
    if (_currentUserId != null) {
      return true;
    }
    
    // Check if user is logged in from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    
    if (userId != null && _users.containsKey(userId)) {
      _currentUserId = userId;
      return true;
    }
    
    return false;
  }
  
  Future<bool> logout() async {
    _currentUserId = null;
    
    // Clear login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    
    return true;
  }
  
  Future<UserProfile?> getCurrentUser() async {
    if (_currentUserId == null) {
      await checkLoggedIn();
    }
    
    return _currentUserId != null ? _users[_currentUserId] : null;
  }
  
  // Item Management Methods
  Future<bool> createMarketplaceItem(MarketplaceItem item) async {
    // In a real app, this would send the item to a backend
    await Future.delayed(Duration(milliseconds: 800));
    
    // In a mock scenario, we'll just pretend it was successful
    return true;
  }
  
  Future<bool> updateMarketplaceItem(MarketplaceItem item) async {
    await Future.delayed(Duration(milliseconds: 600));
    return true;
  }
  
  Future<bool> deleteMarketplaceItem(String itemId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }
  
  Future<bool> createStudyMaterial(StudyMaterial material) async {
    await Future.delayed(Duration(milliseconds: 800));
    return true;
  }
  
  Future<bool> updateStudyMaterial(StudyMaterial material) async {
    await Future.delayed(Duration(milliseconds: 600));
    return true;
  }
  
  Future<bool> deleteStudyMaterial(String materialId) async {
    await Future.delayed(Duration(milliseconds: 500));
    return true;
  }
  
  // Favorites Management
  Future<List<String>> getFavoriteItemIds() async {
    // In a real app, this would come from the backend or local storage
    await Future.delayed(Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorite_items') ?? '[]';
    return List<String>.from(jsonDecode(favoritesJson));
  }
  
  Future<bool> toggleFavoriteItem(String itemId) async {
    final favoriteIds = await getFavoriteItemIds();
    
    if (favoriteIds.contains(itemId)) {
      favoriteIds.remove(itemId);
    } else {
      favoriteIds.add(itemId);
    }
    
    // Save updated favorites
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_items', jsonEncode(favoriteIds));
    
    return true;
  }
  
  Future<List<String>> getFavoriteMaterialIds() async {
    await Future.delayed(Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorite_materials') ?? '[]';
    return List<String>.from(jsonDecode(favoritesJson));
  }
  
  Future<bool> toggleFavoriteMaterial(String materialId) async {
    final favoriteIds = await getFavoriteMaterialIds();
    
    if (favoriteIds.contains(materialId)) {
      favoriteIds.remove(materialId);
    } else {
      favoriteIds.add(materialId);
    }
    
    // Save updated favorites
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_materials', jsonEncode(favoriteIds));
    
    return true;
  }
  
  // Chat Functionality
  Future<List<ChatConversation>> getConversations() async {
    await Future.delayed(Duration(milliseconds: 700));
    
    // Return mock conversations
    return [
      ChatConversation(
        id: 'chat_1',
        userId: 'user_2',
        userName: '张三',
        lastMessage: '请问这个东西还卖吗？',
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        unreadCount: 1,
        userAvatar: null,
      ),
      ChatConversation(
        id: 'chat_2',
        userId: 'user_3',
        userName: '李四',
        lastMessage: '好的，明天给你带过去',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        unreadCount: 0,
        userAvatar: null,
      ),
      ChatConversation(
        id: 'chat_3',
        userId: 'user_4',
        userName: '王五',
        lastMessage: '这本书什么时候能还给我？',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        unreadCount: 3,
        userAvatar: null,
      ),
    ];
  }
  
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    // Return mock messages for the conversation
    final random = Random();
    final messages = <ChatMessage>[];
    
    for (int i = 0; i < 10; i++) {
      messages.add(
        ChatMessage(
          id: 'msg_${conversationId}_$i',
          conversationId: conversationId,
          senderId: i % 2 == 0 ? 'user_1' : conversationId.replaceAll('chat_', 'user_'),
          text: '这是第 ${i + 1} 条消息' + (i % 3 == 0 ? '，比较长的消息内容，测试气泡的换行效果以及文本的截断效果' : ''),
          timestamp: DateTime.now().subtract(Duration(minutes: (10 - i) * 5 + random.nextInt(5))),
          isRead: i < 7,
        ),
      );
    }
    
    return messages;
  }
  
  Future<bool> sendMessage(String conversationId, String text) async {
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }
  
  Future<String> startNewConversation(String userId) async {
    await Future.delayed(Duration(milliseconds: 400));
    return 'chat_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Calendar Integration
  Future<List<CalendarEvent>> getCommunityEvents() async {
    await Future.delayed(Duration(milliseconds: 800));
    
    // Return mock community events that could be added to calendar
    final random = Random();
    final events = <CalendarEvent>[];
    
    final eventTitles = [
      '校园二手市场',
      '考试资料分享会',
      '编程竞赛',
      '英语角活动',
      '校园音乐会',
    ];
    
    final locations = [
      '图书馆前广场',
      '教学楼A101',
      '计算机系会议室',
      '学生活动中心',
      '体育场',
    ];
    
    // Generate events for the next 30 days
    for (int i = 0; i < 10; i++) {
      final daysFromNow = random.nextInt(30) + 1;
      final hoursInDay = random.nextInt(10) + 9; // 9 AM to 7 PM
      
      final startTime = DateTime.now().add(Duration(days: daysFromNow))
        .copyWith(hour: hoursInDay, minute: 0, second: 0);
      final endTime = startTime.add(Duration(hours: 2));
      
      events.add(
        CalendarEvent(
          title: eventTitles[random.nextInt(eventTitles.length)],
          notes: '地点: ${locations[random.nextInt(locations.length)]}\n'
                 '主办方: 学生会',
          startTime: startTime,
          endTime: endTime,
          reminderMinutes: [30, 1440], // 30 minutes and 1 day before
          color: '#${Colors.primaries[random.nextInt(Colors.primaries.length)].value.toRadixString(16).substring(2)}',
        ),
      );
    }
    
    return events;
  }
  
  Future<bool> addEventToCalendar(CalendarEvent event) async {
    // In a real app, this would add the event to the user's calendar
    await Future.delayed(Duration(milliseconds: 500));
    
    // Here we would typically interact with a calendar repository
    return true;
  }
  
  // Generate mock data
  List<MarketplaceItem> _generateMockMarketplaceItems() {
    final random = Random();
    
    final titles = [
      '全新未拆封 iPhone 15',
      '二手笔记本电脑 联想小新',
      '高等数学课本+习题',
      '二手自行车',
      '大学英语四级考试复习资料',
      '乒乓球拍',
      '宿舍小冰箱',
      '蓝牙音箱',
      '网络工程学课本',
      '小米手环',
      '电风扇',
      '羽毛球拍',
      '篮球',
      '计算机组成原理课本',
      '床头灯',
    ];
    
    final descriptions = [
      '全新未使用，只是拆了一下包装看了看',
      '用了一年，8成新，功能完好无损',
      '里面有我的笔记，对考试很有帮助',
      '毕业了用不到了，便宜出',
      '考完试了，不需要了',
      '几乎全新，用过几次',
      '搬家了，用不到了',
      '音质很好，电池续航强',
      '上学期的课本，9成新',
      '最新款，只用了几个月',
    ];
    
    return List.generate(
      15,
      (index) => MarketplaceItem(
        id: 'item_${index + 1}',
        title: titles[index % titles.length],
        description: descriptions[random.nextInt(descriptions.length)],
        price: (random.nextDouble() * 1000 + 10).roundToDouble(),
        sellerName: '用户${random.nextInt(1000)}',
        sellerContact: '1381234${random.nextInt(10000).toString().padLeft(4, '0')}',
        tradeLink: random.nextBool() ? 'https://example.com/trade/item_${index + 1}' : null,
        imageUrls: [],  // In a real app, these would be actual image URLs
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(30))),
        category: ItemCategory.values[random.nextInt(ItemCategory.values.length)],
        condition: ItemCondition.values[random.nextInt(ItemCondition.values.length)],
      ),
    );
  }
  
  List<StudyMaterial> _generateMockStudyMaterials() {
    final random = Random();
    
    final titles = [
      '高等数学期末复习资料',
      '大学英语四级备考笔记',
      '计算机组成原理考点总结',
      '数据结构与算法课件',
      '操作系统实验指导',
      '机器学习入门笔记',
      '数据库系统概念总结',
      '计算机网络知识点',
      '西方经济学复习提纲',
      '有机化学反应大全',
      'Python编程实例',
      '线性代数公式推导',
      'C++程序设计习题解析',
      '电路分析基础总结',
      '离散数学证明题集',
    ];
    
    final descriptions = [
      '包含了所有重点考点和例题',
      '个人整理的笔记，考试得了95分',
      '老师上课提到的所有重点都有标注',
      '实用性很强，对考试很有帮助',
      '整理了近五年的期末试题及答案',
      '包含详细的知识点讲解和例题',
      '按章节整理，内容全面',
      '有很多老师没讲到但考试会考的知识点',
      '经典例题和解题思路',
      '实验课必备参考资料',
    ];
    
    final subjects = [
      '高等数学',
      '大学英语',
      '计算机组成原理',
      '数据结构',
      '操作系统',
      '机器学习',
      '数据库系统',
      '计算机网络',
      '西方经济学',
      '有机化学',
      'Python程序设计',
      '线性代数',
      'C++程序设计',
      '电路分析',
      '离散数学',
    ];
    
    return List.generate(
      15,
      (index) {
        final downloadCount = random.nextInt(500) + 10;
        final viewCount = downloadCount + random.nextInt(300);
        
        return StudyMaterial(
          id: 'material_${index + 1}',
          title: titles[index % titles.length],
          description: descriptions[random.nextInt(descriptions.length)],
          contributor: '用户${random.nextInt(1000)}',
          fileUrl: random.nextBool() ? 'https://example.com/files/material_${index + 1}.pdf' : null,
          externalLink: random.nextBool() ? 'https://example.com/materials/${index + 1}' : null,
          uploadDate: DateTime.now().subtract(Duration(days: random.nextInt(180))),
          tags: [
            subjects[index % subjects.length].split(' ')[0],
            '学习',
            '考试',
            random.nextBool() ? '笔记' : '资料',
          ],
          materialType: StudyMaterialType.values[random.nextInt(StudyMaterialType.values.length)],
          subject: subjects[index % subjects.length],
          downloadCount: downloadCount,
          viewCount: viewCount,
          rating: (random.nextDouble() * 2 + 3).clamp(3.0, 5.0),  // Rating between 3.0 and 5.0
        );
      },
    );
  }

Future<Map<String, dynamic>> signup(String name, String email, String password, 
    {String? phone, String? department, String? grade}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'department': department,
        'grade': grade,
      }),
    );
    
    final data = json.decode(response.body);
    
    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'],
        'userId': data['userId'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? '注册失败，请稍后重试',
      };
    }
  } catch (e) {
    print('注册失败: $e');
    return {
      'success': false,
      'message': '网络错误，请检查网络连接',
    };
  }
}

Future<Map<String, dynamic>> verifyWithCalendar(String userId, String calendarData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-with-calendar'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'calendarData': calendarData,
      }),
    );
    
    final data = json.decode(response.body);
    
    return {
      'success': response.statusCode == 200 && data['success'] == true,
      'message': data['message'],
    };
  } catch (e) {
    print('课表验证失败: $e');
    return {
      'success': false,
      'message': '网络错误，请检查网络连接',
    };
  }
}

Future<Map<String, dynamic>> uploadStudentCard(String userId, File imageFile) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-student-card'),
    );
    
    request.fields['userId'] = userId;
    request.files.add(await http.MultipartFile.fromPath(
      'image', 
      imageFile.path,
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = json.decode(response.body);
    
    return {
      'success': response.statusCode == 200 && data['success'] == true,
      'message': data['message'],
    };
  } catch (e) {
    print('上传学生证失败: $e');
    return {
      'success': false,
      'message': '网络错误，请检查网络连接',
    };
  }
}

Future<String?> parseCalendar(File calendarFile) async {
  try {
    // 这里实现日历解析逻辑
    // 可以使用http上传到服务器解析，或在本地解析
    
    // 示例：仅作示意，实际需要根据您的日历格式开发
    final calendarText = await calendarFile.readAsString();
    if (calendarText.contains('课程') && calendarText.contains('时间')) {
      // 解析成功，返回规范化的JSON字符串
      return json.encode({
        'courses': [
          // 课程数据
        ]
      });
    }
    return null; // 解析失败
  } catch (e) {
    print('解析日历失败: $e');
    return null;
  }
}
}

