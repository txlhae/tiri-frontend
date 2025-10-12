// lib/services/error_handler.dart

import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// Centralized Error Handler for API Responses
///
/// Follows the FRONTEND_ERROR_HANDLING_GUIDE.md specifications
/// Extracts Django error messages and converts them to user-friendly messages
class ErrorHandler {
  /// Extract user-friendly error message from any exception
  ///
  /// Handles:
  /// - DioException with Django error responses
  /// - Field-level errors: {"email": ["Error message"]}
  /// - Form-level errors: {"non_field_errors": ["Error message"]}
  /// - General errors: {"error": "message"} or {"detail": "message"}
  /// - Network errors, timeouts, etc.
  static String getErrorMessage(dynamic error, {String? defaultMessage}) {
    if (error is DioException) {
      return _extractDioError(error);
    }

    if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }

    return defaultMessage ?? 'An unexpected error occurred. Please try again.';
  }

  /// Extract error message from DioException
  static String _extractDioError(DioException error) {
    final response = error.response;
    final data = response?.data;

    // Handle Django error responses
    if (data != null && data is Map) {
      final errorMap = Map<String, dynamic>.from(data);

      // 1. Check for non_field_errors (most common in Django)
      if (errorMap.containsKey('non_field_errors')) {
        return _extractFromList(errorMap['non_field_errors']);
      }

      // 2. Check for field-specific errors (email, password, etc.)
      final fieldErrors = _extractFieldErrors(errorMap);
      if (fieldErrors.isNotEmpty) {
        return fieldErrors;
      }

      // 3. Check for detail field (DRF standard)
      if (errorMap.containsKey('detail')) {
        return errorMap['detail'].toString();
      }

      // 4. Check for error field
      if (errorMap.containsKey('error')) {
        final errorValue = errorMap['error'];
        if (errorValue is Map && errorValue.containsKey('message')) {
          return errorValue['message'].toString();
        }
        return errorValue.toString();
      }

      // 5. Check for message field
      if (errorMap.containsKey('message')) {
        return errorMap['message'].toString();
      }
    }

    // Handle string responses
    if (data is String && data.isNotEmpty) {
      return data;
    }

    // Fallback to HTTP status code messages
    return _getStatusCodeMessage(error);
  }

  /// Extract field-specific errors from Django response
  static String _extractFieldErrors(Map<String, dynamic> errorMap) {
    final fieldErrors = <String>[];

    // Common field names to check
    final commonFields = [
      'email', 'password', 'username', 'phone_number', 'country',
      'first_name', 'last_name', 'referral_code', 'title', 'description',
      'location', 'date_needed', 'volunteers_needed', 'content', 'message'
    ];

    for (final field in commonFields) {
      if (errorMap.containsKey(field)) {
        final error = _extractFromList(errorMap[field]);
        if (error.isNotEmpty) {
          // Capitalize field name and add to message
          final fieldName = field.replaceAll('_', ' ');
          final capitalizedField = fieldName[0].toUpperCase() + fieldName.substring(1);
          fieldErrors.add('$capitalizedField: $error');
        }
      }
    }

    return fieldErrors.isEmpty ? '' : fieldErrors.first;
  }

  /// Extract error message from list format
  static String _extractFromList(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final firstError = value.first;
      if (firstError is Map && firstError.containsKey('string')) {
        return firstError['string'].toString();
      }
      if (firstError is Map && firstError.containsKey('message')) {
        return firstError['message'].toString();
      }
      return firstError.toString();
    }
    if (value is String) {
      return value;
    }
    return '';
  }

  /// Get user-friendly message based on HTTP status code
  static String _getStatusCodeMessage(DioException error) {
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This resource already exists or conflicts with existing data.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return _getDioExceptionTypeMessage(error);
    }
  }

  /// Get message based on Dio exception type
  static String _getDioExceptionTypeMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return 'Network error. Please check your connection and try again.';
    }
  }

  /// Show error message to user using GetX snackbar
  static void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show success message to user using GetX snackbar
  static void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  /// Map specific error types to user-friendly messages
  /// Based on FRONTEND_ERROR_HANDLING_GUIDE.md
  static String mapErrorToUserMessage(String technicalError) {
    final errorLower = technicalError.toLowerCase();

    // Authentication errors
    if (errorLower.contains('invalid credentials') ||
        errorLower.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }
    if (errorLower.contains('email not verified')) {
      return 'Please verify your email before logging in.';
    }
    if (errorLower.contains('account not approved')) {
      return 'Your account is pending approval.';
    }
    if (errorLower.contains('account rejected')) {
      return 'Your account registration was not approved.';
    }
    if (errorLower.contains('email already exists')) {
      return 'This email is already registered.';
    }
    if (errorLower.contains('invalid referral code')) {
      return 'Invalid referral code. Please check and try again.';
    }
    if (errorLower.contains('token') && errorLower.contains('invalid')) {
      return 'Invalid or expired link. Please request a new one.';
    }
    if (errorLower.contains('token') && errorLower.contains('expired')) {
      return 'This link has expired. Please request a new one.';
    }

    // Request errors
    if (errorLower.contains('request not found')) {
      return 'This request no longer exists.';
    }
    if (errorLower.contains('request already accepted') ||
        errorLower.contains('already volunteered')) {
      return 'You have already requested to volunteer for this.';
    }
    if (errorLower.contains('request is full')) {
      return 'This request already has enough volunteers.';
    }
    if (errorLower.contains('cannot volunteer for own request')) {
      return 'You cannot volunteer for your own request.';
    }
    if (errorLower.contains('request not started') ||
        errorLower.contains('request not in progress')) {
      return 'This request has not been started yet.';
    }
    if (errorLower.contains('not the requester') ||
        errorLower.contains('only requester can')) {
      return 'Only the request owner can perform this action.';
    }

    // Chat errors
    if (errorLower.contains('chat room not found')) {
      return 'This conversation no longer exists.';
    }
    if (errorLower.contains('not a participant')) {
      return 'You are not part of this conversation.';
    }
    if (errorLower.contains('message is empty') ||
        errorLower.contains('content cannot be empty')) {
      return 'Message cannot be empty.';
    }

    // Network errors
    if (errorLower.contains('no internet') ||
        errorLower.contains('network error') ||
        errorLower.contains('connection error')) {
      return 'No internet connection. Please check your network.';
    }
    if (errorLower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    // Generic errors
    if (errorLower.contains('server error') ||
        errorLower.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    // If no specific mapping found, return original message
    return technicalError;
  }
}
