/// Enhanced Deep Link Service for Email Verification and App Navigation
/// Handles incoming deep links from email verification and other sources
/// Supports token extraction and automatic authentication
library;

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';

class DeepLinkService extends GetxService {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  @override
  Future<void> onInit() async {
    super.onInit();
    _appLinks = AppLinks();
    await _initializeDeepLinking();
  }

  /// Initialize deep linking and set up listeners
  Future<void> _initializeDeepLinking() async {
    try {
      
      // Check for initial link if app was launched via deep link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
      
      // Listen for incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri);
        },
        onError: (err) {
        },
      );
      
      
    } catch (e) {
      // Error handled silently
    }
  }

  // =============================================================================
  // DEEP LINK HANDLING
  // =============================================================================
  
  /// Handle incoming deep links and route to appropriate handlers
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      
      // Handle different types of deep links
      if (_isEmailVerificationLink(uri)) {
        await _handleEmailVerificationLink(uri);
      } else if (_isPasswordResetLink(uri)) {
        await _handlePasswordResetLink(uri);
      } else {
        _handleGenericLink(uri);
      }
      
    } catch (e) {
      // Error handled silently
      Get.snackbar(
        'Link Error',
        'Unable to process the link. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Check if the link is an email verification link
  bool _isEmailVerificationLink(Uri uri) {
    // TIRI scheme: tiri://verify or tiri://verified
    if (uri.scheme == 'tiri' && (uri.host == 'verify' || uri.host == 'verified')) {
      return true;
    }
    
    // HTTPS scheme: https://domain/api/auth/verify-email/...
    if (uri.scheme == 'https' && uri.path.contains('/api/auth/verify-email')) {
      return true;
    }
    
    // Universal link: https://tiri.app/verify/...
    if (uri.scheme == 'https' && uri.host == 'tiri.app' && uri.path.startsWith('/verify')) {
      return true;
    }
    
    return false;
  }

  /// Check if the link is a password reset link
  bool _isPasswordResetLink(Uri uri) {
    return (uri.scheme == 'tiri' && uri.host == 'reset') ||
           (uri.scheme == 'https' && uri.host == 'tiri.app' && uri.path.startsWith('/reset'));
  }

  // =============================================================================
  // EMAIL VERIFICATION HANDLER (ENHANCED)
  // =============================================================================
  
  /// Handle email verification deep links with enhanced JWT token workflow
  Future<void> _handleEmailVerificationLink(Uri uri) async {
    try {
      
      // Show processing indicator
      _showProcessingDialog('Verifying your email and checking status...');
      
      // Check if user is authenticated first
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated) {
        _closeProcessingDialog();
        _showErrorSnackbar(
          'Authentication Required', 
          'Please log in to check your verification status.'
        );
        
        // Navigate to login
        Get.offAllNamed(Routes.loginPage);
        return;
      }
      
      
      // Call enhanced verification status API (with JWT token support)
      final success = await authController.checkVerificationStatus();
      
      _closeProcessingDialog();
      
      if (success) {
        // Success is handled by AuthController - it will save tokens, navigate and show messages
      } else {
        // Failure cases are handled by AuthController with appropriate navigation
      }
      
    } catch (e) {
      // Error handled silently
      _closeProcessingDialog();
      _showErrorSnackbar(
        'Verification Failed', 
        'Unable to process email verification. Please try logging in manually.'
      );
      
      // Fallback navigation
      Get.offAllNamed(Routes.loginPage);
    }
  }

  // =============================================================================
  // PASSWORD RESET HANDLER
  // =============================================================================
  
  /// Handle password reset deep links
  Future<void> _handlePasswordResetLink(Uri uri) async {
    try {
      
      final token = uri.queryParameters['token'];
      final uid = uri.queryParameters['uid'];
      
      if (token == null || uid == null) {
        _showErrorSnackbar('Invalid Link', 'The password reset link is invalid or expired.');
        return;
      }
      
      // Navigate to password reset screen with token
      Get.toNamed(Routes.forgotPasswordPage, arguments: {
        'token': token,
        'uid': uid,
        'fromDeepLink': true,
      });
      
    } catch (e) {
      // Error handled silently
    }
  }

  // =============================================================================
  // GENERIC LINK HANDLER
  // =============================================================================
  
  /// Handle generic deep links (navigation, etc.)
  void _handleGenericLink(Uri uri) {
    
    // Navigate based on authentication status
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      Get.offAllNamed(Routes.homePage);
    } else {
      Get.offAllNamed(Routes.loginPage);
    }
  }

  // =============================================================================
  // UI HELPER METHODS
  // =============================================================================
  
  /// Show processing dialog
  void _showProcessingDialog(String message) {
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Close processing dialog
  void _closeProcessingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(176, 48, 48, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // =============================================================================
  // TESTING METHODS (Development only)
  // =============================================================================
  
  /// Public method for testing deep link handling in development
  Future<void> testHandleDeepLink(Uri uri) async {
    await _handleDeepLink(uri);
  }

  // =============================================================================
  // CLEANUP
  // =============================================================================
  
  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
