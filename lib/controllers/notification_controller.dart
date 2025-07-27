import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/screens/auth_screens/register_screen.dart';
import 'package:kind_clock/services/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  // // final FirebaseStorageService _store = Get.find<FirebaseStorageService>(); // REMOVED: Migrating to Django // REMOVED: Migrating to Django

  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final isLoading = false.obs;

  List<NotificationModel> get notifications => _notifications;

  @override
  void onInit() {
    super.onInit();
    _getNotifications();
  }

  Future<void> _getNotifications() async {
    isLoading.value = true;
    try {
      final List<NotificationModel> notifications = <NotificationModel>[]; // TODO: Implement Django API call

      _notifications.assignAll(notifications);
      await _calculateUnreadCount(notifications);
    } catch (e) {
      log('Error fetching notifications: $e');
      Get.snackbar('Error', 'Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateNotify(NotificationModel notify) async {
    try {
      // await _store.updateNotification(notify); // REMOVED: Firebase dependency
      log("Notification updated successfully");
    } catch (e) {
      log("Error updating notification: $e");
    }
  }

  Future<void> loadNotification() async {
    try {
      final List<NotificationModel> notificationList = <NotificationModel>[]; // TODO: Implement Django API call
      _notifications.assignAll(notificationList);
      await _calculateUnreadCount(notificationList);
    } catch (e) {
      log("Error loading notifications: $e");
    }
  }

  Future<void> sendReminderNotification(NotificationModel notification) async {
    try {
      // await _store.saveNotification(notification); // REMOVED: Firebase dependency
      log("Reminder notification saved successfully");
    } catch (e) {
      log("Error while saving reminder notification: $e");
      Get.snackbar("Error", "Failed to send notification");
      rethrow;
    }
  }

  /// Add notification to the list
  /// Temporary method for Phase 3 compatibility
  void addNotification(NotificationModel notification) {
    log("NotificationController: addNotification called - ${notification.body}");
    // TODO: Implement proper notification handling in Phase 4
    // For now, just log the notification
  }

  Future<void> _calculateUnreadCount(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notifications') ?? [];
      
      // Get current user ID safely
      final authController = Get.find<AuthController>();
      final currentUserId = authController.currentUserStore.value?.userId ?? '';
      
      if (currentUserId.isNotEmpty) {
        final unread = notifications
            .where((n) => 
                !readIds.contains(n.notificationId) && 
                n.userId == currentUserId)
            .length;
        unreadCount.value = unread;
      } else {
        unreadCount.value = 0;
      }
    } catch (e) {
      log("Error calculating unread count: $e");
      unreadCount.value = 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = _notifications.map((n) => n.notificationId).toList();
      await prefs.setStringList('read_notifications', allIds);
      unreadCount.value = 0;
      log("All notifications marked as read");
    } catch (e) {
      log("Error marking notifications as read: $e");
    }
  }
}



