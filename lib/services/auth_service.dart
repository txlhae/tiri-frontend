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
  /// Map backend user JSON (snake_case) to Flutter UserModel camelCase
  Map<String, dynamic> _mapUserSnakeToCamel(Map<String, dynamic> user) {
    return {
      'userId': user['userId'] ?? user['user_id'] ?? user['id'],
      'email': user['email'],
      'username': user['username'],
      'imageUrl': user['imageUrl'] ?? user['image_url'],
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
        
        // Extract user data and tokens
        final userData = data['user'] ?? data['data'];
        final tokens = data['tokens'];
        
        if (userData != null && tokens != null) {
          // Create user model with field mapping
          final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));
          
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
        '/api/auth/login/',
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
          // Create user model with field mapping
          final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));
          
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


  /// Logout current user and clear all data
  Future<AuthResult> logout() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Attempting logout', name: 'AUTH');
      }

      // Try to logout on server (optional - don't fail if it doesn't work)
      try {
        await _apiService.post(
          '/api/auth/logout/',
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
      if (ApiConfig.enableLogging) {
        log('Attempting email verification (mobile: $isMobile)', name: 'AUTH');
      }

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
        
        if (ApiConfig.enableLogging) {
          log('Email verification successful', name: 'AUTH');
        }

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
      log('Email verification error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Check current user's verification status with enhanced auto-login support
  /// 
  /// Returns: Map with verification status, auto_login flag, and JWT tokens
  Future<Map<String, dynamic>> checkVerificationStatus() async {
    try {
      // 🚨 CRITICAL FIX: Don't require authentication for verification status
      // Pending approval users need to check status before getting JWT tokens
      
      if (ApiConfig.enableLogging) {
        log('Checking verification status (no auth required for pending users)', name: 'AUTH');
      }

      final response = await _apiService.get(ApiConfig.authVerificationStatus);

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('Enhanced verification status response: ${data.toString()}', name: 'AUTH');
        }
        
        // Handle auto-login with direct JWT tokens (new format)
        if (data['auto_login'] == true) {
          // Check for direct access_token and refresh_token in response
          if (data['access_token'] != null && data['refresh_token'] != null) {
            // Save JWT tokens directly from response
            await _apiService.saveTokens(
              data['access_token'],
              data['refresh_token'],
            );
            
            if (ApiConfig.enableLogging) {
              log('Auto-login JWT tokens saved successfully', name: 'AUTH');
              log('   - Access token: ${data['access_token'].toString().substring(0, 20)}...', name: 'AUTH');
              log('   - Refresh token: ${data['refresh_token'].toString().substring(0, 20)}...', name: 'AUTH');
            }
            
            // Update user data if provided
            if (data['user'] != null) {
              final user = UserModel.fromJson(_mapUserSnakeToCamel(data['user']));
              await _saveUserToStorage(user);
              _currentUser = user;
              
              if (ApiConfig.enableLogging) {
                log('User data updated from verification response: ${user.email}', name: 'AUTH');
              }
            }
          } else {
            log('Warning: auto_login=true but no JWT tokens in response', name: 'AUTH');
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
      log('Verification status check error: $e', name: 'AUTH');
      return {
        'is_verified': false,
        'auto_login': false,
        'approval_status': 'error',
        'message': _extractErrorMessage(e),
        'access_token': null,
        'refresh_token': null,
        'user': null,
      };
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
        
        final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));
        
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
        
        final user = UserModel.fromJson(_mapUserSnakeToCamel(userData));
        
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
  // APPROVAL METHODS
  // =============================================================================

  /// Validate referral code (updated to use new backend endpoint)
  /// 
  /// Parameters:
  /// - [code]: Referral code to validate
  /// 
  /// Returns: Map with validation result and referrer info
  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Validating referral code: $code', name: 'AUTH');
      }

      final response = await _apiService.post(
        '/api/auth/validate-referral/',
        data: {'referral_code': code.trim()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('Referral validation successful: ${data.toString()}', name: 'AUTH');
        }
        
        return {
          'valid': data['valid'] ?? false,
          'referrer_name': data['referrer_name'],
          'referrer_email': data['referrer_email'],
          'referrer': data['referrer'],
        };
      }
      
      return null;
      
    } catch (e) {
      log('Referral validation error: $e', name: 'AUTH');
      return null;
    }
  }

  /// Get pending approval requests (for referrers)
  /// 
  /// Returns: List of approval requests
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      // 🚨 DEBUG: Log authentication status
      log('🔍 DEBUG: Checking authentication status...', name: 'AUTH');
      log('🔍 DEBUG: isAuthenticated = $isAuthenticated', name: 'AUTH');
      log('🔍 DEBUG: _apiService.isAuthenticated = ${_apiService.isAuthenticated}', name: 'AUTH');
      log('🔍 DEBUG: _currentUser = ${_currentUser?.email ?? 'null'}', name: 'AUTH');
      print('🔍 DEBUG: isAuthenticated = $isAuthenticated');
      print('🔍 DEBUG: _apiService.isAuthenticated = ${_apiService.isAuthenticated}');
      print('🔍 DEBUG: _currentUser = ${_currentUser?.email ?? 'null'}');
      
      // 🚨 FIX: Use API service authentication for approval requests
      // The API service has tokens even if user data isn't loaded yet
      if (!_apiService.isAuthenticated) {
        log('❌ DEBUG: API Service not authenticated - throwing exception', name: 'AUTH');
        print('❌ DEBUG: API Service not authenticated - throwing exception');
        throw Exception('User not authenticated');
      }
      
      // Log the bypass for debugging
      if (!isAuthenticated) {
        log('⚠️ DEBUG: Full isAuthenticated=false but _apiService.isAuthenticated=true, proceeding with API call', name: 'AUTH');
        print('⚠️ DEBUG: Full isAuthenticated=false but _apiService.isAuthenticated=true, proceeding with API call');
      }

      if (ApiConfig.enableLogging) {
        log('Fetching pending approvals', name: 'AUTH');
      }

      // 🚨 DEBUG: Force log the exact URL being called
      final endpoint = '/api/auth/approvals/pending/';
      log('🔍 DEBUG: About to call endpoint: $endpoint', name: 'AUTH');
      print('🔍 DEBUG: About to call endpoint: $endpoint');

      final response = await _apiService.get(endpoint);

      // 🚨 DEBUG: Log the response details
      log('🔍 DEBUG: Response status: ${response.statusCode}', name: 'AUTH');
      log('🔍 DEBUG: Response data: ${response.data}', name: 'AUTH');
      print('🔍 DEBUG: Response status: ${response.statusCode}');
      print('🔍 DEBUG: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final approvals = data['approvals'] as List<dynamic>? ?? [];
        
        if (ApiConfig.enableLogging) {
          log('Fetched ${approvals.length} pending approvals', name: 'AUTH');
        }
        
        return approvals.cast<Map<String, dynamic>>();
      }
      
      throw Exception('Failed to fetch pending approvals - HTTP ${response.statusCode}');
      
    } catch (e) {
      log('Get pending approvals error: $e', name: 'AUTH');
      throw e;
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
      // Use API service authentication check for consistency
      if (!_apiService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      if (ApiConfig.enableLogging) {
        log('Approving user with approval ID: $approvalId', name: 'AUTH');
      }

      final response = await _apiService.post(
        '/api/auth/approvals/$approvalId/approve/',
        data: {},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('User approval successful', name: 'AUTH');
        }
        
        return AuthResult.success(
          message: data['message'] ?? 'User approved successfully',
        );
      }
      
      return AuthResult.failure(
        message: 'Failed to approve user - HTTP ${response.statusCode}',
      );
      
    } catch (e) {
      log('Approve user error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
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
      // Use API service authentication check for consistency
      if (!_apiService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      if (ApiConfig.enableLogging) {
        log('Rejecting user with approval ID: $approvalId', name: 'AUTH');
      }

      final response = await _apiService.post(
        '/api/auth/approvals/$approvalId/reject/',
        data: {
          if (reason != null && reason.isNotEmpty) 'rejection_reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('User rejection successful', name: 'AUTH');
        }
        
        return AuthResult.success(
          message: data['message'] ?? 'User rejected successfully',
        );
      }
      
      return AuthResult.failure(
        message: 'Failed to reject user - HTTP ${response.statusCode}',
      );
      
    } catch (e) {
      log('Reject user error: $e', name: 'AUTH');
      return AuthResult.failure(
        message: _extractErrorMessage(e),
      );
    }
  }

  /// Get approval history (for referrers)
  /// 
  /// Returns: List of approval history
  Future<List<Map<String, dynamic>>> getApprovalHistory() async {
    try {
      // 🚨 DEBUG: Log authentication status
      log('🔍 DEBUG: getApprovalHistory - isAuthenticated = $isAuthenticated', name: 'AUTH');
      print('🔍 DEBUG: getApprovalHistory - isAuthenticated = $isAuthenticated');
      
      // 🚨 FIX: Use API service authentication for approval requests
      if (!_apiService.isAuthenticated) {
        log('❌ DEBUG: getApprovalHistory - API Service not authenticated', name: 'AUTH');
        print('❌ DEBUG: getApprovalHistory - API Service not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Log the bypass for debugging
      if (!isAuthenticated) {
        log('⚠️ DEBUG: getApprovalHistory - Full isAuthenticated=false but proceeding', name: 'AUTH');
        print('⚠️ DEBUG: getApprovalHistory - Full isAuthenticated=false but proceeding');
      }

      if (ApiConfig.enableLogging) {
        log('Fetching approval history', name: 'AUTH');
      }

      final response = await _apiService.get('/api/auth/approvals/history/');

      if (response.statusCode == 200) {
        final data = response.data;
        final history = data['history'] as List<dynamic>? ?? [];
        
        if (ApiConfig.enableLogging) {
          log('Fetched ${history.length} approval history items', name: 'AUTH');
        }
        
        return history.cast<Map<String, dynamic>>();
      }
      
      throw Exception('Failed to fetch approval history - HTTP ${response.statusCode}');
      
    } catch (e) {
      log('Get approval history error: $e', name: 'AUTH');
      throw e;
    }
  }

  /// Check current user's approval status (for polling)
  /// 
  /// Returns: Map with approval status info
  Future<Map<String, dynamic>> checkApprovalStatus() async {
    try {
      // 🚨 CRITICAL FIX: Don't require authentication for pending approval users
      // They need to check status before getting JWT tokens
      // The verification-status endpoint works without auth for email-verified users
      
      if (ApiConfig.enableLogging) {
        log('Checking approval status (no auth required for pending users)', name: 'AUTH');
      }

      final response = await _apiService.get('/api/auth/verification-status/');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (ApiConfig.enableLogging) {
          log('Approval status check response: ${data.toString()}', name: 'AUTH');
        }
        
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
      log('Check approval status error: $e', name: 'AUTH');
      return {
        'status': 'error',
        'is_approved': false,
        'is_verified': false,
        'rejection_reason': null,
        'expires_at': null,
        'can_login': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  // =============================================================================
  // STORAGE METHODS
  // =============================================================================
  
  /// Load user data from secure storage
  Future<void> _loadUserFromStorage() async {
    try {
      // 🚨 DEBUG: Log user data loading process
      log('🔍 DEBUG: Starting _loadUserFromStorage...', name: 'AUTH');
      print('🔍 DEBUG: Starting _loadUserFromStorage...');
      
      final userDataString = await _secureStorage.read(key: _userDataKey);
      
      log('🔍 DEBUG: userDataString from storage: ${userDataString != null ? 'found' : 'null'}', name: 'AUTH');
      print('🔍 DEBUG: userDataString from storage: ${userDataString != null ? 'found' : 'null'}');
      
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        _currentUser = UserModel.fromJson(userData);
        
        log('🔍 DEBUG: User loaded successfully: ${_currentUser?.email}', name: 'AUTH');
        print('🔍 DEBUG: User loaded successfully: ${_currentUser?.email}');
        
        if (ApiConfig.enableLogging) {
          log('User data loaded from storage: ${_currentUser?.email}', name: 'AUTH');
        }
      } else {
        log('🔍 DEBUG: No user data found in storage', name: 'AUTH');
        print('🔍 DEBUG: No user data found in storage');
      }
    } catch (e) {
      log('❌ DEBUG: Error loading user from storage: $e', name: 'AUTH');
      print('❌ DEBUG: Error loading user from storage: $e');
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
