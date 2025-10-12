// lib/services/api_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/api_config.dart';

/// Enterprise-grade API Service for TIRI application
/// 
/// Features:
/// - Automatic token management and refresh
/// - Network connectivity monitoring
/// - Request/response interceptors
/// - Comprehensive error handling
/// - Automatic retries with exponential backoff
/// - Secure token storage
/// - Request/response logging (development)
/// - Offline request queuing
class ApiService {
  // =============================================================================
  // SINGLETON PATTERN
  // =============================================================================
  
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._internal();
  
  factory ApiService() => instance;
  
  ApiService._internal() {
    _initializeDio();
    _initializeSecureStorage();
    _initializeConnectivity();
  }

  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================
  
  late Dio _dio;
  late FlutterSecureStorage _secureStorage;
  late Connectivity _connectivity;
  
  /// Current access token
  String? _accessToken;
  
  /// Current refresh token
  String? _refreshToken;
  
  /// Track if token refresh is in progress to avoid multiple refresh calls
  bool _isRefreshing = false;
  
  /// Queue for requests waiting for token refresh (for future use)
  // final List<RequestOptions> _requestQueue = [];
  
  /// Track when the access token was last refreshed
  DateTime? _tokenLastRefreshed;
  
  /// Access token lifetime in minutes (Django JWT default is 60 minutes)
  static const int _accessTokenLifetimeMinutes = 60;

  // =============================================================================
  // SECURE STORAGE KEYS
  // =============================================================================
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // =============================================================================
  // INITIALIZATION METHODS
  // =============================================================================
  
  /// Initialize Dio HTTP client with interceptors
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    // Add interceptors - AUTH INTERCEPTOR MUST BE FIRST for silent token refresh
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createRetryInterceptor());
    
    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(_createLoggingInterceptor());
    }
  }

  /// Initialize secure storage for tokens
  void _initializeSecureStorage() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivity() {
    _connectivity = Connectivity();
  }

  // =============================================================================
  // INTERCEPTORS
  // =============================================================================
  
  /// Create authentication interceptor for automatic token handling
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        // Don't add auth header to public endpoints only
        if (options.path == ApiConfig.authTokenRefresh ||
            options.path == ApiConfig.authLogin ||
            options.path == ApiConfig.authRegister) {
          handler.next(options);
          return;
        }

        // Check if token needs proactive refresh before making the request
        if (_shouldProactivelyRefreshToken()) {
          final refreshSuccess = await refreshTokenIfNeeded();
          if (!refreshSuccess && _accessToken == null) {
          }
        }

        // Add access token to other requests if available
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        } else {
        }
        
        handler.next(options);
      },
      
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        
        // Handle token expiration (401 Unauthorized)
        if (error.response?.statusCode == 401) {

          // Prevent endless token refresh loops for the token refresh endpoint itself
          if (error.requestOptions.path == ApiConfig.authTokenRefresh) {
            await clearTokens();
            handler.next(error);
            return;
          }

          if (await refreshTokenIfNeeded()) {

            // Retry the original request with new token
            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer $_accessToken';

            try {
              final response = await _dio.fetch(options);
              // 🚨 FLAG: Mark this as a successful silent auth refresh
              response.extra['silent_auth_success'] = true;
              handler.resolve(response);
              return;
            } catch (retryError) {
              handler.next(error);
              return;
            }
          } else {
          }
        }
        
        handler.next(error);
      },
    );
  }

  /// Create retry interceptor for handling temporary failures
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        final statusCode = error.response?.statusCode;
        
        // Only retry on specific status codes
        if (statusCode != null && 
            ApiConfig.retryStatusCodes.contains(statusCode)) {
          
          // Get retry count from request options
          final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
          
          if (retryCount < ApiConfig.maxRetryAttempts) {
            // Wait before retrying (exponential backoff)
            await Future.delayed(
              Duration(milliseconds: 
                (ApiConfig.retryDelay.inMilliseconds * (retryCount + 1)).toInt()
              ),
            );
            
            // Increment retry count
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            
            try {
              // Retry the request
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
      // Error handled silently
              // If retry fails, continue with original error
            }
          }
        }
        
        handler.next(error);
      },
    );
  }

  /// Create logging interceptor for development
  Interceptor _createLoggingInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) {
      },
    );
  }

  // =============================================================================
  // TOKEN MANAGEMENT
  // =============================================================================
  
  /// Load tokens from secure storage on app start
  Future<void> loadTokensFromStorage() async {
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      
      // Load token refresh timestamp
      final refreshTimeStr = await _secureStorage.read(key: 'token_refresh_time');
      if (refreshTimeStr != null) {
        try {
          _tokenLastRefreshed = DateTime.parse(refreshTimeStr);
        } catch (e) {
      // Error handled silently
        }
      }
      
      if (ApiConfig.enableLogging) {
      }
      
      // Check if token needs proactive refresh
      if (_shouldProactivelyRefreshToken()) {
        await refreshTokenIfNeeded();
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// Save tokens to secure storage
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _tokenLastRefreshed = DateTime.now();
      
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: 'token_refresh_time', value: _tokenLastRefreshed!.toIso8601String());
      
      if (ApiConfig.enableLogging) {
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// Clear all tokens and user data
  Future<void> clearTokens() async {
    try {
      _accessToken = null;
      _refreshToken = null;
      _tokenLastRefreshed = null;
      
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: 'token_refresh_time');
      await _secureStorage.delete(key: _userDataKey);
      
      if (ApiConfig.enableLogging) {
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// Get current access token
  /// 
  /// Returns the current access token if available, null otherwise
  Future<String?> getStoredAccessToken() async {
    if (_accessToken != null) {
      return _accessToken;
    }
    
    // Try to load from secure storage if not in memory
    try {
      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      return _accessToken;
    } catch (e) {
      // Error handled silently
      return null;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> refreshTokenIfNeeded() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh to complete
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isRefreshing;
      });
      return _accessToken != null;
    }

    if (_refreshToken == null) {
      return false;
    }

    _isRefreshing = true;
    
    try {
      
      // Create a separate Dio instance to avoid interceptor loops
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      // Use Django JWT refresh format
      final response = await refreshDio.post(
        ApiConfig.authTokenRefresh, 
        data: {
          'refresh': _refreshToken,
        },
      );

      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        
        final newAccessToken = responseData['access'];
        final newRefreshToken = responseData['refresh'];
        
        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          _tokenLastRefreshed = DateTime.now();
          
          // Save new access token and refresh timestamp
          await _secureStorage.write(key: _accessTokenKey, value: newAccessToken);
          await _secureStorage.write(key: 'token_refresh_time', value: _tokenLastRefreshed!.toIso8601String());
          
          // Handle refresh token rotation if enabled in Django
          if (newRefreshToken != null && newRefreshToken != _refreshToken) {
            _refreshToken = newRefreshToken;
            await _secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);
          }
          
          return true;
        } else {
        }
      } else {
        if (response.data != null) {
        }
      }
      
    } catch (e) {
      // Error handled silently
      
      // Handle invalid refresh token
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        
        if (statusCode == 401 || statusCode == 403) {
          await clearTokens();
        }
      }
    } finally {
      _isRefreshing = false;
    }

    return false;
  }

  /// Check if access token should be proactively refreshed
  /// Refreshes when token is within 5 minutes of expiry
  bool _shouldProactivelyRefreshToken() {
    if (_accessToken == null || _refreshToken == null || _tokenLastRefreshed == null) {
      return false;
    }
    
    final now = DateTime.now();
    final tokenAge = now.difference(_tokenLastRefreshed!);
    final refreshThreshold = const Duration(minutes: _accessTokenLifetimeMinutes - 5); // 55 minutes
    
    final shouldRefresh = tokenAge > refreshThreshold;
    
    if (ApiConfig.enableLogging && shouldRefresh) {
    }
    
    return shouldRefresh;
  }

  /// Get the time remaining before access token expires
  Duration? getTokenTimeRemaining() {
    if (_accessToken == null || _tokenLastRefreshed == null) {
      return null;
    }
    
    final now = DateTime.now();
    final tokenAge = now.difference(_tokenLastRefreshed!);
    final tokenLifetime = const Duration(minutes: _accessTokenLifetimeMinutes);
    
    final remaining = tokenLifetime - tokenAge;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // =============================================================================
  // NETWORK CONNECTIVITY
  // =============================================================================
  
  /// Check if device has internet connectivity
  Future<bool> isConnected() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      // Error handled silently
      return false;
    }
  }

  /// Wait for internet connection to be available
  Future<void> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    final startTime = DateTime.now();
    
    while (!await isConnected()) {
      if (DateTime.now().difference(startTime) > timeout) {
        throw Exception('Connection timeout: No internet connection available');
      }
      
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // =============================================================================
  // HTTP METHODS
  // =============================================================================
  
  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      // 🚨 CRITICAL FIX: Make connectivity check optional for critical endpoints
      // The verification-status endpoint should work even if connectivity check fails
      final skipConnectivityCheck = path.contains('/auth/verification-status/') || 
                                    path.contains('/auth/check-approval/');
      
      if (!skipConnectivityCheck) {
        await waitForConnection();
      }
      
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Error handled silently
      throw _handleError(e);
    }
  }

  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      // Skip connectivity check for logout endpoint - it should work offline
      if (!path.contains('/auth/logout/')) {
        await waitForConnection();
      }
      
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Error handled silently
      throw _handleError(e);
    }
  }

  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await waitForConnection();
      
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Error handled silently
      throw _handleError(e);
    }
  }

  /// Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await waitForConnection();
      
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Error handled silently
      throw _handleError(e);
    }
  }

  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await waitForConnection();
      
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      // Error handled silently
      throw _handleError(e);
    }
  }

  // =============================================================================
  // ERROR HANDLING
  // =============================================================================
  
  /// Handle and transform errors into user-friendly exceptions
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return Exception('Connection timeout. Please check your internet connection.');
        
        case DioExceptionType.sendTimeout:
          return Exception('Request timeout. Please try again.');
        
        case DioExceptionType.receiveTimeout:
          return Exception('Response timeout. Please try again.');
        
        case DioExceptionType.badResponse:
          return _handleHttpError(error);
        
        case DioExceptionType.cancel:
          return Exception('Request was cancelled.');
        
        case DioExceptionType.connectionError:
          return Exception('No internet connection. Please check your network.');
        
        default:
          return Exception('Network error. Please try again.');
      }
    }
    
    if (error is SocketException) {
      return Exception('No internet connection. Please check your network.');
    }
    
    return Exception('Unexpected error occurred. Please try again.');
  }

  /// Handle HTTP response errors
  Exception _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    switch (statusCode) {
      case 400:
        // 🚨 DEBUG FIX: Preserve original DioException for debugging Django validation errors
        
        // Throw the original DioException so RequestService can extract Django errors
        throw error;
      
      case 401:
        return Exception('Authentication failed. Please login again.');
      
      case 403:
        return Exception('Access denied. You don\'t have permission for this action.');
      
      case 404:
        return Exception('Resource not found.');
      
      case 409:
        return Exception('Conflict. The resource already exists.');
      
      case 422:
        // Validation errors
        if (data is Map && data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return Exception(firstError.first.toString());
            }
          }
        }
        return Exception('Validation error. Please check your input.');
      
      case 429:
        return Exception('Too many requests. Please wait a moment and try again.');
      
      case 500:
        return Exception('Server error. Please try again later.');
      
      case 502:
      case 503:
      case 504:
        return Exception('Service temporarily unavailable. Please try again later.');
      
      default:
        return Exception('HTTP error $statusCode. Please try again.');
    }
  }

  // =============================================================================
  // GETTERS
  // =============================================================================
  
  /// Check if user is authenticated (has valid access token)
  bool get isAuthenticated => _accessToken != null;
  
  /// Get current access token
  String? get accessToken => _accessToken;
  
  /// Get current refresh token
  String? get refreshToken => _refreshToken;
}