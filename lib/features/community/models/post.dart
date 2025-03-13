// lib/models/post.dart
class Post {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final String vestName;
  final DateTime createdAt;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  
  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.vestName,
    required this.createdAt,
    this.isLiked = false,
    this.likeCount = 0,
    this.commentCount = 0,
  });
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      vestName: json['vestName'],
      createdAt: DateTime.parse(json['createdAt']),
      isLiked: json['isLiked'] ?? false,
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
    );
  }
  
  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? category,
    String? vestName,
    DateTime? createdAt,
    bool? isLiked,
    int? likeCount,
    int? commentCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      vestName: vestName ?? this.vestName,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

