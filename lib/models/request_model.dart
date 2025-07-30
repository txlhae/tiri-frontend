import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';
import 'feedback_model.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

enum RequestStatus { pending, accepted, complete, incomplete, cancelled ,inprogress, expired}

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

// Extension to add requester functionality
extension RequestModelExtension on RequestModel {
  // Helper method to get requester from JSON if it exists
  static UserModel? getRequesterFromJson(Map<String, dynamic> json) {
    if (json['requester'] != null) {
      return UserModel.fromRequesterJson(json['requester']);
    }
    return null;
  }
  
  // Factory method to create RequestModel with requester parsed
  static RequestModel fromJsonWithRequester(Map<String, dynamic> json) {
    // Parse user request status from Django response
    final userRequestStatusData = json['user_request_status'] as Map<String, dynamic>?;
    
    final requestModel = RequestModel.fromJson(json);
    
    // Store the requester data in a global cache if needed
    if (json['requester'] != null) {
      final requester = UserModel.fromRequesterJson(json['requester']);
      RequestModelExtension._requesterCache[requestModel.requestId] = requester;
    }
    
    // Store user request status data
    if (userRequestStatusData != null) {
      RequestModelExtension._userRequestStatusCache[requestModel.requestId] = {
        'userRequestStatus': userRequestStatusData['request_status'],
        'canRequest': userRequestStatusData['can_request'] ?? false,
        'canCancelRequest': userRequestStatusData['can_cancel_request'] ?? false,
        'volunteerMessage': userRequestStatusData['message_content'],
      };
    }
    
    return requestModel;
  }
  
  // Static cache to store requester data
  static final Map<String, UserModel> _requesterCache = {};
  
  // Static cache to store user request status data
  static final Map<String, Map<String, dynamic>> _userRequestStatusCache = {};
  
  // Get requester for this request
  UserModel? get requester => _requesterCache[requestId];
  
  // Get user request status for this request
  String? get userRequestStatus => _userRequestStatusCache[requestId]?['userRequestStatus'];
  
  // Check if user can request to volunteer
  bool get canRequest => _userRequestStatusCache[requestId]?['canRequest'] ?? false;
  
  // Check if user can cancel their volunteer request
  bool get canCancelRequest => _userRequestStatusCache[requestId]?['canCancelRequest'] ?? false;
  
  // Get volunteer message for pending request
  String? get volunteerMessage => _userRequestStatusCache[requestId]?['volunteerMessage'];
}