/// Real-time WebSocket Integration Examples
/// Demonstrates complete WebSocket integration with NotificationController
library websocket_integration_examples;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lib/controllers/notification_controller.dart';
import '../lib/services/api/websocket_service.dart';

/// Real-time notification screen with WebSocket integration
class RealTimeNotificationScreen extends StatefulWidget {
  const RealTimeNotificationScreen({super.key});

  @override
  State<RealTimeNotificationScreen> createState() => _RealTimeNotificationScreenState();
}

class _RealTimeNotificationScreenState extends State<RealTimeNotificationScreen> {
  late NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    notificationController = Get.find<NotificationController>();
    
    // Connect WebSocket when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectWebSocket();
    });
  }

  /// Connect to WebSocket for real-time notifications
  Future<void> _connectWebSocket() async {
    await notificationController.connectWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Notifications'),
        actions: [
          // WebSocket connection status indicator
          Obx(() => _buildConnectionStatusIcon()),
          
          // Unread count badge
          Obx(() => notificationController.unreadCount.value > 0
              ? Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notificationController.unreadCount.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status bar
          Obx(() => _buildConnectionStatusBar()),
          
          // Notifications list
          Expanded(
            child: Obx(() {
              if (notificationController.isLoading.value && 
                  notificationController.notifications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notificationController.notifications.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => notificationController.refreshNotifications(),
                child: ListView.builder(
                  itemCount: notificationController.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationController.notifications[index];
                    return _buildNotificationCard(notification, index);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showWebSocketInfo,
        child: const Icon(Icons.info),
      ),
    );
  }

  /// Build WebSocket connection status icon
  Widget _buildConnectionStatusIcon() {
    final state = notificationController.webSocketState.value;
    
    IconData icon;
    Color color;
    
    switch (state) {
      case WebSocketState.connected:
        icon = Icons.wifi;
        color = Colors.green;
        break;
      case WebSocketState.connecting:
      case WebSocketState.reconnecting:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case WebSocketState.error:
        icon = Icons.error;
        color = Colors.red;
        break;
      case WebSocketState.disconnected:
        icon = Icons.wifi_off;
        color = Colors.grey;
        break;
    }
    
    return Container(
      margin: const EdgeInsets.all(8),
      child: Icon(icon, color: color, size: 24),
    );
  }

  /// Build connection status bar
  Widget _buildConnectionStatusBar() {
    final state = notificationController.webSocketState.value;
    
    String statusText;
    Color backgroundColor;
    IconData statusIcon;
    
    switch (state) {
      case WebSocketState.connected:
        statusText = 'Real-time updates active';
        backgroundColor = Colors.green.shade100;
        statusIcon = Icons.check_circle;
        break;
      case WebSocketState.connecting:
        statusText = 'Connecting to real-time updates...';
        backgroundColor = Colors.orange.shade100;
        statusIcon = Icons.sync;
        break;
      case WebSocketState.reconnecting:
        statusText = 'Reconnecting to real-time updates...';
        backgroundColor = Colors.orange.shade100;
        statusIcon = Icons.sync;
        break;
      case WebSocketState.error:
        statusText = 'Real-time updates unavailable - using fallback';
        backgroundColor = Colors.red.shade100;
        statusIcon = Icons.error;
        break;
      case WebSocketState.disconnected:
        statusText = 'Using standard refresh mode';
        backgroundColor = Colors.grey.shade100;
        statusIcon = Icons.refresh;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(statusIcon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (state == WebSocketState.error || state == WebSocketState.disconnected)
            TextButton(
              onPressed: () => notificationController.connectWebSocket(),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Build notification card with real-time indicators
  Widget _buildNotificationCard(notification, int index) {
    final isUnread = notification.status == 'unread';
    
    // Show animation for new notifications (first 3 items)
    final isNew = index < 3 && isUnread;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: isNew ? Border.all(color: Colors.blue, width: 2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Card(
        child: ListTile(
          leading: Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnread ? Colors.blue : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.body),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              // Real-time indicator for new notifications
              if (isNew)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fiber_new,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            _getNotificationTitle(notification.body),
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getNotificationMessage(notification.body)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    _formatTime(notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: isUnread
              ? IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () => notificationController.markAsRead(
                    notification.notificationId,
                  ),
                )
              : const Icon(Icons.check_circle, color: Colors.green),
          isThreeLine: true,
          onTap: () {
            if (isUnread) {
              notificationController.markAsRead(notification.notificationId);
            }
          },
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() => Icon(
            notificationController.isWebSocketConnected.value
                ? Icons.notifications_active
                : Icons.notifications_none,
            size: 64,
            color: Colors.grey,
          )),
          const SizedBox(height: 16),
          const Text('No notifications yet'),
          const SizedBox(height: 8),
          Obx(() => Text(
            notificationController.isWebSocketConnected.value
                ? 'You\'ll receive real-time notifications here'
                : 'Pull down to refresh',
            style: Theme.of(context).textTheme.bodySmall,
          )),
        ],
      ),
    );
  }

  /// Show WebSocket connection information
  void _showWebSocketInfo() {
    final service = WebSocketService.instance;
    final connectionInfo = service.getConnectionInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WebSocket Connection Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: ${connectionInfo['state']}'),
            Text('Connected: ${connectionInfo['is_connected']}'),
            Text('Reconnect Attempts: ${connectionInfo['reconnect_attempts']}'),
            Text('Has Auth Token: ${connectionInfo['has_auth_token']}'),
            Text('User ID: ${connectionInfo['user_id'] ?? 'None'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!notificationController.isWebSocketConnected.value)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                notificationController.connectWebSocket();
              },
              child: const Text('Retry Connection'),
            ),
        ],
      ),
    );
  }

  /// Get notification icon
  IconData _getNotificationIcon(String body) {
    final lowerBody = body.toLowerCase();
    if (lowerBody.contains('request')) return Icons.assignment;
    if (lowerBody.contains('message')) return Icons.message;
    if (lowerBody.contains('reminder')) return Icons.alarm;
    return Icons.notifications;
  }

  /// Get notification title
  String _getNotificationTitle(String body) {
    final lines = body.split('\n');
    return lines.isNotEmpty ? lines.first : 'Notification';
  }

  /// Get notification message
  String _getNotificationMessage(String body) {
    final lines = body.split('\n');
    return lines.length > 1 ? lines.sublist(1).join('\n') : '';
  }

  /// Format timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  void dispose() {
    // WebSocket will be managed by the controller's lifecycle
    super.dispose();
  }
}

/// Examples of WebSocket integration patterns
class WebSocketIntegrationExamples {
  
  /// Example: Initialize WebSocket in app startup
  static Future<void> initializeRealTimeNotifications() async {
    // Get the notification controller
    final notificationController = Get.find<NotificationController>();
    
    // WebSocket will auto-connect when loadNotification() is called
    await notificationController.loadNotification();
    
    print('✅ Real-time notifications initialized');
  }
  
  /// Example: Handle authentication changes
  static Future<void> onUserLogin(String newToken) async {
    final notificationController = Get.find<NotificationController>();
    
    // Update WebSocket authentication
    notificationController.updateWebSocketAuth(newToken);
    
    // Connect WebSocket with new token
    await notificationController.connectWebSocket();
    
    print('✅ WebSocket updated for new user session');
  }
  
  /// Example: Handle user logout
  static void onUserLogout() {
    final notificationController = Get.find<NotificationController>();
    
    // Disconnect WebSocket
    notificationController.disconnectWebSocket();
    
    print('✅ WebSocket disconnected for user logout');
  }
  
  /// Example: Check if real-time updates are active
  static bool isRealTimeActive() {
    final notificationController = Get.find<NotificationController>();
    return notificationController.isWebSocketConnected.value;
  }
  
  /// Example: Manual WebSocket reconnection
  static Future<void> reconnectWebSocket() async {
    final notificationController = Get.find<NotificationController>();
    
    // Disconnect first
    notificationController.disconnectWebSocket();
    
    // Wait a moment
    await Future.delayed(const Duration(seconds: 1));
    
    // Reconnect
    await notificationController.connectWebSocket();
    
    print('✅ WebSocket manually reconnected');
  }
  
  /// Example: Listen to WebSocket state changes
  static void setupWebSocketStateListener() {
    final notificationController = Get.find<NotificationController>();
    
    // Listen to WebSocket state changes
    notificationController.webSocketState.listen((state) {
      switch (state) {
        case WebSocketState.connected:
          print('🟢 Real-time notifications connected');
          break;
        case WebSocketState.disconnected:
          print('🔴 Real-time notifications disconnected');
          break;
        case WebSocketState.error:
          print('❌ Real-time notifications error');
          break;
        case WebSocketState.reconnecting:
          print('🟡 Real-time notifications reconnecting...');
          break;
        case WebSocketState.connecting:
          print('🟡 Real-time notifications connecting...');
          break;
      }
    });
  }
}

/// Integration with existing app lifecycle
class AppLifecycleIntegration extends WidgetsBindingObserver {
  final NotificationController notificationController = Get.find<NotificationController>();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - reconnect WebSocket and refresh notifications
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App paused - WebSocket stays connected for background notifications
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        // App terminated - cleanup WebSocket
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        // App inactive - no action needed
        break;
      case AppLifecycleState.hidden:
        // App hidden - no action needed
        break;
    }
  }

  void _onAppResumed() {
    print('📱 App resumed - refreshing notifications and WebSocket');
    
    // Refresh notifications
    notificationController.refreshNotifications();
    
    // Reconnect WebSocket if disconnected
    if (!notificationController.isWebSocketConnected.value) {
      notificationController.connectWebSocket();
    }
  }

  void _onAppPaused() {
    print('📱 App paused - WebSocket remains connected for background updates');
    // WebSocket stays connected to receive background notifications
  }

  void _onAppDetached() {
    print('📱 App detached - cleaning up WebSocket');
    notificationController.disconnectWebSocket();
  }
}

/// Usage in main.dart:
/// 
/// ```dart
/// void main() {
///   runApp(MyApp());
/// }
/// 
/// class MyApp extends StatefulWidget {
///   @override
///   _MyAppState createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> {
///   final _lifecycleObserver = AppLifecycleIntegration();
/// 
///   @override
///   void initState() {
///     super.initState();
///     WidgetsBinding.instance.addObserver(_lifecycleObserver);
///   }
/// 
///   @override
///   void dispose() {
///     WidgetsBinding.instance.removeObserver(_lifecycleObserver);
///     super.dispose();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return GetMaterialApp(
///       // your app configuration
///     );
///   }
/// }
/// ```
