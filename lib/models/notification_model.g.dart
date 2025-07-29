// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      notificationId: json['notificationId'] as String,
      status: json['status'] as String,
      body: json['body'] as String,
      isUserWaiting: json['isUserWaiting'] as bool,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'notificationId': instance.notificationId,
      'status': instance.status,
      'body': instance.body,
      'isUserWaiting': instance.isUserWaiting,
      'userId': instance.userId,
      'timestamp': instance.timestamp.toIso8601String(),
    };