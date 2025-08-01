// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


Map<String, dynamic> _$ChatMessageModelToJson(ChatMessageModel instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'chatRoomId': instance.chatRoomId,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'message': instance.message,
      'isSeen': instance.isSeen,
      'timestamp': instance.timestamp.toIso8601String(),
      'senderName': instance.senderName,
      'senderProfilePic': instance.senderProfilePic,
    };

_$ChatMessageModelImpl _$$ChatMessageModelImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatMessageModelImpl(
      messageId: json['messageId'] as String,
      chatRoomId: json['chatRoomId'] as String,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      message: json['message'] as String,
      isSeen: json['isSeen'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderName: json['senderName'] as String?,
      senderProfilePic: json['senderProfilePic'] as String?,
    );

Map<String, dynamic> _$$ChatMessageModelImplToJson(
        _$ChatMessageModelImpl instance) =>
    <String, dynamic>{
      'messageId': instance.messageId,
      'chatRoomId': instance.chatRoomId,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'message': instance.message,
      'isSeen': instance.isSeen,
      'timestamp': instance.timestamp.toIso8601String(),
      'senderName': instance.senderName,
      'senderProfilePic': instance.senderProfilePic,
    };
