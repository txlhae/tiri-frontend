import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_model.freezed.dart';
part 'feedback_model.g.dart';

@freezed
class FeedbackModel with _$FeedbackModel {
  @JsonSerializable(explicitToJson: true)
  const factory FeedbackModel({
    required String feedbackId,
    required String userId,
    required String requestId,
    required String review,
    required double rating,
    required int hours,
    required DateTime timestamp,
  }) = _FeedbackModel;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);
}
