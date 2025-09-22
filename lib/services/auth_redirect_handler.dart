// lib/services/auth_redirect_handler.dart

import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_storage.dart';
import 'package:tiri/services/auth_service.dart';

/// AuthRedirectHandler manages routing based on authentication response
///
/// Handles the redirect logic based on the `next_step` field from login/register responses
/// and provides centralized navigation for authentication flows
class AuthRedirectHandler {

  /// Handle login success and redirect based on next_step
  static Future<void> handleLoginSuccess(Map<String, dynamic> response) async {
    try {
      log('🛤️ AuthRedirectHandler: Handling login success...');

      // Store auth data first
      await AuthStorage.storeAuthData(response);

      final nextStep = response['next_step'] ?? '';
      final accountStatus = response['account_status'] ?? '';

      log('📊 AuthRedirectHandler: Redirecting based on next_step: $nextStep');
      log('📊 AuthRedirectHandler: Account status: $accountStatus');

      await _handleRedirect(nextStep, response);

    } catch (e) {
      log('❌ AuthRedirectHandler: Error handling login success: $e');
      // Fallback to login page on error
      Get.offAllNamed(Routes.loginPage);
    }
  }

  /// Handle registration success and redirect based on next_step
  static Future<void> handleRegistrationSuccess(Map<String, dynamic> response) async {
    try {
      log('🛤️ AuthRedirectHandler: Handling registration success...');

      // Store auth data first
      await AuthStorage.storeAuthData(response);

      final nextStep = response['next_step'] ?? 'verify_email';
      final accountStatus = response['account_status'] ?? 'email_pending';

      log('📊 AuthRedirectHandler: Redirecting based on next_step: $nextStep');
      log('📊 AuthRedirectHandler: Account status: $accountStatus');

      await _handleRedirect(nextStep, response);

    } catch (e) {
      log('❌ AuthRedirectHandler: Error handling registration success: $e');
      // For registration errors, go to email verification as fallback
      Get.offAllNamed(Routes.emailVerificationPage);
    }
  }

  /// Core redirect logic based on registration_stage.can_access_app (NEW WORKFLOW)
  static Future<void> _handleRedirect(String nextStep, Map<String, dynamic> response) async {
    log('🔍 AuthRedirectHandler: Full response data: $response');
    final registrationStage = response['registration_stage'] as Map<String, dynamic>?;
    log('🔍 AuthRedirectHandler: registration_stage = $registrationStage');

    // 🚨 NEW WORKFLOW: Check can_access_app first
    if (registrationStage != null) {
      final canAccessApp = registrationStage['can_access_app'] == true;
      log('🔍 AuthRedirectHandler: can_access_app = $canAccessApp');
      log('🔍 AuthRedirectHandler: All registrationStage keys: ${registrationStage.keys.toList()}');

      if (canAccessApp) {
        // User can access the app - go to home page
        log('✅ AuthRedirectHandler: User can access app - redirecting to home');
        _showMessage(
          'Welcome to TIRI!',
          'Your account is ready. Welcome to the community!',
          const Color.fromRGBO(0, 140, 170, 1),
        );
        Get.offAllNamed(Routes.homePage);
        return;
      }

      // User cannot access app - check email verification status
      final isEmailVerified = registrationStage['is_email_verified'] == true || registrationStage['isEmailVerified'] == true;
      log('🔍 AuthRedirectHandler: is_email_verified = $isEmailVerified');

      if (!isEmailVerified) {
        // Email not verified - go to email verification page + auto-send email
        log('📧 AuthRedirectHandler: Email not verified - redirecting to email verification');

        // Auto-send verification email
        await _autoSendVerificationEmail();

        _showMessage(
          'Email Verification Required',
          'A new verification email has been sent. Please check your email and click the verification link to continue.',
          Colors.orange,
        );
        Get.offAllNamed(Routes.emailVerificationPage);
        return;
      }

      // Email verified but not approved - check approval status
      final isApproved = registrationStage['is_approved'] == true || registrationStage['isApproved'] == true;
      log('🔍 AuthRedirectHandler: is_approved = $isApproved');

      if (!isApproved) {
        // Email verified but not approved - show popup and stay on login page
        log('⚠️ AuthRedirectHandler: User not approved - showing rejection popup');

        // Show popup with rejection message
        Get.dialog(
          AlertDialog(
            title: const Text('Login Not Available'),
            content: const Text('You cannot login now. Your referrer has not yet approved your account. Please wait for approval or contact your referrer.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        // Don't navigate away - stay on login page
        return;
      }
    }

    // FALLBACK: If no registration_stage data, use legacy next_step logic
    log('⚠️ AuthRedirectHandler: No registration_stage data - falling back to next_step logic');
    switch (nextStep) {
      case 'verify_email':
        log('📧 AuthRedirectHandler: Redirecting to email verification');

        // Auto-send verification email
        await _autoSendVerificationEmail();

        _showMessage(
          'Verification Required',
          'A new verification email has been sent. Please check your email and click the verification link to continue.',
          Colors.orange,
        );
        Get.offAllNamed(Routes.emailVerificationPage);
        break;

      case 'waiting_for_approval':
      case 'needs_referral_approval':
        log('⏳ AuthRedirectHandler: Redirecting to pending approval');
        final referrerEmail = registrationStage?['referrer_email'] ?? 'your referrer';
        _showMessage(
          'Approval Pending',
          'Your registration is waiting for approval from $referrerEmail.',
          Colors.orange,
        );
        Get.offAllNamed(Routes.pendingApprovalPage);
        break;

      case 'approval_rejected':
        log('❌ AuthRedirectHandler: Redirecting to rejection screen');
        _showMessage(
          'Registration Rejected',
          'Your registration was not approved by the referrer.',
          const Color.fromRGBO(176, 48, 48, 1),
        );
        Get.offAllNamed(Routes.rejectionScreen);
        break;

      case 'complete_profile':
        log('🏠 AuthRedirectHandler: Complete profile - redirecting to home page');
        _showMessage(
          'Welcome to TIRI!',
          'Your account is ready. Welcome to the community!',
          const Color.fromRGBO(0, 140, 170, 1),
        );
        Get.offAllNamed(Routes.homePage);
        break;

      case 'ready':
        log('🏠 AuthRedirectHandler: Redirecting to home page');
        _showMessage(
          'Welcome to TIRI!',
          'Your account is ready. Welcome to the community!',
          const Color.fromRGBO(0, 140, 170, 1),
        );
        Get.offAllNamed(Routes.homePage);
        break;

      default:
        log('⚠️ AuthRedirectHandler: Unknown next_step: $nextStep, defaulting to email verification');

        // Auto-send verification email for unknown states
        await _autoSendVerificationEmail();

        _showMessage(
          'Verification Required',
          'A new verification email has been sent. Please verify your email address to continue.',
          Colors.orange,
        );
        Get.offAllNamed(Routes.emailVerificationPage);
    }
  }

  /// Show a snackbar message
  static void _showMessage(String title, String message, Color backgroundColor) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Get route path from next_step without navigation
  static String getRouteFromNextStep(String nextStep) {
    switch (nextStep) {
      case 'verify_email':
        return Routes.emailVerificationPage;
      case 'waiting_for_approval':
      case 'needs_referral_approval':
        return Routes.pendingApprovalPage;
      case 'approval_rejected':
        return Routes.rejectionScreen;
      case 'complete_profile':
        return Routes.homePage; // Fallback to home since profileSetupPage doesn't exist
      case 'ready':
        return Routes.homePage;
      default:
        return Routes.emailVerificationPage;
    }
  }

  /// Check if user should be redirected from current route
  static Future<bool> shouldRedirectFromCurrentRoute() async {
    try {
      final currentRoute = Get.currentRoute;
      final nextStep = await AuthStorage.getNextStep();
      final accountStatus = await AuthStorage.getAccountStatus();

      if (nextStep == null && accountStatus == null) {
        return false;
      }

      final expectedRoute = getRouteFromNextStep(nextStep ?? '');

      log('🤔 AuthRedirectHandler: Current: $currentRoute, Expected: $expectedRoute');

      return currentRoute != expectedRoute;
    } catch (e) {
      log('❌ AuthRedirectHandler: Error checking redirect: $e');
      return false;
    }
  }

  /// Redirect to correct route based on stored auth state
  static Future<void> redirectToCorrectRoute() async {
    try {
      final nextStep = await AuthStorage.getNextStep();

      if (nextStep != null) {
        final correctRoute = getRouteFromNextStep(nextStep);
        log('🛤️ AuthRedirectHandler: Redirecting to correct route: $correctRoute');
        Get.offAllNamed(correctRoute);
      }
    } catch (e) {
      log('❌ AuthRedirectHandler: Error redirecting to correct route: $e');
    }
  }

  /// Handle email verification completion
  static Future<void> handleEmailVerificationComplete() async {
    try {
      log('✅ AuthRedirectHandler: Email verification complete - checking next step');

      // Check current auth state
      final authState = await AuthStorage.getAuthState();
      final nextStep = authState['next_step'];
      final accountStatus = authState['account_status'];

      log('📊 AuthRedirectHandler: Post-verification - NextStep: $nextStep, Status: $accountStatus');

      // Update next step based on current state
      if (accountStatus == 'email_pending') {
        await AuthStorage.updateAccountStatus('email_verified');
        await AuthStorage.updateNextStep('waiting_for_approval');

        _showMessage(
          'Email Verified!',
          'Your email has been verified. Waiting for approval from your referrer.',
          Colors.green,
        );

        Get.offAllNamed(Routes.pendingApprovalPage);
      } else {
        // Redirect based on existing next step
        await redirectToCorrectRoute();
      }

    } catch (e) {
      log('❌ AuthRedirectHandler: Error handling email verification complete: $e');
      Get.offAllNamed(Routes.pendingApprovalPage);
    }
  }

  /// Handle approval status change
  static Future<void> handleApprovalStatusChange(String newStatus) async {
    try {
      log('📊 AuthRedirectHandler: Handling approval status change to: $newStatus');

      switch (newStatus) {
        case 'approved':
          await AuthStorage.updateAccountStatus('approved');
          await AuthStorage.updateNextStep('ready');

          _showMessage(
            'Approved! 🎉',
            'Your registration has been approved. Welcome to TIRI!',
            const Color.fromRGBO(0, 140, 170, 1),
          );

          Get.offAllNamed(Routes.homePage);
          break;

        case 'rejected':
          await AuthStorage.updateAccountStatus('rejected');
          await AuthStorage.updateNextStep('approval_rejected');

          _showMessage(
            'Registration Rejected',
            'Your registration was not approved by the referrer.',
            const Color.fromRGBO(176, 48, 48, 1),
          );

          Get.offAllNamed(Routes.rejectionScreen);
          break;

        case 'expired':
          await AuthStorage.updateAccountStatus('expired');
          await AuthStorage.clearAuthData();

          _showMessage(
            'Approval Expired',
            'Your approval request has expired. Please register again.',
            Colors.orange,
          );

          Get.offAllNamed(Routes.loginPage);
          break;

        default:
          log('⚠️ AuthRedirectHandler: Unknown approval status: $newStatus');
      }

    } catch (e) {
      log('❌ AuthRedirectHandler: Error handling approval status change: $e');
    }
  }

  /// Clear all auth data and redirect to login
  static Future<void> clearAuthAndRedirectToLogin() async {
    try {
      await AuthStorage.clearAuthData();
      Get.offAllNamed(Routes.loginPage);

      _showMessage(
        'Session Cleared',
        'Please log in again.',
        const Color.fromRGBO(176, 48, 48, 1),
      );
    } catch (e) {
      log('❌ AuthRedirectHandler: Error clearing auth: $e');
    }
  }

  /// Auto-send verification email for unverified users
  static Future<void> _autoSendVerificationEmail() async {
    try {
      log('📧 AuthRedirectHandler: Auto-sending verification email...');

      final authService = Get.find<AuthService>();
      final result = await authService.resendVerificationEmail();

      if (result.isSuccess) {
        log('✅ AuthRedirectHandler: Verification email sent automatically');
      } else {
        log('❌ AuthRedirectHandler: Failed to auto-send verification email: ${result.message}');
      }
    } catch (e) {
      log('❌ AuthRedirectHandler: Error auto-sending verification email: $e');
    }
  }
}