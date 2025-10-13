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
      timestamp: _dateTimeFromJson(json['timestamp'] as String),
      requestedTime:
          _nullableDateTimeFromJson(json['requestedTime'] as String?),
      status: $enumDecode(_$RequestStatusEnumMap, json['status']),
      acceptedUser: json['acceptedUser'] == null
          ? const []
          : _acceptedUserFromJson(json['acceptedUser']),
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
  RequestStatus.delayed: 'delayed',
};
