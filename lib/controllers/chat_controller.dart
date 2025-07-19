import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kind_clock/models/chatroom_model.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  Future<String> createOrGetChatRoom(String userA, String userB) async {
    final snapshot = await _firestore
        .collection('chatRooms')
        .where('participantIds', arrayContains: userA)
        .get();

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc['participantIds']);
      if (participants.contains(userB)) {
        return doc.id;
      }
    }

    final newRoomId = const Uuid().v4();
    final newRoom = ChatRoomModel(
      chatRoomId: newRoomId,
      participantIds: [userA, userB],
      lastMessage: '',
      lastMessageTime: null,
    );

    await _firestore
        .collection('chatRooms')
        .doc(newRoomId)
        .set(newRoom.toJson());

    return newRoomId;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final messageId = const Uuid().v4();
    final timestamp = DateTime.now();

    final chatMessage = ChatMessageModel(
      messageId: messageId,
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .set(chatMessage.toJson());

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastSenderId': senderId,
    });
  }

  void listenToMessages(String chatRoomId) {
    _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs
          .map((doc) => ChatMessageModel.fromJson(doc.data()))
          .toList();
    });
  }
void markMessagesAsSeen(String senderId) {
  for (int i = 0; i < messages.length; i++) {
    final message = messages[i];
    if (message.senderId == senderId && !message.isSeen) {
      final updatedMessage = message.copyWith(isSeen: true);

      messages[i] = updatedMessage; // Replace in the RxList
      updateMessageSeenStatus(updatedMessage.messageId, updatedMessage.chatRoomId);
    }
  }
}

  Future<void> updateMessageSeenStatus(String messageId, String chatRoomId) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isSeen': true});
  }

}
