import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/services/deep_link_service.dart';
import 'package:kind_clock/controllers/auth_controller.dart';

/// Development helper for testing deep link functionality
/// Updated for new time-bounded verification workflow
class DeepLinkTestService {
  static const _tag = 'DeepLinkTest';
  
  /// Test enhanced verification workflow with direct JWT tokens
  static Future<void> testEnhancedVerificationWorkflow() async {
    log('🧪 Testing enhanced verification workflow (direct JWT tokens)', name: _tag);
    
    // Simulate enhanced workflow URL - just indicates verification completed
    final testUri = Uri.parse('tiri://verified');
    
    final deepLinkService = Get.find<DeepLinkService>();
    await deepLinkService.testHandleDeepLink(testUri);
  }
  
  /// Test enhanced verification status API directly
  static Future<void> testEnhancedVerificationStatusAPI() async {
    log('🧪 Testing enhanced verification status API call', name: _tag);
    
    // This will call the enhanced checkVerificationStatus method
    final authController = Get.find<AuthController>();
    await authController.checkVerificationStatus();
  }
  
  /// Test verification with traditional tiri://verify for backward compatibility
  static Future<void> testLegacyVerificationScheme() async {
    log('🧪 Testing legacy verification scheme', name: _tag);
    
    final testUri = Uri.parse('tiri://verify');
    
    final deepLinkService = Get.find<DeepLinkService>();
    await deepLinkService.testHandleDeepLink(testUri);
  }
  
  /// Test password reset deep link
  static Future<void> testPasswordReset() async {
    log('🧪 Testing password reset deep link', name: _tag);
    
    final testUri = Uri.parse(
      'tiri://reset?uid=abc123&token=reset-token-123'
    );
    
    final deepLinkService = Get.find<DeepLinkService>();
    await deepLinkService.testHandleDeepLink(testUri);
  }
  
  /// Print all supported deep link formats for enhanced workflow
  static void printSupportedFormats() {
    log('📋 Supported Deep Link Formats (Enhanced Workflow):', name: _tag);
    log('', name: _tag);
    log('1. Enhanced Time-Bounded Verification:', name: _tag);
    log('   tiri://verified (no tokens - calls enhanced verification-status API)', name: _tag);
    log('', name: _tag);
    log('2. Legacy Verification (backward compatibility):', name: _tag);
    log('   tiri://verify (calls enhanced verification-status API)', name: _tag);
    log('', name: _tag);
    log('3. Password Reset:', name: _tag);
    log('   tiri://reset?uid=abc123&token=reset-token', name: _tag);
    log('', name: _tag);
    log('🔄 Enhanced API Response Format (Direct JWT Tokens):', name: _tag);
    log('   {', name: _tag);
    log('     "is_verified": true/false,', name: _tag);
    log('     "auto_login": true/false,', name: _tag);
    log('     "message": "...",', name: _tag);
    log('     "access_token": "eyJ0eXAiOiJKV1Q...", // if auto_login=true', name: _tag);
    log('     "refresh_token": "eyJ0eXAiOiJKV1Q...", // if auto_login=true', name: _tag);
    log('     "user": { "userId": "...", "email": "...", ... } // if auto_login=true', name: _tag);
    log('   }', name: _tag);
    log('', name: _tag);
    log('🎯 Key Changes from Previous Version:', name: _tag);
    log('   - JWT tokens now directly in response (not nested in "tokens" object)', name: _tag);
    log('   - "access_token" and "refresh_token" fields at root level', name: _tag);
    log('   - Automatic token storage when auto_login=true', name: _tag);
    log('   - Enhanced authentication state management', name: _tag);
  }
}
