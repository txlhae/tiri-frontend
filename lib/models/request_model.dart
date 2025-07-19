import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_model.dart';
import 'feedback_model.dart';

part 'request_model.freezed.dart';
part 'request_model.g.dart';

enum RequestStatus { pending, accepted, complete, incomplete, cancelled ,inprogress, expired}

@freezed
class RequestModel with _$RequestModel {
  @JsonSerializable(explicitToJson: true)
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
  @JsonKey(defaultValue: 1)required int numberOfPeople,
  @JsonKey(defaultValue: 1) required int hoursNeeded,
}) = _RequestModel;


  // Convert JSON to Model
  factory RequestModel.fromJson(Map<String, dynamic> json) =>
      _$RequestModelFromJson(json);
}
