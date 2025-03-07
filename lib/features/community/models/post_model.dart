// models/post_model.dart - 帖子模型
import 'comment_model.dart';

class Post {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final DateTime postTime;
  final String content;
  final String category;
  final List<String> tags;
  int likes;
  final int commentCount;
  int shares;
  final double? rewardAmount;
  final bool isLiked;
  final List<Comment> comments;
  
  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.postTime,
    required this.content,
    required this.category,
    required this.tags,
    this.likes = 0,
    this.commentCount = 0,
    this.shares = 0,
    this.rewardAmount,
    this.isLiked = false,
    this.comments = const [],
  });

factory Post.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = [];
    if (json['comments'] != null) {
      comments = (json['comments'] as List)
          .map((commentJson) => Comment.fromJson(commentJson))
          .toList();
    }
    
    return Post(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      userAvatar: json['userAvatar'],
      postTime: DateTime.parse(json['postTime']),
      content: json['content'],
      category: json['category'],
      tags: List<String>.from(json['tags']),
      likes: json['likes'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      shares: json['shares'] ?? 0,
      rewardAmount: json['rewardAmount'],
      isLiked: json['isLiked'] ?? false,
      comments: comments,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'postTime': postTime.toIso8601String(),
      'content': content,
      'category': category,
      'tags': tags,
      'likes': likes,
      'commentCount': commentCount,
      'shares': shares,
      'rewardAmount': rewardAmount,
      'isLiked': isLiked,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
  
  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatar,
    DateTime? postTime,
    String? content,
    String? category,
    List<String>? tags,
    int? likes,
    int? commentCount,
    int? shares,
    double? rewardAmount,
    bool? isLiked,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      postTime: postTime ?? this.postTime,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      shares: shares ?? this.shares,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}