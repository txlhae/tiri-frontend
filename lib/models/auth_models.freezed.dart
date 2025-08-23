// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) {
  return _AuthTokens.fromJson(json);
}

/// @nodoc
mixin _$AuthTokens {
  String get refresh => throw _privateConstructorUsedError;
  String get access => throw _privateConstructorUsedError;

  /// Serializes this AuthTokens to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthTokensCopyWith<AuthTokens> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthTokensCopyWith<$Res> {
  factory $AuthTokensCopyWith(
          AuthTokens value, $Res Function(AuthTokens) then) =
      _$AuthTokensCopyWithImpl<$Res, AuthTokens>;
  @useResult
  $Res call({String refresh, String access});
}

/// @nodoc
class _$AuthTokensCopyWithImpl<$Res, $Val extends AuthTokens>
    implements $AuthTokensCopyWith<$Res> {
  _$AuthTokensCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refresh = null,
    Object? access = null,
  }) {
    return _then(_value.copyWith(
      refresh: null == refresh
          ? _value.refresh
          : refresh // ignore: cast_nullable_to_non_nullable
              as String,
      access: null == access
          ? _value.access
          : access // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthTokensImplCopyWith<$Res>
    implements $AuthTokensCopyWith<$Res> {
  factory _$$AuthTokensImplCopyWith(
          _$AuthTokensImpl value, $Res Function(_$AuthTokensImpl) then) =
      __$$AuthTokensImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String refresh, String access});
}

/// @nodoc
class __$$AuthTokensImplCopyWithImpl<$Res>
    extends _$AuthTokensCopyWithImpl<$Res, _$AuthTokensImpl>
    implements _$$AuthTokensImplCopyWith<$Res> {
  __$$AuthTokensImplCopyWithImpl(
      _$AuthTokensImpl _value, $Res Function(_$AuthTokensImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refresh = null,
    Object? access = null,
  }) {
    return _then(_$AuthTokensImpl(
      refresh: null == refresh
          ? _value.refresh
          : refresh // ignore: cast_nullable_to_non_nullable
              as String,
      access: null == access
          ? _value.access
          : access // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthTokensImpl implements _AuthTokens {
  const _$AuthTokensImpl({required this.refresh, required this.access});

  factory _$AuthTokensImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthTokensImplFromJson(json);

  @override
  final String refresh;
  @override
  final String access;

  @override
  String toString() {
    return 'AuthTokens(refresh: $refresh, access: $access)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthTokensImpl &&
            (identical(other.refresh, refresh) || other.refresh == refresh) &&
            (identical(other.access, access) || other.access == access));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, refresh, access);

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      __$$AuthTokensImplCopyWithImpl<_$AuthTokensImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthTokensImplToJson(
      this,
    );
  }
}

abstract class _AuthTokens implements AuthTokens {
  const factory _AuthTokens(
      {required final String refresh,
      required final String access}) = _$AuthTokensImpl;

  factory _AuthTokens.fromJson(Map<String, dynamic> json) =
      _$AuthTokensImpl.fromJson;

  @override
  String get refresh;
  @override
  String get access;

  /// Create a copy of AuthTokens
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthTokensImplCopyWith<_$AuthTokensImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegistrationStage _$RegistrationStageFromJson(Map<String, dynamic> json) {
  return _RegistrationStage.fromJson(json);
}

/// @nodoc
mixin _$RegistrationStage {
  String get status => throw _privateConstructorUsedError;
  bool get isEmailVerified => throw _privateConstructorUsedError;
  String? get emailVerifiedAt => throw _privateConstructorUsedError;
  bool get isApproved => throw _privateConstructorUsedError;
  bool get hasReferral => throw _privateConstructorUsedError;
  bool get canAccessApp => throw _privateConstructorUsedError;
  String? get approvalStatus => throw _privateConstructorUsedError;
  String? get referrerEmail => throw _privateConstructorUsedError;
  String? get approvalExpiresAt => throw _privateConstructorUsedError;
  String? get timeRemaining => throw _privateConstructorUsedError;
  String? get accountCreatedAt => throw _privateConstructorUsedError;

  /// Serializes this RegistrationStage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegistrationStage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegistrationStageCopyWith<RegistrationStage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegistrationStageCopyWith<$Res> {
  factory $RegistrationStageCopyWith(
          RegistrationStage value, $Res Function(RegistrationStage) then) =
      _$RegistrationStageCopyWithImpl<$Res, RegistrationStage>;
  @useResult
  $Res call(
      {String status,
      bool isEmailVerified,
      String? emailVerifiedAt,
      bool isApproved,
      bool hasReferral,
      bool canAccessApp,
      String? approvalStatus,
      String? referrerEmail,
      String? approvalExpiresAt,
      String? timeRemaining,
      String? accountCreatedAt});
}

/// @nodoc
class _$RegistrationStageCopyWithImpl<$Res, $Val extends RegistrationStage>
    implements $RegistrationStageCopyWith<$Res> {
  _$RegistrationStageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegistrationStage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isEmailVerified = null,
    Object? emailVerifiedAt = freezed,
    Object? isApproved = null,
    Object? hasReferral = null,
    Object? canAccessApp = null,
    Object? approvalStatus = freezed,
    Object? referrerEmail = freezed,
    Object? approvalExpiresAt = freezed,
    Object? timeRemaining = freezed,
    Object? accountCreatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      emailVerifiedAt: freezed == emailVerifiedAt
          ? _value.emailVerifiedAt
          : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isApproved: null == isApproved
          ? _value.isApproved
          : isApproved // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReferral: null == hasReferral
          ? _value.hasReferral
          : hasReferral // ignore: cast_nullable_to_non_nullable
              as bool,
      canAccessApp: null == canAccessApp
          ? _value.canAccessApp
          : canAccessApp // ignore: cast_nullable_to_non_nullable
              as bool,
      approvalStatus: freezed == approvalStatus
          ? _value.approvalStatus
          : approvalStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      referrerEmail: freezed == referrerEmail
          ? _value.referrerEmail
          : referrerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      approvalExpiresAt: freezed == approvalExpiresAt
          ? _value.approvalExpiresAt
          : approvalExpiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      timeRemaining: freezed == timeRemaining
          ? _value.timeRemaining
          : timeRemaining // ignore: cast_nullable_to_non_nullable
              as String?,
      accountCreatedAt: freezed == accountCreatedAt
          ? _value.accountCreatedAt
          : accountCreatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RegistrationStageImplCopyWith<$Res>
    implements $RegistrationStageCopyWith<$Res> {
  factory _$$RegistrationStageImplCopyWith(_$RegistrationStageImpl value,
          $Res Function(_$RegistrationStageImpl) then) =
      __$$RegistrationStageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String status,
      bool isEmailVerified,
      String? emailVerifiedAt,
      bool isApproved,
      bool hasReferral,
      bool canAccessApp,
      String? approvalStatus,
      String? referrerEmail,
      String? approvalExpiresAt,
      String? timeRemaining,
      String? accountCreatedAt});
}

/// @nodoc
class __$$RegistrationStageImplCopyWithImpl<$Res>
    extends _$RegistrationStageCopyWithImpl<$Res, _$RegistrationStageImpl>
    implements _$$RegistrationStageImplCopyWith<$Res> {
  __$$RegistrationStageImplCopyWithImpl(_$RegistrationStageImpl _value,
      $Res Function(_$RegistrationStageImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegistrationStage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isEmailVerified = null,
    Object? emailVerifiedAt = freezed,
    Object? isApproved = null,
    Object? hasReferral = null,
    Object? canAccessApp = null,
    Object? approvalStatus = freezed,
    Object? referrerEmail = freezed,
    Object? approvalExpiresAt = freezed,
    Object? timeRemaining = freezed,
    Object? accountCreatedAt = freezed,
  }) {
    return _then(_$RegistrationStageImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      isEmailVerified: null == isEmailVerified
          ? _value.isEmailVerified
          : isEmailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      emailVerifiedAt: freezed == emailVerifiedAt
          ? _value.emailVerifiedAt
          : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      isApproved: null == isApproved
          ? _value.isApproved
          : isApproved // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReferral: null == hasReferral
          ? _value.hasReferral
          : hasReferral // ignore: cast_nullable_to_non_nullable
              as bool,
      canAccessApp: null == canAccessApp
          ? _value.canAccessApp
          : canAccessApp // ignore: cast_nullable_to_non_nullable
              as bool,
      approvalStatus: freezed == approvalStatus
          ? _value.approvalStatus
          : approvalStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      referrerEmail: freezed == referrerEmail
          ? _value.referrerEmail
          : referrerEmail // ignore: cast_nullable_to_non_nullable
              as String?,
      approvalExpiresAt: freezed == approvalExpiresAt
          ? _value.approvalExpiresAt
          : approvalExpiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      timeRemaining: freezed == timeRemaining
          ? _value.timeRemaining
          : timeRemaining // ignore: cast_nullable_to_non_nullable
              as String?,
      accountCreatedAt: freezed == accountCreatedAt
          ? _value.accountCreatedAt
          : accountCreatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegistrationStageImpl implements _RegistrationStage {
  const _$RegistrationStageImpl(
      {required this.status,
      this.isEmailVerified = false,
      this.emailVerifiedAt,
      this.isApproved = false,
      this.hasReferral = false,
      this.canAccessApp = false,
      this.approvalStatus,
      this.referrerEmail,
      this.approvalExpiresAt,
      this.timeRemaining,
      this.accountCreatedAt});

  factory _$RegistrationStageImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegistrationStageImplFromJson(json);

  @override
  final String status;
  @override
  @JsonKey()
  final bool isEmailVerified;
  @override
  final String? emailVerifiedAt;
  @override
  @JsonKey()
  final bool isApproved;
  @override
  @JsonKey()
  final bool hasReferral;
  @override
  @JsonKey()
  final bool canAccessApp;
  @override
  final String? approvalStatus;
  @override
  final String? referrerEmail;
  @override
  final String? approvalExpiresAt;
  @override
  final String? timeRemaining;
  @override
  final String? accountCreatedAt;

  @override
  String toString() {
    return 'RegistrationStage(status: $status, isEmailVerified: $isEmailVerified, emailVerifiedAt: $emailVerifiedAt, isApproved: $isApproved, hasReferral: $hasReferral, canAccessApp: $canAccessApp, approvalStatus: $approvalStatus, referrerEmail: $referrerEmail, approvalExpiresAt: $approvalExpiresAt, timeRemaining: $timeRemaining, accountCreatedAt: $accountCreatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegistrationStageImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isEmailVerified, isEmailVerified) ||
                other.isEmailVerified == isEmailVerified) &&
            (identical(other.emailVerifiedAt, emailVerifiedAt) ||
                other.emailVerifiedAt == emailVerifiedAt) &&
            (identical(other.isApproved, isApproved) ||
                other.isApproved == isApproved) &&
            (identical(other.hasReferral, hasReferral) ||
                other.hasReferral == hasReferral) &&
            (identical(other.canAccessApp, canAccessApp) ||
                other.canAccessApp == canAccessApp) &&
            (identical(other.approvalStatus, approvalStatus) ||
                other.approvalStatus == approvalStatus) &&
            (identical(other.referrerEmail, referrerEmail) ||
                other.referrerEmail == referrerEmail) &&
            (identical(other.approvalExpiresAt, approvalExpiresAt) ||
                other.approvalExpiresAt == approvalExpiresAt) &&
            (identical(other.timeRemaining, timeRemaining) ||
                other.timeRemaining == timeRemaining) &&
            (identical(other.accountCreatedAt, accountCreatedAt) ||
                other.accountCreatedAt == accountCreatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      isEmailVerified,
      emailVerifiedAt,
      isApproved,
      hasReferral,
      canAccessApp,
      approvalStatus,
      referrerEmail,
      approvalExpiresAt,
      timeRemaining,
      accountCreatedAt);

  /// Create a copy of RegistrationStage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegistrationStageImplCopyWith<_$RegistrationStageImpl> get copyWith =>
      __$$RegistrationStageImplCopyWithImpl<_$RegistrationStageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegistrationStageImplToJson(
      this,
    );
  }
}

abstract class _RegistrationStage implements RegistrationStage {
  const factory _RegistrationStage(
      {required final String status,
      final bool isEmailVerified,
      final String? emailVerifiedAt,
      final bool isApproved,
      final bool hasReferral,
      final bool canAccessApp,
      final String? approvalStatus,
      final String? referrerEmail,
      final String? approvalExpiresAt,
      final String? timeRemaining,
      final String? accountCreatedAt}) = _$RegistrationStageImpl;

  factory _RegistrationStage.fromJson(Map<String, dynamic> json) =
      _$RegistrationStageImpl.fromJson;

  @override
  String get status;
  @override
  bool get isEmailVerified;
  @override
  String? get emailVerifiedAt;
  @override
  bool get isApproved;
  @override
  bool get hasReferral;
  @override
  bool get canAccessApp;
  @override
  String? get approvalStatus;
  @override
  String? get referrerEmail;
  @override
  String? get approvalExpiresAt;
  @override
  String? get timeRemaining;
  @override
  String? get accountCreatedAt;

  /// Create a copy of RegistrationStage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegistrationStageImplCopyWith<_$RegistrationStageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthWarning _$AuthWarningFromJson(Map<String, dynamic> json) {
  return _AuthWarning.fromJson(json);
}

/// @nodoc
mixin _$AuthWarning {
  String get message => throw _privateConstructorUsedError;
  String get deletionDate => throw _privateConstructorUsedError;
  String get actionRequired => throw _privateConstructorUsedError;

  /// Serializes this AuthWarning to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthWarning
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthWarningCopyWith<AuthWarning> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthWarningCopyWith<$Res> {
  factory $AuthWarningCopyWith(
          AuthWarning value, $Res Function(AuthWarning) then) =
      _$AuthWarningCopyWithImpl<$Res, AuthWarning>;
  @useResult
  $Res call({String message, String deletionDate, String actionRequired});
}

/// @nodoc
class _$AuthWarningCopyWithImpl<$Res, $Val extends AuthWarning>
    implements $AuthWarningCopyWith<$Res> {
  _$AuthWarningCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthWarning
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? deletionDate = null,
    Object? actionRequired = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      deletionDate: null == deletionDate
          ? _value.deletionDate
          : deletionDate // ignore: cast_nullable_to_non_nullable
              as String,
      actionRequired: null == actionRequired
          ? _value.actionRequired
          : actionRequired // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthWarningImplCopyWith<$Res>
    implements $AuthWarningCopyWith<$Res> {
  factory _$$AuthWarningImplCopyWith(
          _$AuthWarningImpl value, $Res Function(_$AuthWarningImpl) then) =
      __$$AuthWarningImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String deletionDate, String actionRequired});
}

/// @nodoc
class __$$AuthWarningImplCopyWithImpl<$Res>
    extends _$AuthWarningCopyWithImpl<$Res, _$AuthWarningImpl>
    implements _$$AuthWarningImplCopyWith<$Res> {
  __$$AuthWarningImplCopyWithImpl(
      _$AuthWarningImpl _value, $Res Function(_$AuthWarningImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthWarning
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? deletionDate = null,
    Object? actionRequired = null,
  }) {
    return _then(_$AuthWarningImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      deletionDate: null == deletionDate
          ? _value.deletionDate
          : deletionDate // ignore: cast_nullable_to_non_nullable
              as String,
      actionRequired: null == actionRequired
          ? _value.actionRequired
          : actionRequired // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthWarningImpl implements _AuthWarning {
  const _$AuthWarningImpl(
      {required this.message,
      required this.deletionDate,
      required this.actionRequired});

  factory _$AuthWarningImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthWarningImplFromJson(json);

  @override
  final String message;
  @override
  final String deletionDate;
  @override
  final String actionRequired;

  @override
  String toString() {
    return 'AuthWarning(message: $message, deletionDate: $deletionDate, actionRequired: $actionRequired)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthWarningImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.deletionDate, deletionDate) ||
                other.deletionDate == deletionDate) &&
            (identical(other.actionRequired, actionRequired) ||
                other.actionRequired == actionRequired));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, message, deletionDate, actionRequired);

  /// Create a copy of AuthWarning
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthWarningImplCopyWith<_$AuthWarningImpl> get copyWith =>
      __$$AuthWarningImplCopyWithImpl<_$AuthWarningImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthWarningImplToJson(
      this,
    );
  }
}

abstract class _AuthWarning implements AuthWarning {
  const factory _AuthWarning(
      {required final String message,
      required final String deletionDate,
      required final String actionRequired}) = _$AuthWarningImpl;

  factory _AuthWarning.fromJson(Map<String, dynamic> json) =
      _$AuthWarningImpl.fromJson;

  @override
  String get message;
  @override
  String get deletionDate;
  @override
  String get actionRequired;

  /// Create a copy of AuthWarning
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthWarningImplCopyWith<_$AuthWarningImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) {
  return _AuthResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthResponse {
  UserModel get user => throw _privateConstructorUsedError;
  AuthTokens get tokens => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get accountStatus => throw _privateConstructorUsedError;
  String get nextStep => throw _privateConstructorUsedError;
  RegistrationStage? get registrationStage =>
      throw _privateConstructorUsedError;
  AuthWarning? get warning => throw _privateConstructorUsedError;

  /// Serializes this AuthResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
          AuthResponse value, $Res Function(AuthResponse) then) =
      _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call(
      {UserModel user,
      AuthTokens tokens,
      String message,
      String accountStatus,
      String nextStep,
      RegistrationStage? registrationStage,
      AuthWarning? warning});

  $UserModelCopyWith<$Res> get user;
  $AuthTokensCopyWith<$Res> get tokens;
  $RegistrationStageCopyWith<$Res>? get registrationStage;
  $AuthWarningCopyWith<$Res>? get warning;
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? tokens = null,
    Object? message = null,
    Object? accountStatus = null,
    Object? nextStep = null,
    Object? registrationStage = freezed,
    Object? warning = freezed,
  }) {
    return _then(_value.copyWith(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserModel,
      tokens: null == tokens
          ? _value.tokens
          : tokens // ignore: cast_nullable_to_non_nullable
              as AuthTokens,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      accountStatus: null == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String,
      nextStep: null == nextStep
          ? _value.nextStep
          : nextStep // ignore: cast_nullable_to_non_nullable
              as String,
      registrationStage: freezed == registrationStage
          ? _value.registrationStage
          : registrationStage // ignore: cast_nullable_to_non_nullable
              as RegistrationStage?,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as AuthWarning?,
    ) as $Val);
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserModelCopyWith<$Res> get user {
    return $UserModelCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthTokensCopyWith<$Res> get tokens {
    return $AuthTokensCopyWith<$Res>(_value.tokens, (value) {
      return _then(_value.copyWith(tokens: value) as $Val);
    });
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegistrationStageCopyWith<$Res>? get registrationStage {
    if (_value.registrationStage == null) {
      return null;
    }

    return $RegistrationStageCopyWith<$Res>(_value.registrationStage!, (value) {
      return _then(_value.copyWith(registrationStage: value) as $Val);
    });
  }

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthWarningCopyWith<$Res>? get warning {
    if (_value.warning == null) {
      return null;
    }

    return $AuthWarningCopyWith<$Res>(_value.warning!, (value) {
      return _then(_value.copyWith(warning: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
          _$AuthResponseImpl value, $Res Function(_$AuthResponseImpl) then) =
      __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {UserModel user,
      AuthTokens tokens,
      String message,
      String accountStatus,
      String nextStep,
      RegistrationStage? registrationStage,
      AuthWarning? warning});

  @override
  $UserModelCopyWith<$Res> get user;
  @override
  $AuthTokensCopyWith<$Res> get tokens;
  @override
  $RegistrationStageCopyWith<$Res>? get registrationStage;
  @override
  $AuthWarningCopyWith<$Res>? get warning;
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
      _$AuthResponseImpl _value, $Res Function(_$AuthResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? tokens = null,
    Object? message = null,
    Object? accountStatus = null,
    Object? nextStep = null,
    Object? registrationStage = freezed,
    Object? warning = freezed,
  }) {
    return _then(_$AuthResponseImpl(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UserModel,
      tokens: null == tokens
          ? _value.tokens
          : tokens // ignore: cast_nullable_to_non_nullable
              as AuthTokens,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      accountStatus: null == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String,
      nextStep: null == nextStep
          ? _value.nextStep
          : nextStep // ignore: cast_nullable_to_non_nullable
              as String,
      registrationStage: freezed == registrationStage
          ? _value.registrationStage
          : registrationStage // ignore: cast_nullable_to_non_nullable
              as RegistrationStage?,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as AuthWarning?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl(
      {required this.user,
      required this.tokens,
      required this.message,
      required this.accountStatus,
      required this.nextStep,
      this.registrationStage,
      this.warning});

  factory _$AuthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseImplFromJson(json);

  @override
  final UserModel user;
  @override
  final AuthTokens tokens;
  @override
  final String message;
  @override
  final String accountStatus;
  @override
  final String nextStep;
  @override
  final RegistrationStage? registrationStage;
  @override
  final AuthWarning? warning;

  @override
  String toString() {
    return 'AuthResponse(user: $user, tokens: $tokens, message: $message, accountStatus: $accountStatus, nextStep: $nextStep, registrationStage: $registrationStage, warning: $warning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.tokens, tokens) || other.tokens == tokens) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.accountStatus, accountStatus) ||
                other.accountStatus == accountStatus) &&
            (identical(other.nextStep, nextStep) ||
                other.nextStep == nextStep) &&
            (identical(other.registrationStage, registrationStage) ||
                other.registrationStage == registrationStage) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, user, tokens, message,
      accountStatus, nextStep, registrationStage, warning);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseImplToJson(
      this,
    );
  }
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse(
      {required final UserModel user,
      required final AuthTokens tokens,
      required final String message,
      required final String accountStatus,
      required final String nextStep,
      final RegistrationStage? registrationStage,
      final AuthWarning? warning}) = _$AuthResponseImpl;

  factory _AuthResponse.fromJson(Map<String, dynamic> json) =
      _$AuthResponseImpl.fromJson;

  @override
  UserModel get user;
  @override
  AuthTokens get tokens;
  @override
  String get message;
  @override
  String get accountStatus;
  @override
  String get nextStep;
  @override
  RegistrationStage? get registrationStage;
  @override
  AuthWarning? get warning;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RegistrationStatusResponse _$RegistrationStatusResponseFromJson(
    Map<String, dynamic> json) {
  return _RegistrationStatusResponse.fromJson(json);
}

/// @nodoc
mixin _$RegistrationStatusResponse {
  String get userId => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get accountStatus => throw _privateConstructorUsedError;
  RegistrationStage get registrationStage => throw _privateConstructorUsedError;
  String get nextStep => throw _privateConstructorUsedError;
  AuthWarning? get warning => throw _privateConstructorUsedError;

  /// Serializes this RegistrationStatusResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegistrationStatusResponseCopyWith<RegistrationStatusResponse>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegistrationStatusResponseCopyWith<$Res> {
  factory $RegistrationStatusResponseCopyWith(RegistrationStatusResponse value,
          $Res Function(RegistrationStatusResponse) then) =
      _$RegistrationStatusResponseCopyWithImpl<$Res,
          RegistrationStatusResponse>;
  @useResult
  $Res call(
      {String userId,
      String email,
      String accountStatus,
      RegistrationStage registrationStage,
      String nextStep,
      AuthWarning? warning});

  $RegistrationStageCopyWith<$Res> get registrationStage;
  $AuthWarningCopyWith<$Res>? get warning;
}

/// @nodoc
class _$RegistrationStatusResponseCopyWithImpl<$Res,
        $Val extends RegistrationStatusResponse>
    implements $RegistrationStatusResponseCopyWith<$Res> {
  _$RegistrationStatusResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? accountStatus = null,
    Object? registrationStage = null,
    Object? nextStep = null,
    Object? warning = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      accountStatus: null == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String,
      registrationStage: null == registrationStage
          ? _value.registrationStage
          : registrationStage // ignore: cast_nullable_to_non_nullable
              as RegistrationStage,
      nextStep: null == nextStep
          ? _value.nextStep
          : nextStep // ignore: cast_nullable_to_non_nullable
              as String,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as AuthWarning?,
    ) as $Val);
  }

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RegistrationStageCopyWith<$Res> get registrationStage {
    return $RegistrationStageCopyWith<$Res>(_value.registrationStage, (value) {
      return _then(_value.copyWith(registrationStage: value) as $Val);
    });
  }

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthWarningCopyWith<$Res>? get warning {
    if (_value.warning == null) {
      return null;
    }

    return $AuthWarningCopyWith<$Res>(_value.warning!, (value) {
      return _then(_value.copyWith(warning: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RegistrationStatusResponseImplCopyWith<$Res>
    implements $RegistrationStatusResponseCopyWith<$Res> {
  factory _$$RegistrationStatusResponseImplCopyWith(
          _$RegistrationStatusResponseImpl value,
          $Res Function(_$RegistrationStatusResponseImpl) then) =
      __$$RegistrationStatusResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String email,
      String accountStatus,
      RegistrationStage registrationStage,
      String nextStep,
      AuthWarning? warning});

  @override
  $RegistrationStageCopyWith<$Res> get registrationStage;
  @override
  $AuthWarningCopyWith<$Res>? get warning;
}

/// @nodoc
class __$$RegistrationStatusResponseImplCopyWithImpl<$Res>
    extends _$RegistrationStatusResponseCopyWithImpl<$Res,
        _$RegistrationStatusResponseImpl>
    implements _$$RegistrationStatusResponseImplCopyWith<$Res> {
  __$$RegistrationStatusResponseImplCopyWithImpl(
      _$RegistrationStatusResponseImpl _value,
      $Res Function(_$RegistrationStatusResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? email = null,
    Object? accountStatus = null,
    Object? registrationStage = null,
    Object? nextStep = null,
    Object? warning = freezed,
  }) {
    return _then(_$RegistrationStatusResponseImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      accountStatus: null == accountStatus
          ? _value.accountStatus
          : accountStatus // ignore: cast_nullable_to_non_nullable
              as String,
      registrationStage: null == registrationStage
          ? _value.registrationStage
          : registrationStage // ignore: cast_nullable_to_non_nullable
              as RegistrationStage,
      nextStep: null == nextStep
          ? _value.nextStep
          : nextStep // ignore: cast_nullable_to_non_nullable
              as String,
      warning: freezed == warning
          ? _value.warning
          : warning // ignore: cast_nullable_to_non_nullable
              as AuthWarning?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RegistrationStatusResponseImpl implements _RegistrationStatusResponse {
  const _$RegistrationStatusResponseImpl(
      {required this.userId,
      required this.email,
      required this.accountStatus,
      required this.registrationStage,
      required this.nextStep,
      this.warning});

  factory _$RegistrationStatusResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$RegistrationStatusResponseImplFromJson(json);

  @override
  final String userId;
  @override
  final String email;
  @override
  final String accountStatus;
  @override
  final RegistrationStage registrationStage;
  @override
  final String nextStep;
  @override
  final AuthWarning? warning;

  @override
  String toString() {
    return 'RegistrationStatusResponse(userId: $userId, email: $email, accountStatus: $accountStatus, registrationStage: $registrationStage, nextStep: $nextStep, warning: $warning)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegistrationStatusResponseImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.accountStatus, accountStatus) ||
                other.accountStatus == accountStatus) &&
            (identical(other.registrationStage, registrationStage) ||
                other.registrationStage == registrationStage) &&
            (identical(other.nextStep, nextStep) ||
                other.nextStep == nextStep) &&
            (identical(other.warning, warning) || other.warning == warning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, email, accountStatus,
      registrationStage, nextStep, warning);

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegistrationStatusResponseImplCopyWith<_$RegistrationStatusResponseImpl>
      get copyWith => __$$RegistrationStatusResponseImplCopyWithImpl<
          _$RegistrationStatusResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RegistrationStatusResponseImplToJson(
      this,
    );
  }
}

abstract class _RegistrationStatusResponse
    implements RegistrationStatusResponse {
  const factory _RegistrationStatusResponse(
      {required final String userId,
      required final String email,
      required final String accountStatus,
      required final RegistrationStage registrationStage,
      required final String nextStep,
      final AuthWarning? warning}) = _$RegistrationStatusResponseImpl;

  factory _RegistrationStatusResponse.fromJson(Map<String, dynamic> json) =
      _$RegistrationStatusResponseImpl.fromJson;

  @override
  String get userId;
  @override
  String get email;
  @override
  String get accountStatus;
  @override
  RegistrationStage get registrationStage;
  @override
  String get nextStep;
  @override
  AuthWarning? get warning;

  /// Create a copy of RegistrationStatusResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegistrationStatusResponseImplCopyWith<_$RegistrationStatusResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
