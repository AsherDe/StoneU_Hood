// lib/features/community/models/comment.dart
class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? userAvatar;
  final DateTime commentTime;
  final String content;
  final int likes;
  final bool isLiked;
  
  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.commentTime,
    required this.content,
    this.likes = 0,
    this.isLiked = false,
  });
  
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      username: json['username'],
      userAvatar: json['userAvatar'],
      commentTime: DateTime.parse(json['commentTime']),
      content: json['content'],
      likes: json['likes'] ?? 0,
      isLiked: json['isLiked'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'commentTime': commentTime.toIso8601String(),
      'content': content,
      'likes': likes,
      'isLiked': isLiked,
    };
  }
  
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? userAvatar,
    DateTime? commentTime,
    String? content,
    int? likes,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      commentTime: commentTime ?? this.commentTime,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
