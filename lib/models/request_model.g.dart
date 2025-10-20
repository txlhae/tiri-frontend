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
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: _dateTimeFromJson(json['timestamp'] as String),
      requestedTime:
          _nullableDateTimeFromJson(json['requestedTime'] as String?),
      status: $enumDecode(_$RequestStatusEnumMap, json['status']),
      acceptedUser: json['acceptedUser'] == null
          ? const []
          : _acceptedUserFromJson(json['acceptedUser']),
      numberOfPeople: (json['numberOfPeople'] as num?)?.toInt() ?? 1,
      hoursNeeded: (json['hoursNeeded'] as num?)?.toInt() ?? 1,
      category: _categoryFromJson(json['category']),
    );

Map<String, dynamic> _$$RequestModelImplToJson(_$RequestModelImpl instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'requestedTime': instance.requestedTime?.toIso8601String(),
      'status': _$RequestStatusEnumMap[instance.status]!,
      'acceptedUser': instance.acceptedUser,
      'numberOfPeople': instance.numberOfPeople,
      'hoursNeeded': instance.hoursNeeded,
      'category': instance.category,
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
