/// Deep Link Service for Email Verification and App Navigation
/// Handles incoming deep links from email verification and other sources
library deep_link_service;

import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';

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
      log('🔗 DeepLinkService: Initializing deep linking...');
      
      // Check for initial link if app was launched via deep link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        log('📱 DeepLinkService: App launched with initial link: $initialLink');
        await _handleDeepLink(initialLink);
      }
      
      // Listen for incoming deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          log('📱 DeepLinkService: Received deep link: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          log('❌ DeepLinkService: Error listening to deep links: $err');
        },
      );
      
      log('✅ DeepLinkService: Deep linking initialized successfully');
      
    } catch (e) {
      log('❌ DeepLinkService: Failed to initialize deep linking: $e');
    }
  }

  // =============================================================================
  // DEEP LINK HANDLING
  // =============================================================================
  
  /// Handle incoming deep links and route to appropriate handlers
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      log('🔍 DeepLinkService: Processing deep link: ${uri.toString()}');
      log('   - Scheme: ${uri.scheme}');
      log('   - Host: ${uri.host}');
      log('   - Path: ${uri.path}');
      log('   - Query params: ${uri.queryParameters}');
      
      // Handle different types of deep links
      if (_isEmailVerificationLink(uri)) {
        await _handleEmailVerificationLink(uri);
      } else if (_isPasswordResetLink(uri)) {
        await _handlePasswordResetLink(uri);
      } else {
        log('⚠️ DeepLinkService: Unknown deep link type: ${uri.toString()}');
        _handleGenericLink(uri);
      }
      
    } catch (e) {
      log('❌ DeepLinkService: Error handling deep link: $e');
      Get.snackbar(
        'Link Error',
        'Unable to process the link. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Check if the link is an email verification link
  bool _isEmailVerificationLink(Uri uri) {
    return (uri.scheme == 'tiri' && uri.host == 'verify') ||
           (uri.scheme == 'https' && uri.host == 'tiri.app' && uri.path.startsWith('/verify'));
  }

  /// Check if the link is a password reset link
  bool _isPasswordResetLink(Uri uri) {
    return (uri.scheme == 'tiri' && uri.host == 'reset') ||
           (uri.scheme == 'https' && uri.host == 'tiri.app' && uri.path.startsWith('/reset'));
  }

  // =============================================================================
  // EMAIL VERIFICATION HANDLER
  // =============================================================================
  
  /// Handle email verification deep links
  Future<void> _handleEmailVerificationLink(Uri uri) async {
    try {
      log('📧 DeepLinkService: Processing email verification link');
      
      // Extract verification parameters
      final token = uri.queryParameters['token'];
      final uid = uri.queryParameters['uid'];
      final email = uri.queryParameters['email']; // Optional for better UX
      
      // Validate required parameters
      if (token == null || uid == null) {
        log('❌ DeepLinkService: Missing required verification parameters');
        Get.snackbar(
          'Invalid Link',
          'The verification link is missing required information.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
        return;
      }
      
      log('✅ DeepLinkService: Valid verification parameters found');
      log('   - Token: ${token.substring(0, 10)}...');
      log('   - UID: $uid');
      if (email != null) log('   - Email: $email');
      
      // Show processing indicator
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Verifying your email...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
      
      // Get auth controller and perform verification
      final authController = Get.find<AuthController>();
      await authController.verifyEmail(token, uid);
      
      // Close processing dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
    } catch (e) {
      log('❌ DeepLinkService: Error processing email verification: $e');
      
      // Close processing dialog if open
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      
      Get.snackbar(
        'Verification Failed',
        'Unable to verify your email. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // =============================================================================
  // PASSWORD RESET HANDLER
  // =============================================================================
  
  /// Handle password reset deep links
  Future<void> _handlePasswordResetLink(Uri uri) async {
    try {
      log('🔑 DeepLinkService: Processing password reset link');
      
      final token = uri.queryParameters['token'];
      final uid = uri.queryParameters['uid'];
      
      if (token == null || uid == null) {
        Get.snackbar(
          'Invalid Link',
          'The password reset link is invalid or expired.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      
      // Navigate to password reset screen with token
      Get.toNamed(Routes.forgotPasswordPage, arguments: {
        'token': token,
        'uid': uid,
        'fromDeepLink': true,
      });
      
    } catch (e) {
      log('❌ DeepLinkService: Error processing password reset: $e');
    }
  }

  // =============================================================================
  // GENERIC LINK HANDLER
  // =============================================================================
  
  /// Handle generic deep links (navigation, etc.)
  void _handleGenericLink(Uri uri) {
    log('🔗 DeepLinkService: Handling generic link: ${uri.toString()}');
    
    // You can add more generic link handling here
    // For example, navigation to specific screens, sharing, etc.
    
    // For now, just navigate to home if user is logged in
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn.value) {
      Get.offAllNamed(Routes.homePage);
    } else {
      Get.offAllNamed(Routes.loginPage);
    }
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
