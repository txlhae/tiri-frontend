// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'approval_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ApprovalRequest _$ApprovalRequestFromJson(Map<String, dynamic> json) {
  return _ApprovalRequest.fromJson(json);
}

/// @nodoc
mixin _$ApprovalRequest {
  String get id => throw _privateConstructorUsedError;
  String get newUserEmail => throw _privateConstructorUsedError;
  String get newUserName => throw _privateConstructorUsedError;
  String get newUserCountry => throw _privateConstructorUsedError;
  String? get newUserPhone => throw _privateConstructorUsedError;
  String get referralCodeUsed => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'approved', 'rejected', 'expired'
  DateTime get requestedAt => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  String? get newUserProfileImage => throw _privateConstructorUsedError;
  String? get rejectionReason => throw _privateConstructorUsedError;
  DateTime? get decidedAt => throw _privateConstructorUsedError;

  /// Serializes this ApprovalRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ApprovalRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ApprovalRequestCopyWith<ApprovalRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ApprovalRequestCopyWith<$Res> {
  factory $ApprovalRequestCopyWith(
          ApprovalRequest value, $Res Function(ApprovalRequest) then) =
      _$ApprovalRequestCopyWithImpl<$Res, ApprovalRequest>;
  @useResult
  $Res call(
      {String id,
      String newUserEmail,
      String newUserName,
      String newUserCountry,
      String? newUserPhone,
      String referralCodeUsed,
      String status,
      DateTime requestedAt,
      DateTime expiresAt,
      String? newUserProfileImage,
      String? rejectionReason,
      DateTime? decidedAt});
}

/// @nodoc
class _$ApprovalRequestCopyWithImpl<$Res, $Val extends ApprovalRequest>
    implements $ApprovalRequestCopyWith<$Res> {
  _$ApprovalRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ApprovalRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? newUserEmail = null,
    Object? newUserName = null,
    Object? newUserCountry = null,
    Object? newUserPhone = freezed,
    Object? referralCodeUsed = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? expiresAt = null,
    Object? newUserProfileImage = freezed,
    Object? rejectionReason = freezed,
    Object? decidedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      newUserEmail: null == newUserEmail
          ? _value.newUserEmail
          : newUserEmail // ignore: cast_nullable_to_non_nullable
              as String,
      newUserName: null == newUserName
          ? _value.newUserName
          : newUserName // ignore: cast_nullable_to_non_nullable
              as String,
      newUserCountry: null == newUserCountry
          ? _value.newUserCountry
          : newUserCountry // ignore: cast_nullable_to_non_nullable
              as String,
      newUserPhone: freezed == newUserPhone
          ? _value.newUserPhone
          : newUserPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      referralCodeUsed: null == referralCodeUsed
          ? _value.referralCodeUsed
          : referralCodeUsed // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      newUserProfileImage: freezed == newUserProfileImage
          ? _value.newUserProfileImage
          : newUserProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      decidedAt: freezed == decidedAt
          ? _value.decidedAt
          : decidedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ApprovalRequestImplCopyWith<$Res>
    implements $ApprovalRequestCopyWith<$Res> {
  factory _$$ApprovalRequestImplCopyWith(_$ApprovalRequestImpl value,
          $Res Function(_$ApprovalRequestImpl) then) =
      __$$ApprovalRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String newUserEmail,
      String newUserName,
      String newUserCountry,
      String? newUserPhone,
      String referralCodeUsed,
      String status,
      DateTime requestedAt,
      DateTime expiresAt,
      String? newUserProfileImage,
      String? rejectionReason,
      DateTime? decidedAt});
}

/// @nodoc
class __$$ApprovalRequestImplCopyWithImpl<$Res>
    extends _$ApprovalRequestCopyWithImpl<$Res, _$ApprovalRequestImpl>
    implements _$$ApprovalRequestImplCopyWith<$Res> {
  __$$ApprovalRequestImplCopyWithImpl(
      _$ApprovalRequestImpl _value, $Res Function(_$ApprovalRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of ApprovalRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? newUserEmail = null,
    Object? newUserName = null,
    Object? newUserCountry = null,
    Object? newUserPhone = freezed,
    Object? referralCodeUsed = null,
    Object? status = null,
    Object? requestedAt = null,
    Object? expiresAt = null,
    Object? newUserProfileImage = freezed,
    Object? rejectionReason = freezed,
    Object? decidedAt = freezed,
  }) {
    return _then(_$ApprovalRequestImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      newUserEmail: null == newUserEmail
          ? _value.newUserEmail
          : newUserEmail // ignore: cast_nullable_to_non_nullable
              as String,
      newUserName: null == newUserName
          ? _value.newUserName
          : newUserName // ignore: cast_nullable_to_non_nullable
              as String,
      newUserCountry: null == newUserCountry
          ? _value.newUserCountry
          : newUserCountry // ignore: cast_nullable_to_non_nullable
              as String,
      newUserPhone: freezed == newUserPhone
          ? _value.newUserPhone
          : newUserPhone // ignore: cast_nullable_to_non_nullable
              as String?,
      referralCodeUsed: null == referralCodeUsed
          ? _value.referralCodeUsed
          : referralCodeUsed // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      newUserProfileImage: freezed == newUserProfileImage
          ? _value.newUserProfileImage
          : newUserProfileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      rejectionReason: freezed == rejectionReason
          ? _value.rejectionReason
          : rejectionReason // ignore: cast_nullable_to_non_nullable
              as String?,
      decidedAt: freezed == decidedAt
          ? _value.decidedAt
          : decidedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ApprovalRequestImpl extends _ApprovalRequest {
  const _$ApprovalRequestImpl(
      {required this.id,
      required this.newUserEmail,
      required this.newUserName,
      required this.newUserCountry,
      this.newUserPhone,
      required this.referralCodeUsed,
      required this.status,
      required this.requestedAt,
      required this.expiresAt,
      this.newUserProfileImage,
      this.rejectionReason,
      this.decidedAt})
      : super._();

  factory _$ApprovalRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ApprovalRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String newUserEmail;
  @override
  final String newUserName;
  @override
  final String newUserCountry;
  @override
  final String? newUserPhone;
  @override
  final String referralCodeUsed;
  @override
  final String status;
// 'pending', 'approved', 'rejected', 'expired'
  @override
  final DateTime requestedAt;
  @override
  final DateTime expiresAt;
  @override
  final String? newUserProfileImage;
  @override
  final String? rejectionReason;
  @override
  final DateTime? decidedAt;

  @override
  String toString() {
    return 'ApprovalRequest(id: $id, newUserEmail: $newUserEmail, newUserName: $newUserName, newUserCountry: $newUserCountry, newUserPhone: $newUserPhone, referralCodeUsed: $referralCodeUsed, status: $status, requestedAt: $requestedAt, expiresAt: $expiresAt, newUserProfileImage: $newUserProfileImage, rejectionReason: $rejectionReason, decidedAt: $decidedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApprovalRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.newUserEmail, newUserEmail) ||
                other.newUserEmail == newUserEmail) &&
            (identical(other.newUserName, newUserName) ||
                other.newUserName == newUserName) &&
            (identical(other.newUserCountry, newUserCountry) ||
                other.newUserCountry == newUserCountry) &&
            (identical(other.newUserPhone, newUserPhone) ||
                other.newUserPhone == newUserPhone) &&
            (identical(other.referralCodeUsed, referralCodeUsed) ||
                other.referralCodeUsed == referralCodeUsed) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.newUserProfileImage, newUserProfileImage) ||
                other.newUserProfileImage == newUserProfileImage) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason) &&
            (identical(other.decidedAt, decidedAt) ||
                other.decidedAt == decidedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      newUserEmail,
      newUserName,
      newUserCountry,
      newUserPhone,
      referralCodeUsed,
      status,
      requestedAt,
      expiresAt,
      newUserProfileImage,
      rejectionReason,
      decidedAt);

  /// Create a copy of ApprovalRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApprovalRequestImplCopyWith<_$ApprovalRequestImpl> get copyWith =>
      __$$ApprovalRequestImplCopyWithImpl<_$ApprovalRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ApprovalRequestImplToJson(
      this,
    );
  }
}

abstract class _ApprovalRequest extends ApprovalRequest {
  const factory _ApprovalRequest(
      {required final String id,
      required final String newUserEmail,
      required final String newUserName,
      required final String newUserCountry,
      final String? newUserPhone,
      required final String referralCodeUsed,
      required final String status,
      required final DateTime requestedAt,
      required final DateTime expiresAt,
      final String? newUserProfileImage,
      final String? rejectionReason,
      final DateTime? decidedAt}) = _$ApprovalRequestImpl;
  const _ApprovalRequest._() : super._();

  factory _ApprovalRequest.fromJson(Map<String, dynamic> json) =
      _$ApprovalRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get newUserEmail;
  @override
  String get newUserName;
  @override
  String get newUserCountry;
  @override
  String? get newUserPhone;
  @override
  String get referralCodeUsed;
  @override
  String get status; // 'pending', 'approved', 'rejected', 'expired'
  @override
  DateTime get requestedAt;
  @override
  DateTime get expiresAt;
  @override
  String? get newUserProfileImage;
  @override
  String? get rejectionReason;
  @override
  DateTime? get decidedAt;

  /// Create a copy of ApprovalRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApprovalRequestImplCopyWith<_$ApprovalRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
