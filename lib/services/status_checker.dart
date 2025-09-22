// lib/services/status_checker.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_storage.dart';
import 'package:tiri/services/api_service.dart';

/// StatusChecker provides real-time status updates for user verification and approval
///
/// Features:
/// - Periodic status checking every 30 seconds
/// - Automatic route updates when status changes
/// - Background monitoring for approval status changes
/// - Handles status transitions: pending -> approved/rejected/expired
class StatusChecker extends GetxService {
  Timer? _statusTimer;
  Timer? _verificationTimer;
  final ApiService _apiService = Get.find<ApiService>();

  // Observable status variables
  final RxString currentStatus = ''.obs;
  final RxBool isVerified = false.obs;
  final RxBool isApproved = false.obs;
  final RxBool canAccessApp = false.obs;

  /// Start periodic status checks for current user
  void startPeriodicChecks() {
    log('📡 StatusChecker: Periodic checks DISABLED to prevent token refresh loops');
    // 🚨 DISABLED: These timers were causing infinite token refresh loops
    // The backend authentication issue needs to be fixed first

    // // Check every 30 seconds
    // _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
    //   await _checkStatusUpdate();
    // });
    //
    // // Initial check
    // _checkStatusUpdate();
  }

  /// Start verification-specific checks (more frequent during email verification)
  void startVerificationChecks() {
    log('📧 StatusChecker: Verification checks DISABLED to prevent token refresh loops');
    // 🚨 DISABLED: This was making API calls every 10 seconds causing the issue!

    // // Check every 10 seconds during verification
    // _verificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    //   await _checkVerificationStatus();
    // });
    //
    // // Initial check
    // _checkVerificationStatus();
  }

  /// Stop all periodic checks
  void stopPeriodicChecks() {
    log('🛑 StatusChecker: Stopping periodic checks...');

    _statusTimer?.cancel();
    _statusTimer = null;

    _verificationTimer?.cancel();
    _verificationTimer = null;
  }

  /// Stop only verification checks (keep status checks running)
  void stopVerificationChecks() {
    log('🛑 StatusChecker: Stopping verification checks...');

    _verificationTimer?.cancel();
    _verificationTimer = null;
  }

  /// Check for status updates from the backend
  Future<void> _checkStatusUpdate() async {
    try {
      log('🔍 StatusChecker: Checking status update...');

      final response = await _apiService.get('/api/auth/registration-status/');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final newStatus = data['account_status'] ?? '';
        final newNextStep = data['next_step'] ?? '';
        final verified = data['is_verified'] == true;
        final approved = data['is_approved'] == true;
        final canAccess = data['can_access_app'] == true;

        log('📊 StatusChecker: New status - account: $newStatus, next: $newNextStep, verified: $verified, approved: $approved');

        // Get current stored status
        final currentStoredStatus = await AuthStorage.getAccountStatus();
        final currentStoredNextStep = await AuthStorage.getNextStep();

        // Check if status changed
        if (currentStoredStatus != newStatus || currentStoredNextStep != newNextStep) {
          log('🔄 StatusChecker: Status changed! Old: $currentStoredStatus -> New: $newStatus');

          // Update local storage
          await AuthStorage.storeAuthData(data);

          // Update observable variables
          currentStatus.value = newStatus;
          isVerified.value = verified;
          isApproved.value = approved;
          canAccessApp.value = canAccess;

          // Handle status change
          await _handleStatusChange(newStatus, newNextStep);
        } else {
          log('✅ StatusChecker: No status change detected');
        }
      }
    } catch (e) {
      log('❌ StatusChecker: Error checking status update: $e');
      // Don't show errors for silent polling
    }
  }

  /// Check verification status specifically
  Future<void> _checkVerificationStatus() async {
    try {
      log('📧 StatusChecker: Checking verification status...');

      final response = await _apiService.get('/api/auth/verification-status/');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final verified = data['is_verified'] == true;
        final autoLogin = data['auto_login'] == true;
        final approvalStatus = data['approval_status'] ?? '';

        log('📧 StatusChecker: Verification status - verified: $verified, autoLogin: $autoLogin, approval: $approvalStatus');

        if (verified && isVerified.value != verified) {
          log('✅ StatusChecker: Email verification detected!');

          // Update status
          isVerified.value = verified;

          // Stop verification checks since email is now verified
          stopVerificationChecks();

          // Handle the verification completion
          if (autoLogin && approvalStatus == 'approved') {
            // User is fully approved, redirect to home
            await _navigateToRoute(Routes.homePage, 'Email verified and approved! Welcome to TIRI!');
          } else if (approvalStatus == 'pending') {
            // User needs approval, redirect to pending page
            await _navigateToRoute(Routes.pendingApprovalPage, 'Email verified! Waiting for approval from your referrer.');
          } else {
            // Update storage and continue with regular status checks
            await AuthStorage.updateAccountStatus('email_verified');
            await AuthStorage.updateNextStep('waiting_for_approval');
          }
        }
      }
    } catch (e) {
      log('❌ StatusChecker: Error checking verification status: $e');
    }
  }

  /// Handle status changes and navigate accordingly
  Future<void> _handleStatusChange(String newStatus, String newNextStep) async {
    try {
      log('🔄 StatusChecker: Handling status change - Status: $newStatus, NextStep: $newNextStep');

      switch (newNextStep) {
        case 'ready':
          await _navigateToRoute(
            Routes.homePage,
            'Your account has been approved! Welcome to TIRI! 🎉',
          );
          break;

        case 'waiting_for_approval':
          // Only navigate if not already on pending approval page
          if (Get.currentRoute != Routes.pendingApprovalPage) {
            await _navigateToRoute(
              Routes.pendingApprovalPage,
              'Email verified! Waiting for approval from your referrer.',
            );
          }
          break;

        case 'approval_rejected':
          await _navigateToRoute(
            Routes.rejectionScreen,
            'Your registration was not approved by the referrer.',
          );
          break;

        case 'verify_email':
          // Only navigate if not already on verification page
          if (Get.currentRoute != Routes.emailVerificationPage) {
            await _navigateToRoute(
              Routes.emailVerificationPage,
              'Please verify your email address to continue.',
            );
          }
          break;

        default:
          log('⚠️ StatusChecker: Unknown next step: $newNextStep');
      }
    } catch (e) {
      log('❌ StatusChecker: Error handling status change: $e');
    }
  }

  /// Navigate to a specific route with a message
  Future<void> _navigateToRoute(String route, String message) async {
    try {
      log('🛤️ StatusChecker: Navigating to $route with message: $message');

      // Show success/info message
      Get.snackbar(
        'Status Update',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: route == Routes.homePage
            ? const Color.fromRGBO(0, 140, 170, 1)  // TIRI Blue for success
            : const Color.fromRGBO(255, 152, 0, 1),  // Orange for info
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Navigate after a brief delay to show the message
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(route);

    } catch (e) {
      log('❌ StatusChecker: Error navigating to route: $e');
    }
  }

  /// Manually trigger a status check (for pull-to-refresh)
  Future<void> checkStatusNow() async {
    log('🔄 StatusChecker: Manual status check triggered');
    await _checkStatusUpdate();
  }

  /// Check if user should be redirected based on current route and status
  Future<bool> shouldRedirect() async {
    try {
      final currentRoute = Get.currentRoute;
      final accountStatus = await AuthStorage.getAccountStatus();
      final nextStep = await AuthStorage.getNextStep();

      log('🤔 StatusChecker: Should redirect? Route: $currentRoute, Status: $accountStatus, NextStep: $nextStep');

      // Define route-status mappings
      const routeStatusMap = {
        Routes.emailVerificationPage: ['email_pending', 'verify_email'],
        Routes.pendingApprovalPage: ['email_verified', 'pending_approval', 'waiting_for_approval'],
        Routes.homePage: ['approved', 'active', 'ready'],
        Routes.rejectionScreen: ['rejected', 'approval_rejected'],
      };

      // Check if current route matches the user's status
      for (final entry in routeStatusMap.entries) {
        final route = entry.key;
        final statuses = entry.value;

        if (currentRoute == route) {
          final shouldBeHere = statuses.contains(accountStatus) || statuses.contains(nextStep);
          if (!shouldBeHere) {
            log('🚨 StatusChecker: User should not be on $route with status $accountStatus/$nextStep');
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      log('❌ StatusChecker: Error checking redirect: $e');
      return false;
    }
  }

  /// Get the correct route for the current user status
  Future<String> getCorrectRoute() async {
    try {
      final nextStep = await AuthStorage.getNextStep();
      final accountStatus = await AuthStorage.getAccountStatus();

      log('🛤️ StatusChecker: Getting correct route for status: $accountStatus, nextStep: $nextStep');

      if (nextStep != null) {
        switch (nextStep) {
          case 'verify_email':
            return Routes.emailVerificationPage;
          case 'waiting_for_approval':
          case 'needs_referral_approval':
            return Routes.pendingApprovalPage;
          case 'approval_rejected':
            return Routes.rejectionScreen;
          case 'ready':
            return Routes.homePage;
        }
      }

      if (accountStatus != null) {
        switch (accountStatus) {
          case 'email_pending':
            return Routes.emailVerificationPage;
          case 'email_verified':
          case 'pending_approval':
            return Routes.pendingApprovalPage;
          case 'approved':
          case 'active':
            return Routes.homePage;
          case 'rejected':
            return Routes.rejectionScreen;
        }
      }

      // Default fallback
      return Routes.emailVerificationPage;
    } catch (e) {
      log('❌ StatusChecker: Error getting correct route: $e');
      return Routes.loginPage;
    }
  }

  @override
  void onClose() {
    stopPeriodicChecks();
    super.onClose();
  }
}