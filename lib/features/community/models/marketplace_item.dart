// lib/features/community/models/marketplace_item.dart
import 'package:flutter/material.dart';
class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String sellerName;
  final String sellerContact;
  final String? tradeLink;
  final List<String> imageUrls;
  final DateTime createdAt;
  final ItemCategory category;
  final ItemCondition condition;

  MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.sellerName,
    required this.sellerContact,
    this.tradeLink,
    required this.imageUrls,
    required this.createdAt,
    required this.category,
    required this.condition,
  });

  // Factory method to create from JSON
  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      sellerName: json['sellerName'],
      sellerContact: json['sellerContact'],
      tradeLink: json['tradeLink'],
      imageUrls: List<String>.from(json['imageUrls']),
      createdAt: DateTime.parse(json['createdAt']),
      category: ItemCategory.values[json['category']],
      condition: ItemCondition.values[json['condition']],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'sellerName': sellerName,
      'sellerContact': sellerContact,
      'tradeLink': tradeLink,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'category': category.index,
      'condition': condition.index,
    };
  }
}

enum ItemCategory {
  books,
  electronics,
  clothing,
  furniture,
  sports,
  other,
}

enum ItemCondition {
  new_condition,
  like_new,
  good,
  fair,
  poor,
}

extension ItemCategoryExtension on ItemCategory {
  String get name {
    switch (this) {
      case ItemCategory.books:
        return '书籍';
      case ItemCategory.electronics:
        return '电子产品';
      case ItemCategory.clothing:
        return '服装';
      case ItemCategory.furniture:
        return '家具';
      case ItemCategory.sports:
        return '体育用品';
      case ItemCategory.other:
        return '其他';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.books:
        return Icons.book;
      case ItemCategory.electronics:
        return Icons.devices;
      case ItemCategory.clothing:
        return Icons.shopping_bag;
      case ItemCategory.furniture:
        return Icons.chair;
      case ItemCategory.sports:
        return Icons.sports_basketball;
      case ItemCategory.other:
        return Icons.category;
    }
  }
}

extension ItemConditionExtension on ItemCondition {
  String get name {
    switch (this) {
      case ItemCondition.new_condition:
        return '全新';
      case ItemCondition.like_new:
        return '几乎全新';
      case ItemCondition.good:
        return '良好';
      case ItemCondition.fair:
        return '一般';
      case ItemCondition.poor:
        return '较差';
    }
  }
}