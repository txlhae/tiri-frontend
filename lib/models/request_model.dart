import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';
import 'feedback_model.dart';
import 'category_model.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

enum RequestStatus { pending, accepted, complete, incomplete, cancelled ,inprogress, delayed}

// JSON converter function for acceptedUser field
List<UserModel> _acceptedUserFromJson(dynamic json) {

  if (json == null) return [];
  if (json is! List) return [];

  try {
    return json
        .map((userJson) {
          if (userJson is! Map<String, dynamic>) return null;
          return UserModel.fromJson(userJson);
        })
        .whereType<UserModel>()
        .toList();
  } catch (e) {
    return [];
  }
}

// JSON converter for UTC DateTime to Local DateTime
DateTime _dateTimeFromJson(String json) {
  return DateTime.parse(json).toUtc().toLocal();
}

// JSON converter for nullable UTC DateTime to Local DateTime
DateTime? _nullableDateTimeFromJson(String? json) {
  if (json == null) return null;
  return DateTime.parse(json).toUtc().toLocal();
}

// JSON converter for category field
CategoryModel? _categoryFromJson(dynamic json) {
  if (json == null) return null;
  if (json is! Map<String, dynamic>) return null;
  try {
    return CategoryModel.fromJson(json);
  } catch (e) {
    return null;
  }
}

/// Enhanced user request status for volunteer workflow
class UserRequestStatus {
  final String requestStatus;
  final bool canRequest;
  final bool canCancelRequest;
  final String? messageContent;
  final bool hasVolunteered;
  final DateTime? requestedAt;
  final DateTime? acceptedAt;

  const UserRequestStatus({
    this.requestStatus = 'not_requested',
    this.canRequest = false,
    this.canCancelRequest = false,
    this.messageContent,
    this.hasVolunteered = false,
    this.requestedAt,
    this.acceptedAt,
  });

  factory UserRequestStatus.fromJson(Map<String, dynamic> json) {
    // Try multiple possible field names for the message
    final messageContent = json['message_content'] ??
                          json['message_to_requester'] ??
                          json['volunteer_message'] ??
                          json['message'] ??
                          json['user_message'] ?? '';


    return UserRequestStatus(
      requestStatus: json['request_status'] ?? 'not_requested',
      canRequest: json['can_request'] ?? false,
      canCancelRequest: json['can_cancel_request'] ?? false,
      messageContent: messageContent,
      hasVolunteered: json['has_volunteered'] ?? false,
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'])?.toUtc().toLocal()
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.tryParse(json['accepted_at'])?.toUtc().toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_status': requestStatus,
      'can_request': canRequest,
      'can_cancel_request': canCancelRequest,
      'message_content': messageContent,
      'has_volunteered': hasVolunteered,
      'requested_at': requestedAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
    };
  }
}

@freezed
class RequestModel with _$RequestModel {
  // ignore: unused_element
  const RequestModel._();

  const factory RequestModel({
  required String requestId,
  required String userId,
  required String title,
  required String description,
  String? location, // Made nullable - can be null from backend
  @Default(0.0) double latitude, // Location coordinates
  @Default(0.0) double longitude, // Location coordinates
  // ignore: invalid_annotation_target
  @JsonKey(fromJson: _dateTimeFromJson) required DateTime timestamp,
  // ignore: invalid_annotation_target
  @JsonKey(fromJson: _nullableDateTimeFromJson) DateTime? requestedTime, // Made nullable - might not always be set
  required RequestStatus status,
  // ignore: invalid_annotation_target
  @JsonKey(fromJson: _acceptedUserFromJson) @Default([]) List<UserModel> acceptedUser,
  // ignore: invalid_annotation_target
  @JsonKey(includeFromJson: false, includeToJson: false) List<FeedbackModel>? feedbackList,
  @Default(1) int numberOfPeople, // Removed required for @Default fields
  @Default(1) int hoursNeeded, // Removed required for @Default fields
  // ignore: invalid_annotation_target
  @JsonKey(fromJson: _categoryFromJson) CategoryModel? category, // Category from API
}) = _RequestModel;

  // Convert JSON to Model
  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);
}

// Extension to add requester functionality and enhanced user request status
extension RequestModelExtension on RequestModel {
  // Helper method to get requester from JSON if it exists
  static UserModel? getRequesterFromJson(Map<String, dynamic> json) {
    if (json['requester'] != null) {
      return UserModel.fromRequesterJson(json['requester']);
    }
    return null;
  }
  
  // Factory method to create RequestModel with requester and enhanced user status parsed
  static RequestModel fromJsonWithRequester(Map<String, dynamic> json) {

    // Parse user request status from Django response
    final userRequestStatusData = json['user_request_status'] as Map<String, dynamic>?;

    final requestModel = RequestModel.fromJson(json);
    
    // Store the requester data in cache for backward compatibility
    if (json['requester'] != null) {
      final requester = UserModel.fromRequesterJson(json['requester']);
      RequestModelExtension._requesterCache[requestModel.requestId] = requester;
    }
    
    // Store enhanced user request status data using UserRequestStatus class
    if (userRequestStatusData != null) {
      RequestModelExtension._userRequestStatusCache[requestModel.requestId] = 
          UserRequestStatus.fromJson(userRequestStatusData);
    }
    
    // Store feedback data if available
    if (json['feedback'] != null) {
      RequestModelExtension._feedbackCache[requestModel.requestId] = json['feedback'];
    }
    
    // Store completion data if available
    if (json['completed_at'] != null) {
      try {
        RequestModelExtension._completedAtCache[requestModel.requestId] =
            DateTime.parse(json['completed_at']).toUtc().toLocal();
      } catch (e) {
        RequestModelExtension._completedAtCache[requestModel.requestId] = null;
      }
    }
    
    if (json['completion_confirmed_by_requester'] != null) {
      RequestModelExtension._completionConfirmedCache[requestModel.requestId] =
          json['completion_confirmed_by_requester'] as bool? ?? false;
    }

    // Store notification data if available
    if (json['has_pending_notifications'] != null) {
      RequestModelExtension._hasPendingNotificationsCache[requestModel.requestId] =
          json['has_pending_notifications'] as bool? ?? false;
    }

    if (json['notification_count'] != null) {
      RequestModelExtension._notificationCountCache[requestModel.requestId] =
          json['notification_count'] as int? ?? 0;
    }

    return requestModel;
  }
  
  // Static cache to store requester data
  static final Map<String, UserModel> _requesterCache = {};
  
  // Enhanced cache to store UserRequestStatus objects
  static final Map<String, UserRequestStatus> _userRequestStatusCache = {};
  
  // Cache to store feedback data
  static final Map<String, dynamic> _feedbackCache = {};
  
  // Cache to store completion data
  static final Map<String, DateTime?> _completedAtCache = {};
  static final Map<String, bool> _completionConfirmedCache = {};

  // Cache to store notification data
  static final Map<String, bool> _hasPendingNotificationsCache = {};
  static final Map<String, int> _notificationCountCache = {};
  
  // Cache management methods
  /// Clear user request status cache for a specific request
  static void clearUserStatusCache(String requestId) {
    if (_userRequestStatusCache.containsKey(requestId)) {
      _userRequestStatusCache.remove(requestId);
    } else {
    }
  }
  
  /// Clear all user request status cache entries
  static void clearAllUserStatusCache() {
    _userRequestStatusCache.clear();
  }

  /// Clear ALL caches - user status and requester cache
  static void clearAllCache() {
    _userRequestStatusCache.clear();
    _requesterCache.clear();
  }
  
  // Get requester for this request
  UserModel? get requester => _requesterCache[requestId];
  
  // Get enhanced user request status object
  UserRequestStatus? get userRequestStatusObject => _userRequestStatusCache[requestId];
  
  // Convenient access methods using the enhanced UserRequestStatus
  String get userRequestStatus => userRequestStatusObject?.requestStatus ?? 'not_requested';
  bool get canRequest => userRequestStatusObject?.canRequest ?? false;
  bool get canCancelRequest => userRequestStatusObject?.canCancelRequest ?? false;
  String? get volunteerMessage {
    final statusObject = userRequestStatusObject;
    final message = statusObject?.messageContent;
    return message;
  }
  bool get hasVolunteered => userRequestStatusObject?.hasVolunteered ?? false;
  DateTime? get requestedAt => userRequestStatusObject?.requestedAt;
  DateTime? get acceptedAt => userRequestStatusObject?.acceptedAt;
  
  // Feedback and completion data accessors
  dynamic get feedback => _feedbackCache[requestId];
  DateTime? get completedAt => _completedAtCache[requestId];
  bool get completionConfirmedByRequester => _completionConfirmedCache[requestId] ?? false;

  // Notification data accessors
  bool get hasPendingNotifications => _hasPendingNotificationsCache[requestId] ?? false;
  int get notificationCount => _notificationCountCache[requestId] ?? 0;
}