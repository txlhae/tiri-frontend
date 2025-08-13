import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionService {
  static const String _permissionRequestedKey = 'notification_permission_requested';
  
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  static Future<void> requestNotificationPermissionOnFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasRequestedBefore = prefs.getBool(_permissionRequestedKey) ?? false;
      
      if (!hasRequestedBefore) {
        log('NotificationPermissionService: First launch detected, requesting notification permission');
        
        await _showPermissionDialog();
        
        await prefs.setBool(_permissionRequestedKey, true);
        log('NotificationPermissionService: Permission request completed');
      } else {
        log('NotificationPermissionService: Permission already requested before');
      }
    } catch (e) {
      log('NotificationPermissionService: Error requesting permission: $e');
    }
  }

  static Future<void> _showPermissionDialog() async {
    return Get.dialog(
      AlertDialog(
        title: const Text(
          'Enable Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay updated with important notifications about:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Color.fromRGBO(0, 140, 170, 1), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('New help requests in your area')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Color.fromRGBO(0, 140, 170, 1), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Updates on your active requests')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Color.fromRGBO(0, 140, 170, 1), size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Important community updates')),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'You can change this setting anytime in your device settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              log('NotificationPermissionService: User declined notification permission');
            },
            child: const Text(
              'Not Now',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(Get.context!);
              await _requestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _requestPermissions() async {
    try {
      await _initializeLocalNotifications();
      
      final status = await Permission.notification.request();
      
      switch (status) {
        case PermissionStatus.granted:
          log('NotificationPermissionService: Notification permission granted');
          Get.snackbar(
            'Notifications Enabled',
            'You will now receive important updates',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;
        case PermissionStatus.denied:
          log('NotificationPermissionService: Notification permission denied');
          break;
        case PermissionStatus.permanentlyDenied:
          log('NotificationPermissionService: Notification permission permanently denied');
          _showSettingsDialog();
          break;
        default:
          log('NotificationPermissionService: Notification permission status: $status');
      }
    } catch (e) {
      log('NotificationPermissionService: Error requesting permissions: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );
      
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          log('NotificationPermissionService: Notification tapped: ${details.payload}');
        },
      );
      
      log('NotificationPermissionService: Local notifications initialized');
    } catch (e) {
      log('NotificationPermissionService: Error initializing local notifications: $e');
    }
  }

  static void _showSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notifications are permanently disabled. To enable them, please go to your device settings and allow notifications for TIRI.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<PermissionStatus> checkNotificationPermission() async {
    return await Permission.notification.status;
  }

  static Future<bool> hasNotificationPermission() async {
    final status = await checkNotificationPermission();
    return status == PermissionStatus.granted;
  }

  static Future<void> resetPermissionRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_permissionRequestedKey);
      log('NotificationPermissionService: Permission request flag reset');
    } catch (e) {
      log('NotificationPermissionService: Error resetting permission request: $e');
    }
  }
}