/// Notification API Service Usage Examples - Phase 2
/// Demonstrates how to use the Django-integrated notification service
library notification_api_examples;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../lib/services/api/notification_api_service.dart';
import '../lib/services/models/notification_response.dart';
import '../lib/services/api_foundation.dart';

/// Complete example of notification service integration
class NotificationServiceExamples {
  
  /// Initialize the notification service
  static Future<void> initializeService() async {
    // Initialize API foundation
    ApiFoundationInitializer.initialize();
    
    // Set authentication token (after user login)
    const token = 'your-jwt-token-here';
    ApiFoundationInitializer.setAuthToken(token);
    
    print('✅ Notification service initialized');
  }

  /// Example: Fetch notifications with filtering
  static Future<void> fetchNotifications() async {
    try {
      // Fetch first page of unread notifications
      final response = await NotificationApiService.getNotifications(
        page: 1,
        limit: 20,
        isRead: false,
        orderBy: 'created_at',
        ordering: 'desc',
      );

      if (response.success && response.data != null) {
        final notifications = response.data!;
        print('✅ Fetched ${notifications.results.length} notifications');
        print('   Total unread: ${notifications.unreadNotifications.length}');
        print('   Has next page: ${notifications.hasNext}');
        print('   Display range: ${notifications.getDisplayRange()}');

        // Process notifications
        for (final notification in notifications.results) {
          print('   - ${notification.title}: ${notification.timeAgo}');
        }
      } else {
        print('❌ Failed to fetch notifications: ${response.error?.message}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }

  /// Example: Fetch notifications with search and filtering
  static Future<void> searchNotifications() async {
    try {
      final response = await NotificationApiService.getNotifications(
        page: 1,
        limit: 10,
        search: 'request',
        notificationType: 'request_accepted',
        orderBy: 'created_at',
        ordering: 'desc',
      );

      if (response.success && response.data != null) {
        final notifications = response.data!;
        print('✅ Found ${notifications.results.length} matching notifications');
        
        // Group by category
        final requestNotifications = notifications.getNotificationsByCategory(
          NotificationCategory.request,
        );
        print('   Request notifications: ${requestNotifications.length}');
      }
    } catch (e) {
      print('❌ Search failed: $e');
    }
  }

  /// Example: Mark notifications as read
  static Future<void> markNotificationsAsRead() async {
    try {
      // Mark specific notification as read
      const notificationId = 'notification-uuid-here';
      final markResponse = await NotificationApiService.markAsRead(notificationId);
      
      if (markResponse.success) {
        print('✅ Notification marked as read');
      }

      // Mark all notifications as read
      final markAllResponse = await NotificationApiService.markAllAsRead();
      
      if (markAllResponse.success) {
        print('✅ All notifications marked as read');
      }
    } catch (e) {
      print('❌ Failed to mark as read: $e');
    }
  }

  /// Example: Get unread count for badge
  static Future<void> getUnreadCount() async {
    try {
      final response = await NotificationApiService.getUnreadCount(
        includeBreakdown: true,
      );

      if (response.success && response.data != null) {
        final unreadData = response.data!;
        print('✅ Unread count: ${unreadData.unreadCount}');
        print('   Formatted: ${unreadData.formattedCount}');
        print('   Has unread: ${unreadData.hasUnread}');
        
        // Show breakdown by category
        if (unreadData.categoryBreakdown != null) {
          print('   Category breakdown:');
          unreadData.categoryBreakdown!.forEach((category, count) {
            print('     - $category: $count');
          });
        }
      }
    } catch (e) {
      print('❌ Failed to get unread count: $e');
    }
  }

  /// Example: Update FCM token for push notifications
  static Future<void> updateFcmToken() async {
    try {
      const fcmToken = 'your-fcm-token-here';
      final deviceInfo = {
        'device_type': 'mobile',
        'platform': 'android',
        'app_version': '1.0.0',
        'device_model': 'Samsung Galaxy S21',
      };

      final response = await NotificationApiService.updateFcmToken(
        fcmToken,
        deviceInfo: deviceInfo,
      );

      if (response.success && response.data != null) {
        final tokenData = response.data!;
        print('✅ FCM token updated: ${tokenData.message}');
        print('   Registered at: ${tokenData.registeredAt}');
      }
    } catch (e) {
      print('❌ Failed to update FCM token: $e');
    }
  }

  /// Example: Manage notification preferences
  static Future<void> managePreferences() async {
    try {
      // Get current preferences
      final getResponse = await NotificationApiService.getPreferences();
      
      if (getResponse.success && getResponse.data != null) {
        final preferences = getResponse.data!;
        print('✅ Current preferences:');
        print('   Push enabled: ${preferences.pushEnabled}');
        print('   Email enabled: ${preferences.emailEnabled}');
        print('   SMS enabled: ${preferences.smsEnabled}');
        print('   Enabled types: ${preferences.enabledTypes}');
        
        // Update preferences
        final updatedPreferences = NotificationPreferencesResponse(
          emailEnabled: true,
          pushEnabled: true,
          smsEnabled: false,
          enabledTypes: ['request_accepted', 'message_received'],
          quietHoursStart: '22:00',
          quietHoursEnd: '08:00',
        );

        final updateResponse = await NotificationApiService.updatePreferences(
          updatedPreferences,
        );

        if (updateResponse.success) {
          print('✅ Preferences updated successfully');
        }
      }
    } catch (e) {
      print('❌ Failed to manage preferences: $e');
    }
  }

  /// Example: Delete and clear notifications
  static Future<void> deleteNotifications() async {
    try {
      // Delete specific notification
      const notificationId = 'notification-uuid-here';
      final deleteResponse = await NotificationApiService.deleteNotification(
        notificationId,
      );
      
      if (deleteResponse.success) {
        print('✅ Notification deleted');
      }

      // Clear all read notifications
      final clearResponse = await NotificationApiService.clearReadNotifications();
      
      if (clearResponse.success) {
        print('✅ Read notifications cleared');
      }
    } catch (e) {
      print('❌ Failed to delete notifications: $e');
    }
  }

  /// Example: Get notification statistics
  static Future<void> getStatistics() async {
    try {
      final response = await NotificationApiService.getStatistics(days: 30);

      if (response.success && response.data != null) {
        final stats = response.data!;
        print('✅ Notification statistics (30 days):');
        print('   Total received: ${stats['total_received']}');
        print('   Total read: ${stats['total_read']}');
        print('   Read rate: ${stats['read_rate']}%');
        print('   Most active day: ${stats['most_active_day']}');
      }
    } catch (e) {
      print('❌ Failed to get statistics: $e');
    }
  }

  /// Example: Handle request cancellation
  static Future<void> handleCancellation() async {
    final cancelToken = CancelToken();
    
    // Cancel after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      cancelToken.cancel('Request cancelled by user');
    });

    try {
      final response = await NotificationApiService.getNotifications(
        cancelToken: cancelToken,
      );
      
      if (response.success) {
        print('✅ Request completed before cancellation');
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        print('🛑 Request was cancelled');
      } else {
        print('❌ Request failed: $e');
      }
    }
  }
}

/// Flutter widget demonstrating notification service integration
class NotificationServiceWidget extends StatefulWidget {
  const NotificationServiceWidget({super.key});

  @override
  State<NotificationServiceWidget> createState() => _NotificationServiceWidgetState();
}

class _NotificationServiceWidgetState extends State<NotificationServiceWidget> {
  bool _isLoading = false;
  String _status = 'Ready';
  List<NotificationResponse> _notifications = [];
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  /// Initialize service and load notifications
  Future<void> _initializeAndLoad() async {
    await NotificationServiceExamples.initializeService();
    await _loadNotifications();
    await _loadUnreadCount();
  }

  /// Load notifications from API
  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _status = refresh ? 'Refreshing...' : 'Loading notifications...';
    });

    try {
      final response = await NotificationApiService.getNotifications(
        page: refresh ? 1 : _currentPage,
        limit: 20,
        orderBy: 'created_at',
        ordering: 'desc',
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;
        
        setState(() {
          if (refresh) {
            _notifications = paginatedData.results;
            _currentPage = 1;
          } else {
            _notifications.addAll(paginatedData.results);
          }
          _hasMore = paginatedData.hasNext;
          _status = 'Loaded ${_notifications.length} notifications';
        });
      } else {
        setState(() {
          _status = 'Error: ${response.error?.message ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load unread count
  Future<void> _loadUnreadCount() async {
    try {
      final response = await NotificationApiService.getUnreadCount();
      
      if (response.success && response.data != null) {
        setState(() {
          _unreadCount = response.data!.unreadCount;
        });
      }
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  /// Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await NotificationApiService.markAsRead(notificationId);
      
      if (response.success) {
        setState(() {
          // Update local notification state
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
          }
        });
        
        // Refresh unread count
        await _loadUnreadCount();
        
        setState(() {
          _status = 'Notification marked as read';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to mark as read: $e';
      });
    }
  }

  /// Mark all notifications as read
  Future<void> _markAllAsRead() async {
    try {
      final response = await NotificationApiService.markAllAsRead();
      
      if (response.success) {
        setState(() {
          // Update all local notifications
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
          _unreadCount = 0;
          _status = 'All notifications marked as read';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to mark all as read: $e';
      });
    }
  }

  /// Load more notifications (pagination)
  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      _currentPage++;
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Service'),
        actions: [
          // Unread count badge
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          
          // Actions menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'mark_all_read':
                  await _markAllAsRead();
                  break;
                case 'refresh':
                  await _loadNotifications(refresh: true);
                  await _loadUnreadCount();
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
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          
          // Notifications list
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Load more indicator
                if (index == _notifications.length) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TextButton(
                            onPressed: _loadMore,
                            child: const Text('Load More'),
                          ),
                  );
                }

                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: notification.isRead ? Colors.grey : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForCategory(notification.category),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead 
                            ? FontWeight.normal 
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          notification.timeAgo,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: notification.isRead
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.mark_email_read),
                            onPressed: () => _markAsRead(notification.id),
                          ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon for notification category
  IconData _getIconForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.request:
        return Icons.assignment;
      case NotificationCategory.message:
        return Icons.message;
      case NotificationCategory.system:
        return Icons.settings;
      case NotificationCategory.profile:
        return Icons.person;
      case NotificationCategory.general:
        return Icons.notifications;
    }
  }
}

/// TODO: Phase 3 Integration Points
/// - Add real-time notification updates via WebSocket
/// - Implement notification actions (accept, decline, etc.)
/// - Add notification sound and vibration handling
/// - Create notification grouping and threading
/// - Add notification templates and rich content
/// - Implement notification scheduling and delays
/// - Add notification analytics and user engagement tracking
/// - Create notification A/B testing capabilities
