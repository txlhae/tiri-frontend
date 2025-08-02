/// Phase 3 Integration Example - Updated NotificationController Usage
/// Demonstrates how to use the migrated controller with Django API
library notification_controller_examples;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lib/controllers/notification_controller.dart';
import '../lib/models/notification_model.dart';

/// Example widget showing complete NotificationController integration
class NotificationScreenExample extends StatefulWidget {
  const NotificationScreenExample({super.key});

  @override
  State<NotificationScreenExample> createState() => _NotificationScreenExampleState();
}

class _NotificationScreenExampleState extends State<NotificationScreenExample> {
  late NotificationController notificationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    notificationController = Get.find<NotificationController>();
    _setupScrollListener();
  }

  /// Setup infinite scroll for pagination
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (notificationController.canLoadMore) {
          notificationController.loadMoreNotifications();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
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
                    notificationController.unreadCount.value > 99 
                        ? '99+' 
                        : notificationController.unreadCount.value.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : const SizedBox.shrink(),
          ),
          
          // Menu actions
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await notificationController.markAllAsRead();
                  break;
                case 'refresh':
                  await notificationController.refreshNotifications();
                  break;
                case 'statistics':
                  _showStatistics();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark All Read'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh'),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Text('Statistics'),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        // Loading state
        if (notificationController.isLoading.value && 
            notificationController.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error state
        if (notificationController.hasError.value && 
            notificationController.notifications.isEmpty) {
          return _buildErrorState();
        }

        // Empty state
        if (notificationController.notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications yet'),
              ],
            ),
          );
        }

        // Notifications list
        return RefreshIndicator(
          onRefresh: () => notificationController.refreshNotifications(),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: notificationController.notifications.length + 1, // +1 for load more
            itemBuilder: (context, index) {
              // Load more indicator
              if (index == notificationController.notifications.length) {
                return _buildLoadMoreIndicator();
              }

              final notification = notificationController.notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      }),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = notification.status == 'unread';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isUnread ? Colors.blue : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _getNotificationTitle(notification),
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getNotificationMessage(notification)),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
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
          // Handle notification tap
          if (isUnread) {
            notificationController.markAsRead(notification.notificationId);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            notificationController.errorMessage.value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          )),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              notificationController.clearError();
              notificationController.refreshNotifications();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build load more indicator
  Widget _buildLoadMoreIndicator() {
    return Obx(() {
      if (!notificationController.hasMoreData.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No more notifications'),
          ),
        );
      }

      if (notificationController.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return const SizedBox.shrink();
    });
  }

  /// Get notification icon based on content
  IconData _getNotificationIcon(NotificationModel notification) {
    final body = notification.body.toLowerCase();
    
    if (body.contains('reminder')) {
      return Icons.alarm;
    } else if (body.contains('message')) {
      return Icons.message;
    } else if (body.contains('request')) {
      return Icons.assignment;
    } else if (body.contains('profile')) {
      return Icons.person;
    } else {
      return Icons.notifications;
    }
  }

  /// Extract title from notification body
  String _getNotificationTitle(NotificationModel notification) {
    final lines = notification.body.split('\n');
    return lines.isNotEmpty ? lines.first : 'Notification';
  }

  /// Extract message from notification body
  String _getNotificationMessage(NotificationModel notification) {
    final lines = notification.body.split('\n');
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationModel notification) {
    // Navigate based on notification type
    final body = notification.body.toLowerCase();
    
    if (body.contains('request')) {
      // Navigate to requests screen
      // Get.toNamed('/requests');
    } else if (body.contains('message')) {
      // Navigate to messages screen
      // Get.toNamed('/messages');
    } else if (body.contains('profile')) {
      // Navigate to profile screen
      // Get.toNamed('/profile');
    }
    
    print('Notification tapped: ${notification.notificationId}');
  }

  /// Show statistics dialog
  void _showStatistics() async {
    final stats = await notificationController.getNotificationStatistics();
    
    if (stats != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Received: ${stats['total_received'] ?? 0}'),
              Text('Total Read: ${stats['total_read'] ?? 0}'),
              Text('Read Rate: ${stats['read_rate'] ?? 0}%'),
              Text('Most Active Day: ${stats['most_active_day'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      Get.snackbar('Error', 'Failed to load statistics');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

/// Example: Controller initialization in main app
class AppInitializationExample {
  
  /// Initialize the NotificationController in your app
  static void initializeControllers() {
    // Initialize NotificationController
    Get.put(NotificationController(), permanent: true);
    
    print('✅ NotificationController initialized with Django API integration');
  }
  
  /// Example: Update FCM token after Firebase initialization
  static Future<void> setupPushNotifications(String fcmToken) async {
    final notificationController = Get.find<NotificationController>();
    await notificationController.updateFcmToken(fcmToken);
    
    print('✅ FCM token registered with Django backend');
  }
  
  /// Example: Manual notification refresh
  static Future<void> refreshNotifications() async {
    final notificationController = Get.find<NotificationController>();
    await notificationController.refreshNotifications();
    
    print('✅ Notifications refreshed from Django API');
  }
  
  /// Example: Create and send reminder notification
  static Future<void> createReminderNotification(String message) async {
    final notificationController = Get.find<NotificationController>();
    
    final reminderNotification = NotificationModel(
      notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
      status: 'unread',
      body: 'Reminder\n$message',
      isUserWaiting: true,
      userId: 'current-user-id', // Get from AuthController
      timestamp: DateTime.now(),
    );
    
    await notificationController.sendReminderNotification(reminderNotification);
    
    print('✅ Reminder notification sent via Django API');
  }
}

/// Example: Usage in other parts of the app
class NotificationUsageExamples {
  
  /// Example: Check unread count for badge
  static int getUnreadCount() {
    final notificationController = Get.find<NotificationController>();
    return notificationController.unreadCount.value;
  }
  
  /// Example: Get unread notifications only
  static List<NotificationModel> getUnreadNotifications() {
    final notificationController = Get.find<NotificationController>();
    return notificationController.getUnreadNotifications();
  }
  
  /// Example: Search notifications
  static List<NotificationModel> searchNotifications(String query) {
    final notificationController = Get.find<NotificationController>();
    return notificationController.searchNotifications(query);
  }
  
  /// Example: Mark specific notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    final notificationController = Get.find<NotificationController>();
    await notificationController.markAsRead(notificationId);
  }
  
  /// Example: Load more notifications for infinite scroll
  static Future<void> loadMoreNotifications() async {
    final notificationController = Get.find<NotificationController>();
    if (notificationController.canLoadMore) {
      await notificationController.loadMoreNotifications();
    }
  }
}

/// Migration checklist for existing UI components:
/// 
/// ✅ All existing reactive variables maintained (.obs patterns)
/// ✅ GetX controller structure preserved
/// ✅ Existing method signatures kept for UI compatibility
/// ✅ Firebase calls replaced with Django API calls
/// ✅ Error handling enhanced with network failure support
/// ✅ Pull-to-refresh functionality added
/// ✅ Pagination support implemented
/// ✅ Offline handling with local caching added
/// ✅ Unread count calculation moved to Django API
/// ✅ Additional utility methods for filtering and search
/// ✅ FCM token management integrated
/// ✅ Statistics and analytics support added
/// 
/// No breaking changes to existing UI components!
