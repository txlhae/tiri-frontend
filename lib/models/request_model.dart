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
    return UserRequestStatus(
      requestStatus: json['request_status'] ?? 'not_requested',
      canRequest: json['can_request'] ?? false,
      canCancelRequest: json['can_cancel_request'] ?? false,
      messageContent: json['message_content'],
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
  required String location,
  required DateTime timestamp,
  required DateTime requestedTime,
  required RequestStatus status,
  @Default([]) List<UserModel> acceptedUser, 
  List<FeedbackModel>? feedbackList,
  @Default(1) required int numberOfPeople,
  @Default(1) required int hoursNeeded,
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
  
  // Get requester for this request
  UserModel? get requester => _requesterCache[requestId];
  
  // Get enhanced user request status object
  UserRequestStatus? get userRequestStatusObject => _userRequestStatusCache[requestId];
  
  // Convenient access methods using the enhanced UserRequestStatus
  String get userRequestStatus => userRequestStatusObject?.requestStatus ?? 'not_requested';
  bool get canRequest => userRequestStatusObject?.canRequest ?? false;
  bool get canCancelRequest => userRequestStatusObject?.canCancelRequest ?? false;
  String? get volunteerMessage => userRequestStatusObject?.messageContent;
  bool get hasVolunteered => userRequestStatusObject?.hasVolunteered ?? false;
  DateTime? get requestedAt => userRequestStatusObject?.requestedAt;
  DateTime? get acceptedAt => userRequestStatusObject?.acceptedAt;
}