// lib/services/storage_cleanup_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'auth_storage.dart';
import 'api_service.dart';
import 'firebase_notification_service.dart';
import 'user_state_service.dart';

/// Centralized storage cleanup service
///
/// This service ensures that ALL user data, tokens, and cached information
/// is properly cleared when the user:
/// - Logs out
/// - Deletes their account
/// - Gets redirected back to login (email verification timeout, rejection, expiry, etc.)
/// - Has an expired session
///
/// This prevents issues where old tokens or data persist after logout.
class StorageCleanupService {

  /// Perform complete storage flush
  ///
  /// This method clears:
  /// - Access and refresh tokens (secure storage + SharedPreferences)
  /// - User data (secure storage + SharedPreferences)
  /// - FCM tokens and notification data
  /// - Auth storage data (account status, next step, registration stage)
  /// - User state service data
  /// - Any cached data in SharedPreferences
  ///
  /// Use this method ANY TIME the user goes back to the login page
  static Future<void> flushAllStorage({
    bool removeFCMFromBackend = true,
  }) async {
    try {
      // 1. Clear FCM token from backend first (requires auth tokens)
      if (removeFCMFromBackend) {
        try {
          if (Get.isRegistered<FirebaseNotificationService>()) {
            final fcmService = Get.find<FirebaseNotificationService>();
            await fcmService.cleanup();
          }
        } catch (e) {
      // Error handled silently
          // FCM cleanup failed (non-critical)
        }
      }

      // 2. Clear API service tokens (secure storage)
      try {
        if (Get.isRegistered<ApiService>()) {
          final apiService = Get.find<ApiService>();
          await apiService.clearTokens();
        }
      } catch (e) {
      // Error handled silently
        // API token clear failed
      }

      // 3. Clear AuthStorage data (SharedPreferences)
      try {
        await AuthStorage.clearAuthData();
      } catch (e) {
      // Error handled silently
        // AuthStorage clear failed
      }

      // 4. Clear UserStateService data
      try {
        if (Get.isRegistered<UserStateService>()) {
          final userStateService = Get.find<UserStateService>();
          await userStateService.clearState();
        }
      } catch (e) {
      // Error handled silently
        // UserStateService clear failed
      }

      // 5. Clear ALL secure storage (belt and suspenders approach)
      try {
        const secureStorage = FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

        // Delete all known keys
        final keysToDelete = [
          'access_token',
          'refresh_token',
          'user_data',
          'token_refresh_time',
          'fcm_token',
          'notification_permission',
          'last_registered_fcm_token',
          'user_preferences',
          // 🚨 NEW: Account status cache keys
          'account_status_cache',
          'last_status_check',
        ];

        for (final key in keysToDelete) {
          await secureStorage.delete(key: key);
        }

      } catch (e) {
      // Error handled silently
        // Secure storage clear failed
      }

      // 6. Clear SharedPreferences user data
      try {
        final prefs = await SharedPreferences.getInstance();

        // Remove specific keys
        await prefs.remove('user');
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        await prefs.remove('user_data');
        await prefs.remove('account_status');
        await prefs.remove('next_step');
        await prefs.remove('registration_stage');

        // 🚨 NEW: Clear notification read state
        await prefs.remove('read_notifications');

      } catch (e) {
      // Error handled silently
        // SharedPreferences clear failed
      }

    } catch (e) {
      // Error handled silently
      // Don't rethrow - we want to continue even if some cleanup fails
    }
  }

  /// Perform logout cleanup (includes backend API call)
  ///
  /// This is a wrapper around flushAllStorage that also attempts
  /// to call the backend logout endpoint
  static Future<void> performLogoutCleanup() async {
    try {
      // 1. Try to logout on server
      try {
        if (Get.isRegistered<ApiService>()) {
          final apiService = Get.find<ApiService>();
          await apiService.post(
            '/api/auth/logout/',
            data: {
              'refresh': apiService.refreshToken,
            },
          );
        }
      } catch (e) {
      // Error handled silently
        // Server logout failed (continuing with local cleanup)
      }

      // 2. Perform complete storage flush
      await flushAllStorage(removeFCMFromBackend: true);

    } catch (e) {
      // Error handled silently
      // Still try to flush storage even if server logout fails
      await flushAllStorage(removeFCMFromBackend: false);
    }
  }

  /// Quick flush without FCM backend removal (for scenarios where tokens are already invalid)
  static Future<void> flushStorageQuick() async {
    await flushAllStorage(removeFCMFromBackend: false);
  }
}
