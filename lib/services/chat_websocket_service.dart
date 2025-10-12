// lib/services/chat_websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/chat_message_model.dart';

/// Connection states for WebSocket
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

/// WebSocket Service for real-time chat messaging
/// 
/// Features:
/// - Real-time message delivery
/// - JWT authentication
/// - Auto-reconnection with exponential backoff
/// - Connection state management
/// - Message echo handling
class ChatWebSocketService {
  // =============================================================================
  // PRIVATE VARIABLES
  // =============================================================================
  
  static WebSocketChannel? _channel;
  static String? _currentRoomId;
  static String? _currentUserId;
  static Timer? _reconnectTimer;
  static Timer? _heartbeatTimer;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _baseReconnectDelay = 1000; // milliseconds
  
  /// Private connection status tracking
  static bool _isConnected = false;
  
  /// Stream controller for incoming messages
  static final StreamController<ChatMessageModel> _messageController = 
      StreamController<ChatMessageModel>.broadcast();
  
  /// Stream controller for connection state changes
  static final StreamController<ConnectionState> _connectionStateController = 
      StreamController<ConnectionState>.broadcast();

  static ConnectionState _currentState = ConnectionState.disconnected;

  // =============================================================================
  // PUBLIC GETTERS
  // =============================================================================
  
  /// Stream of incoming chat messages
  static Stream<ChatMessageModel> get messageStream => _messageController.stream;
  
  /// Stream of connection state changes
  static Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Current connection state
  static ConnectionState get connectionState => _currentState;
  
  /// Whether WebSocket is currently connected
  static bool get isConnected => _channel != null && _isConnected;
  
  /// Current room ID
  static String? get currentRoomId => _currentRoomId;

  // =============================================================================
  // CONNECTION MANAGEMENT
  // =============================================================================

  /// Connect to a chat room WebSocket
  /// 
  /// [roomId] - The chat room ID to connect to
  /// [userId] - The current user ID for message handling
  static Future<void> connect(String roomId, String userId) async {
    if (_currentRoomId == roomId && isConnected) {
      return;
    }
    
    // Disconnect from previous room if connected
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await disconnect();
    }
    
    _currentRoomId = roomId;
    _currentUserId = userId;
    _updateConnectionState(ConnectionState.connecting);
    
    try {
      
      // Get JWT token from existing auth system
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      // Build WebSocket URL
      final wsUrl = _buildWebSocketUrl(roomId, token);
      
      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Set up message listener
      _setupMessageListener();
      
      // Set connection as ready immediately since backend is working fine
      _isConnected = true;
      
      // Start heartbeat
      _startHeartbeat();
      
      // Reset reconnect attempts on successful connection
      _reconnectAttempts = 0;
      _updateConnectionState(ConnectionState.connected);
      
      
    } catch (e) {
      // Error handled silently
      _isConnected = false;
      _updateConnectionState(ConnectionState.error);
      _scheduleReconnect();
      rethrow;
    }
  }

  /// Disconnect from current WebSocket
  static Future<void> disconnect() async {
    if (_channel == null) return;
    
    
    _stopHeartbeat();
    _stopReconnectTimer();
    
    try {
      await _channel?.sink.close(status.normalClosure);
    } catch (e) {
      // Error handled silently
      // Channel already closed or error during close
    } finally {
      _channel = null;
      _currentRoomId = null;
      _currentUserId = null;
      _reconnectAttempts = 0;
      _isConnected = false;
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  /// Force reconnect to current room
  static Future<void> reconnect() async {
    if (_currentRoomId != null && _currentUserId != null) {
      await disconnect();
      await connect(_currentRoomId!, _currentUserId!);
    }
  }

  // =============================================================================
  // MESSAGE HANDLING
  // =============================================================================

  /// Send a message through WebSocket
  /// 
  /// Note: This should be used alongside REST API calls for reliability
  static void sendMessage(String content) {
    if (!isConnected || _channel == null) {
      return;
    }
    
    try {
      final message = {
        'type': 'chat_message',
        'content': content.trim(),
        'sender_id': _currentUserId,
        'room_id': _currentRoomId,
      };

      _channel!.sink.add(json.encode(message));

    } catch (e) {
      // Error handled silently
      // Failed to send chat message
    }
  }

  /// Send typing indicator
  static void sendTypingIndicator(bool isTyping) {
    if (!isConnected || _channel == null) return;
    
    try {
      final message = {
        'type': 'typing_indicator',
        'is_typing': isTyping,
        'sender_id': _currentUserId,
        'room_id': _currentRoomId,
      };

      _channel!.sink.add(json.encode(message));

    } catch (e) {
      // Error handled silently
      // Failed to send typing indicator
    }
  }

  // =============================================================================
  // PRIVATE METHODS
  // =============================================================================

  /// Get authentication token from existing auth system with freshness check
  static Future<String?> _getAuthToken() async {
    try {
      // Ensure we have fresh tokens before WebSocket connection
      final refreshed = await ApiService.instance.refreshTokenIfNeeded();
      if (!refreshed) {
      }

      // Get the (potentially refreshed) token
      return await ApiService.instance.getStoredAccessToken();
    } catch (e) {
      // Error handled silently
      return null;
    }
  }

  /// Build WebSocket URL with authentication
  static String _buildWebSocketUrl(String roomId, String token) {
    // Convert HTTP base URL to WebSocket URL
    String wsBaseUrl = ApiConfig.baseUrl
        .replaceAll('http://', 'ws://')
        .replaceAll('https://', 'wss://');
    
    return '$wsBaseUrl/ws/chat/$roomId/?token=$token';
  }

  /// Set up message listener for incoming WebSocket messages
  static void _setupMessageListener() {
    _channel?.stream.listen(
      (data) {
        
        // First message received confirms connection is working
        if (!_isConnected) {
          _isConnected = true;
          _updateConnectionState(ConnectionState.connected);
        }
        
        try {
          final Map<String, dynamic> messageData = json.decode(data);
          _handleIncomingMessage(messageData);
        } catch (e) {
      // Error handled silently
          // Failed to parse incoming message
        }
      },
      onError: (error) {
        _isConnected = false;
        _updateConnectionState(ConnectionState.error);
        _scheduleReconnect();
      },
      onDone: () {
        _isConnected = false;
        if (_currentState == ConnectionState.connected) {
          _updateConnectionState(ConnectionState.disconnected);
          _scheduleReconnect();
        }
      },
    );
  }

  /// Handle incoming WebSocket messages
  static void _handleIncomingMessage(Map<String, dynamic> messageData) {
    try {
      final messageType = messageData['type'];
      
      switch (messageType) {
        case 'chat_message':
          _handleChatMessage(messageData);
          break;
        case 'typing_indicator':
          _handleTypingIndicator(messageData);
          break;
        case 'connection_ack':
          break;
        case 'error':
          break;
        default:
      }
    } catch (e) {
      // Error handled silently
      // Failed to handle incoming message
    }
  }

  /// Handle incoming chat messages
  static void _handleChatMessage(Map<String, dynamic> messageData) {
    
    // Add debug logging BEFORE processing
    
    // Verify nested message object exists
    final messagePayload = messageData['message'];
    if (messagePayload == null) {
      return;
    }
    
    try {
      // Verify stream controller is initialized and ready
      
      // Extract senderId from sender object or fallback to string
      String senderId = '';
      if (messagePayload['sender'] is Map<String, dynamic>) {
        senderId = messagePayload['sender']['id']?.toString() ?? '';
      } else if (messageData['sender'] is Map<String, dynamic>) {
        senderId = messageData['sender']['id']?.toString() ?? '';
      } else {
        senderId = messagePayload['sender_id']?.toString() ?? 
                   messageData['sender_id']?.toString() ?? 
                   messagePayload['sender']?.toString() ?? 
                   messageData['sender']?.toString() ?? '';
      }
      
      // Extract receiverId from receiver object or fallback to string
      String receiverId = '';
      if (messagePayload['receiver'] is Map<String, dynamic>) {
        receiverId = messagePayload['receiver']['id']?.toString() ?? '';
      } else if (messageData['receiver'] is Map<String, dynamic>) {
        receiverId = messageData['receiver']['id']?.toString() ?? '';
      } else {
        receiverId = messagePayload['receiver_id']?.toString() ?? 
                     messageData['receiver_id']?.toString() ?? 
                     messagePayload['receiver']?.toString() ?? 
                     messageData['receiver']?.toString() ?? '';
      }
      
      
      // Map WebSocket message format to ChatMessageModel
      final message = ChatMessageModel(
        messageId: messagePayload['id']?.toString() ?? '',
        chatRoomId: messagePayload['room_id']?.toString() ?? _currentRoomId ?? '',
        senderId: senderId,
        receiverId: receiverId,
        message: messagePayload['content'] ?? '',
        timestamp: messagePayload['timestamp'] != null 
            ? DateTime.parse(messagePayload['timestamp'])
            : DateTime.now(),
        isSeen: messagePayload['is_read'] ?? false,
        senderName: messagePayload['sender_name'],
        senderProfilePic: messagePayload['sender_profile_pic'],
      );
      
      
      // Robust echo prevention with normalized string comparison
      final normalizedSenderId = message.senderId.toString().trim().toLowerCase();
      final normalizedCurrentUserId = (_currentUserId ?? '').toString().trim().toLowerCase();
      
      // Debug logging for message processing
      
      // Verify stream controller state before emission
      if (_messageController.isClosed) {
        return;
      }
      
      // Enhanced filtering logic with explicit logging
      final isFromCurrentUser = normalizedSenderId == normalizedCurrentUserId;
      final hasValidCurrentUser = normalizedCurrentUserId.isNotEmpty;
      
      
      // CRITICAL: Add explicit execution tracking
      
      // Only emit messages that are not from the current user (avoid echo)
      if (!isFromCurrentUser && hasValidCurrentUser) {
        
        try {
          _messageController.add(message);
        } catch (streamError) {
          // Failed to add message to stream
        }
      } else {
      }



    } catch (e) {
      // Error handled silently
      // Failed to process chat message
    }
  }

  /// Handle typing indicators
  static void _handleTypingIndicator(Map<String, dynamic> messageData) {
    // TODO: Implement typing indicator handling
    // This would emit to a separate typing indicator stream
  }

  /// Update connection state and notify listeners
  static void _updateConnectionState(ConnectionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _connectionStateController.add(newState);
    }
  }

  /// Schedule reconnection with exponential backoff
  static void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateConnectionState(ConnectionState.error);
      return;
    }
    
    if (_currentRoomId == null || _currentUserId == null) {
      return;
    }
    
    _reconnectAttempts++;
    final delay = _baseReconnectDelay * (1 << (_reconnectAttempts - 1)); // Exponential backoff
    
    _updateConnectionState(ConnectionState.reconnecting);
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect(_currentRoomId!, _currentUserId!);
    });
  }

  /// Start heartbeat to keep connection alive
  static void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isConnected && _channel != null) {
        try {
          final heartbeat = {
            'type': 'heartbeat',
            'timestamp': DateTime.now().toIso8601String(),
          };
          _channel!.sink.add(json.encode(heartbeat));
        } catch (e) {
      // Error handled silently
          // Failed to send heartbeat
        }
      }
    });
  }

  /// Stop heartbeat timer
  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Stop reconnect timer
  static void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // =============================================================================
  // CLEANUP
  // =============================================================================

  /// Dispose all resources and close streams
  static Future<void> dispose() async {
    await disconnect();
    
    if (!_messageController.isClosed) {
      await _messageController.close();
    }
    
    if (!_connectionStateController.isClosed) {
      await _connectionStateController.close();
    }
    
  }
}
