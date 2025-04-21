// lib/features/community/models/memory_item.dart
import 'user_activity.dart';

/// A memory item represents a user activity stored in the memory stream
/// along with metadata about how it has been processed by the AI system
class MemoryItem {
  /// The user activity that this memory item records
  final UserActivity activity;
  
  /// When this activity occurred
  final DateTime timestamp;
  
  /// Whether this memory has been processed by the background memory processor
  final bool hasBeenProcessed;
  
  /// Optional importance score assigned to this memory (higher = more important)
  final double? importanceScore;
  
  /// Create a new memory item
  MemoryItem({
    required this.activity,
    required this.timestamp,
    this.hasBeenProcessed = false,
    this.importanceScore,
  });
  
  /// Create a copy of this memory item with some fields replaced
  MemoryItem copyWith({
    UserActivity? activity,
    DateTime? timestamp,
    bool? hasBeenProcessed,
    double? importanceScore,
  }) {
    return MemoryItem(
      activity: activity ?? this.activity,
      timestamp: timestamp ?? this.timestamp,
      hasBeenProcessed: hasBeenProcessed ?? this.hasBeenProcessed,
      importanceScore: importanceScore ?? this.importanceScore,
    );
  }
  
  @override
  String toString() {
    return 'MemoryItem(activity: ${activity.type}, processed: $hasBeenProcessed)';
  }
}