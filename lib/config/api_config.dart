// lib/config/api_config.dart

import 'dart:developer';

// Enterprise API Configuration
/// This file contains all API-related configuration for TIRI app
/// 
/// Features:
/// - Environment-based URLs (dev, staging, production)
/// - Timeout configurations
/// - Retry policies
/// - Security headers
/// - API versioning

class ApiConfig {
  // =============================================================================
  // ENVIRONMENT CONFIGURATION
  // =============================================================================
  
  /// Current environment (development, staging, production)
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Base URLs for different environments
  /// 🔧 UPDATED: Using your computer's IP address for physical device testing
  static const Map<String, String> _baseUrls = {
    'development': 'http://192.168.0.122:8000',  // New network IP address
    // 'development': 'http://10.19.218.200:8000',  // Previous network IP (commented for reference)
    // 'development': 'http://192.168.1.15:8000',  // Older network IP (commented for reference)
    'staging': 'https://staging-api.tiri.com',
    'production': 'https://api.tiri.com',
  };

  /// WebSocket URLs for different environments
  static const Map<String, String> _webSocketUrls = {
    'development': 'ws://192.168.0.122:8000',   // New network WebSocket
    // 'development': 'ws://10.19.218.200:8000',   // Previous network WebSocket (commented for reference)
    // 'development': 'ws://192.168.1.15:8000',   // Older network WebSocket (commented for reference)
    'staging': 'wss://staging-api.tiri.com',    // Secure WebSocket for staging
    'production': 'wss://api.tiri.com',         // Secure WebSocket for production
  };

  /// Get the base URL for current environment
  static String get baseUrl => _baseUrls[environment]!;

  /// Get the WebSocket URL for current environment
  static String get webSocketBaseUrl => _webSocketUrls[environment]!;

  // =============================================================================
  // API ENDPOINTS
  // =============================================================================
  
  /// API version
  static const String apiVersion = 'v1';
  
  /// Complete API base URL with version
  static String get apiBaseUrl => baseUrl;

  /// Get WebSocket base URL for real-time connections
  static String getWebSocketBaseUrl() => webSocketBaseUrl;

  /// Authentication endpoints
  static const String authRegister = '/api/auth/register/';
  static const String authLogin = '/api/auth/login/';
  static const String authLogout = '/api/auth/logout/';
  static const String authTokenRefresh = '/api/auth/token/refresh/';
  static const String authVerifyEmail = '/api/auth/verify-email/';
  static const String authResendVerification = '/api/auth/resend-verification/';
  static const String authVerificationStatus = '/api/auth/verification-status/';
  static const String authRegistrationStatus = '/api/auth/registration-status/';
  static const String authPasswordReset = '/api/auth/password-reset/';

  /// Profile endpoints
  static const String profileMe = '/api/profile/me/';
  static const String profileUpdate = '/api/profile/update/';

  /// Request endpoints
  static const String requests = '/api/requests/';
  static const String requestsNearby = '/api/requests/nearby/';
  
  /// Chat endpoints
  static const String chatRooms = '/api/chat/rooms/';
  static const String chatMessages = '/api/chat/messages/';

  /// Feedback endpoints
  static const String feedback = '/api/feedback/';

  /// Notification endpoints
  static const String notifications = '/api/notifications/';

  // =============================================================================
  // TIMEOUT CONFIGURATIONS
  // =============================================================================
  
  /// Connection timeout (how long to wait for connection)
  static const Duration connectTimeout = Duration(seconds: 30);
  
  /// Receive timeout (how long to wait for response)
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  /// Send timeout (how long to wait to send data)
  static const Duration sendTimeout = Duration(seconds: 30);

  // =============================================================================
  // RETRY CONFIGURATION
  // =============================================================================
  
  /// Maximum number of retry attempts
  static const int maxRetryAttempts = 3;
  
  /// Delay between retry attempts
  static const Duration retryDelay = Duration(seconds: 2);

  // =============================================================================
  // SECURITY CONFIGURATION
  // =============================================================================
  
  /// Default headers for all requests
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client-Version': '1.0.0',
        'X-Platform': 'mobile',
      };

  /// Headers for authenticated requests (will add token dynamically)
  static Map<String, String> getAuthHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };

  // =============================================================================
  // PAGINATION CONFIGURATION
  // =============================================================================
  
  /// Default page size for paginated requests
  static const int defaultPageSize = 20;
  
  /// Maximum page size allowed
  static const int maxPageSize = 100;

  // =============================================================================
  // CACHE CONFIGURATION
  // =============================================================================
  
  /// How long to cache user profile data
  static const Duration profileCacheDuration = Duration(minutes: 30);
  
  /// How long to cache request list data
  static const Duration requestsCacheDuration = Duration(minutes: 5);
  
  /// How long to cache user data
  static const Duration userCacheDuration = Duration(minutes: 15);

  // =============================================================================
  // ERROR HANDLING CONFIGURATION
  // =============================================================================
  
  /// HTTP status codes that should trigger a retry
  static const List<int> retryStatusCodes = [408, 429, 500, 502, 503, 504];
  
  /// HTTP status codes that indicate authentication failure
  static const List<int> authFailureStatusCodes = [401, 403];

  // =============================================================================
  // FILE UPLOAD CONFIGURATION
  // =============================================================================
  
  /// Maximum file size for uploads (in bytes) - 10MB
  static const int maxFileSize = 10 * 1024 * 1024;
  
  /// Allowed file types for profile images
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  /// Allowed file types for attachments
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];

  // =============================================================================
  // WEBSOCKET CONFIGURATION
  // =============================================================================
  
  /// WebSocket base URL
  static String get websocketBaseUrl => baseUrl.replaceFirst('http', 'ws');
  
  /// WebSocket connection timeout
  static const Duration websocketTimeout = Duration(seconds: 30);
  
  /// WebSocket ping interval (keep connection alive)
  static const Duration websocketPingInterval = Duration(seconds: 30);

  // =============================================================================
  // LOGGING CONFIGURATION
  // =============================================================================
  
  /// Enable request/response logging (only in development)
  static bool get enableLogging => environment == 'development';
  
  /// Log request details
  static bool get logRequests => enableLogging;
  
  /// Log response details
  static bool get logResponses => enableLogging;
  
  /// Log error details
  static bool get logErrors => true; // Always log errors

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Build complete URL for an endpoint
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }
  
  /// Check if we're in development mode
  static bool get isDevelopment => environment == 'development';
  
  /// Check if we're in production mode
  static bool get isProduction => environment == 'production';
  
  /// Get environment-specific configuration
  static Map<String, dynamic> get environmentConfig => {
        'environment': environment,
        'baseUrl': baseUrl,
        'apiBaseUrl': apiBaseUrl,
        'webSocketBaseUrl': webSocketBaseUrl,
        'isDevelopment': isDevelopment,
        'isProduction': isProduction,
        'enableLogging': enableLogging,
      };

  // =============================================================================
  // DEVELOPMENT HELPERS
  // =============================================================================
  
  /// Print configuration details (development only)
  static void printConfig() {
    if (isDevelopment) {
      log('=== TIRI API Configuration ===');
      log('Environment: $environment');
      log('Base URL: $baseUrl');
      log('API Base URL: $apiBaseUrl');
      log('WebSocket URL: $webSocketBaseUrl');
      log('Logging Enabled: $enableLogging');
      log('Connect Timeout: ${connectTimeout.inSeconds}s');
      log('Receive Timeout: ${receiveTimeout.inSeconds}s');
      log('Max Retry Attempts: $maxRetryAttempts');
      log('==============================');
    }
  }
}