import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/notification_controller.dart';
import 'package:tiri/services/models/notification_response.dart';
import 'package:tiri/services/api/notification_api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final notifyController = Get.find<NotificationController>();
  final authController = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    notifyController.loadNotification();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      notifyController.loadMoreNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Enhanced Header
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(0, 140, 170, 1),
                  Color.fromRGBO(3, 80, 135, 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 140, 170, 0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                            onPressed: () => Get.back(),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Obx(() => notifyController.unreadCount.value > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: InkWell(
                                  onTap: () => notifyController.markAllAsRead(),
                                  child: const Text(
                                    'Mark all read',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(width: 48)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.inbox,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${notifyController.apiNotifications.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.mark_email_unread,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unread',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${notifyController.unreadCount.value}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body Content
          Expanded(
            child: Obx(() {
        if (notifyController.isLoading.value && notifyController.apiNotifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 140, 170, 1)),
            ),
          );
        }

        if (notifyController.hasError.value && notifyController.apiNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load notifications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notifyController.errorMessage.value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => notifyController.refreshNotifications(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final notifications = notifyController.apiNotifications.toList();

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see your notifications here when you receive them',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => notifyController.refreshNotifications(),
          color: const Color.fromRGBO(0, 140, 170, 1),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: notifications.length + (notifyController.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == notifications.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 140, 170, 1)),
                    ),
                  ),
                );
              }

              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          ),
        );
      }),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationResponse notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) async {
        await _deleteNotification(notification.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: _getNotificationCategoryColor(notification.notificationType).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge - properly aligned inside
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getNotificationCategoryColor(notification.notificationType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(notification.notificationType),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getNotificationCategoryName(notification.notificationType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Main notification content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(notification),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (notification.priority != null && notification.priority != 'normal') ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(notification.priority!).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _getPriorityColor(notification.priority!).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    notification.priority!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPriorityColor(notification.priority!),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationResponse notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.category) {
      case NotificationCategory.request:
        iconData = Icons.assignment;
        iconColor = const Color.fromRGBO(0, 140, 170, 1);
        break;
      case NotificationCategory.message:
        iconData = Icons.message;
        iconColor = Colors.green;
        break;
      case NotificationCategory.system:
        iconData = Icons.settings;
        iconColor = Colors.orange;
        break;
      case NotificationCategory.profile:
        iconData = Icons.person;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _onNotificationTap(NotificationResponse notification) async {
    if (!notification.isRead) {
      await notifyController.markAsRead(notification.id);
    }

    // Show detailed notification popup
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and category
              Row(
                children: [
                  _buildNotificationIcon(notification),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getNotificationCategoryColor(notification.notificationType).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getNotificationCategoryColor(notification.notificationType).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _getNotificationCategoryName(notification.notificationType),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getNotificationCategoryColor(notification.notificationType),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Message content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Details section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (notification.priority != null && notification.priority != 'normal')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(notification.priority!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification.priority!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back();
                        await _deleteNotification(notification.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await NotificationApiService.deleteNotification(notificationId);
      if (response.success) {
        // Remove from local list
        notifyController.apiNotifications.removeWhere((n) => n.id == notificationId);
        notifyController.notifications.removeWhere((n) => n.notificationId == notificationId);

        // Update unread count
        await notifyController.loadNotification();

        // Silently remove notification without showing success message
      } else {
        throw Exception(response.error?.message ?? 'Failed to delete notification');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete notification: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Color _getNotificationCategoryColor(String notificationType) {
    switch (notificationType.toLowerCase()) {
      // Authentication & Account Management - Blue tones
      case 'welcome_email':
      case 'email_verification':
      case 'referral_approved':
      case 'account_verified':
      case 'password_reset_request':
      case 'password_reset_confirmation':
      case 'referral_code_used':
      case 'your_referral_approved':
        return const Color(0xFF2196F3); // Blue

      // Service Requests - For Requesters - Green tones
      case 'request_accepted':
      case 'volunteer_checked_in':
      case 'volunteer_completed':
      case 'request_fully_staffed':
        return const Color(0xFF4CAF50); // Green

      // Service Requests - For Volunteers - Orange tones
      case 'new_nearby_request':
      case 'volunteer_request_reminder':
      case 'check_in_reminder':
      case 'other_volunteers_joined':
      case 'request_completion_confirmed':
      case 'request_details_changed':
        return const Color(0xFFFF9800); // Orange

      // General Service Requests - Purple tones
      case 'request_updated':
      case 'request_reminder':
        return const Color(0xFF9C27B0); // Purple

      // Urgent/Important - Red tones
      case 'volunteer_cancelled':
      case 'request_cancelled':
        return const Color(0xFFF44336); // Red

      // Chat & Messaging - Teal tones
      case 'new_message':
      case 'chat_room_created':
      case 'file_shared':
      case 'group_message':
        return const Color(0xFF009688); // Teal

      // Feedback & Reputation - Indigo tones
      case 'new_feedback':
      case 'rating_received':
      case 'hours_added':
      case 'feedback_requested':
      case 'feedback_deadline':
        return const Color(0xFF3F51B5); // Indigo

      // System - Grey tones
      case 'system_update':
      case 'maintenance':
        return const Color(0xFF607D8B); // Blue Grey

      // Profile - Pink tones
      case 'profile_updated':
      case 'settings_changed':
        return const Color(0xFFE91E63); // Pink

      // Test/General - Default app color
      case 'test':
      default:
        return const Color.fromRGBO(0, 140, 170, 1); // App primary color
    }
  }

  IconData _getCategoryIcon(String notificationType) {
    switch (notificationType.toLowerCase()) {
      // Authentication & Account
      case 'welcome_email':
      case 'email_verification':
      case 'account_verified':
        return Icons.verified_user;
      case 'referral_approved':
      case 'referral_code_used':
      case 'your_referral_approved':
        return Icons.people;
      case 'password_reset_request':
      case 'password_reset_confirmation':
        return Icons.lock_reset;

      // Service Requests
      case 'request_accepted':
      case 'request_fully_staffed':
        return Icons.check_circle;
      case 'new_nearby_request':
        return Icons.location_on;
      case 'volunteer_checked_in':
        return Icons.login;
      case 'volunteer_completed':
      case 'request_completion_confirmed':
        return Icons.task_alt;
      case 'volunteer_cancelled':
      case 'request_cancelled':
        return Icons.cancel;
      case 'request_updated':
      case 'request_details_changed':
        return Icons.edit;
      case 'request_reminder':
      case 'volunteer_request_reminder':
      case 'check_in_reminder':
        return Icons.schedule;

      // Chat & Messaging
      case 'new_message':
      case 'group_message':
        return Icons.message;
      case 'chat_room_created':
        return Icons.chat;
      case 'file_shared':
        return Icons.attach_file;

      // Feedback & Reputation
      case 'new_feedback':
      case 'feedback_requested':
        return Icons.feedback;
      case 'rating_received':
        return Icons.star;
      case 'hours_added':
        return Icons.timer;
      case 'feedback_deadline':
        return Icons.warning;

      // System
      case 'system_update':
        return Icons.system_update;
      case 'maintenance':
        return Icons.construction;

      // Profile
      case 'profile_updated':
      case 'settings_changed':
        return Icons.person;

      // Default
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationCategoryName(String notificationType) {
    switch (notificationType.toLowerCase()) {
      // Authentication & Account Management
      case 'welcome_email':
        return 'Welcome';
      case 'email_verification':
        return 'Email Verification';
      case 'referral_approved':
      case 'referral_code_used':
      case 'your_referral_approved':
        return 'Referral';
      case 'account_verified':
        return 'Account Verified';
      case 'password_reset_request':
      case 'password_reset_confirmation':
        return 'Password Reset';

      // Service Requests - For Requesters
      case 'request_accepted':
        return 'Request Accepted';
      case 'volunteer_cancelled':
        return 'Volunteer Cancelled';
      case 'volunteer_checked_in':
        return 'Volunteer Checked In';
      case 'volunteer_completed':
        return 'Service Completed';
      case 'request_fully_staffed':
        return 'Fully Staffed';
      case 'request_reminder':
        return 'Request Reminder';

      // Service Requests - For Volunteers
      case 'new_nearby_request':
        return 'New Nearby Request';
      case 'volunteer_request_reminder':
        return 'Volunteer Reminder';
      case 'check_in_reminder':
        return 'Check-in Reminder';
      case 'other_volunteers_joined':
        return 'Others Joined';
      case 'request_completion_confirmed':
        return 'Completion Confirmed';
      case 'request_details_changed':
        return 'Details Changed';

      // General Service Requests
      case 'request_updated':
        return 'Request Updated';
      case 'request_cancelled':
        return 'Request Cancelled';

      // Chat & Messaging
      case 'new_message':
        return 'New Message';
      case 'chat_room_created':
        return 'Chat Created';
      case 'file_shared':
        return 'File Shared';
      case 'group_message':
        return 'Group Message';

      // Feedback & Reputation
      case 'new_feedback':
        return 'New Feedback';
      case 'rating_received':
        return 'Rating Received';
      case 'hours_added':
        return 'Hours Added';
      case 'feedback_requested':
        return 'Feedback Requested';
      case 'feedback_deadline':
        return 'Feedback Deadline';

      // System
      case 'system_update':
        return 'System Update';
      case 'maintenance':
        return 'Maintenance';

      // Profile
      case 'profile_updated':
        return 'Profile Updated';
      case 'settings_changed':
        return 'Settings Changed';

      // Test/General
      case 'test':
        return 'Test Notification';
      default:
        return 'Notification';
    }
  }
}



