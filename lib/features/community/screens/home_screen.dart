// lib/features/community/models/study_material.dart
import 'package:flutter/material.dart';
import '../community_controller.dart';
// import '../widgets/marketplace_item_card.dart';
// import '../widgets/study_material_card.dart';
import 'package:provider/provider.dart';

class StudyMaterial {
  final String id;
  final String title;
  final String description;
  final String contributor;
  final String? fileUrl;
  final String? externalLink;
  final DateTime uploadDate;
  final List<String> tags;
  final MaterialType materialType;
  final String subject;
  final int downloadCount;
  final int viewCount;
  final double rating;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.contributor,
    this.fileUrl,
    this.externalLink,
    required this.uploadDate,
    required this.tags,
    required this.materialType,
    required this.subject,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.rating = 0.0,
  });

  // Factory method to create from JSON
  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      contributor: json['contributor'],
      fileUrl: json['fileUrl'],
      externalLink: json['externalLink'],
      uploadDate: DateTime.parse(json['uploadDate']),
      tags: List<String>.from(json['tags']),
      materialType: MaterialType.values[json['materialType']],
      subject: json['subject'],
      downloadCount: json['downloadCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'contributor': contributor,
      'fileUrl': fileUrl,
      'externalLink': externalLink,
      'uploadDate': uploadDate.toIso8601String(),
      'tags': tags,
      'materialType': materialType.index,
      'subject': subject,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'rating': rating,
    };
  }
}

enum MaterialType {
  notes,
  pastExam,
  presentation,
  textbook,
  article,
  video,
  other,
}

extension MaterialTypeExtension on MaterialType {
  String get name {
    switch (this) {
      case MaterialType.notes:
        return '笔记';
      case MaterialType.pastExam:
        return '往年考题';
      case MaterialType.presentation:
        return '演示文稿';
      case MaterialType.textbook:
        return '教材';
      case MaterialType.article:
        return '文章';
      case MaterialType.video:
        return '视频';
      case MaterialType.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case MaterialType.notes:
        return Icons.note;
      case MaterialType.pastExam:
        return Icons.assignment;
      case MaterialType.presentation:
        return Icons.slideshow;
      case MaterialType.textbook:
        return Icons.menu_book;
      case MaterialType.article:
        return Icons.article;
      case MaterialType.video:
        return Icons.video_library;
      case MaterialType.other:
        return Icons.folder;
    }
  }

  Color get color {
    switch (this) {
      case MaterialType.notes:
        return Colors.blue;
      case MaterialType.pastExam:
        return Colors.red;
      case MaterialType.presentation:
        return Colors.orange;
      case MaterialType.textbook:
        return Colors.green;
      case MaterialType.article:
        return Colors.purple;
      case MaterialType.video:
        return Colors.pink;
      case MaterialType.other:
        return Colors.grey;
    }
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              '社区首页',
              style: TextStyle(color: Colors.black87),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await controller.initialize();
            },
            child: ListView(
              children: [
                // 首页内容
                // ...
              ],
            ),
          ),
        );
      },
    );
  }
}