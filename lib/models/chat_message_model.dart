import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

@freezed
class ChatMessageModel with _$ChatMessageModel {
  @JsonSerializable(explicitToJson: true)
  const factory ChatMessageModel({
    required String messageId,
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
    @Default(false) bool isSeen,
    required DateTime timestamp,
  }) = _ChatMessageModel;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);
}
