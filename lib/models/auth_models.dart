import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tiri/models/user_model.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    required String refresh,
    required String access,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}

@freezed
class RegistrationStage with _$RegistrationStage {
  const factory RegistrationStage({
    required String status,
    @Default(false) bool isEmailVerified,
    String? emailVerifiedAt,
    @Default(false) bool isApproved,
    @Default(false) bool hasReferral,
    @Default(false) bool canAccessApp,
    String? approvalStatus,
    String? referrerEmail,
    String? approvalExpiresAt,
    String? timeRemaining,
    String? accountCreatedAt,
  }) = _RegistrationStage;

  factory RegistrationStage.fromJson(Map<String, dynamic> json) =>
      _$RegistrationStageFromJson(json);
}

@freezed
class AuthWarning with _$AuthWarning {
  const factory AuthWarning({
    required String message,
    required String deletionDate,
    required String actionRequired,
  }) = _AuthWarning;

  factory AuthWarning.fromJson(Map<String, dynamic> json) =>
      _$AuthWarningFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required UserModel user,
    required AuthTokens tokens,
    required String message,
    required String accountStatus,
    required String nextStep,
    RegistrationStage? registrationStage,
    AuthWarning? warning,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class RegistrationStatusResponse with _$RegistrationStatusResponse {
  const factory RegistrationStatusResponse({
    required String userId,
    required String email,
    required String accountStatus,
    required RegistrationStage registrationStage,
    required String nextStep,
    AuthWarning? warning,
  }) = _RegistrationStatusResponse;

  factory RegistrationStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$RegistrationStatusResponseFromJson(json);
}

enum AccountStatus {
  @JsonValue('email_pending')
  emailPending,
  @JsonValue('email_verified')
  emailVerified,
  @JsonValue('approval_pending')
  approvalPending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('active')
  active,
}

enum NextStep {
  @JsonValue('verify_email')
  verifyEmail,
  @JsonValue('waiting_for_approval')
  waitingForApproval,
  @JsonValue('approval_rejected')
  approvalRejected,
  @JsonValue('complete_profile')
  completeProfile,
  @JsonValue('ready')
  ready,
}