// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RequestModel _$RequestModelFromJson(Map<String, dynamic> json) {
  return _RequestModel.fromJson(json);
}

/// @nodoc
mixin _$RequestModel {
  String get requestId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  DateTime get requestedTime => throw _privateConstructorUsedError;
  RequestStatus get status => throw _privateConstructorUsedError;
  List<UserModel> get acceptedUser => throw _privateConstructorUsedError;
  List<FeedbackModel>? get feedbackList => throw _privateConstructorUsedError;
  @JsonKey(defaultValue: 1)
  int get numberOfPeople => throw _privateConstructorUsedError;
  @JsonKey(defaultValue: 1)
  int get hoursNeeded => throw _privateConstructorUsedError;

  /// Serializes this RequestModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RequestModelCopyWith<RequestModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RequestModelCopyWith<$Res> {
  factory $RequestModelCopyWith(
          RequestModel value, $Res Function(RequestModel) then) =
      _$RequestModelCopyWithImpl<$Res, RequestModel>;
  @useResult
  $Res call(
      {String requestId,
      String userId,
      String title,
      String description,
      String location,
      DateTime timestamp,
      DateTime requestedTime,
      RequestStatus status,
      List<UserModel> acceptedUser,
      List<FeedbackModel>? feedbackList,
      @JsonKey(defaultValue: 1) int numberOfPeople,
      @JsonKey(defaultValue: 1) int hoursNeeded});
}

/// @nodoc
class _$RequestModelCopyWithImpl<$Res, $Val extends RequestModel>
    implements $RequestModelCopyWith<$Res> {
  _$RequestModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? location = null,
    Object? timestamp = null,
    Object? requestedTime = null,
    Object? status = null,
    Object? acceptedUser = null,
    Object? feedbackList = freezed,
    Object? numberOfPeople = null,
    Object? hoursNeeded = null,
  }) {
    return _then(_value.copyWith(
      requestId: null == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requestedTime: null == requestedTime
          ? _value.requestedTime
          : requestedTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RequestStatus,
      acceptedUser: null == acceptedUser
          ? _value.acceptedUser
          : acceptedUser // ignore: cast_nullable_to_non_nullable
              as List<UserModel>,
      feedbackList: freezed == feedbackList
          ? _value.feedbackList
          : feedbackList // ignore: cast_nullable_to_non_nullable
              as List<FeedbackModel>?,
      numberOfPeople: null == numberOfPeople
          ? _value.numberOfPeople
          : numberOfPeople // ignore: cast_nullable_to_non_nullable
              as int,
      hoursNeeded: null == hoursNeeded
          ? _value.hoursNeeded
          : hoursNeeded // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RequestModelImplCopyWith<$Res>
    implements $RequestModelCopyWith<$Res> {
  factory _$$RequestModelImplCopyWith(
          _$RequestModelImpl value, $Res Function(_$RequestModelImpl) then) =
      __$$RequestModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String requestId,
      String userId,
      String title,
      String description,
      String location,
      DateTime timestamp,
      DateTime requestedTime,
      RequestStatus status,
      List<UserModel> acceptedUser,
      List<FeedbackModel>? feedbackList,
      @JsonKey(defaultValue: 1) int numberOfPeople,
      @JsonKey(defaultValue: 1) int hoursNeeded});
}

/// @nodoc
class __$$RequestModelImplCopyWithImpl<$Res>
    extends _$RequestModelCopyWithImpl<$Res, _$RequestModelImpl>
    implements _$$RequestModelImplCopyWith<$Res> {
  __$$RequestModelImplCopyWithImpl(
      _$RequestModelImpl _value, $Res Function(_$RequestModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of RequestModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requestId = null,
    Object? userId = null,
    Object? title = null,
    Object? description = null,
    Object? location = null,
    Object? timestamp = null,
    Object? requestedTime = null,
    Object? status = null,
    Object? acceptedUser = null,
    Object? feedbackList = freezed,
    Object? numberOfPeople = null,
    Object? hoursNeeded = null,
  }) {
    return _then(_$RequestModelImpl(
      requestId: null == requestId
          ? _value.requestId
          : requestId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      requestedTime: null == requestedTime
          ? _value.requestedTime
          : requestedTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as RequestStatus,
      acceptedUser: null == acceptedUser
          ? _value._acceptedUser
          : acceptedUser // ignore: cast_nullable_to_non_nullable
              as List<UserModel>,
      feedbackList: freezed == feedbackList
          ? _value._feedbackList
          : feedbackList // ignore: cast_nullable_to_non_nullable
              as List<FeedbackModel>?,
      numberOfPeople: null == numberOfPeople
          ? _value.numberOfPeople
          : numberOfPeople // ignore: cast_nullable_to_non_nullable
              as int,
      hoursNeeded: null == hoursNeeded
          ? _value.hoursNeeded
          : hoursNeeded // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$RequestModelImpl implements _RequestModel {
  const _$RequestModelImpl(
      {required this.requestId,
      required this.userId,
      required this.title,
      required this.description,
      required this.location,
      required this.timestamp,
      required this.requestedTime,
      required this.status,
      final List<UserModel> acceptedUser = const [],
      final List<FeedbackModel>? feedbackList,
      @JsonKey(defaultValue: 1) required this.numberOfPeople,
      @JsonKey(defaultValue: 1) required this.hoursNeeded})
      : _acceptedUser = acceptedUser,
        _feedbackList = feedbackList;

  factory _$RequestModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RequestModelImplFromJson(json);

  @override
  final String requestId;
  @override
  final String userId;
  @override
  final String title;
  @override
  final String description;
  @override
  final String location;
  @override
  final DateTime timestamp;
  @override
  final DateTime requestedTime;
  @override
  final RequestStatus status;
  final List<UserModel> _acceptedUser;
  @override
  @JsonKey()
  List<UserModel> get acceptedUser {
    if (_acceptedUser is EqualUnmodifiableListView) return _acceptedUser;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_acceptedUser);
  }

  final List<FeedbackModel>? _feedbackList;
  @override
  List<FeedbackModel>? get feedbackList {
    final value = _feedbackList;
    if (value == null) return null;
    if (_feedbackList is EqualUnmodifiableListView) return _feedbackList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(defaultValue: 1)
  final int numberOfPeople;
  @override
  @JsonKey(defaultValue: 1)
  final int hoursNeeded;

  @override
  String toString() {
    return 'RequestModel(requestId: $requestId, userId: $userId, title: $title, description: $description, location: $location, timestamp: $timestamp, requestedTime: $requestedTime, status: $status, acceptedUser: $acceptedUser, feedbackList: $feedbackList, numberOfPeople: $numberOfPeople, hoursNeeded: $hoursNeeded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RequestModelImpl &&
            (identical(other.requestId, requestId) ||
                other.requestId == requestId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.requestedTime, requestedTime) ||
                other.requestedTime == requestedTime) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._acceptedUser, _acceptedUser) &&
            const DeepCollectionEquality()
                .equals(other._feedbackList, _feedbackList) &&
            (identical(other.numberOfPeople, numberOfPeople) ||
                other.numberOfPeople == numberOfPeople) &&
            (identical(other.hoursNeeded, hoursNeeded) ||
                other.hoursNeeded == hoursNeeded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      requestId,
      userId,
      title,
      description,
      location,
      timestamp,
      requestedTime,
      status,
      const DeepCollectionEquality().hash(_acceptedUser),
      const DeepCollectionEquality().hash(_feedbackList),
      numberOfPeople,
      hoursNeeded);

  /// Create a copy of RequestModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RequestModelImplCopyWith<_$RequestModelImpl> get copyWith =>
      __$$RequestModelImplCopyWithImpl<_$RequestModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RequestModelImplToJson(
      this,
    );
  }
}

abstract class _RequestModel implements RequestModel {
  const factory _RequestModel(
          {required final String requestId,
          required final String userId,
          required final String title,
          required final String description,
          required final String location,
          required final DateTime timestamp,
          required final DateTime requestedTime,
          required final RequestStatus status,
          final List<UserModel> acceptedUser,
          final List<FeedbackModel>? feedbackList,
          @JsonKey(defaultValue: 1) required final int numberOfPeople,
          @JsonKey(defaultValue: 1) required final int hoursNeeded}) =
      _$RequestModelImpl;

  factory _RequestModel.fromJson(Map<String, dynamic> json) =
      _$RequestModelImpl.fromJson;

  @override
  String get requestId;
  @override
  String get userId;
  @override
  String get title;
  @override
  String get description;
  @override
  String get location;
  @override
  DateTime get timestamp;
  @override
  DateTime get requestedTime;
  @override
  RequestStatus get status;
  @override
  List<UserModel> get acceptedUser;
  @override
  List<FeedbackModel>? get feedbackList;
  @override
  @JsonKey(defaultValue: 1)
  int get numberOfPeople;
  @override
  @JsonKey(defaultValue: 1)
  int get hoursNeeded;

  /// Create a copy of RequestModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RequestModelImplCopyWith<_$RequestModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
