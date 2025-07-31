// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RequestModelImpl _$$RequestModelImplFromJson(Map<String, dynamic> json) =>
    _$RequestModelImpl(
      requestId: json['requestId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      requestedTime: json['requestedTime'] == null
          ? null
          : DateTime.parse(json['requestedTime'] as String),
      status: $enumDecode(_$RequestStatusEnumMap, json['status']),
      acceptedUser: (json['acceptedUser'] as List<dynamic>?)
              ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      feedbackList: (json['feedbackList'] as List<dynamic>?)
          ?.map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      numberOfPeople: (json['numberOfPeople'] as num?)?.toInt() ?? 1,
      hoursNeeded: (json['hoursNeeded'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$$RequestModelImplToJson(_$RequestModelImpl instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'timestamp': instance.timestamp.toIso8601String(),
      'requestedTime': instance.requestedTime?.toIso8601String(),
      'status': _$RequestStatusEnumMap[instance.status]!,
      'acceptedUser': instance.acceptedUser,
      'feedbackList': instance.feedbackList,
      'numberOfPeople': instance.numberOfPeople,
      'hoursNeeded': instance.hoursNeeded,
    };

const _$RequestStatusEnumMap = {
  RequestStatus.pending: 'pending',
  RequestStatus.accepted: 'accepted',
  RequestStatus.complete: 'complete',
  RequestStatus.incomplete: 'incomplete',
  RequestStatus.cancelled: 'cancelled',
  RequestStatus.inprogress: 'inprogress',
  RequestStatus.expired: 'expired',
};
