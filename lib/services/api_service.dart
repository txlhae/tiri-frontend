// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
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

  /// 🔥 FIX #3: Use Completer to notify waiting requests when refresh completes
  Completer<bool>? _refreshCompleter;

  /// Queue for requests waiting for token refresh (for future use)
  // final List<RequestOptions> _requestQueue = [];

  /// Track when the access token was last refreshed
  DateTime? _tokenLastRefreshed;

  /// 🔥 FIX #5: Track when the access token expires
  DateTime? _tokenExpiresAt;

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

        // 🔥 FIX #5: Check if token is expired before making request
        if (isTokenExpired && _refreshToken != null) {
          // Token is expired or about to expire - refresh it proactively
          await refreshTokenIfNeeded();
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
  /// 🔥 FIX #5: Now also loads token expiry time
  /// 🔥 FIX #6: Added comprehensive logging
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

      // 🔥 FIX #5: Load token expiry time
      final expiryTimeStr = await _secureStorage.read(key: 'token_expires_at');
      if (expiryTimeStr != null) {
        try {
          _tokenExpiresAt = DateTime.parse(expiryTimeStr);
        } catch (e) {
          // Error handled silently - will decode from token if needed
        }
      } else if (_accessToken != null) {
        // No stored expiry - try to decode from token
        _tokenExpiresAt = _decodeTokenExpiry(_accessToken!);
      }

      // 🔥 FIX #6: Add detailed logging
      if (ApiConfig.enableLogging) {
        print('📂 [ApiService] Loaded tokens from storage');
        print('   🔑 Access token: ${_accessToken != null ? "Present" : "Missing"}');
        print('   🔄 Refresh token: ${_refreshToken != null ? "Present" : "Missing"}');
        if (_tokenExpiresAt != null) {
          final isExpired = DateTime.now().isAfter(_tokenExpiresAt!);
          print('   📅 Token expires at: ${_tokenExpiresAt!.toLocal()}');
          print('   ${isExpired ? "⚠️  Token is EXPIRED" : "✅ Token is valid"}');
          if (!isExpired) {
            print('   ⏰ Time until expiry: ${_tokenExpiresAt!.difference(DateTime.now()).inMinutes} minutes');
          }
        }
      }
    } catch (e) {
      // Error handled silently
      if (ApiConfig.enableLogging) {
        print('❌ [ApiService] Failed to load tokens: $e');
      }
    }
  }

  /// Save tokens to secure storage
  /// 🔥 FIX #5: Now extracts and stores token expiry time
  /// 🔥 FIX #6: Added comprehensive logging
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _tokenLastRefreshed = DateTime.now();

      // 🔥 FIX #5: Decode JWT and extract expiry time
      _tokenExpiresAt = _decodeTokenExpiry(accessToken);

      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: 'token_refresh_time', value: _tokenLastRefreshed!.toIso8601String());

      if (_tokenExpiresAt != null) {
        await _secureStorage.write(key: 'token_expires_at', value: _tokenExpiresAt!.toIso8601String());
      }

      // 🔥 FIX #6: Add detailed logging
      if (ApiConfig.enableLogging) {
        print('✅ [ApiService] Tokens saved successfully');
        print('   📅 Token expires at: ${_tokenExpiresAt?.toLocal()}');
        print('   ⏰ Time until expiry: ${_tokenExpiresAt?.difference(DateTime.now()).inMinutes ?? 0} minutes');
      }
    } catch (e) {
      // Error handled silently
      if (ApiConfig.enableLogging) {
        print('❌ [ApiService] Failed to save tokens: $e');
      }
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
  /// 🔥 FIX #3: Uses Completer to handle concurrent refresh requests properly
  /// 🔥 FIX #6: Added comprehensive logging
  Future<bool> refreshTokenIfNeeded() async {
    // 🔥 FIX #6: Log refresh attempt
    if (ApiConfig.enableLogging) {
      print('🔄 [ApiService] Token refresh requested at ${DateTime.now().toLocal()}');
    }

    // 🔥 FIX #3: If refresh is already in progress, wait for it to complete
    if (_isRefreshing && _refreshCompleter != null) {
      if (ApiConfig.enableLogging) {
        print('⏳ [ApiService] Token refresh already in progress, waiting...');
      }
      return await _refreshCompleter!.future;
    }

    if (_refreshToken == null) {
      if (ApiConfig.enableLogging) {
        print('❌ [ApiService] No refresh token available');
      }
      return false;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

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

          // 🔥 FIX #3: Notify all waiting requests that refresh succeeded
          _refreshCompleter?.complete(true);

          // 🔥 FIX #6: Log successful refresh
          if (ApiConfig.enableLogging) {
            print('✅ [ApiService] Token refresh successful');
            print('   📅 New token expires at: ${_tokenExpiresAt?.toLocal()}');
          }

          return true;
        } else {
          if (ApiConfig.enableLogging) {
            print('❌ [ApiService] Token refresh response missing access token');
          }
        }
      } else {
        if (response.data != null) {
          if (ApiConfig.enableLogging) {
            print('❌ [ApiService] Token refresh failed with status ${response.statusCode}');
          }
        }
      }

      // 🔥 FIX #3: Notify all waiting requests that refresh failed
      _refreshCompleter?.complete(false);

    } catch (e) {
      // 🔥 FIX #6: Log refresh errors
      if (ApiConfig.enableLogging) {
        print('❌ [ApiService] Token refresh exception: $e');
      }

      if (e is DioException) {
        final statusCode = e.response?.statusCode;

        if (statusCode == 401 || statusCode == 403) {
          if (ApiConfig.enableLogging) {
            print('⚠️  [ApiService] Refresh token is invalid (${statusCode}), clearing all tokens');
          }
          await clearTokens();
        }
      }

      // 🔥 FIX #3: Notify all waiting requests that refresh failed
      _refreshCompleter?.complete(false);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }

    return false;
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
  // HELPER METHODS
  // =============================================================================

  /// 🔥 FIX #5: Decode JWT token and extract expiry time
  /// Returns null if token is invalid or doesn't have exp claim
  DateTime? _decodeTokenExpiry(String token) {
    try {
      // JWT format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed for base64 decoding
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      // Extract exp claim (expiry timestamp in seconds since epoch)
      final exp = payloadMap['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }

      return null;
    } catch (e) {
      // Failed to decode token
      return null;
    }
  }

  /// 🔥 FIX #5: Check if the current access token is expired or about to expire
  /// Returns true if token is expired or will expire within the next 60 seconds
  bool get isTokenExpired {
    if (_tokenExpiresAt == null) {
      return false; // No expiry info, assume valid
    }

    // Add 60 second buffer - refresh if token expires in less than 1 minute
    final expiryWithBuffer = _tokenExpiresAt!.subtract(const Duration(seconds: 60));
    return DateTime.now().isAfter(expiryWithBuffer);
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