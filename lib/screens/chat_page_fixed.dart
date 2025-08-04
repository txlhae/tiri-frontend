import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:async';
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
  final ChatController chatController = Get.find<ChatController>();
  final AuthController authController = Get.find<AuthController>();
  final RequestController requestController = Get.find<RequestController>();
  final TextEditingController messageController = TextEditingController();
  
  // Debouncing for typing indicator
  Timer? _typingDebounceTimer;
  bool _isTyping = false;

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
      
      // Mark messages as read when user enters the chat room
      chatController.markRoomAsRead(widget.receiverId);
    }
  }

  @override
  void dispose() {
    // Don't disconnect WebSocket - let it stay connected for app-wide use
    messageController.dispose();
    _typingDebounceTimer?.cancel();
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
    _setTypingIndicator(false);
  }

  void _setTypingIndicator(bool isTyping) {
    if (_isTyping == isTyping) return; // Avoid unnecessary calls
    
    _isTyping = isTyping;
    chatController.sendTypingIndicator(isTyping);
    
    // Auto-stop typing indicator after 3 seconds of inactivity
    if (isTyping) {
      _typingDebounceTimer?.cancel();
      _typingDebounceTimer = Timer(const Duration(seconds: 3), () {
        _setTypingIndicator(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = authController.currentUserStore.value!.userId;
    print('🔍 Current user ID at build: "$currentUserId" (${currentUserId.runtimeType})');
    print('🔍 Widget receiver ID: "${widget.receiverId}" (${widget.receiverId.runtimeType})');
    
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

          // Messages list
          Expanded(
            child: Obx(() {
              if (chatController.isLoadingMessages.value && chatController.messages.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (chatController.messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet. Start the conversation!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                reverse: false, // Changed to false for normal order (older messages at top)
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = chatController.messages[index];
                  
                  // Determine if message is from current user
                  final isMe = message.senderId.trim() == currentUserId.trim();
                  
                  // Debug logging
                  print('🔍 Message Debug:');
                  print('   Message senderId: "${message.senderId}" (${message.senderId.runtimeType})');
                  print('   Current userId: "$currentUserId" (${currentUserId.runtimeType})');
                  print('   isMe: $isMe');
                  print('   Message content: "${message.message}"');
                  print('   Sender ID length: ${message.senderId.length}');
                  print('   Current ID length: ${currentUserId.length}');
                  print('   Are they equal? ${message.senderId == currentUserId}');
                  print('   Trimmed comparison: "${message.senderId.trim()}" == "${currentUserId.trim()}" = ${message.senderId.trim() == currentUserId.trim()}');
                  print('---');
                  
                  // Debug logging to check user IDs
                  if (index < 3) { // Only log first few messages to avoid spam
                    print('🔍 Message ${index + 1}: senderId="${message.senderId}", currentUserId="$currentUserId", isMe=$isMe');
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8), // Reduced vertical margin
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        // For received messages, show sender avatar on the left
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: widget.receiverProfilePic.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.receiverProfilePic,
                                      fit: BoxFit.cover,
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.person, size: 16, color: Colors.grey);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.person, size: 16, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        // Message bubble
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Message content
                                Text(
                                  message.message.isNotEmpty ? message.message : "No content",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isMe ? Colors.white : Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                
                                // Timestamp and read status
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      DateFormat('h:mm a').format(message.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        message.isSeen ? Icons.done_all : Icons.check,
                                        size: 14,
                                        color: message.isSeen ? Colors.lightGreen : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced vertical padding
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
                      // Send typing indicator via WebSocket with debouncing
                      if (text.trim().isNotEmpty) {
                        _setTypingIndicator(true);
                      } else {
                        _setTypingIndicator(false);
                      }
                    },
                    onSubmitted: (_) {
                      // Send message when user presses enter
                      sendMessage();
                      // Stop typing indicator
                      _setTypingIndicator(false);
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
