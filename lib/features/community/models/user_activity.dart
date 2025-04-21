// lib/features/community/models/user_activity.dart
import 'package:flutter/foundation.dart';

/// Represents a user activity or state change in the application
class UserActivity {
  /// Type of activity
  final ActivityType type;
  
  /// Description of the activity (can be a message, search query, etc.)
  final String description;
  
  /// Additional metadata associated with this activity
  final Map<String, dynamic>? metadata;
  
  /// Optional identifier for the activity
  final String? id;
  
  /// Optional timestamp when the activity occurred
  final DateTime? timestamp;
  
  /// Create a new user activity
  UserActivity({
    required this.type,
    required this.description,
    this.metadata,
    this.id,
    this.timestamp,
  });
  
  /// Create a copy of this activity with some fields replaced
  UserActivity copyWith({
    ActivityType? type,
    String? description,
    Map<String, dynamic>? metadata,
    String? id,
    DateTime? timestamp,
  }) {
    return UserActivity(
      type: type ?? this.type,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'UserActivity(type: $type, description: $description)';
  }
}

/// Different types of user activities that can be tracked
enum ActivityType {
  /// User opened a new screen
  navigation,
  
  /// User performed a search
  search,
  
  /// User engaged in conversation with AI
  conversation,
  
  /// User received a message
  messageReceived,
  
  /// User sent a message
  messageSent,
  
  /// User made a change to their calendar
  calendarChange,
  
  /// User provided personal information
  userInfo,
  
  /// User set a preference
  preference,
  
  /// User encountered an error
  error,
  
  /// System detected a security-related event
  securityEvent,
  
  /// User has an upcoming event soon
  upcomingEvent,
  
  /// System triggered an alarm/reminder
  alarm,
  
  /// User was idle for a significant period
  inactivity,
  
  /// Other activity types
  other
}