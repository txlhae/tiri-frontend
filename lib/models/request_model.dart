import 'dart:developer';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';
import 'feedback_model.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

enum RequestStatus { pending, accepted, complete, incomplete, cancelled ,inprogress, expired}

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
    
    log('🔍 UserRequestStatus.fromJson DEBUG:');
    log('   - request_status: ${json['request_status']}');
    log('   - ALL JSON KEYS: ${json.keys.toList()}');
    log('   - message_content: "${json['message_content']}"');
    log('   - message_to_requester: "${json['message_to_requester']}"');
    log('   - volunteer_message: "${json['volunteer_message']}"');
    log('   - message: "${json['message']}"');
    log('   - user_message: "${json['user_message']}"');
    log('   - FINAL messageContent: "$messageContent"');
    log('   - messageContent type: ${messageContent.runtimeType}');
    log('   - messageContent isEmpty: ${messageContent?.toString().isEmpty}');
    
    return UserRequestStatus(
      requestStatus: json['request_status'] ?? 'not_requested',
      canRequest: json['can_request'] ?? false,
      canCancelRequest: json['can_cancel_request'] ?? false,
      messageContent: messageContent,
      hasVolunteered: json['has_volunteered'] ?? false,
      requestedAt: json['requested_at'] != null 
          ? DateTime.tryParse(json['requested_at']) 
          : null,
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.tryParse(json['accepted_at']) 
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
  const factory RequestModel({
  required String requestId,
  required String userId,
  required String title,
  required String description,
  String? location, // Made nullable - can be null from backend
  required DateTime timestamp,
  DateTime? requestedTime, // Made nullable - might not always be set
  required RequestStatus status,
  @Default([]) List<UserModel> acceptedUser, 
  List<FeedbackModel>? feedbackList,
  @Default(1) int numberOfPeople, // Removed required for @Default fields
  @Default(1) int hoursNeeded, // Removed required for @Default fields
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
    
    return requestModel;
  }
  
  // Static cache to store requester data
  static final Map<String, UserModel> _requesterCache = {};
  
  // Enhanced cache to store UserRequestStatus objects
  static final Map<String, UserRequestStatus> _userRequestStatusCache = {};
  
  // Cache management methods
  /// Clear user request status cache for a specific request
  static void clearUserStatusCache(String requestId) {
    if (_userRequestStatusCache.containsKey(requestId)) {
      _userRequestStatusCache.remove(requestId);
      log('🗑️ RequestModelExtension: Cleared user status cache for request $requestId');
    } else {
      log('🔍 RequestModelExtension: No cache entry found for request $requestId to clear');
    }
  }
  
  /// Clear all user request status cache entries
  static void clearAllUserStatusCache() {
    final cacheSize = _userRequestStatusCache.length;
    _userRequestStatusCache.clear();
    log('🗑️ RequestModelExtension: Cleared all user status cache ($cacheSize entries)');
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
    // Debug logging can be removed in production
    // print('🔍 volunteerMessage getter DEBUG for requestId: $requestId');
    return message;
  }
  bool get hasVolunteered => userRequestStatusObject?.hasVolunteered ?? false;
  DateTime? get requestedAt => userRequestStatusObject?.requestedAt;
  DateTime? get acceptedAt => userRequestStatusObject?.acceptedAt;
}