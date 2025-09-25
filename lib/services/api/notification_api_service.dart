/// Notification API Service for Django Backend Integration
/// Provides methods for all notification-related API operations
library;

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../api_service.dart';
import '../models/api_response.dart';
import '../models/notification_response.dart';
import '../exceptions/api_exceptions.dart';

/// Service class for notification API operations
/// Uses the authenticated ApiService for all HTTP requests
class NotificationApiService {
  /// Private constructor to prevent instantiation
  NotificationApiService._();

  /// Get the authenticated API service instance
  static ApiService get _apiService => Get.find<ApiService>();

  /// Base path for notification endpoints
  static const String _basePath = '/api/notifications/notifications';
  
  /// Preferences endpoint path
  static const String _preferencesPath = '/api/notifications/preferences';

  /// Fetch paginated notifications for the current user
  /// 
  /// Parameters:
  /// - [page]: Page number (1-based, default: 1)
  /// - [pageSize]: Number of items per page (default: 20, max: 100)
  /// - [isRead]: Filter by read status (null for all)
  /// - [type]: Filter by notification type
  /// - [priority]: Filter by priority level
  /// - [deliveryMethod]: Filter by delivery method
  /// - [dateFrom]: Filter from date (YYYY-MM-DD)
  /// - [dateTo]: Filter to date (YYYY-MM-DD)
  /// - [search]: Search query for title/message
  /// 
  /// Returns: [PaginatedNotificationResponse] with notifications and metadata
  /// 
  /// Throws: [ApiException] subclasses for various error conditions
  static Future<ApiResponse<PaginatedNotificationResponse>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool? isRead,
    String? type,
    String? priority,
    String? deliveryMethod,
    String? dateFrom,
    String? dateTo,
    String? search,
    CancelToken? cancelToken,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      // Add optional filters
      if (isRead != null) {
        queryParams['is_read'] = isRead;
      }
      if (type != null) {
        queryParams['type'] = type;
      }
      if (priority != null) {
        queryParams['priority'] = priority;
      }
      if (deliveryMethod != null) {
        queryParams['delivery_method'] = deliveryMethod;
      }
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom;
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Build query string
      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString = '?' + queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
      }

      // Make API request using authenticated ApiService
      final response = await _apiService.get('$_basePath/$queryString');

      if (response.statusCode == 200 && response.data != null) {
        // Parse paginated response
        final paginatedResponse = PaginatedNotificationResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: paginatedResponse,
          message: 'Notifications fetched successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to fetch notifications',
            statusCode: response.statusCode,
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
      final response = await _apiService.post(
        '$_basePath/$notificationId/mark_as_read/',
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Notification marked as read',
            statusCode: response.statusCode,
          ),
          message: 'Notification marked as read successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to mark notification as read',
            statusCode: response.statusCode,
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
      final response = await _apiService.post(
        '$_basePath/mark_all_read/',
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'All notifications marked as read',
            statusCode: response.statusCode,
          ),
          message: 'All notifications marked as read successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to mark all notifications as read',
            statusCode: response.statusCode,
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

      // Build query string
      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString = '?' + queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
      }

      final response = await _apiService.get('$_basePath/unread_count/$queryString');

      if (response.statusCode == 200 && response.data != null) {
        final unreadCountResponse = UnreadCountResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: unreadCountResponse,
          message: 'Unread count fetched successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to fetch unread count',
            statusCode: response.statusCode,
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

      final response = await _apiService.post(
        '$_preferencesPath/update_fcm_token/',
        data: requestData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final fcmTokenResponse = FcmTokenResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: fcmTokenResponse,
          message: 'FCM token updated successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to update FCM token',
            statusCode: response.statusCode,
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
      final response = await _apiService.get(
        '$_preferencesPath/notification_preferences/',
      );

      if (response.statusCode == 200 && response.data != null) {
        final preferencesResponse = NotificationPreferencesResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: preferencesResponse,
          message: 'Notification preferences fetched successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to fetch notification preferences',
            statusCode: response.statusCode,
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
      final response = await _apiService.put(
        '$_preferencesPath/notification_preferences/',
        data: preferences.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final updatedPreferences = NotificationPreferencesResponse.fromJson(response.data!);
        return ApiResponse.success(
          data: updatedPreferences,
          message: 'Notification preferences updated successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to update notification preferences',
            statusCode: response.statusCode,
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
      final response = await _apiService.delete(
        '$_basePath/$notificationId/',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Notification deleted',
            statusCode: response.statusCode,
          ),
          message: 'Notification deleted successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to delete notification',
            statusCode: response.statusCode,
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
      final response = await _apiService.post(
        '$_basePath/clear_read/',
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(
          data: EmptyResponse(
            message: 'Read notifications cleared',
            statusCode: response.statusCode,
          ),
          message: 'Read notifications cleared successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to clear read notifications',
            statusCode: response.statusCode,
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
      final response = await _apiService.get(
        '$_basePath/statistics/?days=$days',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ApiResponse.success(
          data: response.data!,
          message: 'Notification statistics fetched successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          error: ApiError(
            type: 'api_error',
            message: 'Failed to fetch notification statistics',
            statusCode: response.statusCode,
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
