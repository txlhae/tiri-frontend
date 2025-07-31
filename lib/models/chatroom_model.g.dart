// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chatroom_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


Map<String, dynamic> _$ChatRoomModelToJson(ChatRoomModel instance) =>
    <String, dynamic>{
      'chatRoomId': instance.chatRoomId,
      'participantIds': instance.participantIds,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
      'unreadCountForReceiver': instance.unreadCountForReceiver,
      'lastSenderId': instance.lastSenderId,
    };

_$ChatRoomModelImpl _$$ChatRoomModelImplFromJson(Map<String, dynamic> json) =>
    _$ChatRoomModelImpl(
      chatRoomId: json['chatRoomId'] as String,
      participantIds: (json['participantIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lastMessage: json['lastMessage'] as String?,
      lastMessageTime: json['lastMessageTime'] == null
          ? null
          : DateTime.parse(json['lastMessageTime'] as String),
      unreadCountForReceiver:
          (json['unreadCountForReceiver'] as num?)?.toInt() ?? 0,
      lastSenderId: json['lastSenderId'] as String? ?? null,
    );

Map<String, dynamic> _$$ChatRoomModelImplToJson(_$ChatRoomModelImpl instance) =>
    <String, dynamic>{
      'chatRoomId': instance.chatRoomId,
      'participantIds': instance.participantIds,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
      'unreadCountForReceiver': instance.unreadCountForReceiver,
      'lastSenderId': instance.lastSenderId,
    };
