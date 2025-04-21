// Post Model for handling community posts in AI assistant
import 'dart:convert';

class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final String category;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<String> tags;
  final String? imageUrl;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.category,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.tags,
    this.imageUrl,
  });

  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    String? category,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    List<String>? tags,
    String? imageUrl,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'],
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      isLiked: json['isLiked'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'tags': tags,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}