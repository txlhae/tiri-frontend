// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chatroom_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatRoomModel _$ChatRoomModelFromJson(Map<String, dynamic> json) {
  return _ChatRoomModel.fromJson(json);
}

/// @nodoc
mixin _$ChatRoomModel {
  String get chatRoomId => throw _privateConstructorUsedError;
  List<String> get participantIds => throw _privateConstructorUsedError;
  String? get lastMessage => throw _privateConstructorUsedError;
  DateTime? get lastMessageTime => throw _privateConstructorUsedError;
  int get unreadCountForReceiver => throw _privateConstructorUsedError;
  String? get lastSenderId => throw _privateConstructorUsedError;

  /// Serializes this ChatRoomModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatRoomModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatRoomModelCopyWith<ChatRoomModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatRoomModelCopyWith<$Res> {
  factory $ChatRoomModelCopyWith(
          ChatRoomModel value, $Res Function(ChatRoomModel) then) =
      _$ChatRoomModelCopyWithImpl<$Res, ChatRoomModel>;
  @useResult
  $Res call(
      {String chatRoomId,
      List<String> participantIds,
      String? lastMessage,
      DateTime? lastMessageTime,
      int unreadCountForReceiver,
      String? lastSenderId});
}

/// @nodoc
class _$ChatRoomModelCopyWithImpl<$Res, $Val extends ChatRoomModel>
    implements $ChatRoomModelCopyWith<$Res> {
  _$ChatRoomModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatRoomModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatRoomId = null,
    Object? participantIds = null,
    Object? lastMessage = freezed,
    Object? lastMessageTime = freezed,
    Object? unreadCountForReceiver = null,
    Object? lastSenderId = freezed,
  }) {
    return _then(_value.copyWith(
      chatRoomId: null == chatRoomId
          ? _value.chatRoomId
          : chatRoomId // ignore: cast_nullable_to_non_nullable
              as String,
      participantIds: null == participantIds
          ? _value.participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCountForReceiver: null == unreadCountForReceiver
          ? _value.unreadCountForReceiver
          : unreadCountForReceiver // ignore: cast_nullable_to_non_nullable
              as int,
      lastSenderId: freezed == lastSenderId
          ? _value.lastSenderId
          : lastSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatRoomModelImplCopyWith<$Res>
    implements $ChatRoomModelCopyWith<$Res> {
  factory _$$ChatRoomModelImplCopyWith(
          _$ChatRoomModelImpl value, $Res Function(_$ChatRoomModelImpl) then) =
      __$$ChatRoomModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String chatRoomId,
      List<String> participantIds,
      String? lastMessage,
      DateTime? lastMessageTime,
      int unreadCountForReceiver,
      String? lastSenderId});
}

/// @nodoc
class __$$ChatRoomModelImplCopyWithImpl<$Res>
    extends _$ChatRoomModelCopyWithImpl<$Res, _$ChatRoomModelImpl>
    implements _$$ChatRoomModelImplCopyWith<$Res> {
  __$$ChatRoomModelImplCopyWithImpl(
      _$ChatRoomModelImpl _value, $Res Function(_$ChatRoomModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatRoomModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? chatRoomId = null,
    Object? participantIds = null,
    Object? lastMessage = freezed,
    Object? lastMessageTime = freezed,
    Object? unreadCountForReceiver = null,
    Object? lastSenderId = freezed,
  }) {
    return _then(_$ChatRoomModelImpl(
      chatRoomId: null == chatRoomId
          ? _value.chatRoomId
          : chatRoomId // ignore: cast_nullable_to_non_nullable
              as String,
      participantIds: null == participantIds
          ? _value._participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      unreadCountForReceiver: null == unreadCountForReceiver
          ? _value.unreadCountForReceiver
          : unreadCountForReceiver // ignore: cast_nullable_to_non_nullable
              as int,
      lastSenderId: freezed == lastSenderId
          ? _value.lastSenderId
          : lastSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatRoomModelImpl implements _ChatRoomModel {
  const _$ChatRoomModelImpl(
      {required this.chatRoomId,
      required final List<String> participantIds,
      this.lastMessage,
      this.lastMessageTime,
      this.unreadCountForReceiver = 0,
      this.lastSenderId = null})
      : _participantIds = participantIds;

  factory _$ChatRoomModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatRoomModelImplFromJson(json);

  @override
  final String chatRoomId;
  final List<String> _participantIds;
  @override
  List<String> get participantIds {
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantIds);
  }

  @override
  final String? lastMessage;
  @override
  final DateTime? lastMessageTime;
  @override
  @JsonKey()
  final int unreadCountForReceiver;
  @override
  @JsonKey()
  final String? lastSenderId;

  @override
  String toString() {
    return 'ChatRoomModel(chatRoomId: $chatRoomId, participantIds: $participantIds, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadCountForReceiver: $unreadCountForReceiver, lastSenderId: $lastSenderId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatRoomModelImpl &&
            (identical(other.chatRoomId, chatRoomId) ||
                other.chatRoomId == chatRoomId) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageTime, lastMessageTime) ||
                other.lastMessageTime == lastMessageTime) &&
            (identical(other.unreadCountForReceiver, unreadCountForReceiver) ||
                other.unreadCountForReceiver == unreadCountForReceiver) &&
            (identical(other.lastSenderId, lastSenderId) ||
                other.lastSenderId == lastSenderId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      chatRoomId,
      const DeepCollectionEquality().hash(_participantIds),
      lastMessage,
      lastMessageTime,
      unreadCountForReceiver,
      lastSenderId);

  /// Create a copy of ChatRoomModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatRoomModelImplCopyWith<_$ChatRoomModelImpl> get copyWith =>
      __$$ChatRoomModelImplCopyWithImpl<_$ChatRoomModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatRoomModelImplToJson(
      this,
    );
  }
}

abstract class _ChatRoomModel implements ChatRoomModel {
  const factory _ChatRoomModel(
      {required final String chatRoomId,
      required final List<String> participantIds,
      final String? lastMessage,
      final DateTime? lastMessageTime,
      final int unreadCountForReceiver,
      final String? lastSenderId}) = _$ChatRoomModelImpl;

  factory _ChatRoomModel.fromJson(Map<String, dynamic> json) =
      _$ChatRoomModelImpl.fromJson;

  @override
  String get chatRoomId;
  @override
  List<String> get participantIds;
  @override
  String? get lastMessage;
  @override
  DateTime? get lastMessageTime;
  @override
  int get unreadCountForReceiver;
  @override
  String? get lastSenderId;

  /// Create a copy of ChatRoomModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatRoomModelImplCopyWith<_$ChatRoomModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
