import 'package:get/get.dart';
import 'dart:async';
import '../models/chat_message_model.dart';
import '../models/chatroom_model.dart';
import '../services/chat_api_service.dart';
import '../services/chat_websocket_service.dart';
import '../controllers/auth_controller.dart';

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
  
  /// Debounce timer for mark_read operations to prevent rate limiting
  Timer? _markReadDebounceTimer;
  static const Duration _markReadDebounceDelay = Duration(seconds: 2);
  
  /// Throttle timer for send message operations to prevent spam
  Timer? _sendMessageThrottleTimer;
  static const Duration _sendMessageThrottleDelay = Duration(milliseconds: 500);
  bool _canSendMessage = true;
  
  /// Connection monitoring timer
  Timer? _connectionMonitorTimer;
  
  @override
  void onInit() {
    super.onInit();
    
    // Listen to WebSocket messages
    _messageSubscription = ChatWebSocketService.messageStream.listen((message) {
      // Add incoming messages to the local list with deduplication
      addMessageSafely(message);
      
    });
  }
  
  @override
  void onClose() {
    // Clean up WebSocket connections and subscriptions
    _messageSubscription?.cancel();
    _messageSubscription = null; // Ensure it's nullified
    _markReadDebounceTimer?.cancel();
    _sendMessageThrottleTimer?.cancel();
    _connectionMonitorTimer?.cancel();
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
      
      
      // Enhanced logging for debugging
      
      final ChatRoomModel chatRoom;
      
      if (serviceRequestId != null) {
        // For service request chats, use the specialized endpoint
        chatRoom = await ChatApiService.getOrCreateChatRoom(serviceRequestId, userA, userB);
      } else {
        // For general chats, create a simple room
        chatRoom = await ChatApiService.createChatRoom(userA, userB);
      }
      
      currentChatRoom.value = chatRoom;
      final roomId = chatRoom.chatRoomId;
      
      
      // Enhanced logging
      
      // Validate that we got a proper room ID
      if (roomId.isEmpty) {
        throw Exception('Received empty room ID from server');
      }
      
      return roomId;
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
      
      // Enhanced error logging
      
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // =============================================================================
  // MESSAGE MANAGEMENT
  // =============================================================================

  /// Add message with deduplication to prevent duplicate messages
  /// 
  /// This method ensures that messages with the same messageId are not added twice
  void addMessageSafely(ChatMessageModel message) {
    if (!messages.any((m) => m.messageId == message.messageId)) {
      messages.add(message);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
    }
  }

  /// Send a new message to the chat room
  /// 
  /// This method sends the message via REST API for reliability and uses WebSocket for real-time delivery
  /// Includes throttling to prevent rate limiting
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
    
    // Check throttling
    if (!_canSendMessage) {
      errorMessage.value = 'Please wait before sending another message';
      return;
    }
    
    try {
      isSendingMessage.value = true;
      errorMessage.value = '';
      _canSendMessage = false;
      
      
      // Send message via REST API for reliability
      final sentMessage = await ChatApiService.sendMessage(chatRoomId, message.trim());
      
      // Add the message to local list immediately with deduplication
      addMessageSafely(sentMessage);
      
      
      // Reset throttle timer
      _sendMessageThrottleTimer?.cancel();
      _sendMessageThrottleTimer = Timer(_sendMessageThrottleDelay, () {
        _canSendMessage = true;
      });
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
      _canSendMessage = true;
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
    
    // Connect WebSocket and wait for it to be ready
    _connectWebSocket(chatRoomId).then((_) {
      // Only set up stream listener after connection is established
      if (ChatWebSocketService.isConnected) {
        
        // Cancel existing subscription first to prevent duplicates
        _messageSubscription?.cancel();
        
        _messageSubscription = ChatWebSocketService.messageStream.listen(
          (message) {
            addMessageSafely(message);
          },
          onError: (error) {
          },
        );
      }
    });
  }

  /// Mark messages as read when user enters the chat room
  /// 
  /// This method should be called once when user enters the chat room
  void markRoomAsRead(String senderId) {
    // Add a small delay to ensure messages are loaded first
    Future.delayed(const Duration(milliseconds: 1000), () {
      markMessagesAsSeen(senderId);
    });
  }

  /// Connect to WebSocket for real-time messaging
  Future<void> _connectWebSocket(String chatRoomId) async {
    try {
      final authController = Get.find<AuthController>();
      final currentUserId = authController.currentUserStore.value?.userId ?? '';
      
      if (currentUserId.isEmpty) {
        return;
      }
      
      
      // Wait for WebSocket connection to be fully ready
      await ChatWebSocketService.connect(chatRoomId, currentUserId);
      
      // Only update connection state after successful connection
      isWebSocketConnected.value = ChatWebSocketService.isConnected;
      
      if (ChatWebSocketService.isConnected) {
        webSocketConnectionState.value = 'connected';
        
        // Start connection monitoring
        _startConnectionMonitoring();
      } else {
        webSocketConnectionState.value = 'error';
      }
      
    } catch (e) {
      webSocketConnectionState.value = 'error';
      isWebSocketConnected.value = false;
    }
  }

  /// Internal method to load messages with pagination support
  Future<void> _loadMessages(String chatRoomId, {bool refresh = false}) async {
    
    if (!hasMoreMessages.value && !refresh) {
      return;
    }
    
    
    try {
      if (refresh) {
        isLoadingMessages.value = true;
        messages.clear();
        currentPage.value = 1;
      } else {
        isLoadingMoreMessages.value = true;
      }
      
      errorMessage.value = '';
      
      
      final loadedMessages = await ChatApiService.getMessages(
        chatRoomId,
        page: currentPage.value,
        pageSize: 15,
      );
      
      if (loadedMessages.isEmpty) {
        hasMoreMessages.value = false;
      } else {
        if (refresh) {
          messages.assignAll(loadedMessages);
          // Sort messages by timestamp to ensure correct chronological order
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        } else {
          // Use safe addition for pagination to prevent duplicates with real-time messages
          for (final message in loadedMessages) {
            addMessageSafely(message);
          }
        }
        
        for (int i = 0; i < messages.length && i < 3; i++) {
        }
        
        // Check if we should load more pages
        if (loadedMessages.length < 15) {
          hasMoreMessages.value = false;
        }
        
        currentPage.value++;
      }
      
    } catch (e) {
      final errorMsg = ChatApiService.getErrorMessage(e);
      errorMessage.value = errorMsg;
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
  /// This method updates both backend and local UI state with debouncing to prevent rate limiting
  void markMessagesAsSeen(String senderId) {
    if (currentChatRoom.value == null) return;
    
    final chatRoomId = currentChatRoom.value!.chatRoomId;
    
    // Update local UI immediately for better UX
    bool hasUnreadMessages = false;
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.senderId == senderId && !message.isSeen) {
        final updatedMessage = message.copyWith(isSeen: true);
        messages[i] = updatedMessage;
        hasUnreadMessages = true;
      }
    }
    
    // Only make API call if there were actually unread messages
    if (!hasUnreadMessages) return;
    
    // Cancel existing timer and start a new one for debouncing
    _markReadDebounceTimer?.cancel();
    _markReadDebounceTimer = Timer(_markReadDebounceDelay, () {
      _updateMessageSeenStatus(chatRoomId);
    });
  }

  /// Internal method to update message seen status on backend
  Future<void> _updateMessageSeenStatus(String chatRoomId) async {
    try {
      
      await ChatApiService.markMessagesAsRead(chatRoomId);
      
      
    } catch (e) {
      // Don't show error to user for this background operation
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Clear all chat data
  void clearChatData() {
    // Cancel any existing subscriptions first
    _messageSubscription?.cancel();
    _messageSubscription = null;
    
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
    } else if (webSocketConnectionState.value == 'error') {
      return 'Connection Error';
    } else {
      return 'Offline';
    }
  }
  
  /// Start connection monitoring
  void _startConnectionMonitoring() {
    _connectionMonitorTimer?.cancel();
    _connectionMonitorTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      final actualConnectionStatus = ChatWebSocketService.isConnected;
      if (isWebSocketConnected.value != actualConnectionStatus) {
        isWebSocketConnected.value = actualConnectionStatus;
        webSocketConnectionState.value = actualConnectionStatus ? 'connected' : 'disconnected';
      }
    });
  }
}
