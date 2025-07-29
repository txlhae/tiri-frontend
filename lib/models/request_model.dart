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
    final requestModel = RequestModel.fromJson(json);
    // Store the requester data in a global cache if needed
    if (json['requester'] != null) {
      final requester = UserModel.fromRequesterJson(json['requester']);
      RequestModelExtension._requesterCache[requestModel.requestId] = requester;
    }
    return requestModel;
  }
  
  // Static cache to store requester data
  static final Map<String, UserModel> _requesterCache = {};
  
  // Get requester for this request
  UserModel? get requester => _requesterCache[requestId];
}