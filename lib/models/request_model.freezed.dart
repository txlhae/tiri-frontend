// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RequestModel {

 String get requestId; String get userId; String get title; String get description; String get location; DateTime get timestamp; DateTime get requestedTime; RequestStatus get status; List<UserModel> get acceptedUser; List<FeedbackModel>? get feedbackList;@JsonKey(defaultValue: 1) int get numberOfPeople;@JsonKey(defaultValue: 1) int get hoursNeeded;
/// Create a copy of RequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestModelCopyWith<RequestModel> get copyWith => _$RequestModelCopyWithImpl<RequestModel>(this as RequestModel, _$identity);

  /// Serializes this RequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestModel&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.requestedTime, requestedTime) || other.requestedTime == requestedTime)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.acceptedUser, acceptedUser)&&const DeepCollectionEquality().equals(other.feedbackList, feedbackList)&&(identical(other.numberOfPeople, numberOfPeople) || other.numberOfPeople == numberOfPeople)&&(identical(other.hoursNeeded, hoursNeeded) || other.hoursNeeded == hoursNeeded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,userId,title,description,location,timestamp,requestedTime,status,const DeepCollectionEquality().hash(acceptedUser),const DeepCollectionEquality().hash(feedbackList),numberOfPeople,hoursNeeded);

@override
String toString() {
  return 'RequestModel(requestId: $requestId, userId: $userId, title: $title, description: $description, location: $location, timestamp: $timestamp, requestedTime: $requestedTime, status: $status, acceptedUser: $acceptedUser, feedbackList: $feedbackList, numberOfPeople: $numberOfPeople, hoursNeeded: $hoursNeeded)';
}


}

/// @nodoc
abstract mixin class $RequestModelCopyWith<$Res>  {
  factory $RequestModelCopyWith(RequestModel value, $Res Function(RequestModel) _then) = _$RequestModelCopyWithImpl;
@useResult
$Res call({
 String requestId, String userId, String title, String description, String location, DateTime timestamp, DateTime requestedTime, RequestStatus status, List<UserModel> acceptedUser, List<FeedbackModel>? feedbackList,@JsonKey(defaultValue: 1) int numberOfPeople,@JsonKey(defaultValue: 1) int hoursNeeded
});




}
/// @nodoc
class _$RequestModelCopyWithImpl<$Res>
    implements $RequestModelCopyWith<$Res> {
  _$RequestModelCopyWithImpl(this._self, this._then);

  final RequestModel _self;
  final $Res Function(RequestModel) _then;

/// Create a copy of RequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requestId = null,Object? userId = null,Object? title = null,Object? description = null,Object? location = null,Object? timestamp = null,Object? requestedTime = null,Object? status = null,Object? acceptedUser = null,Object? feedbackList = freezed,Object? numberOfPeople = null,Object? hoursNeeded = null,}) {
  return _then(_self.copyWith(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,requestedTime: null == requestedTime ? _self.requestedTime : requestedTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,acceptedUser: null == acceptedUser ? _self.acceptedUser : acceptedUser // ignore: cast_nullable_to_non_nullable
as List<UserModel>,feedbackList: freezed == feedbackList ? _self.feedbackList : feedbackList // ignore: cast_nullable_to_non_nullable
as List<FeedbackModel>?,numberOfPeople: null == numberOfPeople ? _self.numberOfPeople : numberOfPeople // ignore: cast_nullable_to_non_nullable
as int,hoursNeeded: null == hoursNeeded ? _self.hoursNeeded : hoursNeeded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestModel].
extension RequestModelPatterns on RequestModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestModel value)  $default,){
final _that = this;
switch (_that) {
case _RequestModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _RequestModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String requestId,  String userId,  String title,  String description,  String location,  DateTime timestamp,  DateTime requestedTime,  RequestStatus status,  List<UserModel> acceptedUser,  List<FeedbackModel>? feedbackList, @JsonKey(defaultValue: 1)  int numberOfPeople, @JsonKey(defaultValue: 1)  int hoursNeeded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestModel() when $default != null:
return $default(_that.requestId,_that.userId,_that.title,_that.description,_that.location,_that.timestamp,_that.requestedTime,_that.status,_that.acceptedUser,_that.feedbackList,_that.numberOfPeople,_that.hoursNeeded);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String requestId,  String userId,  String title,  String description,  String location,  DateTime timestamp,  DateTime requestedTime,  RequestStatus status,  List<UserModel> acceptedUser,  List<FeedbackModel>? feedbackList, @JsonKey(defaultValue: 1)  int numberOfPeople, @JsonKey(defaultValue: 1)  int hoursNeeded)  $default,) {final _that = this;
switch (_that) {
case _RequestModel():
return $default(_that.requestId,_that.userId,_that.title,_that.description,_that.location,_that.timestamp,_that.requestedTime,_that.status,_that.acceptedUser,_that.feedbackList,_that.numberOfPeople,_that.hoursNeeded);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String requestId,  String userId,  String title,  String description,  String location,  DateTime timestamp,  DateTime requestedTime,  RequestStatus status,  List<UserModel> acceptedUser,  List<FeedbackModel>? feedbackList, @JsonKey(defaultValue: 1)  int numberOfPeople, @JsonKey(defaultValue: 1)  int hoursNeeded)?  $default,) {final _that = this;
switch (_that) {
case _RequestModel() when $default != null:
return $default(_that.requestId,_that.userId,_that.title,_that.description,_that.location,_that.timestamp,_that.requestedTime,_that.status,_that.acceptedUser,_that.feedbackList,_that.numberOfPeople,_that.hoursNeeded);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _RequestModel implements RequestModel {
  const _RequestModel({required this.requestId, required this.userId, required this.title, required this.description, required this.location, required this.timestamp, required this.requestedTime, required this.status, final  List<UserModel> acceptedUser = const [], final  List<FeedbackModel>? feedbackList, @JsonKey(defaultValue: 1) required this.numberOfPeople, @JsonKey(defaultValue: 1) required this.hoursNeeded}): _acceptedUser = acceptedUser,_feedbackList = feedbackList;
  factory _RequestModel.fromJson(Map<String, dynamic> json) => _$RequestModelFromJson(json);

@override final  String requestId;
@override final  String userId;
@override final  String title;
@override final  String description;
@override final  String location;
@override final  DateTime timestamp;
@override final  DateTime requestedTime;
@override final  RequestStatus status;
 final  List<UserModel> _acceptedUser;
@override@JsonKey() List<UserModel> get acceptedUser {
  if (_acceptedUser is EqualUnmodifiableListView) return _acceptedUser;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_acceptedUser);
}

 final  List<FeedbackModel>? _feedbackList;
@override List<FeedbackModel>? get feedbackList {
  final value = _feedbackList;
  if (value == null) return null;
  if (_feedbackList is EqualUnmodifiableListView) return _feedbackList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(defaultValue: 1) final  int numberOfPeople;
@override@JsonKey(defaultValue: 1) final  int hoursNeeded;

/// Create a copy of RequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestModelCopyWith<_RequestModel> get copyWith => __$RequestModelCopyWithImpl<_RequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestModel&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.location, location) || other.location == location)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.requestedTime, requestedTime) || other.requestedTime == requestedTime)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._acceptedUser, _acceptedUser)&&const DeepCollectionEquality().equals(other._feedbackList, _feedbackList)&&(identical(other.numberOfPeople, numberOfPeople) || other.numberOfPeople == numberOfPeople)&&(identical(other.hoursNeeded, hoursNeeded) || other.hoursNeeded == hoursNeeded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requestId,userId,title,description,location,timestamp,requestedTime,status,const DeepCollectionEquality().hash(_acceptedUser),const DeepCollectionEquality().hash(_feedbackList),numberOfPeople,hoursNeeded);

@override
String toString() {
  return 'RequestModel(requestId: $requestId, userId: $userId, title: $title, description: $description, location: $location, timestamp: $timestamp, requestedTime: $requestedTime, status: $status, acceptedUser: $acceptedUser, feedbackList: $feedbackList, numberOfPeople: $numberOfPeople, hoursNeeded: $hoursNeeded)';
}


}

/// @nodoc
abstract mixin class _$RequestModelCopyWith<$Res> implements $RequestModelCopyWith<$Res> {
  factory _$RequestModelCopyWith(_RequestModel value, $Res Function(_RequestModel) _then) = __$RequestModelCopyWithImpl;
@override @useResult
$Res call({
 String requestId, String userId, String title, String description, String location, DateTime timestamp, DateTime requestedTime, RequestStatus status, List<UserModel> acceptedUser, List<FeedbackModel>? feedbackList,@JsonKey(defaultValue: 1) int numberOfPeople,@JsonKey(defaultValue: 1) int hoursNeeded
});




}
/// @nodoc
class __$RequestModelCopyWithImpl<$Res>
    implements _$RequestModelCopyWith<$Res> {
  __$RequestModelCopyWithImpl(this._self, this._then);

  final _RequestModel _self;
  final $Res Function(_RequestModel) _then;

/// Create a copy of RequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requestId = null,Object? userId = null,Object? title = null,Object? description = null,Object? location = null,Object? timestamp = null,Object? requestedTime = null,Object? status = null,Object? acceptedUser = null,Object? feedbackList = freezed,Object? numberOfPeople = null,Object? hoursNeeded = null,}) {
  return _then(_RequestModel(
requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,requestedTime: null == requestedTime ? _self.requestedTime : requestedTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RequestStatus,acceptedUser: null == acceptedUser ? _self._acceptedUser : acceptedUser // ignore: cast_nullable_to_non_nullable
as List<UserModel>,feedbackList: freezed == feedbackList ? _self._feedbackList : feedbackList // ignore: cast_nullable_to_non_nullable
as List<FeedbackModel>?,numberOfPeople: null == numberOfPeople ? _self.numberOfPeople : numberOfPeople // ignore: cast_nullable_to_non_nullable
as int,hoursNeeded: null == hoursNeeded ? _self.hoursNeeded : hoursNeeded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
