// lib/services/app_startup_handler.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tiri/config/api_config.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_storage.dart';
import 'package:tiri/services/api_service.dart';

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
      log('🚀 AppStartupHandler: Determining initial route...');

      // Check if we have stored tokens
      final hasTokens = await AuthStorage.hasValidTokens();
      log('📱 AppStartupHandler: Has stored tokens: $hasTokens');

      if (!hasTokens) {
        log('❌ AppStartupHandler: No tokens found, routing to login');
        return Routes.loginPage;
      }

      // Load tokens into API service
      await _loadTokensIntoApiService();

      // Validate tokens with backend
      final isValid = await _validateStoredTokens();
      log('🔍 AppStartupHandler: Token validation result: $isValid');

      if (!isValid) {
        // Try to refresh tokens
        final refreshed = await _tryRefreshToken();
        log('🔄 AppStartupHandler: Token refresh result: $refreshed');

        if (!refreshed) {
          // Tokens are invalid and refresh failed
          await AuthStorage.clearAuthData();
          log('🧹 AppStartupHandler: Cleared invalid tokens, routing to login');
          return Routes.loginPage;
        }
      }

      // Tokens are valid, check user's next step
      final nextStep = await AuthStorage.getNextStep();
      final accountStatus = await AuthStorage.getAccountStatus();

      log('📊 AppStartupHandler: Account status: $accountStatus');
      log('➡️ AppStartupHandler: Next step: $nextStep');

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
      log('❌ AppStartupHandler: Error determining route: $e');
      // Clear potentially corrupted data and route to login
      await AuthStorage.clearAuthData();
      return Routes.loginPage;
    }
  }

  /// Load stored tokens into the API service
  static Future<void> _loadTokensIntoApiService() async {
    try {
      final apiService = Get.find<ApiService>();
      await apiService.loadTokensFromStorage();
      log('✅ AppStartupHandler: Tokens loaded into API service');
    } catch (e) {
      log('❌ AppStartupHandler: Error loading tokens into API service: $e');
    }
  }

  /// Validate stored tokens with the backend
  static Future<bool> _validateStoredTokens() async {
    try {
      final accessToken = await AuthStorage.getAccessToken();
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
      log('🔍 AppStartupHandler: Token validation - Status: ${response.statusCode}, Valid: $isValid');
      return isValid;

    } catch (e) {
      log('❌ AppStartupHandler: Token validation error: $e');
      return false;
    }
  }

  /// Attempt to refresh the token
  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/api/auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final newAccessToken = data['access'];

        if (newAccessToken != null) {
          // Update tokens in storage
          await AuthStorage.updateTokens(newAccessToken, refreshToken);

          // Update API service with new token
          final apiService = Get.find<ApiService>();
          await apiService.saveTokens(newAccessToken, refreshToken);

          log('✅ AppStartupHandler: Token refreshed successfully');
          return true;
        }
      }

      log('❌ AppStartupHandler: Token refresh failed - Status: ${response.statusCode}');
      return false;

    } catch (e) {
      log('❌ AppStartupHandler: Token refresh error: $e');
      return false;
    }
  }

  /// Get route from next_step value
  static String _getRouteFromNextStep(String nextStep) {
    log('🛤️ AppStartupHandler: Routing based on next_step: $nextStep');

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
        log('⚠️ AppStartupHandler: Unknown next_step: $nextStep, defaulting to email verification');
        return Routes.emailVerificationPage;
    }
  }

  /// Get route from account_status value
  static String _getRouteFromAccountStatus(String accountStatus) {
    log('🛤️ AppStartupHandler: Routing based on account_status: $accountStatus');

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
        log('⚠️ AppStartupHandler: Unknown account_status: $accountStatus, checking backend');
        return Routes.emailVerificationPage;
    }
  }

  /// Get route by checking verification status from backend
  static Future<String> _getRouteFromBackendStatus() async {
    try {
      log('🔍 AppStartupHandler: Checking verification status from backend...');

      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/auth/verification-status/');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final isVerified = data['is_verified'] == true;
        final isApproved = data['is_approved'] == true;
        final approvalStatus = data['approval_status'] ?? 'unknown';
        final canAccessApp = data['can_access_app'] == true;

        log('📊 AppStartupHandler: Backend status - verified: $isVerified, approved: $isApproved, status: $approvalStatus, canAccess: $canAccessApp');

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
      log('⚠️ AppStartupHandler: Backend status check failed, defaulting to email verification');
      return Routes.emailVerificationPage;

    } catch (e) {
      log('❌ AppStartupHandler: Backend status check error: $e');
      return Routes.emailVerificationPage;
    }
  }

  /// Check if the current session has expired
  static Future<bool> isSessionExpired() async {
    try {
      // For basic implementation, just check if tokens exist and are valid
      return !(await _validateStoredTokens());
    } catch (e) {
      log('❌ AppStartupHandler: Session check error: $e');
      return true;
    }
  }

  /// Clear session and reset to login
  static Future<void> clearSessionAndRedirect() async {
    try {
      await AuthStorage.clearAuthData();
      Get.offAllNamed(Routes.loginPage);
      log('✅ AppStartupHandler: Session cleared and redirected to login');
    } catch (e) {
      log('❌ AppStartupHandler: Error clearing session: $e');
    }
  }
}