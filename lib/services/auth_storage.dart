// lib/services/auth_storage.dart

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthStorage class for managing authentication data locally
///
/// Handles storage and retrieval of:
/// - Access and refresh tokens
/// - User data
/// - Account status
/// - Next step routing information
/// - Registration stage details
class AuthStorage {
  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _accountStatusKey = 'account_status';
  static const String _nextStepKey = 'next_step';
  static const String _registrationStageKey = 'registration_stage';

  /// Store complete authentication data from login/register response
  static Future<void> storeAuthData(Map<String, dynamic> authResponse) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store tokens
      if (authResponse['tokens'] != null) {
        final tokens = authResponse['tokens'] as Map<String, dynamic>;
        await prefs.setString(_accessTokenKey, tokens['access'] ?? '');
        await prefs.setString(_refreshTokenKey, tokens['refresh'] ?? '');
      }

      // Store user data
      if (authResponse['user'] != null) {
        await prefs.setString(_userDataKey, jsonEncode(authResponse['user']));
      }

      // Store account status and next step
      await prefs.setString(_accountStatusKey, authResponse['account_status'] ?? '');
      await prefs.setString(_nextStepKey, authResponse['next_step'] ?? '');

      // Store registration stage if available
      if (authResponse['registration_stage'] != null) {
        await prefs.setString(_registrationStageKey, jsonEncode(authResponse['registration_stage']));
      }

      log('✅ AuthStorage: Authentication data stored successfully');
    } catch (e) {
      log('❌ AuthStorage: Error storing auth data: $e');
      rethrow;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      log('❌ AuthStorage: Error getting access token: $e');
      return null;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      log('❌ AuthStorage: Error getting refresh token: $e');
      return null;
    }
  }

  /// Get next step for routing
  static Future<String?> getNextStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nextStepKey);
    } catch (e) {
      log('❌ AuthStorage: Error getting next step: $e');
      return null;
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userDataKey);
      return userData != null ? jsonDecode(userData) : null;
    } catch (e) {
      log('❌ AuthStorage: Error getting user data: $e');
      return null;
    }
  }

  /// Get account status
  static Future<String?> getAccountStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accountStatusKey);
    } catch (e) {
      log('❌ AuthStorage: Error getting account status: $e');
      return null;
    }
  }

  /// Get registration stage
  static Future<Map<String, dynamic>?> getRegistrationStage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registrationStage = prefs.getString(_registrationStageKey);
      return registrationStage != null ? jsonDecode(registrationStage) : null;
    } catch (e) {
      log('❌ AuthStorage: Error getting registration stage: $e');
      return null;
    }
  }

  /// Update next step only
  static Future<void> updateNextStep(String nextStep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nextStepKey, nextStep);
      log('✅ AuthStorage: Next step updated to: $nextStep');
    } catch (e) {
      log('❌ AuthStorage: Error updating next step: $e');
    }
  }

  /// Update account status only
  static Future<void> updateAccountStatus(String accountStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountStatusKey, accountStatus);
      log('✅ AuthStorage: Account status updated to: $accountStatus');
    } catch (e) {
      log('❌ AuthStorage: Error updating account status: $e');
    }
  }

  /// Update tokens only (for refresh token operations)
  static Future<void> updateTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      log('✅ AuthStorage: Tokens updated successfully');
    } catch (e) {
      log('❌ AuthStorage: Error updating tokens: $e');
    }
  }

  /// Check if user has valid stored tokens
  static Future<bool> hasValidTokens() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      return accessToken != null && accessToken.isNotEmpty &&
             refreshToken != null && refreshToken.isNotEmpty;
    } catch (e) {
      log('❌ AuthStorage: Error checking token validity: $e');
      return false;
    }
  }

  /// Clear all authentication data
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_accountStatusKey);
      await prefs.remove(_nextStepKey);
      await prefs.remove(_registrationStageKey);
      log('✅ AuthStorage: All authentication data cleared');
    } catch (e) {
      log('❌ AuthStorage: Error clearing auth data: $e');
    }
  }

  /// Clear only tokens (for logout but keep user data)
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      log('✅ AuthStorage: Tokens cleared');
    } catch (e) {
      log('❌ AuthStorage: Error clearing tokens: $e');
    }
  }

  /// Get complete auth state for debugging
  static Future<Map<String, dynamic>> getAuthState() async {
    try {
      return {
        'access_token': await getAccessToken(),
        'refresh_token': await getRefreshToken(),
        'user_data': await getUserData(),
        'account_status': await getAccountStatus(),
        'next_step': await getNextStep(),
        'registration_stage': await getRegistrationStage(),
        'has_valid_tokens': await hasValidTokens(),
      };
    } catch (e) {
      log('❌ AuthStorage: Error getting auth state: $e');
      return {};
    }
  }
}