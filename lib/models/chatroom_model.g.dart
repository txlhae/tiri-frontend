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
      'serviceRequestId': instance.serviceRequestId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastMessageObject': instance.lastMessageObject?.toJson(),
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
      serviceRequestId: json['serviceRequestId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      lastMessageObject: json['lastMessageObject'] == null
          ? null
          : ChatMessageModel.fromJson(
              json['lastMessageObject'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ChatRoomModelImplToJson(_$ChatRoomModelImpl instance) =>
    <String, dynamic>{
      'chatRoomId': instance.chatRoomId,
      'participantIds': instance.participantIds,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime?.toIso8601String(),
      'unreadCountForReceiver': instance.unreadCountForReceiver,
      'lastSenderId': instance.lastSenderId,
      'serviceRequestId': instance.serviceRequestId,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'lastMessageObject': instance.lastMessageObject,
    };
