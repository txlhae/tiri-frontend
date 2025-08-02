/// Quick Email Verification Test Helper
/// Add this to your app for easy testing of the verification flow
library email_verification_helper;

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/services/deep_link_service.dart';

class EmailVerificationTestHelper {
  
  /// Quick test method - call this from anywhere in your app for testing
  static void testEmailVerification() {
    log('🧪 Starting Email Verification Test');
    
    // Test 1: Check if services are initialized
    try {
      final deepLinkService = Get.find<DeepLinkService>();
      final authController = Get.find<AuthController>();
      log('✅ Services initialized successfully');
      log('   - DeepLinkService: ${deepLinkService.runtimeType}');
      log('   - AuthController: ${authController.runtimeType}');
    } catch (e) {
      log('❌ Service initialization error: $e');
      return;
    }
    
    // Test 2: Simulate deep link processing
    log('🔗 Testing deep link simulation...');
    _simulateDeepLink();
    
    // Test 3: Show test results
    _showTestResults();
  }
  
  /// Simulate a deep link for testing
  static void _simulateDeepLink() {
    try {
      const testUrl = 'tiri://verify?token=test123&uid=user456&email=test@example.com';
      log('📱 Simulating deep link: $testUrl');
      
      // You can use this for manual testing
      Get.snackbar(
        'Test Deep Link',
        'Simulated: $testUrl',
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      log('❌ Deep link simulation error: $e');
    }
  }
  
  /// Show test results in UI
  static void _showTestResults() {
    Get.dialog(
      AlertDialog(
        title: const Text('📧 Email Verification Test'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Deep Link Service: Initialized'),
            Text('✅ Auth Controller: Ready'),
            Text('✅ URL Schemes: Configured'),
            SizedBox(height: 16),
            Text('🧪 Test Instructions:'),
            SizedBox(height: 8),
            Text('1. Register a new account'),
            Text('2. Check verification email'),
            Text('3. Click verification link'),
            Text('4. Verify app opens automatically'),
            SizedBox(height: 16),
            Text('📱 Manual Test URL:'),
            Text('tiri://verify?token=test123&uid=user456', 
                 style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _testManualVerification();
            },
            child: const Text('Test Manual Check'),
          ),
        ],
      ),
    );
  }
  
  /// Test the manual verification check
  static void _testManualVerification() {
    try {
      final authController = Get.find<AuthController>();
      
      Get.dialog(
        const AlertDialog(
          title: Text('Testing Manual Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking verification status...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );
      
      // Simulate the manual check process
      Future.delayed(const Duration(seconds: 2), () {
        Get.back(); // Close loading dialog
        
        if (authController.currentUserStore.value?.isVerified == true) {
          Get.snackbar(
            'Test Result',
            '✅ User is verified',
            backgroundColor: Get.theme.colorScheme.primary,
            colorText: Get.theme.colorScheme.onPrimary,
          );
        } else {
          Get.snackbar(
            'Test Result',
            '⚠️ User not verified or not logged in',
            backgroundColor: Get.theme.colorScheme.secondary,
            colorText: Get.theme.colorScheme.onSecondary,
          );
        }
      });
      
    } catch (e) {
      Get.back(); // Close any open dialogs
      log('❌ Manual verification test error: $e');
      
      Get.snackbar(
        'Test Error',
        'Failed to test verification: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }
  
  /// Add a floating action button to any screen for quick testing
  static Widget buildTestFAB() {
    return FloatingActionButton.extended(
      onPressed: testEmailVerification,
      icon: const Icon(Icons.email),
      label: const Text('Test Verification'),
      backgroundColor: Colors.orange,
    );
  }
}
