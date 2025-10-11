// lib/services/chat_api_service.dart

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
      
      final response = await _apiService.get('/api/chat/rooms/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> roomsJson = data['results'] ?? data;
        
        final chatRooms = roomsJson
            .map((json) => _mapChatRoomFromBackend(json as Map<String, dynamic>))
            .toList();
        
        return chatRooms;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch chat rooms',
        );
      }
    } catch (e) {
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
      
      // Enhanced logging for debugging
      
      final requestData = {
        'service_request_id': requestId,
        'participants': [userId1, userId2],
      };
      
      
      // Enhanced logging for exact payload
      
      
      final response = await _apiService.post(
        '/api/chat/rooms/get_or_create/',
        data: requestData,
      );
      
      
      // Enhanced response logging
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle the nested chat_room structure from get_or_create endpoint
        final responseData = response.data as Map<String, dynamic>;
        
        final chatRoomData = responseData['chat_room'] as Map<String, dynamic>;
        
        final chatRoom = _mapChatRoomFromBackend(chatRoomData);
        
        
        return chatRoom;
      } else {
        
        
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to get or create chat room',
        );
      }
    } catch (e) {
      
      
      rethrow;
    }
  }

  /// Get chat room details by ID
  static Future<ChatRoomModel> getChatRoom(String roomId) async {
    try {
      
      final response = await _apiService.get('/api/chat/rooms/$roomId/');
      
      if (response.statusCode == 200) {
        final chatRoom = _mapChatRoomFromBackend(response.data as Map<String, dynamic>);
        return chatRoom;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch chat room',
        );
      }
    } catch (e) {
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
        
        
        // Log first message for debugging
        if (messages.isNotEmpty) {
        }
        
        return messages;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to fetch messages',
        );
      }
    } catch (e) {
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
      
      
      final response = await _apiService.post(
        '/api/chat/rooms/$roomId/send_message/',
        data: messageData,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final message = _mapMessageFromBackend(response.data as Map<String, dynamic>);
        return message;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to send message',
        );
      }
    } catch (e) {
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
      
      final response = await _apiService.post(
        '/api/chat/rooms/$roomId/mark_read/',
        data: {},
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to mark messages as read',
        );
      }
    } catch (e) {
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

      // Match the working format: service_request_id first, then participants
      final roomData = <String, dynamic>{
        if (serviceRequestId != null) 'service_request_id': serviceRequestId,
        'participants': [userId1, userId2],
      };


      // Use the get_or_create endpoint for all chat room creation for consistency
      final response = await _apiService.post(
        '/api/chat/rooms/get_or_create/',
        data: roomData,
      );

      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle the nested chat_room structure from get_or_create endpoint
        final responseData = response.data as Map<String, dynamic>;
        final chatRoomData = responseData['chat_room'] as Map<String, dynamic>;
        final chatRoom = _mapChatRoomFromBackend(chatRoomData);
        return chatRoom;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create chat room',
        );
      }
    } catch (e) {
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
