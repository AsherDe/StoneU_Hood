// lib/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Chat> _chats = [];
  Timer? _messageListener;
  Function(Message)? _onNewMessageCallback;
  
  List<Chat> get chats => [..._chats];
  
  Future<void> fetchChats() async {
    final response = await apiService.get('/chats');
    
    _chats = (response['chats'] as List)
        .map((chat) => Chat.fromJson(chat))
        .toList();
        
    notifyListeners();
  }
  
  Future<String> createPrivateChat(String receiverId, String receiverVestName, String postId) async {
    final response = await apiService.post(
      '/chats',
      {
        'receiverId': receiverId,
        'postId': postId,
      },
    );
    
    // 检查聊天是否已存在
    final existingChatIndex = _chats.indexWhere((chat) => chat.id == response['id']);
    
    if (existingChatIndex < 0) {
      final newChat = Chat(
        id: response['id'],
        otherUserId: receiverId,
        otherVestName: receiverVestName,
        postId: postId,
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
      
      _chats.insert(0, newChat);
      notifyListeners();
    }
    
    return response['id'];
  }
  
  Future<List<Message>> fetchMessages(String chatId) async {
    final response = await apiService.get('/chats/$chatId/messages');
    final currentUserId = response['currentUserId'];
    
    // 清除未读消息计数
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex >= 0) {
      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        otherUserId: _chats[chatIndex].otherUserId,
        otherVestName: _chats[chatIndex].otherVestName,
        postId: _chats[chatIndex].postId,
        lastMessage: _chats[chatIndex].lastMessage,
        lastMessageTime: _chats[chatIndex].lastMessageTime,
        unreadCount: 0,
      );
      
      notifyListeners();
    }
    
    return (response['messages'] as List)
        .map((message) => Message.fromJson(message, currentUserId))
        .toList();
  }
  
  Future<void> sendMessage(String chatId, String content) async {
    final _ = await apiService.post(
      '/chats/$chatId/messages',
      {'content': content},
    );
    
    // 更新聊天列表中的最后一条消息
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex >= 0) {
      _chats[chatIndex] = Chat(
        id: _chats[chatIndex].id,
        otherUserId: _chats[chatIndex].otherUserId,
        otherVestName: _chats[chatIndex].otherVestName,
        postId: _chats[chatIndex].postId,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
      
      // 将刚发送消息的聊天移到顶部
      if (chatIndex > 0) {
        final chat = _chats.removeAt(chatIndex);
        _chats.insert(0, chat);
      }
      
      notifyListeners();
    }
  }
  
  void startMessageListener(String chatId, Function(Message) onNewMessage) {
    _stopMessageListener();
    _onNewMessageCallback = onNewMessage;
    
    // 模拟WebSocket连接，定期轮询新消息
    // 实际应用中应使用WebSocket或FCM等实时通信技术
    _messageListener = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        final response = await apiService.get('/chats/$chatId/messages/new');
        final currentUserId = response['currentUserId'];
        
        if (response['hasNewMessages']) {
          final newMessages = (response['messages'] as List)
              .map((message) => Message.fromJson(message, currentUserId))
              .toList();
              
          // 按时间先后顺序处理消息
          for (final message in newMessages) {
            _onNewMessageCallback?.call(message);
          }
        }
      } catch (e) {
        print('获取新消息失败: $e');
      }
    });
  }
  
  void stopMessageListener() {
    _stopMessageListener();
  }
  
  void _stopMessageListener() {
    _messageListener?.cancel();
    _messageListener = null;
    _onNewMessageCallback = null;
  }
}