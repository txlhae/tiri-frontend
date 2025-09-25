import 'package:freezed_annotation/freezed_annotation.dart';
import 'chat_message_model.dart';

part 'chatroom_model.freezed.dart';
part 'chatroom_model.g.dart';

@freezed
class ChatRoomModel with _$ChatRoomModel {
  const factory ChatRoomModel({
    required String chatRoomId,
    required List<String> participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int unreadCountForReceiver,
    @Default(null) String? lastSenderId,
    String? serviceRequestId,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessageModel? lastMessageObject,
  }) = _ChatRoomModel;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);
}