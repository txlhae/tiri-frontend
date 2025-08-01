import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/chat_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/models/chat_message_model.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String receiverId;
  final String receiverName;
  final String receiverProfilePic;

  const ChatPage({
    super.key,
    required this.chatRoomId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverProfilePic,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatController chatController = Get.put(ChatController());
  final AuthController authController = Get.find<AuthController>();
  final RequestController requestController = Get.find<RequestController>();
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.chatRoomId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Chat Room ID is missing.');
        Get.back();
      });
    } else {
      chatController.listenToMessages(widget.chatRoomId);
    }
     chatController.markMessagesAsSeen(widget.receiverId);
  }

  @override
  void dispose() {
    // Disconnect WebSocket when leaving chat page
    chatController.disconnectWebSocket();
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    chatController.sendMessage(
      chatRoomId: widget.chatRoomId,
      senderId: authController.currentUserStore.value!.userId,
      receiverId: widget.receiverId,
      message: text,
    );
    messageController.clear();
    
    // Stop typing indicator
    chatController.sendTypingIndicator(false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.currentUserStore.value!.userId;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), 
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0,
         // iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 4,
           shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10), 
          ),
        ),
        leading:  Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: CustomBackButton(
                          controller: requestController,
                        ),
        ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9,bottom: 5),
                  child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      child: widget.receiverProfilePic.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                widget.receiverProfilePic,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, size: 24, color: Colors.blue);
                                },
                              ),
                            )
                          : const Icon(Icons.person, size: 24, color: Colors.blue),
                    ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.receiverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Connection status indicator
                      Obx(() => Text(
                        chatController.connectionStatusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: chatController.isWebSocketConnected.value 
                              ? Colors.lightGreen 
                              : Colors.white70,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Error message display
          Obx(() {
            if (chatController.errorMessage.value.isNotEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatController.errorMessage.value,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => chatController.errorMessage.value = '',
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
    Expanded(
      child: Obx(() {
        // Show loading indicator when loading messages
        if (chatController.isLoadingMessages.value && chatController.messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading messages...', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }
        
        final messages = chatController.messages;
        chatController.markMessagesAsSeen(widget.receiverId);
        
        if (messages.isEmpty && !chatController.isLoadingMessages.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: messages.length + (chatController.isLoadingMoreMessages.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the top when loading more messages
            if (index == 0 && chatController.isLoadingMoreMessages.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            final messageIndex = chatController.isLoadingMoreMessages.value ? index - 1 : index;
            final ChatMessageModel message = messages[messageIndex];
            final isMe = message.senderId == currentUserId;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                constraints: const BoxConstraints(maxWidth: 150),
                decoration: BoxDecoration(
                  color: isMe ?  Colors.blue : Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message.message,
                        style:TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color:isMe ?Colors.white70: Colors.grey.shade800,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isSeen
                                ? Icons.done_all
                                : Icons.check,
                            size: 16,
                            color: message.isSeen
                                ? Colors.yellow
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    ),
    Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child:Material(
                    elevation: 3,
                    shadowColor: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    child: TextField(
                    controller: messageController,
                    onChanged: (text) {
                      // Send typing indicator via WebSocket
                      if (text.isNotEmpty) {
                        chatController.sendTypingIndicator(true);
                      } else {
                        chatController.sendTypingIndicator(false);
                      }
                    },
                    onSubmitted: (_) {
                      // Send message when user presses enter
                      sendMessage();
                      // Stop typing indicator
                      chatController.sendTypingIndicator(false);
                    },
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                  filled: true,
                  fillColor: Colors.white,
                    ),
                  ),
                  ),

                ),
                const SizedBox(width: 8),
                Obx(() => CircleAvatar(
                  backgroundColor: chatController.isSendingMessage.value 
                      ? Colors.grey 
                      : Colors.blue,
                  radius: 20,
                  child: chatController.isSendingMessage.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          alignment: Alignment.center,
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: chatController.isSendingMessage.value 
                              ? null 
                              : sendMessage,
                        ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
