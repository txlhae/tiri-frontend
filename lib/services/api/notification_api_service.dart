/// Notification API Service for Django Backend Integration
/// Provides methods for all notification-related API operations
library notification_api_service;

import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/notification_response.dart';
import '../exceptions/api_exceptions.dart';

/// Static service class for notification API operations
/// Uses the established ApiClient foundation for all HTTP requests
class NotificationApiService {
  /// Private constructor to prevent instantiation
  NotificationApiService._();

  /// Base path for notification endpoints
  static const String _basePath = '/api/notifications';
  
  /// Preferences endpoint path
  static const String _preferencesPath = '/api/preferences';

  /// Fetch paginated notifications for the current user
  /// 
  /// Parameters:
  /// - [page]: Page number (1-based, default: 1)
  /// - [limit]: Number of items per page (default: 20)
  /// - [isRead]: Filter by read status (null for all)
  /// - [notificationType]: Filter by notification type
  /// - [category]: Filter by notification category
  /// - [search]: Search query for title/message
  /// - [orderBy]: Order results by field (created_at, title, etc.)
  /// - [ordering]: Sort direction (asc, desc)
  /// 
  /// Returns: [PaginatedNotificationResponse] with notifications and metadata
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<PaginatedNotificationResponse>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? notificationType,
    String? category,
    String? search,
    String? orderBy,
    String? ordering,
    CancelToken? cancelToken,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      // Add optional filters
      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }
      if (notificationType != null) {
        queryParams['notification_type'] = notificationType;
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (orderBy != null) {
        queryParams['order_by'] = orderBy;
      }
      if (ordering != null) {
        queryParams['ordering'] = ordering;
      }

      // Make API request
      final response = await ApiClient.get<Map<String, dynamic>>(
        '$_basePath/',
        queryParams: queryParams,
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        // Parse paginated response
        final paginatedResponse = PaginatedNotificationResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: paginatedResponse,
          message: 'Notifications fetched successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to fetch notifications',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Mark a specific notification as read
  /// 
  /// Parameters:
  /// - [notificationId]: The ID of the notification to mark as read
  /// 
  /// Returns: [ApiResponse<EmptyResponse>] indicating success or failure
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<EmptyResponse>> markAsRead(
    String notificationId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '$_basePath/$notificationId/mark_as_read/',
        cancelToken: cancelToken,
      );

      if (response.success) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Notification marked as read',
            statusCode: response.statusCode,
            metadata: response.metadata,
          ),
          message: 'Notification marked as read successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to mark notification as read',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Mark all notifications as read for the current user
  /// 
  /// Returns: [ApiResponse<EmptyResponse>] with operation result
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<EmptyResponse>> markAllAsRead({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '$_basePath/mark_all_read/',
        cancelToken: cancelToken,
      );

      if (response.success) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'All notifications marked as read',
            statusCode: response.statusCode,
            metadata: response.metadata,
          ),
          message: 'All notifications marked as read successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to mark all notifications as read',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Get unread notification count for badge display
  /// 
  /// Parameters:
  /// - [includeBreakdown]: Whether to include category/type breakdown
  /// 
  /// Returns: [ApiResponse<UnreadCountResponse>] with count data
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<UnreadCountResponse>> getUnreadCount({
    bool includeBreakdown = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (includeBreakdown) {
        queryParams['include_breakdown'] = true;
      }

      final response = await ApiClient.get<Map<String, dynamic>>(
        '$_basePath/unread_count/',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        final unreadCountResponse = UnreadCountResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: unreadCountResponse,
          message: 'Unread count fetched successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to fetch unread count',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Update FCM token for push notifications
  /// 
  /// Parameters:
  /// - [fcmToken]: The Firebase Cloud Messaging token
  /// - [deviceInfo]: Optional device information
  /// 
  /// Returns: [ApiResponse<FcmTokenResponse>] with registration result
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<FcmTokenResponse>> updateFcmToken(
    String fcmToken, {
    Map<String, dynamic>? deviceInfo,
    CancelToken? cancelToken,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'fcm_token': fcmToken,
      };

      // Add device information if provided
      if (deviceInfo != null) {
        requestData.addAll(deviceInfo);
      }

      final response = await ApiClient.post<Map<String, dynamic>>(
        '$_preferencesPath/update_fcm_token/',
        data: requestData,
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        final fcmTokenResponse = FcmTokenResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: fcmTokenResponse,
          message: 'FCM token updated successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to update FCM token',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Get notification preferences for the current user
  /// 
  /// Returns: [ApiResponse<NotificationPreferencesResponse>] with preferences
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<NotificationPreferencesResponse>> getPreferences({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '$_preferencesPath/notification_preferences/',
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        final preferencesResponse = NotificationPreferencesResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: preferencesResponse,
          message: 'Notification preferences fetched successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to fetch notification preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Update notification preferences for the current user
  /// 
  /// Parameters:
  /// - [preferences]: The updated notification preferences
  /// 
  /// Returns: [ApiResponse<NotificationPreferencesResponse>] with updated preferences
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<NotificationPreferencesResponse>> updatePreferences(
    NotificationPreferencesResponse preferences, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.put<Map<String, dynamic>>(
        '$_preferencesPath/notification_preferences/',
        data: preferences.toJson(),
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        final updatedPreferences = NotificationPreferencesResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: updatedPreferences,
          message: 'Notification preferences updated successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to update notification preferences',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Delete a specific notification
  /// 
  /// Parameters:
  /// - [notificationId]: The ID of the notification to delete
  /// 
  /// Returns: [ApiResponse<EmptyResponse>] indicating success or failure
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<EmptyResponse>> deleteNotification(
    String notificationId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.delete<Map<String, dynamic>>(
        '$_basePath/$notificationId/',
        cancelToken: cancelToken,
      );

      if (response.success) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Notification deleted',
            statusCode: response.statusCode,
            metadata: response.metadata,
          ),
          message: 'Notification deleted successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to delete notification',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Clear all read notifications for the current user
  /// 
  /// Returns: [ApiResponse<EmptyResponse>] with operation result
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<EmptyResponse>> clearReadNotifications({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '$_basePath/clear_read/',
        cancelToken: cancelToken,
      );

      if (response.success) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Read notifications cleared',
            statusCode: response.statusCode,
            metadata: response.metadata,
          ),
          message: 'Read notifications cleared successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to clear read notifications',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }

  /// Get notification statistics for the current user
  /// 
  /// Parameters:
  /// - [days]: Number of days to include in statistics (default: 30)
  /// 
  /// Returns: [ApiResponse<Map<String, dynamic>>] with statistics data
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<Map<String, dynamic>>> getStatistics({
    int days = 30,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '$_basePath/statistics/',
        queryParams: {'days': days},
        cancelToken: cancelToken,
      );

      if (response.success && response.data != null) {
        return ApiResponse.success(
          data: response.data!,
          message: 'Notification statistics fetched successfully',
          statusCode: response.statusCode,
          metadata: response.metadata,
        );
      } else {
        return ApiResponse.error(
          error: response.error ?? ApiError(
            type: 'unknown_error',
            message: 'Failed to fetch notification statistics',
          ),
        );
      }
    } on ApiException catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: e.runtimeType.toString().toLowerCase(),
          message: e.message,
          statusCode: e.statusCode,
        ),
      );
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'unexpected_error',
          message: 'An unexpected error occurred: ${e.toString()}',
        ),
      );
    }
  }
}

/// Utility class for notification-related helper methods
class NotificationUtils {
  /// Private constructor to prevent instantiation
  NotificationUtils._();

  /// Build filter parameters for notifications
  static Map<String, dynamic> buildFilterParams({
    bool? isRead,
    String? notificationType,
    String? category,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final params = <String, dynamic>{};

    if (isRead != null) params['is_read'] = isRead;
    if (notificationType != null) params['notification_type'] = notificationType;
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();

    return params;
  }

  /// Build pagination parameters
  static Map<String, dynamic> buildPaginationParams({
    int page = 1,
    int limit = 20,
    String? orderBy,
    String? ordering,
  }) {
    return {
      'page': page,
      'limit': limit,
      if (orderBy != null) 'order_by': orderBy,
      if (ordering != null) 'ordering': ordering,
    };
  }

  /// Get device information for FCM token registration
  static Map<String, dynamic> getDeviceInfo() {
    // TODO: Phase 3 - Implement actual device info collection
    return {
      'platform': 'flutter',
      'app_version': '1.0.0',
      'device_type': 'mobile',
    };
  }
}

/// TODO: Phase 3 Integration Points
/// - Add real-time notification streaming via WebSocket
/// - Implement notification scheduling and delay capabilities
/// - Add notification template management
/// - Create notification action handling (buttons, quick replies)
/// - Add notification analytics and tracking
/// - Implement notification grouping and threading
/// - Add notification attachment support (images, files)
/// - Create notification sound and vibration preferences
