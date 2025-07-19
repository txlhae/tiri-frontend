import 'package:freezed_annotation/freezed_annotation.dart';

part 'chatroom_model.freezed.dart';
part 'chatroom_model.g.dart';

@freezed
class ChatRoomModel with _$ChatRoomModel {
  @JsonSerializable(explicitToJson: true)
  const factory ChatRoomModel({
    required String chatRoomId,
    required List<String> participantIds,
    String? lastMessage,
    DateTime? lastMessageTime,
    @Default(0) int unreadCountForReceiver,
    @Default(null) String? lastSenderId,
  }) = _ChatRoomModel;

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomModelFromJson(json);
}
