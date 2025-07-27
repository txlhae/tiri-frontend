// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chatroom_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatRoomModel {

 String get chatRoomId; List<String> get participantIds; String? get lastMessage; DateTime? get lastMessageTime; int get unreadCountForReceiver; String? get lastSenderId;
/// Create a copy of ChatRoomModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRoomModelCopyWith<ChatRoomModel> get copyWith => _$ChatRoomModelCopyWithImpl<ChatRoomModel>(this as ChatRoomModel, _$identity);

  /// Serializes this ChatRoomModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRoomModel&&(identical(other.chatRoomId, chatRoomId) || other.chatRoomId == chatRoomId)&&const DeepCollectionEquality().equals(other.participantIds, participantIds)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&(identical(other.unreadCountForReceiver, unreadCountForReceiver) || other.unreadCountForReceiver == unreadCountForReceiver)&&(identical(other.lastSenderId, lastSenderId) || other.lastSenderId == lastSenderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chatRoomId,const DeepCollectionEquality().hash(participantIds),lastMessage,lastMessageTime,unreadCountForReceiver,lastSenderId);

@override
String toString() {
  return 'ChatRoomModel(chatRoomId: $chatRoomId, participantIds: $participantIds, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadCountForReceiver: $unreadCountForReceiver, lastSenderId: $lastSenderId)';
}


}

/// @nodoc
abstract mixin class $ChatRoomModelCopyWith<$Res>  {
  factory $ChatRoomModelCopyWith(ChatRoomModel value, $Res Function(ChatRoomModel) _then) = _$ChatRoomModelCopyWithImpl;
@useResult
$Res call({
 String chatRoomId, List<String> participantIds, String? lastMessage, DateTime? lastMessageTime, int unreadCountForReceiver, String? lastSenderId
});




}
/// @nodoc
class _$ChatRoomModelCopyWithImpl<$Res>
    implements $ChatRoomModelCopyWith<$Res> {
  _$ChatRoomModelCopyWithImpl(this._self, this._then);

  final ChatRoomModel _self;
  final $Res Function(ChatRoomModel) _then;

/// Create a copy of ChatRoomModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? chatRoomId = null,Object? participantIds = null,Object? lastMessage = freezed,Object? lastMessageTime = freezed,Object? unreadCountForReceiver = null,Object? lastSenderId = freezed,}) {
  return _then(_self.copyWith(
chatRoomId: null == chatRoomId ? _self.chatRoomId : chatRoomId // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self.participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTime: freezed == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unreadCountForReceiver: null == unreadCountForReceiver ? _self.unreadCountForReceiver : unreadCountForReceiver // ignore: cast_nullable_to_non_nullable
as int,lastSenderId: freezed == lastSenderId ? _self.lastSenderId : lastSenderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatRoomModel].
extension ChatRoomModelPatterns on ChatRoomModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatRoomModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatRoomModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatRoomModel value)  $default,){
final _that = this;
switch (_that) {
case _ChatRoomModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatRoomModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChatRoomModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String chatRoomId,  List<String> participantIds,  String? lastMessage,  DateTime? lastMessageTime,  int unreadCountForReceiver,  String? lastSenderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatRoomModel() when $default != null:
return $default(_that.chatRoomId,_that.participantIds,_that.lastMessage,_that.lastMessageTime,_that.unreadCountForReceiver,_that.lastSenderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String chatRoomId,  List<String> participantIds,  String? lastMessage,  DateTime? lastMessageTime,  int unreadCountForReceiver,  String? lastSenderId)  $default,) {final _that = this;
switch (_that) {
case _ChatRoomModel():
return $default(_that.chatRoomId,_that.participantIds,_that.lastMessage,_that.lastMessageTime,_that.unreadCountForReceiver,_that.lastSenderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String chatRoomId,  List<String> participantIds,  String? lastMessage,  DateTime? lastMessageTime,  int unreadCountForReceiver,  String? lastSenderId)?  $default,) {final _that = this;
switch (_that) {
case _ChatRoomModel() when $default != null:
return $default(_that.chatRoomId,_that.participantIds,_that.lastMessage,_that.lastMessageTime,_that.unreadCountForReceiver,_that.lastSenderId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _ChatRoomModel implements ChatRoomModel {
  const _ChatRoomModel({required this.chatRoomId, required final  List<String> participantIds, this.lastMessage, this.lastMessageTime, this.unreadCountForReceiver = 0, this.lastSenderId = null}): _participantIds = participantIds;
  factory _ChatRoomModel.fromJson(Map<String, dynamic> json) => _$ChatRoomModelFromJson(json);

@override final  String chatRoomId;
 final  List<String> _participantIds;
@override List<String> get participantIds {
  if (_participantIds is EqualUnmodifiableListView) return _participantIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participantIds);
}

@override final  String? lastMessage;
@override final  DateTime? lastMessageTime;
@override@JsonKey() final  int unreadCountForReceiver;
@override@JsonKey() final  String? lastSenderId;

/// Create a copy of ChatRoomModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatRoomModelCopyWith<_ChatRoomModel> get copyWith => __$ChatRoomModelCopyWithImpl<_ChatRoomModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatRoomModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatRoomModel&&(identical(other.chatRoomId, chatRoomId) || other.chatRoomId == chatRoomId)&&const DeepCollectionEquality().equals(other._participantIds, _participantIds)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastMessageTime, lastMessageTime) || other.lastMessageTime == lastMessageTime)&&(identical(other.unreadCountForReceiver, unreadCountForReceiver) || other.unreadCountForReceiver == unreadCountForReceiver)&&(identical(other.lastSenderId, lastSenderId) || other.lastSenderId == lastSenderId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,chatRoomId,const DeepCollectionEquality().hash(_participantIds),lastMessage,lastMessageTime,unreadCountForReceiver,lastSenderId);

@override
String toString() {
  return 'ChatRoomModel(chatRoomId: $chatRoomId, participantIds: $participantIds, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadCountForReceiver: $unreadCountForReceiver, lastSenderId: $lastSenderId)';
}


}

/// @nodoc
abstract mixin class _$ChatRoomModelCopyWith<$Res> implements $ChatRoomModelCopyWith<$Res> {
  factory _$ChatRoomModelCopyWith(_ChatRoomModel value, $Res Function(_ChatRoomModel) _then) = __$ChatRoomModelCopyWithImpl;
@override @useResult
$Res call({
 String chatRoomId, List<String> participantIds, String? lastMessage, DateTime? lastMessageTime, int unreadCountForReceiver, String? lastSenderId
});




}
/// @nodoc
class __$ChatRoomModelCopyWithImpl<$Res>
    implements _$ChatRoomModelCopyWith<$Res> {
  __$ChatRoomModelCopyWithImpl(this._self, this._then);

  final _ChatRoomModel _self;
  final $Res Function(_ChatRoomModel) _then;

/// Create a copy of ChatRoomModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? chatRoomId = null,Object? participantIds = null,Object? lastMessage = freezed,Object? lastMessageTime = freezed,Object? unreadCountForReceiver = null,Object? lastSenderId = freezed,}) {
  return _then(_ChatRoomModel(
chatRoomId: null == chatRoomId ? _self.chatRoomId : chatRoomId // ignore: cast_nullable_to_non_nullable
as String,participantIds: null == participantIds ? _self._participantIds : participantIds // ignore: cast_nullable_to_non_nullable
as List<String>,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTime: freezed == lastMessageTime ? _self.lastMessageTime : lastMessageTime // ignore: cast_nullable_to_non_nullable
as DateTime?,unreadCountForReceiver: null == unreadCountForReceiver ? _self.unreadCountForReceiver : unreadCountForReceiver // ignore: cast_nullable_to_non_nullable
as int,lastSenderId: freezed == lastSenderId ? _self.lastSenderId : lastSenderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
