// lib/services/api_error_handler.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_storage.dart';

/// ApiErrorHandler provides comprehensive error handling for authentication scenarios
///
/// Handles:
/// - HTTP status code mapping to user-friendly messages
/// - Token expiry detection and cleanup
/// - Account deletion/expiry scenarios
/// - Network and server errors
/// - Automatic navigation for auth errors
class ApiErrorHandler {

  /// Handle authentication-related errors and return user-friendly messages
  static String handleAuthError(int statusCode, Map<String, dynamic>? errorBody) {
    log('🚨 ApiErrorHandler: Handling auth error - Status: $statusCode, Body: $errorBody');

    switch (statusCode) {
      case 400:
        return _handleBadRequestError(errorBody);
      case 401:
        return _handleUnauthorizedError(errorBody);
      case 403:
        return _handleForbiddenError(errorBody);
      case 404:
        return _handleNotFoundError(errorBody);
      case 429:
        return 'Too many attempts. Please try again later';
      case 500:
        return 'Server error. Please try again later';
      case 502:
        return 'Service temporarily unavailable. Please try again';
      case 503:
        return 'Service maintenance in progress. Please try again later';
      default:
        return 'An unexpected error occurred. Please try again';
    }
  }

  /// Handle 400 Bad Request errors
  static String _handleBadRequestError(Map<String, dynamic>? errorBody) {
    if (errorBody == null) return 'Invalid request data';

    // Check for Django DRF non_field_errors
    if (errorBody.containsKey('non_field_errors')) {
      final errors = errorBody['non_field_errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }

    // Check for field-specific errors
    if (errorBody.containsKey('email')) {
      final emailErrors = errorBody['email'];
      if (emailErrors is List && emailErrors.isNotEmpty) {
        return 'Email: ${emailErrors.first}';
      }
    }

    if (errorBody.containsKey('password')) {
      final passwordErrors = errorBody['password'];
      if (passwordErrors is List && passwordErrors.isNotEmpty) {
        return 'Password: ${passwordErrors.first}';
      }
    }

    if (errorBody.containsKey('referral_code')) {
      final codeErrors = errorBody['referral_code'];
      if (codeErrors is List && codeErrors.isNotEmpty) {
        return 'Referral code: ${codeErrors.first}';
      }
    }

    // Check for detail field
    if (errorBody.containsKey('detail')) {
      return errorBody['detail'].toString();
    }

    // Check for message field
    if (errorBody.containsKey('message')) {
      return errorBody['message'].toString();
    }

    return 'Invalid request data. Please check your input';
  }

  /// Handle 401 Unauthorized errors
  static String _handleUnauthorizedError(Map<String, dynamic>? errorBody) {
    if (errorBody != null && errorBody.containsKey('detail')) {
      final detail = errorBody['detail'].toString().toLowerCase();

      if (detail.contains('token') && detail.contains('expired')) {
        // Token expired - trigger cleanup
        _handleTokenExpiry();
        return 'Your session has expired. Please log in again';
      }

      if (detail.contains('invalid') && detail.contains('token')) {
        // Invalid token - trigger cleanup
        _handleTokenExpiry();
        return 'Invalid session. Please log in again';
      }
    }

    return 'Invalid email or password';
  }

  /// Handle 403 Forbidden errors
  static String _handleForbiddenError(Map<String, dynamic>? errorBody) {
    if (errorBody != null) {
      if (errorBody.containsKey('detail')) {
        final detail = errorBody['detail'].toString().toLowerCase();

        if (detail.contains('suspended')) {
          return 'Your account has been suspended. Please contact support';
        }

        if (detail.contains('approval') && detail.contains('pending')) {
          return 'Your account is pending approval from your referrer';
        }

        if (detail.contains('rejected')) {
          return 'Your registration was not approved. Please contact support';
        }

        if (detail.contains('expired')) {
          return 'Your approval period has expired. Please register again';
        }
      }

      if (errorBody.containsKey('message')) {
        return errorBody['message'].toString();
      }
    }

    return 'Access denied. Please check your account status';
  }

  /// Handle 404 Not Found errors
  static String _handleNotFoundError(Map<String, dynamic>? errorBody) {
    if (errorBody != null) {
      if (errorBody.containsKey('detail')) {
        final detail = errorBody['detail'].toString().toLowerCase();

        if (detail.contains('account') && detail.contains('not found')) {
          // Account was deleted due to expiry
          _handleAccountDeletion();
          return 'Your account was not found. It may have been deleted due to inactivity';
        }
      }

      if (errorBody.containsKey('message')) {
        return errorBody['message'].toString();
      }
    }

    return 'Resource not found. Please try again';
  }

  /// Handle token expiry by clearing local data and redirecting
  static void _handleTokenExpiry() async {
    try {
      log('🧹 ApiErrorHandler: Handling token expiry - clearing auth data');
      await AuthStorage.clearAuthData();

      // Navigate to login screen
      Get.offAllNamed(Routes.loginPage);

      // Show snackbar
      Get.snackbar(
        'Session Expired',
        'Your session has expired. Please log in again',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color.fromRGBO(176, 48, 48, 1),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      log('❌ ApiErrorHandler: Error handling token expiry: $e');
    }
  }

  /// Handle account deletion scenarios
  static void _handleAccountDeletion() async {
    try {
      log('🧹 ApiErrorHandler: Handling account deletion - clearing auth data');
      await AuthStorage.clearAuthData();

      // Navigate to login screen
      Get.offAllNamed(Routes.loginPage);

      // Show account expired dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Account Expired'),
          content: const Text(
            'Your account verification period has expired and your account has been deleted. Please register again with a new referral code.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed(Routes.registerPage);
              },
              child: const Text('Register Again'),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      log('❌ ApiErrorHandler: Error handling account deletion: $e');
    }
  }

  /// Extract error message from DioException
  static String extractErrorMessage(DioException error) {
    try {
      final response = error.response;
      final statusCode = response?.statusCode ?? 0;

      log('🚨 ApiErrorHandler: Extracting error - Type: ${error.type}, Status: $statusCode');

      // Handle network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet connection';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection';
      }

      // Handle HTTP errors
      if (response != null && response.data != null) {
        Map<String, dynamic>? errorBody;

        if (response.data is Map<String, dynamic>) {
          errorBody = response.data as Map<String, dynamic>;
        } else if (response.data is String) {
          try {
            errorBody = {'message': response.data as String};
          } catch (e) {
            errorBody = {'message': 'Server returned an error'};
          }
        }

        return handleAuthError(statusCode, errorBody);
      }

      return 'Network error. Please try again';
    } catch (e) {
      log('❌ ApiErrorHandler: Error extracting message: $e');
      return 'An unexpected error occurred';
    }
  }

  /// Check if error indicates account status issue
  static bool isAccountStatusError(DioException error) {
    final response = error.response;
    if (response?.data != null && response!.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final detail = data['detail']?.toString().toLowerCase() ?? '';

      return detail.contains('approval') ||
             detail.contains('verification') ||
             detail.contains('suspended') ||
             detail.contains('expired') ||
             detail.contains('rejected');
    }
    return false;
  }

  /// Get suggested route based on error type
  static String? getSuggestedRoute(DioException error) {
    final response = error.response;
    if (response?.data != null && response!.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final detail = data['detail']?.toString().toLowerCase() ?? '';

      if (detail.contains('verification')) {
        return Routes.emailVerificationPage;
      } else if (detail.contains('approval') && detail.contains('pending')) {
        return Routes.pendingApprovalPage;
      } else if (detail.contains('rejected')) {
        return Routes.rejectionScreen;
      } else if (detail.contains('expired')) {
        return Routes.expiredScreen ?? Routes.loginPage;
      }
    }
    return null;
  }

  /// Handle error with automatic navigation
  static void handleErrorWithNavigation(DioException error) {
    final message = extractErrorMessage(error);
    final route = getSuggestedRoute(error);

    if (route != null) {
      Get.offAllNamed(route);
    }

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(176, 48, 48, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}