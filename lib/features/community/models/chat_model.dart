// models/chat_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatModel extends ChangeNotifier {
  final List<types.Room> _rooms = [];
  final Map<String, List<types.Message>> _messages = {};
  final String _selfUserId;
  
  ChatModel(this._selfUserId);
  
  List<types.Room> get rooms => List.unmodifiable(_rooms);
  
  List<types.Message> getMessages(String roomId) {
    return List.unmodifiable(_messages[roomId] ?? []);
  }
  
  // 创建或获取与用户的聊天室
  types.Room createOrGetRoom(String userId, String userName, String? userAvatar) {
    // 检查是否已存在与该用户的聊天室
    for (final room in _rooms) {
      if (room.type == types.RoomType.direct) {
        final otherUser = room.users.firstWhere(
          (user) => user.id != _selfUserId,
          orElse: () => types.User(id: ''),
        );
        
        if (otherUser.id == userId) {
          return room;
        }
      }
    }
    
    // 创建新的聊天室
    final roomId = const Uuid().v4();
    final selfUser = types.User(id: _selfUserId);
    final otherUser = types.User(
      id: userId,
      firstName: userName,
      imageUrl: userAvatar,
    );
    
    final newRoom = types.Room(
      id: roomId,
      type: types.RoomType.direct,
      users: [selfUser, otherUser],
      name: userName,
      imageUrl: userAvatar,
    );
    
    _rooms.add(newRoom);
    _messages[roomId] = [];
    notifyListeners();
    
    return newRoom;
  }
  
  // 发送消息
  void sendMessage(String roomId, String text) {
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }
    
    final message = types.TextMessage(
      id: const Uuid().v4(),
      author: types.User(id: _selfUserId),
      text: text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    
    _messages[roomId]!.insert(0, message);
    
    // 更新房间最后一条消息
    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final updatedRoom = room.copyWith(
        lastMessages: [message],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      _rooms[roomIndex] = updatedRoom;
      
      // 将最近聊天的房间移动到列表前面
      if (roomIndex > 0) {
        _rooms.removeAt(roomIndex);
        _rooms.insert(0, updatedRoom);
      }
    }
    
    notifyListeners();
    
    // 这里应该调用API发送消息到服务器
    // 为简化示例，这里只是本地处理
    _simulateReceivedMessage(roomId);
  }
  
  // 模拟接收消息（实际应用中会由WebSocket推送）
  void _simulateReceivedMessage(String roomId) {
    Future.delayed(const Duration(seconds: 1), () {
      final room = _rooms.firstWhere((room) => room.id == roomId);
      final otherUser = room.users.firstWhere((user) => user.id != _selfUserId);
      
      final message = types.TextMessage(
        id: const Uuid().v4(),
        author: otherUser,
        text: '这是自动回复消息',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      _messages[roomId]!.insert(0, message);
      
      // 更新房间最后一条消息
      final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        final updatedRoom = room.copyWith(
          lastMessages: [message],
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _rooms[roomIndex] = updatedRoom;
      }
      
      notifyListeners();
    });
  }
  
  // 处理收到的消息
  void handleReceivedMessage(String roomId, types.Message message) {
    if (!_messages.containsKey(roomId)) {
      _messages[roomId] = [];
    }
    
    _messages[roomId]!.insert(0, message);
    
    // 更新房间最后一条消息
    final roomIndex = _rooms.indexWhere((room) => room.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      final updatedRoom = room.copyWith(
        lastMessages: [message],
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      
      _rooms[roomIndex] = updatedRoom;
      
      // 将最近聊天的房间移动到列表前面
      if (roomIndex > 0) {
        _rooms.removeAt(roomIndex);
        _rooms.insert(0, updatedRoom);
      }
    }
    
    notifyListeners();
  }
}