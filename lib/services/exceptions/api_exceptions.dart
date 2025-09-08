/// API Exception Classes for Django Backend Integration
/// Provides comprehensive error handling for HTTP operations
library;

/// Abstract base class for all API-related exceptions
/// Provides common properties and behavior for error handling
abstract class ApiException implements Exception {
  /// Human-readable error message
  final String message;
  
  /// HTTP status code (if applicable)
  final int? statusCode;
  
  /// Original error object that caused this exception
  final dynamic originalError;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  /// Additional context data for debugging
  final Map<String, dynamic>? context;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
    DateTime? timestamp,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$runtimeType: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write(' - Context: $context');
    }
    return buffer.toString();
  }

  /// Convert exception to a map for logging/analytics
  Map<String, dynamic> toMap() {
    return {
      'type': runtimeType.toString(),
      'message': message,
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
      'context': context,
    };
  }
}

/// Network connectivity and timeout related exceptions
/// Thrown when there are issues with network connectivity
class NetworkException extends ApiException {
  /// Type of network error
  final NetworkErrorType errorType;
  
  NetworkException(
    super.message, {
    this.errorType = NetworkErrorType.unknown,
    super.originalError,
    super.context,
  });

  /// Factory constructor for connection timeout
  factory NetworkException.timeout({String? customMessage}) {
    return NetworkException(
      customMessage ?? 'Connection timeout. Please check your internet connection.',
      errorType: NetworkErrorType.timeout,
    );
  }

  /// Factory constructor for no internet connection
  factory NetworkException.noConnection({String? customMessage}) {
    return NetworkException(
      customMessage ?? 'No internet connection. Please check your network settings.',
      errorType: NetworkErrorType.noConnection,
    );
  }

  /// Factory constructor for DNS resolution failure
  factory NetworkException.dnsFailure({String? customMessage}) {
    return NetworkException(
      customMessage ?? 'Unable to resolve server address. Please try again later.',
      errorType: NetworkErrorType.dnsFailure,
    );
  }
}

/// Network error types for better categorization
enum NetworkErrorType {
  timeout,
  noConnection,
  dnsFailure,
  unknown,
}

/// Authentication related exceptions (401 Unauthorized)
/// Thrown when authentication credentials are invalid or expired
class AuthenticationException extends ApiException {
  /// Whether this is a token expiration issue
  final bool isTokenExpired;
  
  /// Whether automatic token refresh should be attempted
  final bool canRetryWithRefresh;

  AuthenticationException(
    super.message, {
    this.isTokenExpired = false,
    this.canRetryWithRefresh = true,
    super.originalError,
    super.context,
  }) : super(
          statusCode: 401,
        );

  /// Factory constructor for expired token
  factory AuthenticationException.tokenExpired({String? customMessage}) {
    return AuthenticationException(
      customMessage ?? 'Authentication token has expired. Please login again.',
      isTokenExpired: true,
      canRetryWithRefresh: true,
    );
  }

  /// Factory constructor for invalid credentials
  factory AuthenticationException.invalidCredentials({String? customMessage}) {
    return AuthenticationException(
      customMessage ?? 'Invalid credentials. Please check your login information.',
      isTokenExpired: false,
      canRetryWithRefresh: false,
    );
  }
}

/// Authorization related exceptions (403 Forbidden)
/// Thrown when user doesn't have permission to access a resource
class AuthorizationException extends ApiException {
  /// Required permission level
  final String? requiredPermission;
  
  /// User's current permission level
  final String? currentPermission;

  AuthorizationException(
    super.message, {
    this.requiredPermission,
    this.currentPermission,
    super.originalError,
    super.context,
  }) : super(
          statusCode: 403,
        );

  /// Factory constructor for insufficient permissions
  factory AuthorizationException.insufficientPermissions({
    String? customMessage,
    String? requiredPermission,
  }) {
    return AuthorizationException(
      customMessage ?? 'You don\'t have permission to perform this action.',
      requiredPermission: requiredPermission,
    );
  }
}

/// Rate limiting exceptions (429 Too Many Requests)
/// Thrown when API rate limits are exceeded
class RateLimitException extends ApiException {
  /// Number of seconds to wait before retrying
  final int retryAfterSeconds;
  
  /// Current rate limit quota
  final int? currentLimit;
  
  /// Remaining requests in current window
  final int? remainingRequests;
  
  /// When the rate limit window resets
  final DateTime? resetTime;

  RateLimitException(
    super.message,
    this.retryAfterSeconds, {
    this.currentLimit,
    this.remainingRequests,
    this.resetTime,
    super.originalError,
    super.context,
  }) : super(
          statusCode: 429,
        );

  /// Factory constructor with retry-after header parsing
  factory RateLimitException.fromHeaders(
    Map<String, dynamic> headers, {
    String? customMessage,
  }) {
    final retryAfter = int.tryParse(headers['retry-after']?.toString() ?? '') ?? 60;
    final limit = int.tryParse(headers['x-ratelimit-limit']?.toString() ?? '');
    final remaining = int.tryParse(headers['x-ratelimit-remaining']?.toString() ?? '');
    
    return RateLimitException(
      customMessage ?? 'Rate limit exceeded. Please wait $retryAfter seconds before retrying.',
      retryAfter,
      currentLimit: limit,
      remainingRequests: remaining,
    );
  }
}

/// Validation related exceptions (400 Bad Request)
/// Thrown when request data doesn't meet validation requirements
class ValidationException extends ApiException {
  /// Field-specific validation errors
  final Map<String, List<String>> fieldErrors;
  
  /// General validation errors not tied to specific fields
  final List<String> generalErrors;

  ValidationException(
    super.message, {
    this.fieldErrors = const {},
    this.generalErrors = const [],
    super.originalError,
    super.context,
  }) : super(
          statusCode: 400,
        );

  /// Factory constructor from Django REST framework error response
  factory ValidationException.fromDjangoResponse(Map<String, dynamic> response) {
    final Map<String, List<String>> fieldErrors = {};
    final List<String> generalErrors = [];
    
    response.forEach((key, value) {
      if (key == 'non_field_errors') {
        generalErrors.addAll(List<String>.from(value));
      } else {
        fieldErrors[key] = List<String>.from(value);
      }
    });
    
    final message = generalErrors.isNotEmpty 
        ? generalErrors.first 
        : 'Validation failed for submitted data.';
    
    return ValidationException(
      message,
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
    );
  }

  /// Get formatted error message for UI display
  String getFormattedMessage() {
    final buffer = StringBuffer();
    
    if (generalErrors.isNotEmpty) {
      buffer.writeln(generalErrors.join('\n'));
    }
    
    fieldErrors.forEach((field, errors) {
      buffer.writeln('$field: ${errors.join(', ')}');
    });
    
    return buffer.toString().trim();
  }
}

/// Server-side exceptions (5xx status codes)
/// Thrown when the server encounters an error
class ServerException extends ApiException {
  /// Server error type
  final ServerErrorType errorType;
  
  /// Whether the operation can be retried
  final bool isRetryable;

  ServerException(
    super.message, {
    required int super.statusCode,
    this.errorType = ServerErrorType.unknown,
    this.isRetryable = true,
    super.originalError,
    super.context,
  });

  /// Factory constructor for internal server error
  factory ServerException.internalError({String? customMessage}) {
    return ServerException(
      customMessage ?? 'Internal server error. Please try again later.',
      statusCode: 500,
      errorType: ServerErrorType.internal,
      isRetryable: true,
    );
  }

  /// Factory constructor for service unavailable
  factory ServerException.serviceUnavailable({String? customMessage}) {
    return ServerException(
      customMessage ?? 'Service temporarily unavailable. Please try again later.',
      statusCode: 503,
      errorType: ServerErrorType.unavailable,
      isRetryable: true,
    );
  }

  /// Factory constructor for gateway timeout
  factory ServerException.gatewayTimeout({String? customMessage}) {
    return ServerException(
      customMessage ?? 'Gateway timeout. Please try again later.',
      statusCode: 504,
      errorType: ServerErrorType.timeout,
      isRetryable: true,
    );
  }
}

/// Server error types for better categorization
enum ServerErrorType {
  internal,      // 500 Internal Server Error
  unavailable,   // 503 Service Unavailable
  timeout,       // 504 Gateway Timeout
  unknown,       // Other 5xx errors
}

/// Resource not found exceptions (404 Not Found)
/// Thrown when requested resource doesn't exist
class NotFoundException extends ApiException {
  /// Type of resource that was not found
  final String? resourceType;
  
  /// ID of the resource that was not found
  final String? resourceId;

  NotFoundException(
    super.message, {
    this.resourceType,
    this.resourceId,
    super.originalError,
    super.context,
  }) : super(
          statusCode: 404,
        );

  /// Factory constructor for generic not found
  factory NotFoundException.resource({
    required String resourceType,
    String? resourceId,
    String? customMessage,
  }) {
    final message = customMessage ?? 
        'The requested $resourceType${resourceId != null ? ' (ID: $resourceId)' : ''} was not found.';
    
    return NotFoundException(
      message,
      resourceType: resourceType,
      resourceId: resourceId,
    );
  }
}

/// Unknown or unexpected exceptions
/// Thrown when an error doesn't fit into other categories
class UnknownApiException extends ApiException {
  UnknownApiException(
    super.message, {
    super.statusCode,
    super.originalError,
    super.context,
  });

  /// Factory constructor for unexpected errors
  factory UnknownApiException.unexpected({
    String? customMessage,
    dynamic originalError,
  }) {
    return UnknownApiException(
      customMessage ?? 'An unexpected error occurred. Please try again.',
      originalError: originalError,
    );
  }
}

/// Utility class for converting various errors to API exceptions
class ApiExceptionMapper {
  /// Convert a generic exception to an appropriate ApiException
  static ApiException mapException(dynamic error, {int? statusCode}) {
    // If it's already an ApiException, return as-is
    if (error is ApiException) {
      return error;
    }

    // Handle status code based exceptions
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return ValidationException('Bad request: ${error.toString()}');
        case 401:
          return AuthenticationException.invalidCredentials();
        case 403:
          return AuthorizationException.insufficientPermissions();
        case 404:
          return NotFoundException('Resource not found: ${error.toString()}');
        case 429:
          return RateLimitException('Rate limit exceeded: ${error.toString()}', 60);
        case >= 500:
          return ServerException(
            'Server error: ${error.toString()}',
            statusCode: statusCode,
          );
      }
    }

    // Handle network-related errors
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('timeout') || errorMessage.contains('timed out')) {
      return NetworkException.timeout();
    }
    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return NetworkException.noConnection();
    }
    if (errorMessage.contains('dns') || errorMessage.contains('resolve')) {
      return NetworkException.dnsFailure();
    }

    // Default to unknown exception
    return UnknownApiException.unexpected(
      customMessage: error.toString(),
      originalError: error,
    );
  }
}

/// TODO: Phase 2 Integration Points
/// - Add logging integration with ApiExceptionMapper
/// - Implement retry logic based on exception types
/// - Add analytics tracking for different exception types
/// - Create user-friendly error message mapping
/// - Add localization support for error messages
