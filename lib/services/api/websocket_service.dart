/// WebSocket Service for Real-time Notifications
/// Provides auto-reconnection, message handling, and state management
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:get/get.dart';
import '../../config/api_config.dart';
import '../models/notification_response.dart';
import '../api_service.dart';

/// WebSocket connection states
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket message types from backend
enum WebSocketMessageType {
  notification,
  unreadCount,
  connectionAck,
  error,
  unknown,
}

/// WebSocket message wrapper
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic>? data;
  final String? error;

  const WebSocketMessage({
    required this.type,
    this.data,
    this.error,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String?;
    final type = _parseMessageType(typeString);
    
    return WebSocketMessage(
      type: type,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  static WebSocketMessageType _parseMessageType(String? typeString) {
    switch (typeString) {
      case 'notification':
        return WebSocketMessageType.notification;
      case 'unread_count':
        return WebSocketMessageType.unreadCount;
      case 'connection_ack':
        return WebSocketMessageType.connectionAck;
      case 'error':
        return WebSocketMessageType.error;
      default:
        return WebSocketMessageType.unknown;
    }
  }
}

/// Callback type for notification messages
typedef NotificationCallback = void Function(NotificationResponse notification);
typedef UnreadCountCallback = void Function(int unreadCount);
typedef ConnectionStateCallback = void Function(WebSocketState state);
typedef ErrorCallback = void Function(String error);

/// WebSocket Service for real-time notifications
class WebSocketService extends GetxService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  // Connection state
  final Rx<WebSocketState> _connectionState = WebSocketState.disconnected.obs;
  WebSocketState get connectionState => _connectionState.value;

  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;
  static const int baseReconnectDelay = 1000; // 1 second
  static const int maxReconnectDelay = 30000; // 30 seconds
  static const int pingInterval = 30; // 30 seconds

  // Authentication
  String? _authToken;
  String? _userId;

  // Callbacks
  NotificationCallback? _onNotification;
  UnreadCountCallback? _onUnreadCount;
  ConnectionStateCallback? _onConnectionStateChange;
  ErrorCallback? _onError;

  // Connection status getters
  bool get isConnected => _connectionState.value == WebSocketState.connected;
  bool get isConnecting => _connectionState.value == WebSocketState.connecting;
  bool get isReconnecting => _connectionState.value == WebSocketState.reconnecting;
  bool get hasError => _connectionState.value == WebSocketState.error;

  /// Initialize WebSocket service with authentication
  void initialize({
    required String authToken,
    required String userId,
    NotificationCallback? onNotification,
    UnreadCountCallback? onUnreadCount,
    ConnectionStateCallback? onConnectionStateChange,
    ErrorCallback? onError,
  }) {
    
    _authToken = authToken;
    _userId = userId;
    _onNotification = onNotification;
    _onUnreadCount = onUnreadCount;
    _onConnectionStateChange = onConnectionStateChange;
    _onError = onError;

    // Listen to connection state changes
    _connectionState.listen((state) {
      _onConnectionStateChange?.call(state);
    });
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_authToken == null || _userId == null) {
      _setConnectionState(WebSocketState.error);
      _onError?.call('Authentication required');
      return;
    }

    if (isConnecting || isConnected) {
      return;
    }

    _setConnectionState(WebSocketState.connecting);
    
    try {
      await _createConnection();
    } catch (e) {
      _setConnectionState(WebSocketState.error);
      _onError?.call(e.toString());
      _scheduleReconnect();
    }
  }

  /// Create WebSocket connection
  Future<void> _createConnection() async {
    // Construct WebSocket URL with authentication
    final wsUrl = _buildWebSocketUrl();

    try {
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

      _setConnectionState(WebSocketState.connected);
      _reconnectAttempts = 0;
      
      
      // Send connection acknowledgment
      _sendMessage({
        'type': 'connection_ack',
        'user_id': _userId,
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Build WebSocket URL with authentication
  String _buildWebSocketUrl() {
    final baseUrl = ApiConfig.getWebSocketBaseUrl();
    return '$baseUrl/ws/notifications/?token=$_authToken';
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic rawMessage) {
    try {
      
      final Map<String, dynamic> messageJson = jsonDecode(rawMessage);
      final message = WebSocketMessage.fromJson(messageJson);

      switch (message.type) {
        case WebSocketMessageType.notification:
          _handleNotificationMessage(message.data!);
          break;
          
        case WebSocketMessageType.unreadCount:
          _handleUnreadCountMessage(message.data!);
          break;
          
        case WebSocketMessageType.connectionAck:
          break;
          
        case WebSocketMessageType.error:
          _handleServerError(message.error ?? 'Unknown server error');
          break;
          
        case WebSocketMessageType.unknown:
          break;
      }
    } catch (e) {
    }
  }

  /// Handle notification message
  void _handleNotificationMessage(Map<String, dynamic> data) {
    try {
      final notification = NotificationResponse.fromJson(data);
      _onNotification?.call(notification);
    } catch (e) {
    }
  }

  /// Handle unread count message
  void _handleUnreadCountMessage(Map<String, dynamic> data) {
    try {
      final unreadCount = data['unread_count'] as int? ?? 0;
      _onUnreadCount?.call(unreadCount);
    } catch (e) {
    }
  }

  /// Handle server error message
  void _handleServerError(String error) {
    _onError?.call('Server error: $error');
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _setConnectionState(WebSocketState.error);
    _onError?.call(error.toString());
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    _setConnectionState(WebSocketState.disconnected);
    _cleanup();
    _scheduleReconnect();
  }

  /// Send message to WebSocket server
  void _sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      return;
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: pingInterval), (timer) {
      if (isConnected) {
        _sendMessage({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }

  /// Set connection state and notify listeners
  void _setConnectionState(WebSocketState state) {
    _connectionState.value = state;
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _setConnectionState(WebSocketState.error);
      _onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _calculateReconnectDelay();
    
    _setConnectionState(WebSocketState.reconnecting);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect();
    });
  }

  /// Calculate reconnection delay with exponential backoff
  int _calculateReconnectDelay() {
    final delay = baseReconnectDelay * (1 << (_reconnectAttempts - 1));
    return delay > maxReconnectDelay ? maxReconnectDelay : delay;
  }

  /// Update authentication token
  void updateAuthToken(String newToken) {
    if (_authToken != newToken) {
      _authToken = newToken;

      // Reconnect with new token
      if (isConnected) {
        disconnect();
        connect();
      }
    }
  }

  /// Refresh authentication token and reconnect if needed
  Future<void> refreshAuthToken() async {
    try {
      // Get ApiService instance
      final apiService = Get.find<ApiService>();

      // Ensure we have fresh tokens
      await apiService.refreshTokenIfNeeded();
      final freshToken = apiService.accessToken;

      if (freshToken != null && freshToken != _authToken) {
        updateAuthToken(freshToken);
      }
    } catch (e) {
    }
  }

  /// Mark notification as read via WebSocket
  void markNotificationAsRead(String notificationId) {
    _sendMessage({
      'type': 'mark_as_read',
      'notification_id': notificationId,
    });
  }

  /// Mark all notifications as read via WebSocket
  void markAllNotificationsAsRead() {
    _sendMessage({
      'type': 'mark_all_as_read',
    });
  }

  /// Request unread count update
  void requestUnreadCount() {
    _sendMessage({
      'type': 'get_unread_count',
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _cleanup();
    _setConnectionState(WebSocketState.disconnected);
    _reconnectAttempts = 0;
  }

  /// Cleanup resources
  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    
    _channel?.sink.close();
    _channel = null;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Check if WebSocket is available (network connectivity)
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get connection info for debugging
  Map<String, dynamic> getConnectionInfo() {
    return {
      'state': _connectionState.value.toString(),
      'reconnect_attempts': _reconnectAttempts,
      'is_connected': isConnected,
      'has_auth_token': _authToken != null,
      'user_id': _userId,
    };
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
