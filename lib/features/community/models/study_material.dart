// lib/features/community/models/study_material.dart
import 'package:flutter/material.dart';

class StudyMaterial {
  final String id;
  final String title;
  final String description;
  final String contributor;
  final String? fileUrl;
  final String? externalLink;
  final DateTime uploadDate;
  final List<String> tags;
  final StudyMaterialType materialType;
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
      materialType: StudyMaterialType.values[json['materialType']],
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

enum StudyMaterialType {
  notes,
  pastExam,
  presentation,
  textbook,
  article,
  video,
  other,
}

extension MaterialTypeExtension on StudyMaterialType {
  String get name {
    switch (this) {
      case StudyMaterialType.notes:
        return '笔记';
      case StudyMaterialType.pastExam:
        return '往年考题';
      case StudyMaterialType.presentation:
        return '演示文稿';
      case StudyMaterialType.textbook:
        return '教材';
      case StudyMaterialType.article:
        return '文章';
      case StudyMaterialType.video:
        return '视频';
      case StudyMaterialType.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case StudyMaterialType.notes:
        return Icons.note;
      case StudyMaterialType.pastExam:
        return Icons.assignment;
      case StudyMaterialType.presentation:
        return Icons.slideshow;
      case StudyMaterialType.textbook:
        return Icons.menu_book;
      case StudyMaterialType.article:
        return Icons.article;
      case StudyMaterialType.video:
        return Icons.video_library;
      case StudyMaterialType.other:
        return Icons.folder;
    }
  }

  Color get color {
    switch (this) {
      case StudyMaterialType.notes:
        return Colors.blue;
      case StudyMaterialType.pastExam:
        return Colors.red;
      case StudyMaterialType.presentation:
        return Colors.orange;
      case StudyMaterialType.textbook:
        return Colors.green;
      case StudyMaterialType.article:
        return Colors.purple;
      case StudyMaterialType.video:
        return Colors.pink;
      case StudyMaterialType.other:
        return Colors.grey;
    }
  }
}