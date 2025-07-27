// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    _FeedbackModel(
      feedbackId: json['feedbackId'] as String,
      userId: json['userId'] as String,
      requestId: json['requestId'] as String,
      review: json['review'] as String,
      rating: (json['rating'] as num).toDouble(),
      hours: (json['hours'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FeedbackModelToJson(_FeedbackModel instance) =>
    <String, dynamic>{
      'feedbackId': instance.feedbackId,
      'userId': instance.userId,
      'requestId': instance.requestId,
      'review': instance.review,
      'rating': instance.rating,
      'hours': instance.hours,
      'timestamp': instance.timestamp.toIso8601String(),
    };
