/// Notification Response Models for Django Backend Integration
/// Data models matching Django notification API structure
library;

import '../models/api_response.dart';

/// Individual notification response model matching Django structure
class NotificationResponse {
  /// Unique notification identifier
  final String id;
  
  /// Notification title/subject
  final String title;
  
  /// Notification message body
  final String message;
  
  /// Whether the notification has been read
  final bool isRead;
  
  /// When the notification was created
  final DateTime createdAt;
  
  /// Type of notification (request_accepted, message_received, etc.)
  final String notificationType;
  
  /// Optional metadata for the notification
  final Map<String, dynamic>? metadata;
  
  /// Related entity ID (request_id, user_id, etc.)
  final String? relatedId;
  
  /// Priority level of the notification
  final String? priority;
  
  /// Action URL or deep link
  final String? actionUrl;

  const NotificationResponse({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.notificationType,
    this.metadata,
    this.relatedId,
    this.priority,
    this.actionUrl,
  });

  /// Create NotificationResponse from JSON
  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      notificationType: json['notification_type'] as String,
      metadata: json['extra_data'] as Map<String, dynamic>?,
      relatedId: json['created_by'] as String?,
      priority: json['priority'] as String?,
      actionUrl: null, // Not provided in Django API
    );
  }

  /// Convert NotificationResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'notification_type': notificationType,
      'metadata': metadata,
      'related_id': relatedId,
      'priority': priority,
      'action_url': actionUrl,
    };
  }

  /// Check if notification is urgent
  bool get isUrgent => priority == 'high' || priority == 'urgent';
  
  /// Check if notification is informational
  bool get isInfo => priority == 'low' || priority == 'info';
  
  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Get notification category based on type
  NotificationCategory get category {
    switch (notificationType) {
      case 'request_accepted':
      case 'request_declined':
      case 'request_completed':
        return NotificationCategory.request;
      case 'message_received':
      case 'chat_started':
        return NotificationCategory.message;
      case 'system_update':
      case 'maintenance':
        return NotificationCategory.system;
      case 'profile_updated':
      case 'settings_changed':
        return NotificationCategory.profile;
      default:
        return NotificationCategory.general;
    }
  }
  
  /// Create a copy with updated read status
  NotificationResponse copyWith({
    String? id,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? notificationType,
    Map<String, dynamic>? metadata,
    String? relatedId,
    String? priority,
    String? actionUrl,
  }) {
    return NotificationResponse(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      notificationType: notificationType ?? this.notificationType,
      metadata: metadata ?? this.metadata,
      relatedId: relatedId ?? this.relatedId,
      priority: priority ?? this.priority,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  @override
  String toString() {
    return 'NotificationResponse{id: $id, title: $title, isRead: $isRead, type: $notificationType}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationResponse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Notification categories for organization
enum NotificationCategory {
  general,
  request,
  message,
  system,
  profile,
}

/// Extension for NotificationCategory
extension NotificationCategoryExtension on NotificationCategory {
  /// Get display name for category
  String get displayName {
    switch (this) {
      case NotificationCategory.general:
        return 'General';
      case NotificationCategory.request:
        return 'Requests';
      case NotificationCategory.message:
        return 'Messages';
      case NotificationCategory.system:
        return 'System';
      case NotificationCategory.profile:
        return 'Profile';
    }
  }
  
  /// Get icon for category
  String get iconName {
    switch (this) {
      case NotificationCategory.general:
        return 'notifications';
      case NotificationCategory.request:
        return 'assignment';
      case NotificationCategory.message:
        return 'message';
      case NotificationCategory.system:
        return 'settings';
      case NotificationCategory.profile:
        return 'person';
    }
  }
}

/// Paginated notification response matching Django REST framework format
class PaginatedNotificationResponse extends PaginatedResponse<NotificationResponse> {
  /// Total unread count across all pages
  final int? totalUnreadCount;
  
  /// Breakdown by notification type
  final Map<String, int>? typeBreakdown;

  PaginatedNotificationResponse({
    required super.results,
    required super.totalCount,
    required super.currentPage,
    required super.totalPages,
    required super.pageSize,
    required super.hasNext,
    required super.hasPrevious,
    super.nextPageUrl,
    super.previousPageUrl,
    this.totalUnreadCount,
    this.typeBreakdown,
  });

  /// Factory constructor from Django pagination response
  factory PaginatedNotificationResponse.fromJson(Map<String, dynamic> json) {
    final baseResponse = PaginatedResponse.fromJson(
      json,
      (itemJson) => NotificationResponse.fromJson(itemJson),
    );

    return PaginatedNotificationResponse(
      results: baseResponse.results,
      totalCount: baseResponse.totalCount,
      currentPage: baseResponse.currentPage,
      totalPages: baseResponse.totalPages,
      pageSize: baseResponse.pageSize,
      hasNext: baseResponse.hasNext,
      hasPrevious: baseResponse.hasPrevious,
      nextPageUrl: baseResponse.nextPageUrl,
      previousPageUrl: baseResponse.previousPageUrl,
      totalUnreadCount: json['total_unread_count'],
      typeBreakdown: json['type_breakdown'] != null 
          ? Map<String, int>.from(json['type_breakdown'])
          : null,
    );
  }

  /// Convert to JSON
  @override
  Map<String, dynamic> toJson({Map<String, dynamic> Function(NotificationResponse)? toJsonT}) {
    final baseJson = super.toJson(toJsonT: toJsonT);
    baseJson.addAll({
      'total_unread_count': totalUnreadCount,
      'type_breakdown': typeBreakdown,
    });
    return baseJson;
  }

  /// Get unread notifications from current page
  List<NotificationResponse> get unreadNotifications {
    return results.where((notification) => !notification.isRead).toList();
  }

  /// Get notifications by category
  List<NotificationResponse> getNotificationsByCategory(NotificationCategory category) {
    return results.where((notification) => notification.category == category).toList();
  }

  /// Get notifications by type
  List<NotificationResponse> getNotificationsByType(String type) {
    return results.where((notification) => notification.notificationType == type).toList();
  }

  /// Get urgent notifications
  List<NotificationResponse> get urgentNotifications {
    return results.where((notification) => notification.isUrgent).toList();
  }

  @override
  String toString() {
    return 'PaginatedNotificationResponse{page: $currentPage/$totalPages, items: ${results.length}/$totalCount, unread: ${unreadNotifications.length}}';
  }
}

/// Unread count response for badge display
class UnreadCountResponse {
  /// Total unread notification count
  final int unreadCount;
  
  /// Breakdown by notification category
  final Map<String, int>? categoryBreakdown;
  
  /// Breakdown by notification type
  final Map<String, int>? typeBreakdown;
  
  /// Most recent unread notification timestamp
  final DateTime? latestUnreadAt;

  const UnreadCountResponse({
    required this.unreadCount,
    this.categoryBreakdown,
    this.typeBreakdown,
    this.latestUnreadAt,
  });

  /// Create UnreadCountResponse from JSON
  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unread_count'] as int,
      categoryBreakdown: json['category_breakdown'] != null
          ? Map<String, int>.from(json['category_breakdown'])
          : null,
      typeBreakdown: json['type_breakdown'] != null
          ? Map<String, int>.from(json['type_breakdown'])
          : null,
      latestUnreadAt: json['latest_unread_at'] != null
          ? DateTime.parse(json['latest_unread_at'] as String)
          : null,
    );
  }

  /// Convert UnreadCountResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'unread_count': unreadCount,
      'category_breakdown': categoryBreakdown,
      'type_breakdown': typeBreakdown,
      'latest_unread_at': latestUnreadAt?.toIso8601String(),
    };
  }

  /// Check if there are any unread notifications
  bool get hasUnread => unreadCount > 0;
  
  /// Get unread count for specific category
  int getUnreadCountForCategory(NotificationCategory category) {
    return categoryBreakdown?[category.name] ?? 0;
  }
  
  /// Get unread count for specific type
  int getUnreadCountForType(String type) {
    return typeBreakdown?[type] ?? 0;
  }
  
  /// Get formatted unread count string (99+ for large numbers)
  String get formattedCount {
    if (unreadCount > 99) {
      return '99+';
    }
    return unreadCount.toString();
  }

  @override
  String toString() {
    return 'UnreadCountResponse{unreadCount: $unreadCount, hasUnread: $hasUnread}';
  }
}

/// FCM token update response
class FcmTokenResponse {
  /// Success status
  final bool success;
  
  /// Response message
  final String message;
  
  /// Token registration timestamp
  final DateTime? registeredAt;

  const FcmTokenResponse({
    required this.success,
    required this.message,
    this.registeredAt,
  });

  /// Create FcmTokenResponse from JSON
  factory FcmTokenResponse.fromJson(Map<String, dynamic> json) {
    return FcmTokenResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : null,
    );
  }

  /// Convert FcmTokenResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'registered_at': registeredAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FcmTokenResponse{success: $success, message: $message}';
  }
}

/// Notification preferences response
class NotificationPreferencesResponse {
  /// Email notifications enabled
  final bool emailEnabled;
  
  /// Push notifications enabled
  final bool pushEnabled;
  
  /// SMS notifications enabled
  final bool smsEnabled;
  
  /// Enabled notification types
  final List<String> enabledTypes;
  
  /// Quiet hours start time (24-hour format)
  final String? quietHoursStart;
  
  /// Quiet hours end time (24-hour format)
  final String? quietHoursEnd;

  const NotificationPreferencesResponse({
    required this.emailEnabled,
    required this.pushEnabled,
    required this.smsEnabled,
    required this.enabledTypes,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  /// Create NotificationPreferencesResponse from JSON
  factory NotificationPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesResponse(
      emailEnabled: json['email_enabled'] as bool,
      pushEnabled: json['push_enabled'] as bool,
      smsEnabled: json['sms_enabled'] as bool,
      enabledTypes: List<String>.from(json['enabled_types'] as List),
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
    );
  }

  /// Convert NotificationPreferencesResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'email_enabled': emailEnabled,
      'push_enabled': pushEnabled,
      'sms_enabled': smsEnabled,
      'enabled_types': enabledTypes,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
    };
  }

  /// Check if specific notification type is enabled
  bool isTypeEnabled(String type) {
    return enabledTypes.contains(type);
  }
  
  /// Check if quiet hours are configured
  bool get hasQuietHours {
    return quietHoursStart != null && quietHoursEnd != null;
  }

  @override
  String toString() {
    return 'NotificationPreferencesResponse{push: $pushEnabled, email: $emailEnabled, sms: $smsEnabled}';
  }
}

/// TODO: Phase 3 Integration Points
/// - Add real-time notification model for WebSocket events
/// - Implement notification action models for interactive notifications
/// - Add notification attachment models for rich content
/// - Create notification template models for customization
/// - Add notification analytics models for tracking
