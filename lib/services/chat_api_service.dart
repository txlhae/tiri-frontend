// lib/services/chat_api_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/chatroom_model.dart';
import '../models/chat_message_model.dart';

/// Chat API Service for handling all chat-related backend communication
/// 
/// Features:
/// - Real-time message synchronization
/// - Chat room management
/// - Message pagination
/// - Read status updates
/// - Error handling with Dio exceptions
class ChatApiService {
  // Get the singleton ApiService instance
  static final ApiService _apiService = ApiService.instance;

  // =============================================================================
  // CHAT ROOMS
  // =============================================================================

  /// Get all chat rooms for the current user
  /// 
  /// Returns a list of chat rooms with participant information,
  /// last messages, and unread counts
  static Future<List<ChatRoomModel>> getChatRooms() async {
    try {
      log('🔄 Fetching chat rooms...', name: 'ChatAPI');
      
      final response = await _apiService.get('/api/chat/rooms/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> roomsJson = data['results'] ?? data;
        
        final chatRooms = roomsJson
            .map((json) => _mapChatRoomFromBackend(json as Map<String, dynamic>))
            .toList();
        
        log('✅ Fetched ${chatRooms.length} chat rooms', name: 'ChatAPI');
        return chatRooms;
      } else {
        log('❌ Failed to fetch chat rooms - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch chat rooms',
        );
      }
    } catch (e) {
      log('❌ Error fetching chat rooms: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  /// Get or create a chat room for a specific service request
  /// 
  /// This method handles the creation of chat rooms between users
  /// in the context of a service request
  static Future<ChatRoomModel> getOrCreateChatRoom(
    String requestId,
    String userId1,
    String userId2,
  ) async {
    try {
      log('🔄 Getting or creating chat room for request: $requestId', name: 'ChatAPI');
      log('👥 Participants: $userId1, $userId2', name: 'ChatAPI');
      
      // Enhanced logging for debugging
      log('🔍 [CHAT API] === API Call Debug ===');
      log('🔍 [CHAT API] Endpoint: POST /api/chat/rooms/get_or_create/');
      log('🔍 [CHAT API] Request ID: $requestId');
      log('🔍 [CHAT API] User ID 1: $userId1');
      log('🔍 [CHAT API] User ID 2: $userId2');
      
      final requestData = {
        'service_request_id': requestId,
        'participants': [userId1, userId2],
      };
      
      log('📤 Sending request data: $requestData', name: 'ChatAPI');
      
      // Enhanced logging for exact payload
      log('🔍 [CHAT API] === Request Payload ===');
      log('🔍 [CHAT API] service_request_id: $requestId');
      log('🔍 [CHAT API] participants: [$userId1, $userId2]');
      log('🔍 [CHAT API] Full payload: $requestData');
      log('🔍 [CHAT API] JSON payload: ${requestData.toString()}');
      
      log('🔍 [CHAT API] Making API call...');
      
      final response = await _apiService.post(
        '/api/chat/rooms/get_or_create/',
        data: requestData,
      );
      
      log('📡 Response status: ${response.statusCode}', name: 'ChatAPI');
      log('📡 Response data: ${response.data}', name: 'ChatAPI');
      
      // Enhanced response logging
      log('🔍 [CHAT API] === API Response ===');
      log('🔍 [CHAT API] Status Code: ${response.statusCode}');
      log('🔍 [CHAT API] Response Headers: ${response.headers}');
      log('🔍 [CHAT API] Response Data: ${response.data}');
      log('🔍 [CHAT API] Response Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle the nested chat_room structure from get_or_create endpoint
        final responseData = response.data as Map<String, dynamic>;
        log('🔍 [CHAT API] Processing successful response...');
        log('🔍 [CHAT API] Response data keys: ${responseData.keys.toList()}');
        
        final chatRoomData = responseData['chat_room'] as Map<String, dynamic>;
        log('🔍 [CHAT API] Chat room data: $chatRoomData');
        
        final chatRoom = _mapChatRoomFromBackend(chatRoomData);
        log('✅ Chat room ready: ${chatRoom.chatRoomId}', name: 'ChatAPI');
        
        log('✅ [CHAT API] Chat room created successfully');
        log('✅ [CHAT API] Room ID: ${chatRoom.chatRoomId}');
        
        return chatRoom;
      } else {
        log('❌ Failed to get/create chat room - Status: ${response.statusCode}', name: 'ChatAPI');
        log('❌ Response body: ${response.data}', name: 'ChatAPI');
        
        log('❌ [CHAT API] API call failed');
        log('❌ [CHAT API] Status Code: ${response.statusCode}');
        log('❌ [CHAT API] Error Response: ${response.data}');
        
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get or create chat room',
        );
      }
    } catch (e) {
      log('❌ Error getting/creating chat room: $e', name: 'ChatAPI');
      
      log('❌ [CHAT API] Exception in getOrCreateChatRoom: $e');
      log('❌ [CHAT API] Exception type: ${e.runtimeType}');
      
      rethrow;
    }
  }

  /// Get chat room details by ID
  static Future<ChatRoomModel> getChatRoom(String roomId) async {
    try {
      log('🔄 Fetching chat room: $roomId', name: 'ChatAPI');
      
      final response = await _apiService.get('/api/chat/rooms/$roomId/');
      
      if (response.statusCode == 200) {
        final chatRoom = _mapChatRoomFromBackend(response.data as Map<String, dynamic>);
        log('✅ Chat room fetched: ${chatRoom.chatRoomId}', name: 'ChatAPI');
        return chatRoom;
      } else {
        log('❌ Failed to fetch chat room - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch chat room',
        );
      }
    } catch (e) {
      log('❌ Error fetching chat room: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  // =============================================================================
  // MESSAGES
  // =============================================================================

  /// Get messages for a specific chat room with pagination
  /// 
  /// [roomId] - The chat room ID
  /// [page] - Page number (default: 1)
  /// [pageSize] - Number of messages per page (default: 50)
  /// 
  /// Returns messages ordered by timestamp (newest first)
  static Future<List<ChatMessageModel>> getMessages(
    String roomId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      log('🔄 Fetching messages for room: $roomId (page: $page)', name: 'ChatAPI');
      
      final response = await _apiService.get(
        '/api/chat/rooms/$roomId/messages/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> messagesJson = data['results'] ?? data;
        
        final messages = messagesJson
            .map((json) => _mapMessageFromBackend(json as Map<String, dynamic>))
            .toList();
        
        log('✅ Fetched ${messages.length} messages for room: $roomId', name: 'ChatAPI');
        
        // Log first message for debugging
        if (messages.isNotEmpty) {
          log('📄 First message: "${messages.first.message}" from ${messages.first.senderId}', name: 'ChatAPI');
        }
        
        return messages;
      } else {
        log('❌ Failed to fetch messages - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch messages',
        );
      }
    } catch (e) {
      log('❌ Error fetching messages: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  /// Send a new message to a chat room
  /// 
  /// [roomId] - The chat room ID
  /// [content] - The message content
  /// 
  /// Returns the created message with server-generated ID and timestamp
  static Future<ChatMessageModel> sendMessage(
    String roomId,
    String content,
  ) async {
    try {
      log('🔄 Sending message to room: $roomId', name: 'ChatAPI');
      
      // Validate room ID is not empty
      if (roomId.isEmpty) {
        throw ArgumentError('Room ID cannot be empty');
      }
      
      // Validate content is not empty
      if (content.trim().isEmpty) {
        throw ArgumentError('Message content cannot be empty');
      }
      
      final messageData = {
        'room_id': roomId,
        'content': content.trim(),
        'message_type': 'text',
      };
      
      log('📤 Sending message data: $messageData', name: 'ChatAPI');
      log('📍 Endpoint: /api/chat/rooms/$roomId/send_message/', name: 'ChatAPI');
      
      final response = await _apiService.post(
        '/api/chat/rooms/$roomId/send_message/',
        data: messageData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final message = _mapMessageFromBackend(response.data as Map<String, dynamic>);
        log('✅ Message sent successfully: ${message.messageId}', name: 'ChatAPI');
        return message;
      } else {
        log('❌ Failed to send message - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to send message',
        );
      }
    } catch (e) {
      log('❌ Error sending message: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  /// Mark all messages in a chat room as read
  /// 
  /// [roomId] - The chat room ID
  /// 
  /// This updates the read status for all unread messages
  /// in the specified chat room for the current user
  static Future<void> markMessagesAsRead(String roomId) async {
    try {
      log('🔄 Marking messages as read for room: $roomId', name: 'ChatAPI');
      
      final response = await _apiService.post(
        '/api/chat/rooms/$roomId/mark_read/',
        data: {},
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        log('✅ Messages marked as read for room: $roomId', name: 'ChatAPI');
      } else {
        log('❌ Failed to mark messages as read - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to mark messages as read',
        );
      }
    } catch (e) {
      log('❌ Error marking messages as read: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Create a new chat room between two users
  /// 
  /// [userId1] - First participant ID
  /// [userId2] - Second participant ID
  /// [serviceRequestId] - Optional service request ID to associate with the room
  /// 
  /// Returns the newly created chat room
  static Future<ChatRoomModel> createChatRoom(
    String userId1,
    String userId2, {
    String? serviceRequestId,
  }) async {
    try {
      log('🔄 Creating chat room between users: $userId1, $userId2', name: 'ChatAPI');
      log('🔍 [DIRECT CHAT API] === API Call Debug ===');
      log('🔍 [DIRECT CHAT API] User ID 1: $userId1');
      log('🔍 [DIRECT CHAT API] User ID 2: $userId2');
      log('🔍 [DIRECT CHAT API] Service Request ID: $serviceRequestId');

      // Match the working format: service_request_id first, then participants
      final roomData = <String, dynamic>{
        if (serviceRequestId != null) 'service_request_id': serviceRequestId,
        'participants': [userId1, userId2],
      };

      log('🔍 [DIRECT CHAT API] === Request Payload ===');
      log('🔍 [DIRECT CHAT API] participants: [$userId1, $userId2]');
      log('🔍 [DIRECT CHAT API] service_request_id: $serviceRequestId');
      log('🔍 [DIRECT CHAT API] Full payload: $roomData');
      log('🔍 [DIRECT CHAT API] Endpoint: POST /api/chat/rooms/get_or_create/');

      // Use the get_or_create endpoint for all chat room creation for consistency
      final response = await _apiService.post(
        '/api/chat/rooms/get_or_create/',
        data: roomData,
      );

      log('🔍 [DIRECT CHAT API] === API Response ===');
      log('🔍 [DIRECT CHAT API] Status Code: ${response.statusCode}');
      log('🔍 [DIRECT CHAT API] Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle the nested chat_room structure from get_or_create endpoint
        final responseData = response.data as Map<String, dynamic>;
        final chatRoomData = responseData['chat_room'] as Map<String, dynamic>;
        final chatRoom = _mapChatRoomFromBackend(chatRoomData);
        log('✅ Chat room created: ${chatRoom.chatRoomId}', name: 'ChatAPI');
        return chatRoom;
      } else {
        log('❌ Failed to create chat room - Status: ${response.statusCode}', name: 'ChatAPI');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create chat room',
        );
      }
    } catch (e) {
      log('❌ Error creating chat room: $e', name: 'ChatAPI');
      rethrow;
    }
  }

  // =============================================================================
  // ERROR HANDLING
  // =============================================================================

  /// Handle chat-specific API errors
  /// 
  /// This method provides user-friendly error messages
  /// for common chat API error scenarios
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Authentication required. Please log in again.';
        case 403:
          return 'You don\'t have permission to access this chat.';
        case 404:
          return 'Chat room not found.';
        case 405:
          return 'Operation not allowed. Please try again.';
        case 429:
          return 'Too many requests. Please wait a moment before trying again.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Network error. Please check your connection.';
      }
    }
    
    return 'An unexpected error occurred.';
  }

  // =============================================================================
  // PRIVATE MAPPING METHODS
  // =============================================================================

  /// Map backend chat room JSON to ChatRoomModel
  static ChatRoomModel _mapChatRoomFromBackend(Map<String, dynamic> json) {
    return ChatRoomModel(
      chatRoomId: json['id']?.toString() ?? '',
      participantIds: List<String>.from(json['participants'] ?? []),
      lastMessage: json['last_message']?['message'],
      lastMessageTime: json['last_message']?['timestamp'] != null
          ? DateTime.parse(json['last_message']['timestamp'])
          : null,
      unreadCountForReceiver: json['unread_count'] ?? 0,
      lastSenderId: json['last_message']?['sender']?.toString(),
    );
  }

  /// Map backend message JSON to ChatMessageModel
  static ChatMessageModel _mapMessageFromBackend(Map<String, dynamic> json) {
    log('🔍 Mapping message JSON: $json', name: 'ChatAPI');
    
    final messageContent = json['content'] ?? json['message'] ?? '';
    
    // Extract senderId from sender object or fallback to string
    String senderId = '';
    if (json['sender'] is Map<String, dynamic>) {
      senderId = json['sender']['id']?.toString() ?? '';
    } else {
      senderId = json['sender']?.toString() ?? '';
    }
    
    // Extract receiverId from receiver object or fallback to string
    String receiverId = '';
    if (json['receiver'] is Map<String, dynamic>) {
      receiverId = json['receiver']['id']?.toString() ?? '';
    } else {
      receiverId = json['receiver']?.toString() ?? '';
    }
    
    log('📝 Message details: content="$messageContent", senderId="$senderId", receiverId="$receiverId"', name: 'ChatAPI');
    
    return ChatMessageModel(
      messageId: json['id']?.toString() ?? '',
      chatRoomId: json['chat_room']?.toString() ?? '',
      senderId: senderId,
      receiverId: receiverId,
      message: messageContent,
      isSeen: json['is_read'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      senderName: json['sender_name'],
      senderProfilePic: json['sender_profile_pic'],
    );
  }
}
