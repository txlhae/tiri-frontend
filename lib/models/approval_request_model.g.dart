// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ApprovalRequestImpl _$$ApprovalRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$ApprovalRequestImpl(
      id: json['id'] as String,
      newUserEmail: json['newUserEmail'] as String,
      newUserName: json['newUserName'] as String,
      newUserCountry: json['newUserCountry'] as String,
      newUserPhone: json['newUserPhone'] as String?,
      referralCodeUsed: json['referralCodeUsed'] as String,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      newUserProfileImage: json['newUserProfileImage'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      decidedAt: json['decidedAt'] == null
          ? null
          : DateTime.parse(json['decidedAt'] as String),
    );

Map<String, dynamic> _$$ApprovalRequestImplToJson(
        _$ApprovalRequestImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'newUserEmail': instance.newUserEmail,
      'newUserName': instance.newUserName,
      'newUserCountry': instance.newUserCountry,
      'newUserPhone': instance.newUserPhone,
      'referralCodeUsed': instance.referralCodeUsed,
      'status': instance.status,
      'requestedAt': instance.requestedAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'newUserProfileImage': instance.newUserProfileImage,
      'rejectionReason': instance.rejectionReason,
      'decidedAt': instance.decidedAt?.toIso8601String(),
    };
