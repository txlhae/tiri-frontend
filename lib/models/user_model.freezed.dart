// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserModel {

 String get userId; String get email; String get username; String? get imageUrl; String? get referralUserId; String? get phoneNumber; String? get country; String? get referralCode; double? get rating; int? get hours; DateTime? get createdAt;@JsonKey(name: 'is_verified') bool get isVerified;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);

  /// Serializes this UserModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.referralUserId, referralUserId) || other.referralUserId == referralUserId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.country, country) || other.country == country)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,username,imageUrl,referralUserId,phoneNumber,country,referralCode,rating,hours,createdAt,isVerified);

@override
String toString() {
  return 'UserModel(userId: $userId, email: $email, username: $username, imageUrl: $imageUrl, referralUserId: $referralUserId, phoneNumber: $phoneNumber, country: $country, referralCode: $referralCode, rating: $rating, hours: $hours, createdAt: $createdAt, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String userId, String email, String username, String? imageUrl, String? referralUserId, String? phoneNumber, String? country, String? referralCode, double? rating, int? hours, DateTime? createdAt,@JsonKey(name: 'is_verified') bool isVerified
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? email = null,Object? username = null,Object? imageUrl = freezed,Object? referralUserId = freezed,Object? phoneNumber = freezed,Object? country = freezed,Object? referralCode = freezed,Object? rating = freezed,Object? hours = freezed,Object? createdAt = freezed,Object? isVerified = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,referralUserId: freezed == referralUserId ? _self.referralUserId : referralUserId // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,referralCode: freezed == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String email,  String username,  String? imageUrl,  String? referralUserId,  String? phoneNumber,  String? country,  String? referralCode,  double? rating,  int? hours,  DateTime? createdAt, @JsonKey(name: 'is_verified')  bool isVerified)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.userId,_that.email,_that.username,_that.imageUrl,_that.referralUserId,_that.phoneNumber,_that.country,_that.referralCode,_that.rating,_that.hours,_that.createdAt,_that.isVerified);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String email,  String username,  String? imageUrl,  String? referralUserId,  String? phoneNumber,  String? country,  String? referralCode,  double? rating,  int? hours,  DateTime? createdAt, @JsonKey(name: 'is_verified')  bool isVerified)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.userId,_that.email,_that.username,_that.imageUrl,_that.referralUserId,_that.phoneNumber,_that.country,_that.referralCode,_that.rating,_that.hours,_that.createdAt,_that.isVerified);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String email,  String username,  String? imageUrl,  String? referralUserId,  String? phoneNumber,  String? country,  String? referralCode,  double? rating,  int? hours,  DateTime? createdAt, @JsonKey(name: 'is_verified')  bool isVerified)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.userId,_that.email,_that.username,_that.imageUrl,_that.referralUserId,_that.phoneNumber,_that.country,_that.referralCode,_that.rating,_that.hours,_that.createdAt,_that.isVerified);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _UserModel implements UserModel {
  const _UserModel({required this.userId, required this.email, required this.username, this.imageUrl, this.referralUserId, this.phoneNumber, this.country, this.referralCode, this.rating, this.hours, this.createdAt = null, @JsonKey(name: 'is_verified') this.isVerified = false});
  factory _UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

@override final  String userId;
@override final  String email;
@override final  String username;
@override final  String? imageUrl;
@override final  String? referralUserId;
@override final  String? phoneNumber;
@override final  String? country;
@override final  String? referralCode;
@override final  double? rating;
@override final  int? hours;
@override@JsonKey() final  DateTime? createdAt;
@override@JsonKey(name: 'is_verified') final  bool isVerified;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.username, username) || other.username == username)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.referralUserId, referralUserId) || other.referralUserId == referralUserId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.country, country) || other.country == country)&&(identical(other.referralCode, referralCode) || other.referralCode == referralCode)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,username,imageUrl,referralUserId,phoneNumber,country,referralCode,rating,hours,createdAt,isVerified);

@override
String toString() {
  return 'UserModel(userId: $userId, email: $email, username: $username, imageUrl: $imageUrl, referralUserId: $referralUserId, phoneNumber: $phoneNumber, country: $country, referralCode: $referralCode, rating: $rating, hours: $hours, createdAt: $createdAt, isVerified: $isVerified)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String userId, String email, String username, String? imageUrl, String? referralUserId, String? phoneNumber, String? country, String? referralCode, double? rating, int? hours, DateTime? createdAt,@JsonKey(name: 'is_verified') bool isVerified
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? email = null,Object? username = null,Object? imageUrl = freezed,Object? referralUserId = freezed,Object? phoneNumber = freezed,Object? country = freezed,Object? referralCode = freezed,Object? rating = freezed,Object? hours = freezed,Object? createdAt = freezed,Object? isVerified = null,}) {
  return _then(_UserModel(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,referralUserId: freezed == referralUserId ? _self.referralUserId : referralUserId // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,referralCode: freezed == referralCode ? _self.referralCode : referralCode // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,hours: freezed == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
