// lib/services/app_startup_handler.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tiri/config/api_config.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_storage.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/storage_cleanup_service.dart';

/// AppStartupHandler determines the initial route based on user authentication state
///
/// Handles:
/// - Token validation
/// - Token refresh attempts
/// - User state routing based on next_step
/// - Account status verification
/// - Error handling for expired/invalid sessions
class AppStartupHandler {

  /// Determine the initial route for the application
  static Future<String> determineInitialRoute() async {
    try {

      // 🔥 FIX #1: Load tokens from ApiService (single source of truth)
      await _loadTokensIntoApiService();

      // Check if we have valid tokens in ApiService
      final apiService = Get.find<ApiService>();
      final hasTokens = apiService.isAuthenticated;

      if (!hasTokens) {
        return Routes.loginPage;
      }

      // Validate tokens with backend
      final isValid = await _validateStoredTokens();

      if (!isValid) {
        // Try to refresh tokens
        final refreshed = await _tryRefreshToken();

        if (!refreshed) {
          // Tokens are invalid and refresh failed
          // 🚨 NEW: Use centralized cleanup service
          await StorageCleanupService.flushStorageQuick();
          return Routes.loginPage;
        }
      }

      // Tokens are valid, check user's next step
      final nextStep = await AuthStorage.getNextStep();
      final accountStatus = await AuthStorage.getAccountStatus();


      // If we have a next step, use it; otherwise determine from account status
      if (nextStep != null && nextStep.isNotEmpty) {
        return _getRouteFromNextStep(nextStep);
      } else if (accountStatus != null) {
        return _getRouteFromAccountStatus(accountStatus);
      } else {
        // Fallback to checking verification status from backend
        return await _getRouteFromBackendStatus();
      }

    } catch (e) {
      // Error handled silently
      // Clear potentially corrupted data and route to login
      // 🚨 NEW: Use centralized cleanup service
      await StorageCleanupService.flushStorageQuick();
      return Routes.loginPage;
    }
  }

  /// Load stored tokens into the API service
  static Future<void> _loadTokensIntoApiService() async {
    try {
      final apiService = Get.find<ApiService>();
      await apiService.loadTokensFromStorage();
    } catch (e) {
      // Error handled silently
    }
  }

  /// Validate stored tokens with the backend
  static Future<bool> _validateStoredTokens() async {
    try {
      // 🔥 FIX #1: Get token from ApiService (single source of truth)
      final apiService = Get.find<ApiService>();
      final accessToken = apiService.accessToken;

      if (accessToken == null || accessToken.isEmpty) {
        return false;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/api/auth/token/verify/',
        data: {'token': accessToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final isValid = response.statusCode == 200;
      return isValid;

    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Attempt to refresh the token
  static Future<bool> _tryRefreshToken() async {
    try {
      // 🔥 FIX #1: Use ApiService's built-in refresh logic (single source of truth)
      final apiService = Get.find<ApiService>();

      if (apiService.refreshToken == null || apiService.refreshToken!.isEmpty) {
        return false;
      }

      // Use ApiService's refresh method which handles all storage
      final refreshed = await apiService.refreshTokenIfNeeded();

      return refreshed;

    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Get route from next_step value
  static String _getRouteFromNextStep(String nextStep) {

    switch (nextStep) {
      case 'verify_email':
        return Routes.emailVerificationPage;
      case 'waiting_for_approval':
        return Routes.pendingApprovalPage;
      case 'approval_rejected':
        return Routes.rejectionScreen;
      case 'needs_referral_approval':
        return Routes.pendingApprovalPage;
      case 'complete_profile':
        return Routes.homePage; // Fallback to home since profileSetupPage doesn't exist
      case 'ready':
        return Routes.homePage;
      default:
        return Routes.emailVerificationPage;
    }
  }

  /// Get route from account_status value
  static String _getRouteFromAccountStatus(String accountStatus) {

    switch (accountStatus) {
      case 'email_pending':
        return Routes.emailVerificationPage;
      case 'email_verified':
        return Routes.pendingApprovalPage;
      case 'pending_approval':
        return Routes.pendingApprovalPage;
      case 'approved':
      case 'active':
        return Routes.homePage;
      case 'rejected':
        return Routes.rejectionScreen;
      case 'expired':
        return Routes.loginPage; // Fallback to login since expiredScreen doesn't exist
      default:
        return Routes.emailVerificationPage;
    }
  }

  /// Get route by checking verification status from backend
  static Future<String> _getRouteFromBackendStatus() async {
    try {

      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/auth/verification-status/');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final isVerified = data['is_verified'] == true;
        final isApproved = data['is_approved'] == true;
        final approvalStatus = data['approval_status'] ?? 'unknown';
        final canAccessApp = data['can_access_app'] == true;


        // Update local storage with backend data
        await AuthStorage.updateAccountStatus(approvalStatus);

        if (canAccessApp && isVerified && isApproved) {
          await AuthStorage.updateNextStep('ready');
          return Routes.homePage;
        } else if (isVerified && !isApproved) {
          if (approvalStatus == 'pending') {
            await AuthStorage.updateNextStep('waiting_for_approval');
            return Routes.pendingApprovalPage;
          } else if (approvalStatus == 'rejected') {
            await AuthStorage.updateNextStep('approval_rejected');
            return Routes.rejectionScreen;
          }
        } else if (!isVerified) {
          await AuthStorage.updateNextStep('verify_email');
          return Routes.emailVerificationPage;
        }
      }

      // Fallback if backend check fails
      return Routes.emailVerificationPage;

    } catch (e) {
      // Error handled silently
      return Routes.emailVerificationPage;
    }
  }

  /// Check if the current session has expired
  static Future<bool> isSessionExpired() async {
    try {
      // For basic implementation, just check if tokens exist and are valid
      return !(await _validateStoredTokens());
    } catch (e) {
      // Error handled silently
      return true;
    }
  }

  /// Clear session and reset to login
  static Future<void> clearSessionAndRedirect() async {
    try {
      // 🚨 NEW: Use centralized cleanup service
      await StorageCleanupService.flushStorageQuick();
      Get.offAllNamed(Routes.loginPage);
    } catch (e) {
      // Error handled silently
    }
  }

}