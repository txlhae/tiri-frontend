import 'package:get/get.dart';
import 'dart:developer';
import 'dart:async';
import '../models/chat_message_model.dart';
import '../models/chatroom_model.dart';
import '../services/chat_api_service.dart';
import '../services/chat_websocket_service.dart';

class ChatController extends GetxController {
  // =============================================================================
  // REACTIVE VARIABLES
  // =============================================================================
  
  /// List of messages in the current chat room
  RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  
  /// Loading states
  var isLoading = false.obs;
  var isLoadingMessages = false.obs;
  var isSendingMessage = false.obs;
  var isLoadingMoreMessages = false.obs;
  
  /// Error handling
  var errorMessage = ''.obs;
  
  /// Pagination
  var currentPage = 1.obs;
  var hasMoreMessages = true.obs;
  
  /// Current chat room
  var currentChatRoom = Rxn<ChatRoomModel>();
  
  /// WebSocket connection state
  var isWebSocketConnected = false.obs;
  var webSocketConnectionState = 'disconnected'.obs; // String representation for now
  
  /// Stream subscriptions for cleanup
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  
  @override
  void onInit() {
    super.onInit();
    
    // Listen to WebSocket messages
    _messageSubscription = ChatWebSocketService.messageStream.listen((message) {
      // Add incoming messages to the local list
      messages.add(message);
      // Sort by timestamp to maintain order
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      log('📥 Received real-time message: ${message.messageId}', name: 'ChatController');
    });
  }
  
  @override
  void onClose() {
    // Clean up WebSocket connections and subscriptions
    _messageSubscription?.cancel();
    ChatWebSocketService.disconnect();
    super.onClose();
  }
  
  // =============================================================================
  // CHAT ROOM MANAGEMENT
  // =============================================================================

  /// Create or get existing chat room between two users
  /// 
  /// This method handles the creation of chat rooms for service requests
  /// and general user-to-user communication
  Future<String> createOrGetChatRoom(String userA, String userB, {String? serviceRequestId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      log('🔄 Creating or getting chat room between $userA and $userB', name: 'ChatController');
      
      final ChatRoomModel chatRoom;
      
      if (serviceRequestId != null) {
        // For service request chats, use the specialized endpoint
        chatRoom = await ChatApiService.getOrCreateChatRoom(serviceRequestId, userA, userB);
      } else {
        // For general chats, create a simple room
        chatRoom = await ChatApiService.createChatRoom(userA, userB);
      }
      
      currentChatRoom.value = chatRoom;
      log('✅ Chat room ready: ${chatRoom.chatRoomId}', name: 'ChatController');
      
      return chatRoom.chatRoomId;
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
      log('❌ Error creating/getting chat room: $e', name: 'ChatController');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // =============================================================================
  // MESSAGE MANAGEMENT
  // =============================================================================

  /// Send a new message to the chat room
  /// 
  /// This method sends the message via REST API for reliability and uses WebSocket for real-time delivery
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    if (message.trim().isEmpty) {
      errorMessage.value = 'Message cannot be empty';
      return;
    }
    
    try {
      isSendingMessage.value = true;
      errorMessage.value = '';
      
      log('🔄 Sending message to room: $chatRoomId', name: 'ChatController');
      
      // Send message via REST API for reliability
      final sentMessage = await ChatApiService.sendMessage(chatRoomId, message.trim());
      
      // Add the message to local list with server response data
      messages.add(sentMessage);
      
      // Sort messages by timestamp to maintain order
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Also send via WebSocket for real-time delivery (if connected)
      if (ChatWebSocketService.isConnected) {
        ChatWebSocketService.sendMessage(message.trim());
        log('📤 Message also sent via WebSocket for real-time delivery', name: 'ChatController');
      }
      
      log('✅ Message sent successfully: ${sentMessage.messageId}', name: 'ChatController');
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
      log('❌ Error sending message: $e', name: 'ChatController');
      
      // Don't rethrow here as we want to show error message in UI
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Load messages for a specific chat room
  /// 
  /// This method loads initial messages via REST API and establishes WebSocket connection for real-time updates
  void listenToMessages(String chatRoomId) {
    // Reset pagination
    currentPage.value = 1;
    hasMoreMessages.value = true;
    
    // Load initial messages via REST API
    _loadMessages(chatRoomId, refresh: true);
    
    // Establish WebSocket connection for real-time updates
    _connectWebSocket(chatRoomId);
  }

  /// Connect to WebSocket for real-time messaging
  Future<void> _connectWebSocket(String chatRoomId) async {
    try {
      // Get current user ID from AuthController
      final authController = Get.find<dynamic>();
      final currentUserId = authController.currentUserStore?.value?.userId ?? '';
      
      if (currentUserId.isEmpty) {
        log('⚠️ Cannot connect WebSocket - no user ID available', name: 'ChatController');
        return;
      }
      
      log('🔌 Connecting WebSocket for room: $chatRoomId', name: 'ChatController');
      
      await ChatWebSocketService.connect(chatRoomId, currentUserId);
      isWebSocketConnected.value = ChatWebSocketService.isConnected;
      
      if (ChatWebSocketService.isConnected) {
        webSocketConnectionState.value = 'connected';
        log('✅ WebSocket connected for real-time messaging', name: 'ChatController');
      } else {
        webSocketConnectionState.value = 'error';
        log('❌ WebSocket connection failed', name: 'ChatController');
      }
      
    } catch (e) {
      log('❌ Error connecting WebSocket: $e', name: 'ChatController');
      webSocketConnectionState.value = 'error';
      // Don't show error to user as REST API still works
    }
  }

  /// Internal method to load messages with pagination support
  Future<void> _loadMessages(String chatRoomId, {bool refresh = false}) async {
    if (!hasMoreMessages.value && !refresh) return;
    
    try {
      if (refresh) {
        isLoadingMessages.value = true;
        messages.clear();
        currentPage.value = 1;
      } else {
        isLoadingMoreMessages.value = true;
      }
      
      errorMessage.value = '';
      
      log('🔄 Loading messages for room: $chatRoomId (page: ${currentPage.value})', name: 'ChatController');
      
      final loadedMessages = await ChatApiService.getMessages(
        chatRoomId,
        page: currentPage.value,
        pageSize: 50,
      );
      
      if (loadedMessages.isEmpty) {
        hasMoreMessages.value = false;
        log('📄 No more messages to load', name: 'ChatController');
      } else {
        if (refresh) {
          messages.assignAll(loadedMessages);
        } else {
          messages.addAll(loadedMessages);
        }
        
        // Sort by timestamp to maintain chronological order
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Check if we should load more pages
        if (loadedMessages.length < 50) {
          hasMoreMessages.value = false;
        }
        
        currentPage.value++;
        log('✅ Loaded ${loadedMessages.length} messages. Total: ${messages.length}', name: 'ChatController');
      }
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
      log('❌ Error loading messages: $e', name: 'ChatController');
    } finally {
      isLoadingMessages.value = false;
      isLoadingMoreMessages.value = false;
    }
  }

  /// Load more messages (pagination)
  /// 
  /// This method is called when user scrolls to top of message list
  Future<void> loadMoreMessages(String chatRoomId) async {
    await _loadMessages(chatRoomId, refresh: false);
  }

  /// Refresh messages (pull to refresh)
  /// 
  /// This method refreshes the entire message list
  Future<void> refreshMessages(String chatRoomId) async {
    await _loadMessages(chatRoomId, refresh: true);
  }

  // =============================================================================
  // MESSAGE STATUS MANAGEMENT
  // =============================================================================

  /// Mark messages as seen for a specific sender
  /// 
  /// This method updates both backend and local UI state
  void markMessagesAsSeen(String senderId) {
    if (currentChatRoom.value == null) return;
    
    final chatRoomId = currentChatRoom.value!.chatRoomId;
    
    // Update local UI immediately for better UX
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.senderId == senderId && !message.isSeen) {
        final updatedMessage = message.copyWith(isSeen: true);
        messages[i] = updatedMessage;
      }
    }
    
    // Update backend asynchronously
    _updateMessageSeenStatus(chatRoomId);
  }

  /// Internal method to update message seen status on backend
  Future<void> _updateMessageSeenStatus(String chatRoomId) async {
    try {
      log('🔄 Marking messages as read for room: $chatRoomId', name: 'ChatController');
      
      await ChatApiService.markMessagesAsRead(chatRoomId);
      
      log('✅ Messages marked as read successfully', name: 'ChatController');
      
    } catch (e) {
      log('❌ Error marking messages as read: $e', name: 'ChatController');
      // Don't show error to user for this background operation
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Clear all chat data
  void clearChatData() {
    messages.clear();
    currentChatRoom.value = null;
    errorMessage.value = '';
    currentPage.value = 1;
    hasMoreMessages.value = true;
    isLoading.value = false;
    isLoadingMessages.value = false;
    isSendingMessage.value = false;
    isLoadingMoreMessages.value = false;
    
    // Disconnect WebSocket
    ChatWebSocketService.disconnect();
    isWebSocketConnected.value = false;
    webSocketConnectionState.value = 'disconnected';
  }

  /// Disconnect WebSocket when leaving chat room
  void disconnectWebSocket() {
    ChatWebSocketService.disconnect();
    isWebSocketConnected.value = false;
    webSocketConnectionState.value = 'disconnected';
    log('🔌 WebSocket disconnected from chat room', name: 'ChatController');
  }

  /// Reconnect WebSocket if connection is lost
  Future<void> reconnectWebSocket() async {
    if (currentChatRoom.value != null) {
      await _connectWebSocket(currentChatRoom.value!.chatRoomId);
    }
  }

  /// Get unread message count for current chat
  int get unreadMessageCount {
    return messages.where((message) => !message.isSeen).length;
  }

  /// Check if there are any loading operations in progress
  bool get isAnyLoading {
    return isLoading.value || 
           isLoadingMessages.value || 
           isSendingMessage.value || 
           isLoadingMoreMessages.value;
  }

  /// Send typing indicator via WebSocket
  void sendTypingIndicator(bool isTyping) {
    if (ChatWebSocketService.isConnected) {
      ChatWebSocketService.sendTypingIndicator(isTyping);
    }
  }

  /// Get connection status for UI display
  String get connectionStatusText {
    if (isWebSocketConnected.value) {
      return 'Online';
    } else if (webSocketConnectionState.value == 'connecting') {
      return 'Connecting...';
    } else if (webSocketConnectionState.value == 'reconnecting') {
      return 'Reconnecting...';
    } else {
      return 'Offline';
    }
  }
}
