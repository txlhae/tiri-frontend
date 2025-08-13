/// Main API Client for Django Backend Integration
/// Provides centralized HTTP client with configuration and error handling

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer';
import '../../config/api_config.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import 'api_interceptors.dart';

/// Static API client for making HTTP requests to Django backend
/// Provides a centralized point for all API communications
class ApiClient {
  /// Private Dio instance
  static Dio? _dio;
  
  /// Current authentication token
  static String? _authToken;
  
  /// Base URL for API requests
  static String? _baseUrl;
  
  /// Whether the client has been initialized
  static bool _isInitialized = false;

  /// Private constructor to prevent instantiation
  ApiClient._();

  /// Initialize the API client with configuration
  /// Must be called before using any HTTP methods
  static void initialize({
    String? baseUrl,
    String? authToken,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool enableRetry = true,
    int maxRetries = 3,
  }) {
    // Set base URL
    _baseUrl = baseUrl ?? ApiConfig.apiBaseUrl;
    _authToken = authToken;

    // Create Dio instance with configuration
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: connectTimeout ?? ApiConfig.connectTimeout,
      receiveTimeout: receiveTimeout ?? ApiConfig.receiveTimeout,
      sendTimeout: sendTimeout ?? ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
      validateStatus: (status) {
        // Accept all status codes so we can handle them in interceptors
        return status != null && status < 500;
      },
    ));

    // Add interceptors
    final interceptors = ApiConfig.isDevelopment
        ? InterceptorFactory.createDevelopmentInterceptors()
        : InterceptorFactory.createProductionInterceptors();
    
    for (final interceptor in interceptors) {
      _dio!.interceptors.add(interceptor);
    }

    _isInitialized = true;

    if (kDebugMode) {
      log('🚀 ApiClient initialized with base URL: $_baseUrl');
    }
  }

  /// Get the Dio instance (for advanced usage)
  static Dio get dio {
    _ensureInitialized();
    return _dio!;
  }

  /// Set authentication token for all future requests
  static void setAuthToken(String? token) {
    _authToken = token;
    
    if (_dio != null) {
      if (token != null) {
        _dio!.options.headers['Authorization'] = 'Bearer $token';
      } else {
        _dio!.options.headers.remove('Authorization');
      }
    }

    if (kDebugMode) {
      log('🔐 Auth token ${token != null ? 'set' : 'removed'}');
    }
  }

  /// Get current authentication token
  static String? get authToken => _authToken;

  /// Update base URL (useful for environment switching)
  static void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    if (_dio != null) {
      _dio!.options.baseUrl = newBaseUrl;
    }

    if (kDebugMode) {
      log('🔄 Base URL updated to: $newBaseUrl');
    }
  }

  /// Make a GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Options? options,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio!.get(
        endpoint,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Make a POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio!.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Make a PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio!.put(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Make a PATCH request
  static Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio!.patch(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Make a DELETE request
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
    T Function(dynamic)? fromJson,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final response = await _dio!.delete(
        endpoint,
        data: data,
        queryParameters: queryParams,
        options: options,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Upload a file using multipart/form-data
  static Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath,
    String fieldName, {
    Map<String, dynamic>? additionalData,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      final formData = FormData();
      
      // Add file
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(filePath),
      ));

      // Add additional data
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio!.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return _handleUnexpectedError<T>(e);
    }
  }

  /// Download a file
  static Future<ApiResponse<String>> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParams,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    _ensureInitialized();

    try {
      await _dio!.download(
        endpoint,
        savePath,
        queryParameters: queryParams,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      return ApiResponse.success(
        data: savePath,
        message: 'File downloaded successfully',
      );
    } on DioException catch (e) {
      return _handleError<String>(e);
    } catch (e) {
      return _handleUnexpectedError<String>(e);
    }
  }

  /// Handle successful responses
  static ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final statusCode = response.statusCode ?? 200;
    
    // Handle different success status codes
    if (statusCode >= 200 && statusCode < 300) {
      // For empty responses (204 No Content, etc.)
      if (response.data == null || response.data == '') {
        return ApiResponse.success(
          data: null as T,
          statusCode: statusCode,
          message: 'Request completed successfully',
        );
      }

      // Parse response data
      if (fromJson != null) {
        try {
          final data = fromJson(response.data);
          return ApiResponse.success(
            data: data,
            statusCode: statusCode,
            metadata: _extractMetadata(response),
          );
        } catch (e) {
          return ApiResponse.error(
            error: ApiError(
              type: 'parse_error',
              message: 'Failed to parse response data: $e',
              statusCode: statusCode,
            ),
          );
        }
      } else {
        return ApiResponse.success(
          data: response.data as T,
          statusCode: statusCode,
          metadata: _extractMetadata(response),
        );
      }
    }

    // Handle non-success status codes
    return ApiResponse.error(
      error: ApiError(
        type: 'http_error',
        message: 'HTTP $statusCode: ${response.statusMessage ?? 'Unknown error'}',
        statusCode: statusCode,
        details: response.data,
      ),
    );
  }

  /// Handle Dio errors
  static ApiResponse<T> _handleError<T>(DioException error) {
    // The error interceptor should have already converted this to ApiException
    final apiException = error.error is ApiException 
        ? error.error as ApiException
        : ApiExceptionMapper.mapException(error, statusCode: error.response?.statusCode);

    return ApiResponse.error(
      error: ApiError(
        type: apiException.runtimeType.toString().toLowerCase(),
        message: apiException.message,
        statusCode: apiException.statusCode,
        details: error.response?.data,
      ),
    );
  }

  /// Handle unexpected errors
  static ApiResponse<T> _handleUnexpectedError<T>(dynamic error) {
    return ApiResponse.error(
      error: ApiError(
        type: 'unexpected_error',
        message: 'An unexpected error occurred: ${error.toString()}',
        details: {'original_error': error.toString()},
      ),
    );
  }

  /// Extract metadata from response
  static Map<String, dynamic> _extractMetadata(Response response) {
    return {
      'status_code': response.statusCode,
      'headers': response.headers.map,
      'request_url': response.requestOptions.uri.toString(),
      'response_time': response.extra['response_time'],
      'duration_ms': response.extra['duration_ms'],
    };
  }

  /// Ensure the client is initialized before use
  static void _ensureInitialized() {
    if (!_isInitialized || _dio == null) {
      throw Exception(
        'ApiClient not initialized. Call ApiClient.initialize() first.',
      );
    }
  }

  /// Check if the client is initialized
  static bool get isInitialized => _isInitialized;

  /// Get current base URL
  static String? get baseUrl => _baseUrl;

  /// Clear all data and reset the client
  static void reset() {
    _dio?.close();
    _dio = null;
    _authToken = null;
    _baseUrl = null;
    _isInitialized = false;

    if (kDebugMode) {
      log('🔄 ApiClient reset');
    }
  }

  /// Create a cancel token for request cancellation
  static CancelToken createCancelToken() {
    return CancelToken();
  }

  /// Check if a cancel token is cancelled
  static bool isCancelled(CancelToken cancelToken) {
    return cancelToken.isCancelled;
  }
}

/// Utility class for common API operations
class ApiUtils {
  /// Build query parameters, filtering out null values
  static Map<String, dynamic> buildQueryParams(Map<String, dynamic> params) {
    final filtered = <String, dynamic>{};
    
    params.forEach((key, value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    
    return filtered;
  }

  /// Create options with custom headers
  static Options createOptions({
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return Options(
      headers: headers,
      responseType: responseType,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  /// Create multipart form data from a map
  static FormData createFormData(Map<String, dynamic> data) {
    final formData = FormData();
    
    data.forEach((key, value) {
      if (value is MultipartFile) {
        formData.files.add(MapEntry(key, value));
      } else {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });
    
    return formData;
  }

  /// Extract error message from response
  static String extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Try different common error message fields
      return responseData['message'] ?? 
             responseData['error'] ?? 
             responseData['detail'] ?? 
             'An error occurred';
    } else if (responseData is String) {
      return responseData;
    }
    
    return 'An unknown error occurred';
  }
}

/// TODO: Phase 2 Integration Points
/// - Add request/response caching layer
/// - Implement request queuing for offline scenarios
/// - Add request prioritization system
/// - Create specialized clients for different API domains
/// - Add request deduplication for identical requests
/// - Implement connection pooling optimization
/// - Add request/response compression support
/// - Create mock client for testing environments
