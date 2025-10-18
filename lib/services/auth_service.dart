// lib/services/auth_service.dart

import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import 'api_service.dart';
import 'firebase_notification_service.dart';
import 'auth_storage.dart';
import 'error_handler.dart';

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
  /// Map backend user JSON (snake_case) to Flutter UserModel camelCase
  /// 🔥 FIX: Prioritize full_name over username field since backend sends email in username
  Map<String, dynamic> _mapUserSnakeToCamel(Map<String, dynamic> user) {
    // Prioritize full_name, then first_name, then username as fallback
    String displayName = user['username'] ?? 'Unknown';
    if (user['full_name'] != null && user['full_name'].toString().trim().isNotEmpty) {
      displayName = user['full_name'];
    } else if (user['first_name'] != null && user['first_name'].toString().trim().isNotEmpty) {
      displayName = user['first_name'];
    }

    return {
      'userId': user['userId'] ?? user['user_id'] ?? user['id'],
      'email': user['email'],
      'username': displayName,  // 🔥 Use full_name instead of username
      'imageUrl': user['imageUrl'] ?? user['image_url'] ?? user['profile_image'],
      'referralUserId': user['referralUserId'] ?? user['referral_user_id'],
      'phoneNumber': user['phoneNumber'] ?? user['phone_number'],
      'country': user['country'],
      'referralCode': user['referralCode'] ?? user['referral_code'],
      'rating': user['rating'],
      'hours': user['hours'],
      'createdAt': user['createdAt'],
      'isVerified': user['isVerified'] ?? user['is_verified'],
      // Approval system fields
      'isApproved': user['isApproved'] ?? user['is_approved'],
      'approvalStatus': user['approvalStatus'] ?? user['approval_status'],
      'rejectionReason': user['rejectionReason'] ?? user['rejection_reason'],
      'approvalExpiresAt': user['approvalExpiresAt'] ?? user['approval_expires_at'],
      // New referral fields from backend
      'referredByUserId': user['referredByUserId'] ?? user['referred_by_user_id'],
      'referredByName': user['referredByName'] ?? user['referred_by_name'],
      'referredByEmail': user['referredByEmail'] ?? user['referred_by_email'],
      'approvalDate': user['approvalDate'] ?? user['approval_date'],
    };
  }
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
      
    } catch (e) {
      // Error handled silently
      // Silent initialization error handling
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
  /// Returns: Enhanced AuthResult with account status and next steps
  Future<EnhancedAuthResult> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String country,
    required String password,
    required String referralCode,
    String? imageUrl,
  }) async {
    try {

      final response = await _apiService.post(
        '/api/auth/register/',
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
        
        
        try {
          // Map snake_case to camelCase for AuthResponse
          final Map<String, dynamic> mappedData = {
            'user': data['user'],
            'tokens': data['tokens'],
            'message': data['message'] ?? 'Registration successful',
            'accountStatus': data['account_status'] ?? data['accountStatus'],
            'nextStep': data['next_step'] ?? data['nextStep'],
            'registrationStage': data['registration_stage'] ?? data['registrationStage'],
            'warning': data['warning'],
          };

          // Parse the enhanced auth response
          final authResponse = AuthResponse.fromJson(mappedData);
          
          // Save tokens
          await _apiService.saveTokens(
            authResponse.tokens.access,
            authResponse.tokens.refresh,
          );
          
          // Save user data
          await _saveUserToStorage(authResponse.user);
          _currentUser = authResponse.user;
          
          
          // Set up push notifications after successful registration
          _setupPushNotificationsAfterAuth();
          
          // Also call FCM setup immediately to ensure it happens
          _setupFCMTokenImmediately();
          
          return EnhancedAuthResult.success(
            authResponse: authResponse,
            message: authResponse.message,
          );
        } catch (e) {
      // Error handled silently
          // Fallback to legacy format if new format parsing fails
          
          final userData = data['user'] ?? data['data'];
          final tokens = data['tokens'];
          
          if (userData != null && tokens != null) {
            final mappedData = _mapUserSnakeToCamel(userData);
            final user = UserModel.fromJson(mappedData);
            
            await _apiService.saveTokens(tokens['access'], tokens['refresh']);
            await _saveUserToStorage(user);
            _currentUser = user;
            
            // Set up push notifications after successful legacy registration
            _setupPushNotificationsAfterAuth();
            
            // Also call FCM setup immediately to ensure it happens
            _setupFCMTokenImmediately();
            
            return EnhancedAuthResult.legacy(
              user: user,
              message: data['message'] ?? 'Registration successful',
            );
          }
        }
      }
      
      return EnhancedAuthResult.failure(
        message: 'Registration failed: Invalid response format',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Registration failed. Please try again.');
      return EnhancedAuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Login user with email and password with enhanced next_step routing
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Returns: Enhanced AuthResult with account status and next steps
  Future<EnhancedAuthResult> login({
    required String email,
    required String password,
  }) async {
    try {

      final response = await _apiService.post(
        '/api/auth/login/',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        try {
          // Try to parse enhanced response with next_step
          if (data['next_step'] != null && data['account_status'] != null) {

            // Store complete auth response using AuthStorage
            await AuthStorage.storeAuthData(data);

            // Parse user and tokens
            final userData = data['user'] ?? {};
            final tokens = data['tokens'] ?? {};

            if (tokens['access'] != null && tokens['refresh'] != null) {
              await _apiService.saveTokens(tokens['access'], tokens['refresh']);
            }

            if (userData.isNotEmpty) {
              final mappedData = _mapUserSnakeToCamel(userData);
              final user = UserModel.fromJson(mappedData);
              await _saveUserToStorage(user);
              _currentUser = user;
            }

            // Set up push notifications
            _setupPushNotificationsAfterAuth();
            _setupFCMTokenImmediately();

            try {
              // Parse user data separately with proper error handling
              UserModel? parsedUser;
              try {
                final mappedUserData = _mapUserSnakeToCamel(userData);
                parsedUser = UserModel.fromJson(mappedUserData);
              } catch (userParseError) {
                // Use existing _currentUser if available, or create minimal user
                parsedUser = _currentUser;
              }

              // Parse tokens separately
              AuthTokens? parsedTokens;
              try {
                parsedTokens = AuthTokens.fromJson(tokens);
              } catch (tokenParseError) {
                // Create tokens manually
                parsedTokens = AuthTokens(
                  access: tokens['access'] ?? '',
                  refresh: tokens['refresh'] ?? '',
                );
              }

              // Parse registration stage separately if present
              RegistrationStage? parsedRegistrationStage;
              if (data['registration_stage'] != null) {
                try {
                  // Map snake_case fields to camelCase for RegistrationStage parsing
                  final registrationStageData = data['registration_stage'] as Map<String, dynamic>;
                  final mappedRegistrationStage = {
                    'status': registrationStageData['status'],
                    'isEmailVerified': registrationStageData['is_email_verified'] ?? registrationStageData['isEmailVerified'] ?? false,
                    'emailVerifiedAt': registrationStageData['email_verified_at'] ?? registrationStageData['emailVerifiedAt'],
                    'isApproved': registrationStageData['is_approved'] ?? registrationStageData['isApproved'] ?? false,
                    'hasReferral': registrationStageData['has_referral'] ?? registrationStageData['hasReferral'] ?? false,
                    'canAccessApp': registrationStageData['can_access_app'] ?? registrationStageData['canAccessApp'] ?? false,
                    'approvalStatus': registrationStageData['approval_status'] ?? registrationStageData['approvalStatus'],
                    'referrerEmail': registrationStageData['referrer_email'] ?? registrationStageData['referrerEmail'],
                    'approvalExpiresAt': registrationStageData['approval_expires_at'] ?? registrationStageData['approvalExpiresAt'],
                    'timeRemaining': registrationStageData['time_remaining'] ?? registrationStageData['timeRemaining'],
                    'accountCreatedAt': registrationStageData['account_created_at'] ?? registrationStageData['accountCreatedAt'],
                  };

                  parsedRegistrationStage = RegistrationStage.fromJson(mappedRegistrationStage);
                } catch (stageParseError) {
                  // Continue without registration stage
                }
              }

              // Only attempt AuthResponse creation if we have essential data
              if (parsedUser != null) {
                try {
                  final authResponse = AuthResponse(
                    user: parsedUser,
                    tokens: parsedTokens,
                    message: data['message'] ?? 'Login successful',
                    accountStatus: data['account_status'] ?? 'unknown',
                    nextStep: data['next_step'] ?? 'ready',
                    registrationStage: parsedRegistrationStage,
                    warning: null, // Skip warning parsing for now
                  );

                  return EnhancedAuthResult.success(
                    authResponse: authResponse,
                    message: data['message'] ?? 'Login successful',
                  );
                } catch (authResponseError) {
                  // Fall through to legacy response
                }
              }

              // Fallback to legacy response
              return EnhancedAuthResult.legacy(
                user: parsedUser ?? _currentUser!,
                message: data['message'] ?? 'Login successful',
              );

            } catch (parseError) {
              // Last resort fallback - if we have tokens and user data saved, succeed anyway
              if (_currentUser != null) {
                return EnhancedAuthResult.legacy(
                  user: _currentUser!,
                  message: data['message'] ?? 'Login successful',
                );
              }

              // Only fail if we absolutely cannot recover
              return EnhancedAuthResult.failure(
                message: 'Login completed but response format is unexpected. Please try logging in again.',
              );
            }
          } else {
            // Legacy response format
            final userData = data['user'] ?? data['data'];
            final tokens = data['tokens'];

            if (userData != null && tokens != null) {
              final mappedData = _mapUserSnakeToCamel(userData);
              final user = UserModel.fromJson(mappedData);

              await _apiService.saveTokens(tokens['access'], tokens['refresh']);
              await _saveUserToStorage(user);
              _currentUser = user;

              // For legacy responses, store basic auth data
              await AuthStorage.storeAuthData({
                'user': userData,
                'tokens': tokens,
                'account_status': user.isApproved ? 'active' : 'pending_approval',
                'next_step': user.isApproved ? 'ready' : 'waiting_for_approval',
                'message': data['message'] ?? 'Login successful',
              });

              _setupPushNotificationsAfterAuth();
              _setupFCMTokenImmediately();

              return EnhancedAuthResult.legacy(
                user: user,
                message: data['message'] ?? 'Login successful',
              );
            } else {
              // Missing user data or tokens in legacy response
              return EnhancedAuthResult.failure(
                message: 'Login failed: Incomplete response data',
              );
            }
          }
        } catch (e) {
      // Error handled silently
          return EnhancedAuthResult.failure(
            message: 'Login failed: Invalid response format',
          );
        }
      } else {
        // Non-200 response
        return EnhancedAuthResult.failure(
          message: 'Login failed: Server error',
        );
      }

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Login failed. Please try again.');
      return EnhancedAuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }


  /// Logout current user and clear all data
  Future<AuthResult> logout() async {
    try {

      // Try to logout on server (optional - don't fail if it doesn't work)
      try {
        await _apiService.post(
          '/api/auth/logout/',
          data: {
            'refresh': _apiService.refreshToken,
          },
        );
      } catch (e) {
      // Error handled silently
        // Server logout failed, but continue with local cleanup
      }

      // Clean up Firebase notifications
      try {
        final firebaseNotificationService = Get.find<FirebaseNotificationService>();
        await firebaseNotificationService.cleanup();
      } catch (e) {
      // Error handled silently
        // Firebase notification cleanup failed (continuing)
      }

      // Clear all local data
      await _clearAllUserData();
      
      return AuthResult.success(
        message: 'Logout successful',
      );
      
    } catch (e) {
      // Error handled silently
      // Even if logout fails, clear local data
      await _clearAllUserData();

      return AuthResult.success(
        message: 'Logout completed',
      );
    }
  }

  /// Verify user's email address (enhanced for mobile deep links)
  /// 
  /// Parameters:
  /// - [token]: Email verification token
  /// - [uid]: User ID (base64 encoded)
  /// - [isMobile]: Whether this is a mobile verification request
  /// 
  /// Returns: AuthResult with verification status and optional tokens
  Future<AuthResult> verifyEmail({
    required String token,
    required String uid,
    bool isMobile = false,
  }) async {
    try {

      // Use mobile endpoint if this is from a mobile deep link
      final endpoint = isMobile 
          ? '${ApiConfig.authVerifyEmail}$uid/$token/?mobile=true'
          : ApiConfig.authVerifyEmail;

      final response = await _apiService.post(
        endpoint,
        data: isMobile ? {} : {
          'token': token,
          'uid': uid,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        

        // Handle mobile response with tokens
        if (isMobile && data['access_token'] != null && data['refresh_token'] != null) {
          // Save tokens from mobile verification
          await _apiService.saveTokens(
            data['access_token'],
            data['refresh_token'],
          );

          // Update user data if provided
          if (data['user'] != null) {
            final user = UserModel.fromJson(data['user']);
            await _saveUserToStorage(user);
            _currentUser = user;
            
            return AuthResult.success(
              user: user,
              message: data['message'] ?? 'Email verified successfully - you are now logged in',
            );
          }
        }
        
        return AuthResult.success(
          message: data['message'] ?? 'Email verified successfully',
        );
      }


      return AuthResult.failure(
        message: 'Email verification failed',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Email verification failed. Please try again.');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Check current user's verification status with enhanced auto-login support
  ///
  /// Returns: Map with verification status, auto_login flag, and JWT tokens

  static bool _isCheckingVerificationStatus = false; // 🚨 MUTEX to prevent concurrent calls

  Future<Map<String, dynamic>> checkVerificationStatus() async {
    // 🚨 PREVENT CONCURRENT CALLS: Only allow one verification check at a time
    if (_isCheckingVerificationStatus) {
      // Wait for ongoing check to complete
      while (_isCheckingVerificationStatus) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return empty result for subsequent calls
      return {'status': 'already_checking'};
    }

    _isCheckingVerificationStatus = true;

    try {
      // 🚨 CRITICAL FIX: Ensure API service has latest tokens before making the call
      await _apiService.loadTokensFromStorage();


      final response = await _apiService.get(ApiConfig.authVerificationStatus);

      if (response.statusCode == 200) {
        final data = response.data;
        
        
        // Handle auto-login with direct JWT tokens (new format)
        if (data['auto_login'] == true) {
          // Check for direct access_token and refresh_token in response
          if (data['access_token'] != null && data['refresh_token'] != null) {
            // Save JWT tokens directly from response
            await _apiService.saveTokens(
              data['access_token'],
              data['refresh_token'],
            );
            
            
            // Update user data if provided
            if (data['user'] != null) {
              final user = UserModel.fromJson(_mapUserSnakeToCamel(data['user']));
              await _saveUserToStorage(user);
              _currentUser = user;
              
            }
          }
        }
        
        return {
          'is_verified': data['is_verified'] ?? false,
          'auto_login': data['auto_login'] ?? false,
          'approval_status': data['approval_status'] ?? 'unknown',
          'message': data['message'] ?? 'Status retrieved successfully',
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'user': data['user'],
        };
      }
      
      throw Exception('Failed to check verification status - HTTP ${response.statusCode}');
      
    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not check verification status');
      return {
        'is_verified': false,
        'auto_login': false,
        'approval_status': 'error',
        'message': ErrorHandler.mapErrorToUserMessage(errorMessage),
        'access_token': null,
        'refresh_token': null,
        'user': null,
      };
    } finally {
      // 🚨 CRITICAL: Always release the mutex
      _isCheckingVerificationStatus = false;
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

      final response = await _apiService.post(
        ApiConfig.authPasswordReset,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;


        return AuthResult.success(
          message: data['message'] ?? 'Password reset email sent',
        );
      }

      return AuthResult.failure(
        message: 'Password reset request failed. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Password reset request failed');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Confirm password reset with token
  ///
  /// Parameters:
  /// - [uid]: User ID (base64 encoded)
  /// - [token]: Password reset token
  /// - [newPassword]: New password
  ///
  /// Returns: AuthResult with confirmation status
  Future<AuthResult> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    try {

      final response = await _apiService.post(
        '/api/auth/password-reset-confirm/',
        data: {
          'uid': uid,
          'token': token,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;


        return AuthResult.success(
          message: data['message'] ?? 'Password reset successful',
        );
      }

      return AuthResult.failure(
        message: 'Password reset confirmation failed. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Password reset failed');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Resend verification email
  ///
  /// Parameters:
  /// - [email]: User's email address (optional - uses current user if not provided)
  ///
  /// Returns: AuthResult with resend status
  Future<AuthResult> resendVerificationEmail({String? email}) async {
    try {
      final targetEmail = email ?? _currentUser?.email;

      if (targetEmail == null) {
        return AuthResult.failure(
          message: 'No email address available',
        );
      }


      final response = await _apiService.post(
        ApiConfig.authResendVerification,
        data: {'email': targetEmail.trim().toLowerCase()},
      );

      if (response.statusCode == 200) {
        final data = response.data;


        return AuthResult.success(
          message: data['message'] ?? 'Verification email sent successfully',
        );
      }

      return AuthResult.failure(
        message: 'Failed to resend verification email. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Failed to send verification email');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Verify email with token (limited access endpoint)
  ///
  /// Parameters:
  /// - [token]: Email verification token
  ///
  /// Returns: AuthResult with verification status and potential tokens
  Future<AuthResult> verifyEmailWithToken(String token) async {
    try {

      final response = await _apiService.post(
        '/api/auth/verify-email/',
        data: {'token': token},
      );

      if (response.statusCode == 200) {
        final data = response.data;


        // Check if response includes new tokens (for auto-login)
        if (data['access_token'] != null && data['refresh_token'] != null) {
          await _apiService.saveTokens(
            data['access_token'],
            data['refresh_token'],
          );

          // Update user data if provided
          if (data['user'] != null) {
            final mappedData = _mapUserSnakeToCamel(data['user']);
            final user = UserModel.fromJson(mappedData);
            await _saveUserToStorage(user);
            _currentUser = user;
          }
        }

        return AuthResult.success(
          message: data['message'] ?? 'Email verified successfully',
          data: data,
        );
      }

      return AuthResult.failure(
        message: 'Email verification failed. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Email verification failed');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Get verification status (limited access endpoint)
  /// Works for users who have tokens but may not be fully approved
  ///
  /// Returns: Map with verification status and potential auto-login tokens
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {

      final response = await _apiService.get(
        '/api/auth/verification-status/',
      );

      if (response.statusCode == 200) {
        final data = response.data;


        // Handle auto-login tokens if provided
        if (data['auto_login'] == true && data['access_token'] != null) {
          await _apiService.saveTokens(
            data['access_token'],
            data['refresh_token'],
          );

          if (data['user'] != null) {
            final mappedData = _mapUserSnakeToCamel(data['user']);
            final user = UserModel.fromJson(mappedData);
            await _saveUserToStorage(user);
            _currentUser = user;
          }
        }

        return {
          'is_verified': data['is_verified'] ?? false,
          'auto_login': data['auto_login'] ?? false,
          'approval_status': data['approval_status'] ?? 'unknown',
          'message': data['message'] ?? 'Status retrieved successfully',
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'user': data['user'],
          'can_access_app': data['can_access_app'] ?? false,
        };
      }

      throw Exception('Failed to get verification status - HTTP ${response.statusCode}');

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not get verification status');
      return {
        'is_verified': false,
        'auto_login': false,
        'approval_status': 'error',
        'message': ErrorHandler.mapErrorToUserMessage(errorMessage),
        'access_token': null,
        'refresh_token': null,
        'user': null,
        'can_access_app': false,
      };
    }
  }

  /// Get registration status (limited access endpoint)
  /// Works for verified users waiting for approval
  ///
  /// Returns: Map with complete registration status
  Future<Map<String, dynamic>> getRegistrationStatusLimited() async {
    try {

      final response = await _apiService.get(
        '/api/auth/registration-status/',
      );

      if (response.statusCode == 200) {
        final data = response.data;


        return {
          'account_status': data['account_status'],
          'next_step': data['next_step'],
          'is_verified': data['is_verified'] ?? false,
          'is_approved': data['is_approved'] ?? false,
          'can_access_app': data['can_access_app'] ?? false,
          'approval_status': data['approval_status'],
          'registration_stage': data['registration_stage'],
          'message': data['message'] ?? 'Status retrieved successfully',
        };
      }

      throw Exception('Failed to get registration status - HTTP ${response.statusCode}');

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not get registration status');
      return {
        'account_status': 'error',
        'next_step': 'verify_email',
        'is_verified': false,
        'is_approved': false,
        'can_access_app': false,
        'approval_status': 'error',
        'registration_stage': null,
        'message': ErrorHandler.mapErrorToUserMessage(errorMessage),
      };
    }
  }

  /// Refresh access token using refresh token
  ///
  /// Returns: AuthResult with new token or failure
  Future<AuthResult> refreshAccessToken() async {
    try {
      final refreshToken = _apiService.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        return AuthResult.failure(message: 'No refresh token available');
      }


      final response = await _apiService.post(
        '/api/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access'];

        if (newAccessToken != null) {
          await _apiService.saveTokens(newAccessToken, refreshToken);


          return AuthResult.success(
            message: 'Token refreshed successfully',
            data: {'access_token': newAccessToken},
          );
        }
      }

      return AuthResult.failure(
        message: 'Session expired. Please log in again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Session refresh failed');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  // =============================================================================
  // USER PROFILE METHODS
  // =============================================================================
  
  /// Get current user profile from server
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      // This requires full authentication (verified + approved)
      if (!isAuthenticated) {
        return null;
      }

      final response = await _apiService.get(ApiConfig.profileMe);

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['data'] ?? data;
        
        final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));
        
        // Update local user data
        await _saveUserToStorage(user);
        _currentUser = user;
        
        return user;
      }
      
      return null;
      
    } catch (e) {
      // Error handled silently
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
      // This requires full authentication (verified + approved)
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

        final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));

        // Update local user data
        await _saveUserToStorage(user);
        _currentUser = user;


        return user;
      }

      return null;

    } catch (e) {
      // Error handled silently
      return null;
    }
  }

  /// Update user profile with multipart form data (for image uploads)
  ///
  /// Parameters:
  /// - [firstName]: User's first name (optional)
  /// - [lastName]: User's last name (optional)
  /// - [country]: User's country (optional)
  /// - [phoneNumber]: User's phone number (optional)
  /// - [profileImagePath]: Local path to profile image file (optional)
  ///
  /// Returns: Updated UserModel or null if failed
  Future<UserModel?> updateProfileWithImage({
    String? firstName,
    String? lastName,
    String? country,
    String? phoneNumber,
    String? profileImagePath,
  }) async {
    try {
      // This requires full authentication (verified + approved)
      if (!isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Create FormData for multipart request
      final formData = dio.FormData();

      // Add text fields only if provided
      if (firstName != null && firstName.isNotEmpty) {
        formData.fields.add(MapEntry('first_name', firstName));
      }
      if (lastName != null && lastName.isNotEmpty) {
        formData.fields.add(MapEntry('last_name', lastName));
      }
      if (country != null && country.isNotEmpty) {
        formData.fields.add(MapEntry('country', country));
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        formData.fields.add(MapEntry('phone_number', phoneNumber));
      }

      // Add profile image if provided
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final fileName = profileImagePath.split('/').last;
        formData.files.add(MapEntry(
          'profile_image',
          await dio.MultipartFile.fromFile(
            profileImagePath,
            filename: fileName,
          ),
        ));
      }

      final response = await _apiService.patch(
        ApiConfig.profileUpdate,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['data'] ?? data;

        final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));

        // Update local user data
        await _saveUserToStorage(user);
        _currentUser = user;


        return user;
      }

      return null;

    } catch (e) {
      // Error handled silently
      rethrow;
    }
  }

  // =============================================================================
  // APPROVAL METHODS
  // =============================================================================

  /// Validate referral code (updated to use new backend endpoint)
  ///
  /// Parameters:
  /// - [code]: Referral code to validate
  ///
  /// Returns: Map with validation result and referrer info, or error info
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {

      final response = await _apiService.post(
        '/api/auth/validate-referral/',
        data: {'referral_code': code.trim()},
      );

      if (response.statusCode == 200) {
        final data = response.data;


        return {
          'valid': data['valid'] ?? false,
          'referrer_name': data['referrer_name'],
          'referrer_email': data['referrer_email'],
          'referrer': data['referrer'],
          'error': null,
        };
      }

      return {
        'valid': false,
        'error': 'Failed to validate referral code',
      };

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Invalid referral code');
      return {
        'valid': false,
        'error': ErrorHandler.mapErrorToUserMessage(errorMessage),
      };
    }
  }

  /// Get pending approval requests (for referrers)
  /// 
  /// Returns: List of approval requests
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      // Use hasValidTokens for approval operations since they work for verified users
      if (!hasValidTokens) {
        throw Exception('User not authenticated');
      }

      final endpoint = '/api/auth/approvals/pending/';

      final response = await _apiService.get(endpoint);


      if (response.statusCode == 200) {
        final data = response.data;
        final approvals = data['approvals'] as List<dynamic>? ?? [];
        
        
        return approvals.cast<Map<String, dynamic>>();
      }


      final errorMessage = 'Failed to fetch pending approvals - HTTP ${response.statusCode}';
      throw Exception(errorMessage);

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not load pending approvals');
      throw Exception(ErrorHandler.mapErrorToUserMessage(errorMessage));
    }
  }

  /// Approve a user registration request
  /// 
  /// Parameters:
  /// - [approvalId]: ID of the approval request
  /// 
  /// Returns: AuthResult with approval status
  Future<AuthResult> approveUser(String approvalId) async {
    try {
      // Use hasValidTokens for approval operations
      if (!hasValidTokens) {
        throw Exception('User not authenticated');
      }


      final response = await _apiService.post(
        '/api/auth/approvals/$approvalId/approve/',
        data: {},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        
        return AuthResult.success(
          message: data['message'] ?? 'User approved successfully',
        );
      }


      return AuthResult.failure(
        message: 'Failed to approve user. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not approve user');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Reject a user registration request
  /// 
  /// Parameters:
  /// - [approvalId]: ID of the approval request
  /// - [reason]: Optional rejection reason
  /// 
  /// Returns: AuthResult with rejection status
  Future<AuthResult> rejectUser(String approvalId, [String? reason]) async {
    try {
      // Use hasValidTokens for approval operations
      if (!hasValidTokens) {
        throw Exception('User not authenticated');
      }


      final response = await _apiService.post(
        '/api/auth/approvals/$approvalId/reject/',
        data: {
          if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        
        return AuthResult.success(
          message: data['message'] ?? 'User rejected successfully',
        );
      }


      return AuthResult.failure(
        message: 'Failed to reject user. Please try again.',
      );

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not reject user');
      return AuthResult.failure(
        message: ErrorHandler.mapErrorToUserMessage(errorMessage),
      );
    }
  }

  /// Get approval history (for referrers)
  /// 
  /// Returns: List of approval history
  Future<List<Map<String, dynamic>>> getApprovalHistory() async {
    try {
      // Use hasValidTokens for approval operations
      if (!hasValidTokens) {
        throw Exception('User not authenticated');
      }


      final response = await _apiService.get('/api/auth/approvals/history/');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle null response
        if (data == null) {
          return [];
        }
        
        // Check if data is directly a list or wrapped in an object
        List<dynamic> history;
        if (data is List) {
          history = data;
        } else if (data is Map && data.containsKey('history')) {
          history = data['history'] as List<dynamic>? ?? [];
        } else if (data is Map && data.containsKey('approvals')) {
          history = data['approvals'] as List<dynamic>? ?? [];
        } else if (data is Map && data.containsKey('results')) {
          // Handle paginated response
          history = data['results'] as List<dynamic>? ?? [];
        } else {
          // Try to extract any list from the response
          history = [];
          if (data is Map) {
              data.forEach((key, value) {
              if (value is List && history.isEmpty) {
                history = value;
              }
            });
          }
        }
        
        
        // Ensure we're returning valid Map objects
        final validHistory = <Map<String, dynamic>>[];
        for (var item in history) {
          if (item is Map<String, dynamic>) {
            validHistory.add(item);
          } else if (item is Map) {
            validHistory.add(Map<String, dynamic>.from(item));
          }
        }
        
        return validHistory;
      }


      final errorMessage = 'Failed to fetch approval history - HTTP ${response.statusCode}';
      throw Exception(errorMessage);

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not load approval history');
      throw Exception(ErrorHandler.mapErrorToUserMessage(errorMessage));
    }
  }

  /// Get current registration status with comprehensive account information
  /// 
  /// Returns: RegistrationStatusResponse with full account state
  Future<RegistrationStatusResponse?> getRegistrationStatus() async {
    // TEMPORARILY DISABLED: Registration status endpoint doesn't exist
    return null;
    
  }

  /// Check current user's approval status (for polling)
  /// 
  /// Returns: Map with approval status info
  Future<Map<String, dynamic>> checkApprovalStatus() async {
    try {
      // 🚨 CRITICAL FIX: Don't require authentication for pending approval users
      // They need to check status before getting JWT tokens
      // The verification-status endpoint works without auth for email-verified users
      

      final response = await _apiService.get('/api/auth/verification-status/');

      if (response.statusCode == 200) {
        final data = response.data;
        
        
        return {
          'status': data['approval_status'] ?? 'pending',
          'is_approved': data['is_approved'] ?? false,
          'is_verified': data['is_verified'] ?? false,
          'rejection_reason': data['rejection_reason'],
          'expires_at': data['expires_at'],
          'can_login': data['can_login'] ?? false,
          'message': data['message'] ?? 'Status retrieved successfully',
        };
      }


      throw Exception('Failed to check approval status - HTTP ${response.statusCode}');

    } catch (e) {
      // Error handled silently
      final errorMessage = ErrorHandler.getErrorMessage(e, defaultMessage: 'Could not check approval status');
      return {
        'status': 'error',
        'is_approved': false,
        'is_verified': false,
        'rejection_reason': null,
        'expires_at': null,
        'can_login': false,
        'message': ErrorHandler.mapErrorToUserMessage(errorMessage),
      };
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
        

      } else {
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// Save user data to secure storage
  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final userDataString = jsonEncode({
        'userId': user.userId,
        'email': user.email,
        'username': user.username,
        'rating': user.rating,
        'hours': user.hours,
      });
      await _secureStorage.write(key: _userDataKey, value: userDataString);

    } catch (e) {
      // Error handled silently
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

    } catch (e) {
      // Error handled silently
    }
  }

  // =============================================================================
  // NOTIFICATION INTEGRATION
  // =============================================================================
  
  /// Set up push notifications after successful authentication
  void _setupPushNotificationsAfterAuth() {
    try {
      
      // Run in background to avoid blocking the auth flow
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          
          if (!Get.isRegistered<FirebaseNotificationService>()) {
            return;
          }
          
          final firebaseNotificationService = Get.find<FirebaseNotificationService>();
          await firebaseNotificationService.setupPushNotifications();
        } catch (e) {
      // Error handled silently
        }
      });
    } catch (e) {
      // Error handled silently
    }
  }

  /// Immediately set up FCM token registration after login (no delay)
  void _setupFCMTokenImmediately() {
    try {
      
      // Run without delay to ensure it happens
      Future.microtask(() async {
        try {
          
          if (!Get.isRegistered<FirebaseNotificationService>()) {
            return;
          }
          
          final firebaseNotificationService = Get.find<FirebaseNotificationService>();
          
          // 🔥 CRITICAL FIX: Use setupPushNotifications instead of registerTokenWithBackend
          // This ensures permissions are requested before token registration
          await firebaseNotificationService.setupPushNotifications();

        } catch (e) {
      // Error handled silently
        }
      });
    } catch (e) {
      // Error handled silently
    }
  }

  // =============================================================================
  // GETTERS
  // =============================================================================
  
  /// Check if user is authenticated AND fully approved
  /// This prevents routing to protected screens for users who have tokens
  /// but are not yet verified or approved
  bool get isAuthenticated {
    // Must have valid API tokens
    if (!_apiService.isAuthenticated) {
      return false;
    }
    
    // Must have user data loaded
    if (_currentUser == null) {
      return false;
    }
    
    // Must be email verified AND approved to access protected resources
    // This prevents unverified/unapproved users from accessing home page
    final isVerified = _currentUser?.isVerified ?? false;
    final isApproved = _currentUser?.isApproved ?? false;
    
    return isVerified && isApproved;
  }
  
  /// Check if user has valid tokens (but may not be fully approved yet)
  /// Use this for API calls that work for verified but not yet approved users
  bool get hasValidTokens => _apiService.isAuthenticated;
  
  /// Get current user
  UserModel? get currentUser => _currentUser;
  
  /// Get current user's ID
  String? get currentUserId => _currentUser?.userId;
  
  /// Get current user's email
  String? get currentUserEmail => _currentUser?.email;
  
  /// Check if current user is verified
  bool get isUserVerified => _currentUser?.isVerified ?? false;

  /// Check if current user is approved
  bool get isUserApproved => _currentUser?.isApproved ?? false;
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
}

// =============================================================================
// ENHANCED AUTH RESULT CLASS
// =============================================================================

/// Enhanced result class for authentication operations with account status
class EnhancedAuthResult {
  final bool isSuccess;
  final AuthResponse? authResponse;
  final UserModel? user;
  final String message;
  final String? accountStatus;
  final String? nextStep;
  final Map<String, dynamic>? data;

  EnhancedAuthResult._({
    required this.isSuccess,
    this.authResponse,
    this.user,
    required this.message,
    this.accountStatus,
    this.nextStep,
    this.data,
  });

  /// Create successful enhanced auth result with full response
  factory EnhancedAuthResult.success({
    required AuthResponse authResponse,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return EnhancedAuthResult._(
      isSuccess: true,
      authResponse: authResponse,
      user: authResponse.user,
      message: message,
      accountStatus: authResponse.accountStatus,
      nextStep: authResponse.nextStep,
      data: data,
    );
  }

  /// Create successful result for legacy format compatibility
  factory EnhancedAuthResult.legacy({
    required UserModel user,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return EnhancedAuthResult._(
      isSuccess: true,
      user: user,
      message: message,
      accountStatus: 'active', // Assume active for legacy
      nextStep: 'ready', // Assume ready for legacy
      data: data,
    );
  }

  /// Create failed enhanced auth result
  factory EnhancedAuthResult.failure({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return EnhancedAuthResult._(
      isSuccess: false,
      message: message,
      data: data,
    );
  }

  @override
  String toString() {
    return 'EnhancedAuthResult(isSuccess: $isSuccess, message: $message, accountStatus: $accountStatus, nextStep: $nextStep, user: ${user?.email})';
  }
}
