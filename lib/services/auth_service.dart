// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Authentication Service for TIRI application
/// 
/// Handles all authentication-related operations:
/// - User registration with referral codes
/// - Login with email/password
/// - Logout with token cleanup
/// - Email verification
/// - Password reset
/// - User profile management
/// - Token management
class AuthService {
  // =============================================================================
  // SINGLETON PATTERN
  // =============================================================================
  
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._internal();
  
  factory AuthService() => instance;
  
  AuthService._internal() {
    _initializeService();
  }

  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================
  
  late ApiService _apiService;
  late FlutterSecureStorage _secureStorage;
  
  /// Current authenticated user
  UserModel? _currentUser;

  // =============================================================================
  // SECURE STORAGE KEYS
  // =============================================================================
  
  static const String _userDataKey = 'user_data';
  static const String _userPreferencesKey = 'user_preferences';

  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  void _initializeService() {
    _apiService = ApiService.instance;
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  /// Initialize auth service and load saved user data
  Future<void> initialize() async {
    try {
      // Load tokens from storage
      await _apiService.loadTokensFromStorage();
      
      // Load user data from storage
      await _loadUserFromStorage();
      
      if (ApiConfig.enableLogging) {
        log('AuthService initialized', name: 'AUTH');
        log('User authenticated: ${isAuthenticated}', name: 'AUTH');
      }
    } catch (e) {
      log('Error initializing AuthService: $e', name: 'AUTH');
    }
  }

  // =============================================================================
  // AUTHENTICATION METHODS
  // =============================================================================
  
  /// Register new user with referral code
  /// 
  /// Parameters:
  /// - [name]: User's full name
  /// - [email]: User's email address
  /// - [phoneNumber]: User's phone number with country code
  /// - [country]: User's country
  /// - [password]: User's password
  /// - [referralCode]: Referral code from existing user
  /// - [imageUrl]: Optional profile image URL
  /// 
  /// Returns: AuthResult with user data and tokens
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String country,
    required String password,
    required String referralCode,
    String? imageUrl,
  }) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Attempting registration for email: $email', name: 'AUTH');
      }

      final response = await _apiService.post(
        ApiConfig.authRegister,
        data: {
                  'first_name': name.trim(),                    // ✅ FIXED: Django expects first_name
                  'last_name': '',                              // ✅ ADDED: Django expects last_name  
                  'email': email.trim().toLowerCase(),
                  'phone_number': phoneNumber.trim(),
                  'country': country.trim(),
                  'password': password,
                  'password_confirm': password,                 // ✅ ADDED: Django requires this
                  'referral_code': referralCode.trim(),
                  if (imageUrl != null) 'image_url': imageUrl,
                },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        
        // Extract user data and tokens
        final userData = data['user'] ?? data['data'];
        final tokens = data['tokens'];
        
        if (userData != null && tokens != null) {
          // Create user model
          final user = UserModel.fromJson(userData);
          
          // Save tokens
          await _apiService.saveTokens(
            tokens['access'],
            tokens['refresh'],
          );
          
          // Save user data
          await _saveUserToStorage(user);
          _currentUser = user;
          
          if (ApiConfig.enableLogging) {
            log('Registration successful for: ${user.email}', name: 'AUTH');
          }
          
          return AuthResult.success(
            user: user,
            message: data['message'] ?? 'Registration successful',
          );
        }
      }
      
      return AuthResult.failure(
        message: 'Registration failed: Invalid response format',
      );
      
    } catch (e) {
      log('Registration error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Login user with email and password
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns: AuthResult with user data and tokens
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Attempting login for email: $email', name: 'AUTH');
      }

      final response = await _apiService.post(
        ApiConfig.authLogin,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extract user data and tokens
        final userData = data['user'] ?? data['data'];
        final tokens = data['tokens'];
        
        if (userData != null && tokens != null) {
          // Create user model
          final user = UserModel.fromJson(userData);
          
          // Save tokens
          await _apiService.saveTokens(
            tokens['access'],
            tokens['refresh'],
          );
          
          // Save user data
          await _saveUserToStorage(user);
          _currentUser = user;
          
          if (ApiConfig.enableLogging) {
            log('Login successful for: ${user.email}', name: 'AUTH');
          }
          
          return AuthResult.success(
            user: user,
            message: data['message'] ?? 'Login successful',
          );
        }
      }
      
      return AuthResult.failure(
        message: 'Login failed: Invalid response format',
      );
      
    } catch (e) {
      log('Login error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  Future<Map<String, dynamic>?> verifyReferralCode(String referralCode) async {
    try {
      log('Calling Django API to verify referral code: $referralCode', name: 'AUTH');
      
      // Use the ApiService instance to call Django backend
      final response = await _apiService.post(
        '/auth/verify-referral/',
        data: {
          'referral_code': referralCode,
        },
      );

      log('Django API response status: ${response.statusCode}', name: 'AUTH');
      log('Django API response data: ${response.data}', name: 'AUTH');

      if (response.statusCode == 200 && response.data != null) {
        log('Referral code verified successfully', name: 'AUTH');
        return response.data as Map<String, dynamic>;
      }
      
      log('Referral code verification failed - status: ${response.statusCode}', name: 'AUTH');
      return null;
    } catch (e) {
      log('Error verifying referral code: $e', name: 'AUTH');
      return null;
    }
  }

  /// Logout current user and clear all data
  Future<AuthResult> logout() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Attempting logout', name: 'AUTH');
      }

      // Try to logout on server (optional - don't fail if it doesn't work)
      try {
        await _apiService.post(
          ApiConfig.authLogout,
          data: {
            'refresh': _apiService.refreshToken,
          },
        );
      } catch (e) {
        // Server logout failed, but continue with local cleanup
        log('Server logout failed (continuing with local cleanup): $e', name: 'AUTH');
      }

      // Clear all local data
      await _clearAllUserData();
      
      if (ApiConfig.enableLogging) {
        log('Logout completed', name: 'AUTH');
      }
      
      return AuthResult.success(
        message: 'Logout successful',
      );
      
    } catch (e) {
      log('Logout error: $e', name: 'AUTH');
      
      // Even if logout fails, clear local data
      await _clearAllUserData();
      
      return AuthResult.success(
        message: 'Logout completed',
      );
    }
  }

  /// Verify user's email address
  /// 
  /// Parameters:
  /// - [token]: Email verification token
  /// - [uid]: User ID (base64 encoded)
  /// 
  /// Returns: AuthResult with verification status
  Future<AuthResult> verifyEmail({
    required String token,
    required String uid,
  }) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Attempting email verification', name: 'AUTH');
      }

      final response = await _apiService.post(
        ApiConfig.authVerifyEmail,
        data: {
          'token': token,
          'uid': uid,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('Email verification successful', name: 'AUTH');
        }
        
        return AuthResult.success(
          message: data['message'] ?? 'Email verified successfully',
        );
      }
      
      return AuthResult.failure(
        message: 'Email verification failed',
      );
      
    } catch (e) {
      log('Email verification error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Request password reset
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// 
  /// Returns: AuthResult with reset status
  Future<AuthResult> requestPasswordReset({
    required String email,
  }) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Requesting password reset for: $email', name: 'AUTH');
      }

      final response = await _apiService.post(
        ApiConfig.authPasswordReset,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('Password reset requested successfully', name: 'AUTH');
        }
        
        return AuthResult.success(
          message: data['message'] ?? 'Password reset email sent',
        );
      }
      
      return AuthResult.failure(
        message: 'Password reset request failed',
      );
      
    } catch (e) {
      log('Password reset request error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  // =============================================================================
  // USER PROFILE METHODS
  // =============================================================================
  
  /// Get current user profile from server
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) {
        return null;
      }

      final response = await _apiService.get(ApiConfig.profileMe);

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['data'] ?? data;
        
        final user = UserModel.fromJson(userData);
        
        // Update local user data
        await _saveUserToStorage(user);
        _currentUser = user;
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      log('Get current user profile error: $e', name: 'AUTH');
      return null;
    }
  }

  /// Update user profile
  /// 
  /// Parameters:
  /// - [updates]: Map of fields to update
  /// 
  /// Returns: Updated UserModel or null if failed
  Future<UserModel?> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (!isAuthenticated) {
        return null;
      }

      final response = await _apiService.patch(
        ApiConfig.profileUpdate,
        data: updates,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['data'] ?? data;
        
        final user = UserModel.fromJson(userData);
        
        // Update local user data
        await _saveUserToStorage(user);
        _currentUser = user;
        
        if (ApiConfig.enableLogging) {
          log('Profile updated successfully', name: 'AUTH');
        }
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      log('Update profile error: $e', name: 'AUTH');
      return null;
    }
  }

  // =============================================================================
  // STORAGE METHODS
  // =============================================================================
  
  /// Load user data from secure storage
  Future<void> _loadUserFromStorage() async {
    try {
      final userDataString = await _secureStorage.read(key: _userDataKey);
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUser = UserModel.fromJson(userData);
        
        if (ApiConfig.enableLogging) {
          log('User data loaded from storage: ${_currentUser?.email}', name: 'AUTH');
        }
      }
    } catch (e) {
      log('Error loading user from storage: $e', name: 'AUTH');
    }
  }

  /// Save user data to secure storage
  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final userDataString = jsonEncode(user.toJson());
      await _secureStorage.write(key: _userDataKey, value: userDataString);
      
      if (ApiConfig.enableLogging) {
        log('User data saved to storage: ${user.email}', name: 'AUTH');
      }
    } catch (e) {
      log('Error saving user to storage: $e', name: 'AUTH');
    }
  }

  /// Clear all user data from storage
  Future<void> _clearAllUserData() async {
    try {
      _currentUser = null;
      
      // Clear tokens
      await _apiService.clearTokens();
      
      // Clear user data
      await _secureStorage.delete(key: _userDataKey);
      await _secureStorage.delete(key: _userPreferencesKey);
      
      if (ApiConfig.enableLogging) {
        log('All user data cleared', name: 'AUTH');
      }
    } catch (e) {
      log('Error clearing user data: $e', name: 'AUTH');
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Extract user-friendly error message from exception
  String _extractErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      
      return message;
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  // =============================================================================
  // GETTERS
  // =============================================================================
  
  /// Check if user is authenticated
  bool get isAuthenticated => _apiService.isAuthenticated && _currentUser != null;
  
  /// Get current user
  UserModel? get currentUser => _currentUser;
  
  /// Get current user's ID
  String? get currentUserId => _currentUser?.userId;
  
  /// Get current user's email
  String? get currentUserEmail => _currentUser?.email;
  
  /// Check if current user is verified
  bool get isUserVerified => _currentUser?.isVerified ?? false;
}

// =============================================================================
// AUTH RESULT CLASS
// =============================================================================

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final UserModel? user;
  final String message;
  final Map<String, dynamic>? data;

  AuthResult._({
    required this.isSuccess,
    this.user,
    required this.message,
    this.data,
  });

  /// Create successful auth result
  factory AuthResult.success({
    UserModel? user,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
      data: data,
    );
  }

  /// Create failed auth result
  factory AuthResult.failure({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      data: data,
    );
  }

  @override
  String toString() {
    return 'AuthResult(isSuccess: $isSuccess, message: $message, user: ${user?.email})';
  }

  /// Verify referral code with Django backend
  /// 
  /// Parameters:
  /// - [referralCode]: The referral code to verify
  /// 
  /// Returns: Map with validation result and referrer info
/// Verify referral code with Django backend
  /// 
  /// Parameters:
  /// - [referralCode]: The referral code to verify
  /// 
  /// Returns: Map with validation result and referrer info
  Future<Map<String, dynamic>?> verifyReferralCode(String referralCode) async {
    try {
      // Use the singleton instance of ApiService
      final response = await ApiService.instance.post(
        '/auth/verify-referral/',
        data: {
          'referral_code': referralCode,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        log('Referral code verified successfully', name: 'AUTH');
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      log('Error verifying referral code: $e', name: 'AUTH');
      return null;
    }
  }
}
