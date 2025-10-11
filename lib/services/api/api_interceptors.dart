/// API Interceptors for Django Backend Integration
/// Handles request/response interception, logging, and error mapping
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/api_exceptions.dart';

/// Request interceptor for adding authentication headers and logging
class RequestInterceptor extends Interceptor {
  static const String _tag = 'RequestInterceptor';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Add request timestamp
      options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
      
      // Add request ID for tracking
      options.extra['request_id'] = _generateRequestId();
      
      // Add authentication headers if available
      _addAuthenticationHeaders(options);
      
      // Add default headers
      _addDefaultHeaders(options);
      
      // Log request details in debug mode
      if (kDebugMode) {
        _logRequest(options);
      }
      
      handler.next(options);
    } catch (e) {
      // If there's an error in the interceptor, log it and continue
      if (kDebugMode) {
      }
      handler.next(options);
    }
  }

  /// Add authentication headers to the request
  void _addAuthenticationHeaders(RequestOptions options) {
    // TODO: Phase 2 - Integrate with AuthService for token management
    final token = _getStoredAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Add default headers to all requests
  void _addDefaultHeaders(RequestOptions options) {
    // Content-Type header (don't override if already set)
    if (!options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }
    
    // Accept header
    options.headers['Accept'] = 'application/json';
    
    // User-Agent header
    options.headers['User-Agent'] = 'TiriNajidApp/1.0.0 Flutter';
    
    // Request tracking headers
    options.headers['X-Requested-With'] = 'XMLHttpRequest';
    options.headers['X-Request-ID'] = options.extra['request_id'];
    
    // Client information headers
    options.headers['X-Client-Platform'] = 'Flutter';
    options.headers['X-Client-Version'] = '1.0.0'; // TODO: Get from package info
  }

  /// Log request details
  void _logRequest(RequestOptions options) {
    final requestId = options.extra['request_id'];
    
    if (options.queryParameters.isNotEmpty) {
    }
    
    if (options.data != null) {
    }
    
    if (options.headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, dynamic>.from(options.headers);
      // Remove sensitive headers from logs
      sanitizedHeaders.remove('Authorization');
    }
  }

  /// Generate a unique request ID
  String _generateRequestId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }

  /// Get stored authentication token
  String? _getStoredAuthToken() {
    // TODO: Phase 2 - Implement secure token storage integration
    // This should integrate with flutter_secure_storage or similar
    return null;
  }

  /// Sanitize sensitive data for logging
  dynamic _sanitizeLogData(dynamic data) {
    if (data is Map) {
      final sanitized = Map<String, dynamic>.from(data);
      // Remove sensitive fields from logs
      const sensitiveFields = ['password', 'token', 'secret', 'key'];
      for (final field in sensitiveFields) {
        if (sanitized.containsKey(field)) {
          sanitized[field] = '***REDACTED***';
        }
      }
      return sanitized;
    }
    return data;
  }
}

/// Response interceptor for logging and success handling
class ResponseInterceptor extends Interceptor {
  static const String _tag = 'ResponseInterceptor';

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    try {
      // Calculate request duration
      final startTime = response.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null 
          ? DateTime.now().millisecondsSinceEpoch - startTime 
          : null;
      
      // Add response metadata
      response.extra['response_time'] = DateTime.now().millisecondsSinceEpoch;
      response.extra['duration_ms'] = duration;
      
      // Handle token refresh if provided
      _handleTokenRefresh(response);
      
      // Log response details in debug mode
      if (kDebugMode) {
        _logResponse(response, duration);
      }
      
      handler.next(response);
    } catch (e) {
      // If there's an error in the interceptor, log it and continue
      if (kDebugMode) {
      }
      handler.next(response);
    }
  }

  /// Handle automatic token refresh
  void _handleTokenRefresh(Response response) {
    // TODO: Phase 2 - Implement automatic token refresh logic
    final newToken = response.headers.value('X-New-Token');
    if (newToken != null) {
      _storeAuthToken(newToken);
    }
  }

  /// Log response details
  void _logResponse(Response response, int? duration) {
    final requestId = response.requestOptions.extra['request_id'];
    final durationText = duration != null ? ' (${duration}ms)' : '';
    
    
    if (response.data != null) {
      final dataPreview = _getDataPreview(response.data);
    }
  }

  /// Get a preview of response data for logging
  String _getDataPreview(dynamic data) {
    if (data is Map) {
      final preview = Map<String, dynamic>.from(data);
      // If response is too large, show only keys
      final jsonString = preview.toString();
      if (jsonString.length > 500) {
        return 'Map with keys: ${preview.keys.toList()}';
      }
      return jsonString;
    } else if (data is List) {
      return 'List with ${data.length} items';
    } else {
      final dataString = data.toString();
      return dataString.length > 200 
          ? '${dataString.substring(0, 200)}...' 
          : dataString;
    }
  }

  /// Store authentication token securely
  void _storeAuthToken(String token) {
    // TODO: Phase 2 - Implement secure token storage
    // This should integrate with flutter_secure_storage
  }
}

/// Error interceptor for converting errors to custom exceptions
class ErrorInterceptor extends Interceptor {
  static const String _tag = 'ErrorInterceptor';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      // Calculate request duration if available
      final startTime = err.requestOptions.extra['request_start_time'] as int?;
      final duration = startTime != null 
          ? DateTime.now().millisecondsSinceEpoch - startTime 
          : null;

      // Log error details in debug mode
      if (kDebugMode) {
        _logError(err, duration);
      }

      // Convert DioException to custom ApiException
      final apiException = _mapDioExceptionToApiException(err);
      
      // Create a new DioException with our custom exception
      final newError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      );

      handler.next(newError);
    } catch (e) {
      // If there's an error in the interceptor, log it and continue with original error
      if (kDebugMode) {
      }
      handler.next(err);
    }
  }

  /// Log error details
  void _logError(DioException err, int? duration) {
    final requestId = err.requestOptions.extra['request_id'];
    final durationText = duration != null ? ' (${duration}ms)' : '';
    
    
    if (err.response?.data != null) {
    }
  }

  /// Map DioException to appropriate ApiException
  ApiException _mapDioExceptionToApiException(DioException err) {
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout(
          customMessage: 'Request timeout. Please check your connection and try again.',
        );

      case DioExceptionType.connectionError:
        if (err.message?.toLowerCase().contains('network') == true) {
          return NetworkException.noConnection();
        } else {
          return NetworkException.dnsFailure();
        }

      case DioExceptionType.badResponse:
        return _mapStatusCodeToException(statusCode!, responseData);

      case DioExceptionType.cancel:
        return UnknownApiException(
          'Request was cancelled',
          originalError: err,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownApiException.unexpected(
          customMessage: err.message ?? 'An unexpected error occurred',
          originalError: err,
        );
    }
  }

  /// Map HTTP status codes to specific exceptions
  ApiException _mapStatusCodeToException(int statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        if (responseData is Map<String, dynamic>) {
          return ValidationException.fromDjangoResponse(responseData);
        }
        return ValidationException('Bad request: Invalid data submitted');

      case 401:
        return AuthenticationException.invalidCredentials();

      case 403:
        return AuthorizationException.insufficientPermissions();

      case 404:
        return NotFoundException('The requested resource was not found');

      case 429:
        Map<String, dynamic> headers = {};
        if (responseData is Map<String, dynamic> && responseData.containsKey('headers')) {
          headers = Map<String, dynamic>.from(responseData['headers']);
        }
        return RateLimitException.fromHeaders(headers);

      case >= 500:
        switch (statusCode) {
          case 500:
            return ServerException.internalError();
          case 503:
            return ServerException.serviceUnavailable();
          case 504:
            return ServerException.gatewayTimeout();
          default:
            return ServerException(
              'Server error occurred',
              statusCode: statusCode,
            );
        }

      default:
        return UnknownApiException(
          'HTTP $statusCode: ${responseData?.toString() ?? 'Unknown error'}',
          statusCode: statusCode,
        );
    }
  }
}

/// Retry interceptor for handling automatic retries
class RetryInterceptor extends Interceptor {
  static const String _tag = 'RetryInterceptor';
  
  /// Maximum number of retry attempts
  final int maxRetries;
  
  /// Delay between retry attempts
  final Duration retryDelay;
  
  /// Multiplier for exponential backoff
  final double backoffMultiplier;
  
  /// HTTP status codes that should trigger a retry
  final List<int> retryStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.retryStatusCodes = const [500, 502, 503, 504, 408],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retry_count'] as int? ?? 0;

    // Check if we should retry this error
    if (_shouldRetry(err, retryCount)) {
      try {
        // Increment retry count
        err.requestOptions.extra['retry_count'] = retryCount + 1;
        
        // Calculate delay with exponential backoff
        final delay = Duration(
          milliseconds: (retryDelay.inMilliseconds * 
              (retryCount == 0 ? 1 : backoffMultiplier * retryCount)).round(),
        );
        
        if (kDebugMode) {
          final requestId = err.requestOptions.extra['request_id'];
        }
        
        // Wait before retrying
        await Future.delayed(delay);
        
        // Retry the request
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        // If retry fails, continue with original error
        if (kDebugMode) {
        }
      }
    }

    // No retry or max retries reached
    handler.next(err);
  }

  /// Determine if the error should trigger a retry
  bool _shouldRetry(DioException err, int retryCount) {
    // Don't retry if max attempts reached
    if (retryCount >= maxRetries) return false;

    // Only retry specific error types
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && retryStatusCodes.contains(statusCode);

      default:
        return false;
    }
  }
}

/// Factory class for creating interceptor instances
class InterceptorFactory {
  /// Create standard set of interceptors for API client
  static List<Interceptor> createDefaultInterceptors({
    bool enableLogging = true,
    bool enableRetry = true,
    int maxRetries = 3,
  }) {
    final interceptors = <Interceptor>[];

    // Request interceptor (always enabled)
    interceptors.add(RequestInterceptor());

    // Retry interceptor (optional)
    if (enableRetry) {
      interceptors.add(RetryInterceptor(maxRetries: maxRetries));
    }

    // Response interceptor (always enabled)
    interceptors.add(ResponseInterceptor());

    // Error interceptor (always enabled)
    interceptors.add(ErrorInterceptor());

    return interceptors;
  }

  /// Create interceptors for production environment
  static List<Interceptor> createProductionInterceptors() {
    // Create minimal interceptors for production - no logging, limited retries
    final interceptors = <Interceptor>[];

    // Only add essential interceptors
    interceptors.add(ProductionRequestInterceptor()); // Minimal request handling
    interceptors.add(RetryInterceptor(maxRetries: 2)); // Limited retries
    interceptors.add(ProductionErrorInterceptor()); // Minimal error handling

    return interceptors;
  }

  /// Create interceptors for development environment
  static List<Interceptor> createDevelopmentInterceptors() {
    return createDefaultInterceptors(
      enableLogging: true,
      enableRetry: true,
      maxRetries: 3,
    );
  }
}

/// Production-optimized request interceptor with minimal logging
class ProductionRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Add authentication headers if available
      final token = _getStoredAuthToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Add essential headers only
      options.headers['Content-Type'] = 'application/json';
      options.headers['Accept'] = 'application/json';

      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }

  String? _getStoredAuthToken() {
    // TODO: Integrate with AuthStorage
    return null;
  }
}

/// Production-optimized error interceptor with minimal logging
class ProductionErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    try {
      // Convert to API exception without verbose logging
      final apiException = _mapDioExceptionToApiException(err);

      final newError = DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      );

      handler.next(newError);
    } catch (e) {
      handler.next(err);
    }
  }

  ApiException _mapDioExceptionToApiException(DioException err) {
    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();

      case DioExceptionType.connectionError:
        return NetworkException.noConnection();

      case DioExceptionType.badResponse:
        return _mapStatusCodeToException(statusCode!, responseData);

      case DioExceptionType.cancel:
        return UnknownApiException('Request cancelled');

      default:
        return UnknownApiException.unexpected();
    }
  }

  ApiException _mapStatusCodeToException(int statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        return ValidationException('Invalid request data');
      case 401:
        return AuthenticationException.invalidCredentials();
      case 403:
        return AuthorizationException.insufficientPermissions();
      case 404:
        return NotFoundException('Resource not found');
      case 429:
        return RateLimitException.fromHeaders({});
      case >= 500:
        return ServerException.internalError();
      default:
        return UnknownApiException('HTTP $statusCode error');
    }
  }
}

/// TODO: Phase 2 Integration Points
/// - Integrate with AuthService for automatic token management
/// - Implement request queuing for offline scenarios
/// - Add performance monitoring and analytics tracking
/// - Create custom interceptors for specific API endpoints
/// - Add request/response compression handling
