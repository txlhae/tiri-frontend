// lib/services/auth_storage.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  /// Maximum storage size in KB before cleanup
  static const int maxStorageSizeKB = 100;

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

      // Store user data with size check
      if (authResponse['user'] != null) {
        await _storeWithSizeCheck(prefs, _userDataKey, jsonEncode(authResponse['user']));
      }

      // Store account status and next step
      await prefs.setString(_accountStatusKey, authResponse['account_status'] ?? '');
      await prefs.setString(_nextStepKey, authResponse['next_step'] ?? '');

      // Store registration stage if available
      if (authResponse['registration_stage'] != null) {
        await _storeWithSizeCheck(prefs, _registrationStageKey, jsonEncode(authResponse['registration_stage']));
      }

      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      
      return null;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      
      return null;
    }
  }

  /// Get next step for routing
  static Future<String?> getNextStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nextStepKey);
    } catch (e) {
      
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
      
      return null;
    }
  }

  /// Get account status
  static Future<String?> getAccountStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accountStatusKey);
    } catch (e) {
      
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
      
      return null;
    }
  }

  /// Update next step only
  static Future<void> updateNextStep(String nextStep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nextStepKey, nextStep);
      
    } catch (e) {
      
    }
  }

  /// Update account status only
  static Future<void> updateAccountStatus(String accountStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountStatusKey, accountStatus);
      
    } catch (e) {
      
    }
  }

  /// Update tokens only (for refresh token operations)
  static Future<void> updateTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      
    } catch (e) {
      
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
      
    } catch (e) {
      
    }
  }

  /// Clear only tokens (for logout but keep user data)
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      
    } catch (e) {
      
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
        'storage_size_kb': await getStorageSizeKB(),
      };
    } catch (e) {

      return {};
    }
  }

  /// Get current storage size in KB
  static Future<double> getStorageSizeKB() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int totalSize = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          totalSize += key.length * 2; // UTF-16 for key
          totalSize += value.length * 2; // UTF-16 for value
        } else if (value != null) {
          totalSize += key.length * 2;
          totalSize += value.toString().length * 2;
        }
      }

      return totalSize / 1024.0; // Convert to KB
    } catch (e) {
      if (kDebugMode) {
      }
      return 0.0;
    }
  }

  /// Check if storage cleanup is needed
  static Future<bool> isCleanupNeeded() async {
    final sizeKB = await getStorageSizeKB();
    return sizeKB > maxStorageSizeKB;
  }

  /// Perform storage cleanup (remove non-essential data)
  static Future<void> performCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Essential keys to preserve
      final essentialKeys = {
        _accessTokenKey,
        _refreshTokenKey,
        _userDataKey,
        _accountStatusKey,
        _nextStepKey,
        _registrationStageKey,
      };

      final sizeBefore = await getStorageSizeKB();

      // Remove non-essential keys
      int removedCount = 0;
      for (final key in keys) {
        if (!essentialKeys.contains(key)) {
          await prefs.remove(key);
          removedCount++;
        }
      }

      final sizeAfter = await getStorageSizeKB();

      if (kDebugMode) {
            'size reduced from ${sizeBefore.toStringAsFixed(2)}KB to ${sizeAfter.toStringAsFixed(2)}KB');
      }
    } catch (e) {
      if (kDebugMode) {
      }
    }
  }

  /// Store data with size check
  static Future<void> _storeWithSizeCheck(SharedPreferences prefs, String key, String value) async {
    await prefs.setString(key, value);

    // Check if cleanup is needed after storing
    if (await isCleanupNeeded()) {
      await performCleanup();
    }
  }
}
