// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuthTokensImpl _$$AuthTokensImplFromJson(Map<String, dynamic> json) =>
    _$AuthTokensImpl(
      refresh: json['refresh'] as String,
      access: json['access'] as String,
    );

Map<String, dynamic> _$$AuthTokensImplToJson(_$AuthTokensImpl instance) =>
    <String, dynamic>{
      'refresh': instance.refresh,
      'access': instance.access,
    };

_$RegistrationStageImpl _$$RegistrationStageImplFromJson(
        Map<String, dynamic> json) =>
    _$RegistrationStageImpl(
      status: json['status'] as String,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      isApproved: json['isApproved'] as bool? ?? false,
      hasReferral: json['hasReferral'] as bool? ?? false,
      canAccessApp: json['canAccessApp'] as bool? ?? false,
      approvalStatus: json['approvalStatus'] as String?,
      referrerEmail: json['referrerEmail'] as String?,
      approvalExpiresAt: json['approvalExpiresAt'] as String?,
      timeRemaining: json['timeRemaining'] as String?,
      accountCreatedAt: json['accountCreatedAt'] as String?,
    );

Map<String, dynamic> _$$RegistrationStageImplToJson(
        _$RegistrationStageImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'isEmailVerified': instance.isEmailVerified,
      'emailVerifiedAt': instance.emailVerifiedAt,
      'isApproved': instance.isApproved,
      'hasReferral': instance.hasReferral,
      'canAccessApp': instance.canAccessApp,
      'approvalStatus': instance.approvalStatus,
      'referrerEmail': instance.referrerEmail,
      'approvalExpiresAt': instance.approvalExpiresAt,
      'timeRemaining': instance.timeRemaining,
      'accountCreatedAt': instance.accountCreatedAt,
    };

_$AuthWarningImpl _$$AuthWarningImplFromJson(Map<String, dynamic> json) =>
    _$AuthWarningImpl(
      message: json['message'] as String,
      deletionDate: json['deletionDate'] as String,
      actionRequired: json['actionRequired'] as String,
    );

Map<String, dynamic> _$$AuthWarningImplToJson(_$AuthWarningImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'deletionDate': instance.deletionDate,
      'actionRequired': instance.actionRequired,
    };

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      message: json['message'] as String,
      accountStatus: json['accountStatus'] as String,
      nextStep: json['nextStep'] as String,
      registrationStage: json['registrationStage'] == null
          ? null
          : RegistrationStage.fromJson(
              json['registrationStage'] as Map<String, dynamic>),
      warning: json['warning'] == null
          ? null
          : AuthWarning.fromJson(json['warning'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'user': instance.user,
      'tokens': instance.tokens,
      'message': instance.message,
      'accountStatus': instance.accountStatus,
      'nextStep': instance.nextStep,
      'registrationStage': instance.registrationStage,
      'warning': instance.warning,
    };

_$RegistrationStatusResponseImpl _$$RegistrationStatusResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$RegistrationStatusResponseImpl(
      userId: json['userId'] as String,
      email: json['email'] as String,
      accountStatus: json['accountStatus'] as String,
      registrationStage: RegistrationStage.fromJson(
          json['registrationStage'] as Map<String, dynamic>),
      nextStep: json['nextStep'] as String,
      warning: json['warning'] == null
          ? null
          : AuthWarning.fromJson(json['warning'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$RegistrationStatusResponseImplToJson(
        _$RegistrationStatusResponseImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'email': instance.email,
      'accountStatus': instance.accountStatus,
      'registrationStage': instance.registrationStage,
      'nextStep': instance.nextStep,
      'warning': instance.warning,
    };
