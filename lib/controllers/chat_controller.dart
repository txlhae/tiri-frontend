import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';

class ChatController extends GetxController {
  // TODO: Replace with your preferred backend service
  // final YourBackendService _backendService = YourBackendService.instance;

  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;

  Future<String> createOrGetChatRoom(String userA, String userB) async {
    // TODO: Implement with your backend service
    // For now, return a mock chat room ID
    final mockRoomId = "${userA}_${userB}".hashCode.toString();
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return mockRoomId;
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    // TODO: Implement with your backend service
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

    // For now, add message locally to simulate sending
    messages.add(chatMessage);
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // TODO: Send to your backend service
    // await _backendService.sendMessage(chatMessage);
  }

  void listenToMessages(String chatRoomId) {
    // TODO: Implement with your backend service
    // For now, create some mock messages for testing
    messages.clear();
    
    // Simulate loading messages from backend
    Future.delayed(const Duration(milliseconds: 500), () {
      // Add some sample messages for testing UI
      // Remove this when integrating with real backend
      final sampleMessages = [
        ChatMessageModel(
          messageId: "sample1",
          chatRoomId: chatRoomId,
          senderId: "other_user",
          receiverId: "current_user",
          message: "Hello! How are you?",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isSeen: true,
        ),
        ChatMessageModel(
          messageId: "sample2",
          chatRoomId: chatRoomId,
          senderId: "current_user",
          receiverId: "other_user",
          message: "Hi! I'm doing great, thanks!",
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          isSeen: true,
        ),
      ];
      messages.addAll(sampleMessages);
    });
    
    // TODO: Replace with real-time listener to your backend
    // _backendService.listenToMessages(chatRoomId, (newMessages) {
    //   messages.value = newMessages;
    // });
  }

  void markMessagesAsSeen(String senderId) {
    // TODO: Implement with your backend service
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
    // TODO: Implement with your backend service
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 200));
    
    // TODO: Update message seen status on your backend
    // await _backendService.updateMessageSeenStatus(messageId, chatRoomId);
  }
}
