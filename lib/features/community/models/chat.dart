// lib/models/chat.dart
class Chat {
  final String id;
  final String otherUserId;
  final String otherVestName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  
  Chat({
    required this.id,
    required this.otherUserId,
    required this.otherVestName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
  
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      otherUserId: json['otherUserId'],
      otherVestName: json['otherVestName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}