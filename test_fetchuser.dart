// Quick test to verify fetchUser implementation
// This file can be deleted after testing

import 'dart:developer';
import 'package:get/get.dart';
import 'lib/controllers/auth_controller.dart';

void testFetchUser() async {
  // Get AuthController instance
  final authController = Get.find<AuthController>();
  
  // Test fetching a user (replace 'test-user-id' with actual user ID)
  log('🧪 Testing fetchUser implementation...');
  
  try {
    final user = await authController.fetchUser('test-user-id');
    if (user != null) {
      log('✅ fetchUser SUCCESS: ${user.username} (${user.userId})');
      log('📊 User details: Hours: ${user.hours}, Rating: ${user.rating}');
    } else {
      log('❌ fetchUser returned null - check API endpoint or user ID');
    }
  } catch (e) {
    log('💥 fetchUser ERROR: $e');
  }
}
