import 'package:get/get.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/screens/auth_screens/register_screen.dart';
import 'package:kind_clock/services/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {
  final FirebaseStorageService _store = Get.find<FirebaseStorageService>();

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
      final List<NotificationModel> notifications =
          await _store.fetchNotifications();

      _notifications.assignAll(notifications);
      isLoading.value = false;
      await _calculateUnreadCount(notifications);
      
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Error fetching notifications: $e');
    }
    isLoading.value = false;
  }

  Future<void> updateNotify(NotificationModel notify) async {
    // log("Inside noti controll: ${notify.toJson().toString()}");
    await _store.updateNotification(notify);
  }

  Future<void> loadNotification() async {
    final List<NotificationModel> notificationList =
      await _store.fetchNotifications(); 
      notifications.assignAll(notificationList);
      await _calculateUnreadCount(notificationList);
  }

  Future<void> sendReminderNotification(NotificationModel notification) async {
    try {
      await _store.saveNotification(notification);
      print("Notification saved successfully");
    } catch (e) {
      print("Error while saving notification: $e");
      Get.snackbar("Error", "Failed to send notification");
      rethrow; // to allow the caller to also handle it
    }
  }
  
Future<void> _calculateUnreadCount(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final readIds = prefs.getStringList('read_notifications') ?? [];
    final currentUserId = authController.currentUserStore!.value?.userId ?? '';
    final unread = notifications.where((n) => !readIds.contains(n.notificationId) && n.userId == currentUserId).length;
    unreadCount.value = unread;
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = _notifications.map((n) => n.notificationId).toList();
    await prefs.setStringList('read_notifications', allIds);
    unreadCount.value = 0;
  }

}