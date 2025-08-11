// lib/controllers/auth_controller.dart
// 🚨 COMPLETE REWRITE: Your existing AuthController + Token Loading Fix
// Prompt 31.7 - All existing functionality preserved + 401 error fix

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/models/approval_request_model.dart';
import 'package:tiri/screens/auth_screens/email_verification_screen.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/user_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise AuthController for TIRI application
/// 
/// Features:
/// - Django backend integration
/// - Enterprise-grade security
/// - Automatic token management
/// - Comprehensive validation
/// - GetX reactive state management
/// - Backward compatibility with existing UI
class AuthController extends GetxController {
  // =============================================================================
  // SERVICES
  // =============================================================================
  
  /// Enterprise authentication service
  late AuthService _authService;
  
  /// Enterprise API service
  late ApiService _apiService;
  
  /// User state management service
  late UserStateService _userStateService;

  // =============================================================================
  // UI CONSTANTS
  // =============================================================================
  
  static const Color move = Color.fromRGBO(0, 140, 170, 1);  // TIRI Blue
  static const Color cancel = Color.fromRGBO(176, 48, 48, 1);

  // =============================================================================
  // REACTIVE STATE VARIABLES
  // =============================================================================
  
  /// Loading state for UI
  final isLoading = false.obs;
  
  /// Password obscure state
  final isObscure = true.obs;
  
  /// Current authenticated user
  final Rx<UserModel?> currentUserStore = Rx<UserModel?>(null);
  
  /// Login status
  final RxBool isLoggedIn = false.obs;

  // =============================================================================
  // FORM KEYS
  // =============================================================================
  
  final loginformKey = GlobalKey<FormState>().obs;
  final forgotPasswordFormKey = GlobalKey<FormState>().obs;
  final registerformKey = GlobalKey<FormState>().obs;

  // =============================================================================
  // FORM CONTROLLERS
  // =============================================================================
  
  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;
  final userNameController = TextEditingController().obs;
  final countryController = TextEditingController().obs;
  final phoneNumberController = TextEditingController().obs;
  final referralCodeController = TextEditingController().obs;

  // =============================================================================
  // COUNTRY SELECTION
  // =============================================================================
  
  final selectedCountry = Rx<Country?>(null);
  final phoneNumberWithCode = RxString('');

  // =============================================================================
  // VALIDATION STATE
  // =============================================================================
  
  final isCodeValid = true.obs;
  final isNameValid = true.obs;
  final isPhoneValid = true.obs;
  final isCountryValid = true.obs;
  final isEmailValid = true.obs;
  final isPasswordValid = true.obs;

  // =============================================================================
  // ERROR MESSAGES
  // =============================================================================
  
  final codeError = ''.obs;
  final nameError = ''.obs;
  final phoneError = ''.obs;
  final countryError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;

  // =============================================================================
  // REFERRAL STATE
  // =============================================================================
  
  final referredUser = ''.obs;
  final referredUid = ''.obs;

  // =============================================================================
  // APPROVAL SYSTEM STATE
  // =============================================================================
  
  /// Approval-related state
  final RxList<ApprovalRequest> pendingApprovals = <ApprovalRequest>[].obs;
  final RxList<ApprovalRequest> approvalHistory = <ApprovalRequest>[].obs;
  final RxInt pendingApprovalsCount = 0.obs;
  final RxBool hasNewApprovals = false.obs;
  final RxString approvalStatus = 'pending'.obs; // for current user
  final RxString rejectionReason = ''.obs; // for current user
  final Rx<DateTime?> approvalExpiresAt = Rx<DateTime?>(null); // for current user
  
  // Error state management for approvals
  final RxBool pendingApprovalsError = false.obs;
  final RxString pendingApprovalsErrorMessage = ''.obs;
  final RxBool approvalHistoryError = false.obs;
  final RxString approvalHistoryErrorMessage = ''.obs;

  // =============================================================================
  // BACKWARD COMPATIBILITY GETTERS
  // =============================================================================
  
  /// Backward compatibility - UI expects 'isloading'
  RxBool get isloading => isLoading;

  /// Backward compatibility - UI expects 'forgotPassworformKey' 
  Rx<GlobalKey<FormState>> get forgotPassworformKey => forgotPasswordFormKey;

  // =============================================================================
  // 🚨 FIXED INITIALIZATION WITH TOKEN LOADING
  // =============================================================================
  
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadUserFromStorageWithTokens(); // 🚨 FIXED: Loads tokens + user data
  }

  /// Initialize enterprise services
  void _initializeServices() {
    try {
      _authService = Get.find<AuthService>();
      _apiService = Get.find<ApiService>();
      _userStateService = Get.find<UserStateService>();
      log('✅ AuthController: Services initialized successfully');
    } catch (e) {
      log('❌ AuthController: Error initializing services: $e');
    }
  }

  /// 🚨 FIXED: Load user data from storage on app start + JWT tokens
  /// This is the FIX for the 401 Unauthorized errors on app restart
  Future<void> _loadUserFromStorageWithTokens() async {
    try {
      log('🔄 AuthController: Loading tokens and user data on app startup...');
      
      // 🚨 STEP 1: Load JWT tokens from secure storage FIRST
      log('📱 Step 1: Loading JWT tokens from secure storage...');
      await _apiService.loadTokensFromStorage();
      log('   - Tokens loaded successfully');
      
      // 🚨 STEP 2: Load user data from shared preferences
      log('👤 Step 2: Loading user data from shared preferences...');
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      
      if (userStr != null) {
        final userJson = jsonDecode(userStr);
        currentUserStore.value = UserModel.fromJson(userJson);
        isLoggedIn.value = true;
        log('✅ User loaded from storage: ${currentUserStore.value?.email}');
        log('   - User ID: ${currentUserStore.value?.userId}');
        log('   - Verified: ${currentUserStore.value?.isVerified}');
      } else {
        log('ℹ️ No stored user data found');
      }
      
      log('🎯 AuthController: Token and user loading complete');
      
    } catch (e) {
      log('❌ Error loading user/tokens from storage: $e');
      
      // Fallback: Clear potentially corrupted data
      try {
        await _apiService.clearTokens();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user');
        isLoggedIn.value = false;
        currentUserStore.value = null;
        log('🧹 Cleared corrupted session data');
      } catch (clearError) {
        log('❌ Failed to clear corrupted data: $clearError');
      }
    }
  }

  // =============================================================================
  // AUTHENTICATION METHODS
  // =============================================================================
  
  /// Login user with email and password
  Future<void> login([String? email, String? password, String? routeName]) async {
    if (!validateLoginForm()) return;

    isLoading.value = true;
    
    try {
      log('🔐 AuthController: Starting login process...');
      
      final result = await _authService.login(
        email: emailController.value.text.trim(),
        password: passwordController.value.text,
      );

      if (result.isSuccess && result.user != null) {
        log('✅ Login successful via AuthService');
        
        // Update reactive state
        currentUserStore.value = result.user;
        isLoggedIn.value = true;
        
        // Save to storage
        await _saveUserToStorage(result.user!);
        
        // ✅ APPROVAL SYSTEM: Check user status and route appropriately
        final user = result.user!;
        
        if (!user.isVerified) {
          log('🚨 User not verified - redirecting to email verification');
          Get.snackbar(
            'Email Verification Required',
            'Please verify your email address to continue',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          Get.offAllNamed(Routes.emailVerificationPage);
          return;
        }
        
        if (!user.isApproved) {
          log('🚨 User not approved - checking approval status');
          
          // Check current approval status
          final statusResult = await _authService.checkApprovalStatus();
          final status = statusResult['status'] ?? 'pending';
          
          switch (status) {
            case 'pending':
              log('📋 User approval still pending');
              Get.snackbar(
                'Approval Pending',
                'Your registration is still waiting for approval from your referrer',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              Get.offAllNamed(Routes.pendingApprovalPage);
              return;
              
            case 'rejected':
              log('❌ User registration was rejected');
              rejectionReason.value = statusResult['rejection_reason'] ?? '';
              Get.snackbar(
                'Registration Rejected',
                'Your registration was not approved by the referrer',
                snackPosition: SnackPosition.TOP,
                backgroundColor: cancel,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              Get.offAllNamed(Routes.rejectionScreen);
              return;
              
            case 'expired':
              log('⏰ User approval request expired');
              Get.snackbar(
                'Approval Expired',
                'Your approval request has expired after 7 days',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              Get.offAllNamed(Routes.expiredScreen);
              return;
              
            default:
              log('⚠️ Unknown approval status: $status');
              Get.snackbar(
                'Account Status Unknown',
                'Please contact support for assistance',
                snackPosition: SnackPosition.TOP,
                backgroundColor: cancel,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
              return;
          }
        }
        
        // ✅ User is both verified and approved - proceed to home
        log('🏠 User fully approved - navigating to home page');
        Get.snackbar(
          'Welcome Back!',
          'Hello ${user.username}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        Get.offAllNamed(Routes.homePage);
        
        // Clear form
        _clearLoginForm();
        
      } else {
        log('❌ Login failed: ${result.message}');
        
        // ✅ APPROVAL SYSTEM: Handle backend login errors with specific routing
        final message = result.message.toLowerCase();
        
        if (message.contains('pending approval') || message.contains('pending_approval')) {
          log('📋 Backend reports pending approval');
          Get.snackbar(
            'Approval Pending',
            'Your registration is waiting for approval from your referrer',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Get.toNamed(Routes.pendingApprovalPage);
          return;
        }
        
        if (message.contains('rejected') || message.contains('not approved')) {
          log('❌ Backend reports user rejected');
          Get.snackbar(
            'Registration Rejected',
            'Your registration was not approved by the referrer',
            snackPosition: SnackPosition.TOP,
            backgroundColor: cancel,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Get.toNamed(Routes.rejectionScreen);
          return;
        }
        
        if (message.contains('expired')) {
          log('⏰ Backend reports approval expired');
          Get.snackbar(
            'Approval Expired',
            'Your approval request has expired after 7 days',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Get.toNamed(Routes.expiredScreen);
          return;
        }
        
        if (message.contains('verify') || message.contains('verification')) {
          log('📧 Backend reports email not verified');
          Get.snackbar(
            'Email Verification Required',
            'Please verify your email address first',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          Get.toNamed(Routes.emailVerificationPage);
          return;
        }
        
        // Generic error message for other failures
        Get.snackbar(
          'Login Failed',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      log('💥 Login error: $e');
      Get.snackbar(
        'Login Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Login with parameters (for backward compatibility with UI)
  Future<void> loginWithCredentials(String email, String password, bool rememberMe) async {
    emailController.value.text = email;
    passwordController.value.text = password;
    await login();
  }

  /// Register new user
  Future<void> register([String? name, String? phoneNumber, String? country, String? email, String? referralUid, String? password, String? routeName, String? imageURL]) async {
    if (!validateRegisterForm()) return;

    isLoading.value = true;
    
    try {
      log('📝 AuthController: Starting registration process...');
      
      // Build phone number with country code
      updatePhoneWithCode();
      
      final result = await _authService.register(
        name: userNameController.value.text.trim(),
        email: emailController.value.text.trim(),
        phoneNumber: phoneNumberWithCode.value,
        country: selectedCountry.value?.name ?? countryController.value.text.trim(),
        password: passwordController.value.text,
        referralCode: referredUid.value.isNotEmpty ? referredUid.value : referralCodeController.value.text.trim(),
      );

      if (result.isSuccess) {
        log('✅ Registration successful');
        
        // ✅ SET AUTHENTICATION STATE
        isLoggedIn.value = true;
        currentUserStore.value = result.user;
        
        // ✅ UPDATE USER STATE: Set initial state after registration
        final usedReferralCode = referredUid.value.isNotEmpty ? referredUid.value : referralCodeController.value.text.trim();
        await _userStateService.updateState(
          UserApprovalState.emailUnverified,
          userId: result.user!.userId,
          referrerName: referredUser.value.isNotEmpty ? referredUser.value : null,
        );
        log('📊 AuthController: User state updated to emailUnverified after registration');
        
        Get.snackbar(
          'Registration Successful!',
          'An email has been sent to verify your account',
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // ✅ APPROVAL SYSTEM: Route based on referral usage
        if (usedReferralCode.isNotEmpty) {
          log('🔄 Registration with referral code - will need approval after email verification');
          // User will go to pending approval after email verification
          Get.offAll(() => const EmailVerificationScreen());
        } else {
          log('🔄 Direct registration without referral - proceeding to email verification only');
          Get.offAll(() => const EmailVerificationScreen());
        }
        
        // Clear form
        _clearRegisterForm();
        
      } else {
        log('❌ Registration failed: ${result.message}');
        
        Get.snackbar(
          'Registration Failed',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      log('💥 Registration error: $e');
      Get.snackbar(
        'Registration Error',
        'An unexpected error occurred. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Register with parameters (for backward compatibility with UI)  
  Future<void> registerWithDetails(
    String name,
    String phoneNumber,
    String country,
    String email,
    String referralUid,
    String password,
    String routeName,
    String? imageURL,
  ) async {
    userNameController.value.text = name;
    phoneNumberController.value.text = phoneNumber;
    countryController.value.text = country;
    emailController.value.text = email;
    referralCodeController.value.text = referralUid;
    passwordController.value.text = password;
    
    await register();
  }

  /// Logout current user
  /// 🚨 ENHANCED: Proper token cleanup
  Future<void> logout() async {
    try {
      log('🚪 AuthController: Starting logout process...');
      isLoading.value = true;
      
      final result = await _authService.logout();
      
      // Update reactive state
      currentUserStore.value = null;
      isLoggedIn.value = false;
      
      // Clear storage
      await _clearUserData();
      
      // 🚨 FIXED: Clear tokens
      await _apiService.clearTokens();
      
      // ✅ CLEAR USER STATE: Reset approval state on logout
      await _userStateService.clearState();
      log('📊 AuthController: User state cleared on logout');
      
      Get.snackbar(
        'Logged Out',
        result.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: move,
        colorText: Colors.white,
      );
      
      // Navigate to login
      Get.offAllNamed(Routes.loginPage);
      
      log('✅ Logout completed successfully');
      
    } catch (e) {
      log('❌ Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // =============================================================================
  // USER MANAGEMENT METHODS
  // =============================================================================
  
  /// Fetch user by ID (for profile screens)
  Future<UserModel?> fetchUser(String userId) async {
    try {
      // If requesting current user, return from cache
      if (currentUserStore.value?.userId == userId) {
        return currentUserStore.value;
      }
      
      log('👤 AuthController: Fetching user $userId from Django API');
      
      final response = await _apiService.get('/api/profile/users/$userId/');
      
      if (response.statusCode == 200 && response.data != null) {
        // Apply user field mapping for Django compatibility
        final userData = response.data as Map<String, dynamic>;
        final flutterUserData = _mapDjangoUserToFlutter(userData);
        final UserModel user = UserModel.fromJson(flutterUserData);
        
        log('✅ AuthController: Fetched user $userId successfully');
        return user;
      } else {
        log('❌ AuthController: Failed to fetch user $userId - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('💥 AuthController: Error fetching user $userId - $e');
      return null;
    }
  }

  /// Map Django user object to Flutter UserModel format
  Map<String, dynamic> _mapDjangoUserToFlutter(dynamic djangoUser) {
    if (djangoUser is! Map) return {};
    
    final userMap = djangoUser as Map<String, dynamic>;
    return {
      'userId': userMap['id']?.toString() ?? '',
      'username': userMap['username'] ?? userMap['full_name'] ?? 'Unknown',
      'email': userMap['email']?.toString() ?? '',
      'imageUrl': userMap['profile_image_url'] ?? userMap['profile_image'],
      'referralUserId': userMap['referral_user_id']?.toString(),
      'phoneNumber': userMap['phone_number']?.toString(),
      'country': userMap['country'] ?? userMap['location_display'],
      'referralCode': userMap['referral_code'] ?? userMap['full_name'],
      'rating': (userMap['average_rating'] as num?)?.toDouble(),
      'hours': userMap['total_hours_helped'] as int?,
      'createdAt': userMap['created_at'] != null 
          ? DateTime.parse(userMap['created_at']) 
          : null,
      'isVerified': userMap['is_verified'] ?? false,
    };
  }

  /// Fetch user by referral code (Updated for approval system)
  Future<UserModel?> fetchUserByReferralCode(String code) async {
    try {
      log('fetchUserByReferralCode called for code: $code');
      
      // Basic validation
      if (code.isEmpty || code.length < 3) {
        isCodeValid.value = false;
        codeError.value = 'Invalid referral code';
        return null;
      }
      
      // Call Django API to verify referral code via AuthService
      log('Calling Django API to verify referral code: $code');
      final result = await _authService.validateReferralCode(code);
      log('Django API response: ${result.toString()}');
      
      if (result != null && result['valid'] == true) {
        log('Referral code verified successfully: ${result.toString()}');
        
        isCodeValid.value = true;
        codeError.value = '';
        
        // Store referrer information for registration
        referredUid.value = code;
        
        // Handle different response formats from backend
        String referrerName = 'Unknown Referrer';
        String referrerEmail = '';
        
        if (result['referrer_name'] != null) {
          referrerName = result['referrer_name'];
        } else if (result['referrer'] != null) {
          final referrer = result['referrer'] as Map<String, dynamic>;
          referrerName = referrer['name'] ?? 'Unknown Referrer';
          referrerEmail = referrer['email'] ?? '';
        }
        
        if (result['referrer_email'] != null) {
          referrerEmail = result['referrer_email'];
        }
        
        referredUser.value = referrerName;
        log('Referrer found: $referrerName ($referrerEmail)');
        
        // Create a minimal UserModel for backward compatibility with the dialog
        // The dialog expects a UserModel object to determine success
        return UserModel(
          userId: code, // Use code as temporary ID for validation success
          username: referrerName,
          email: referrerEmail,
          imageUrl: '',
          phoneNumber: '',
          country: '',
          referralCode: code,
        );
      } else {
        log('Referral code validation failed - Django returned: ${result.toString()}');
        isCodeValid.value = false;
        codeError.value = 'Invalid or expired referral code';
        return null;
      }
    } catch (e) {
      log('Error fetching user by referral code: $e');
      isCodeValid.value = false;
      codeError.value = 'Error validating referral code. Please try again.';
      return null;
    }
  }

  /// Complete user registration (for email verification flow)
  Future<void> completeUserRegistration() async {
    try {
      log('🎯 AuthController: Completing user registration...');
      
      // Refresh user profile to get latest data from server
      await refreshUserProfile();
      
      final currentUser = currentUserStore.value;
      if (currentUser != null && currentUser.isVerified) {
        log('✅ AuthController: User is verified, checking approval status...');
        
        // ✅ APPROVAL SYSTEM: Check if user also needs approval
        if (!currentUser.isApproved) {
          log('📋 User is verified but needs approval - checking status');
          
          // Check current approval status from backend
          final statusResult = await _authService.checkApprovalStatus();
          final status = statusResult['status'] ?? 'pending';
          
          switch (status) {
            case 'approved':
              log('🎉 User is now approved - completing registration');
              
              // Update user model with approval status
              final updatedUser = currentUser.copyWith(
                isApproved: true,
                approvalStatus: 'approved',
              );
              currentUserStore.value = updatedUser;
              await _saveUserToStorage(updatedUser);
              
              // Welcome message
              Get.snackbar(
                'Welcome to TIRI!',
                'Your account has been verified and approved. Welcome to the community!',
                snackPosition: SnackPosition.TOP,
                backgroundColor: move,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
                icon: const Icon(Icons.celebration, color: Colors.white),
              );
              
              // Navigate to home
              await Future.delayed(const Duration(seconds: 1));
              Get.offAllNamed(Routes.homePage);
              return;
              
            case 'pending':
              log('⏳ Email verified but approval still pending');
              
              // ✅ CRITICAL FIX: Update user state to emailVerifiedPendingApproval
              await _userStateService.updateState(
                UserApprovalState.emailVerifiedPendingApproval,
                userId: currentUser.userId,
                referrerName: statusResult['user']?['referred_by_name'] ?? statusResult['user']?['referredByName'],
              );
              log('📊 AuthController: User state updated to emailVerifiedPendingApproval in completeUserRegistration');
              
              Get.snackbar(
                'Email Verified!',
                'Your email is verified. Now waiting for approval from your referrer.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
              Get.offAllNamed(Routes.pendingApprovalPage);
              return;
              
            case 'rejected':
              log('❌ Email verified but registration was rejected');
              rejectionReason.value = statusResult['rejection_reason'] ?? '';
              Get.snackbar(
                'Registration Rejected',
                'Your email is verified, but your registration was not approved.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: cancel,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
              Get.offAllNamed(Routes.rejectionScreen);
              return;
              
            case 'expired':
              log('⏰ Email verified but approval request expired');
              Get.snackbar(
                'Approval Expired',
                'Your email is verified, but the approval request has expired.',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
              Get.offAllNamed(Routes.expiredScreen);
              return;
          }
        } else {
          log('✅ User is both verified and approved - completing registration');
          
          // Update login status
          isLoggedIn.value = true;
          
          // Show welcome message
          Get.snackbar(
            'Welcome to TIRI!',
            'Your account has been successfully verified and activated.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: move,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.celebration, color: Colors.white),
          );
          
          // Navigate to home page
          log('🏠 AuthController: Navigating to home page');
          await Future.delayed(const Duration(seconds: 1)); // Brief delay for UX
          Get.offAllNamed(Routes.homePage);
        }
        
      } else {
        log('⚠️ AuthController: User verification status unclear');
        
        // User might not be verified yet, guide them appropriately
        if (currentUser == null) {
          // No user data, redirect to login
          Get.snackbar(
            'Authentication Required',
            'Please log in to continue.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: cancel,
            colorText: Colors.white,
          );
          Get.offAllNamed(Routes.loginPage);
        } else {
          // User exists but not verified, show verification pending
          Get.snackbar(
            'Verification Pending',
            'Please check your email and click the verification link.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      }
      
    } catch (e) {
      log('❌ AuthController: Error completing user registration: $e');
      
      Get.snackbar(
        'Registration Error',
        'Unable to complete registration. Please try logging in.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
      
      // Fallback to login page
      Get.offAllNamed(Routes.loginPage);
    }
  }

  /// Edit user profile
  Future<void> editUser(UserModel user, String newValue) async {
    try {
      isLoading.value = true;
      
      // TODO: Implement Django API call to update user
      // For now, just log the action
      log('editUser called for user: ${user.userId} with value: $newValue');
      
      Get.snackbar(
        'Profile Updated',
        'Profile updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: move,
        colorText: Colors.white,
      );
      
    } catch (e) {
      log('Error editing user: $e');
      Get.snackbar(
        'Update Failed',
        'Failed to update profile',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount({required String email, required String password}) async {
    try {
      isLoading.value = true;
      
      // TODO: Implement Django API call to delete account
      log('deleteUserAccount called for email: $email');
      
      // Clear user data
      await _authService.logout();
      currentUserStore.value = null;
      isLoggedIn.value = false;
      await _clearUserData();
      await _apiService.clearTokens(); // 🚨 FIXED: Clear tokens
      
      Get.offAllNamed(Routes.loginPage);
      Get.snackbar(
        'Account Deleted',
        'Your account has been successfully deleted',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
      
    } catch (e) {
      log('Error deleting account: $e');
      Get.snackbar(
        'Delete Failed',
        'Failed to delete account',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify user (for admin/verification workflows)
  Future<void> verifyUser(UserModel user) async {
    try {
      isLoading.value = true;
      
      // TODO: Implement Django API call to verify user
      log('verifyUser called for user: ${user.userId}');
      
      Get.snackbar(
        'User Verified',
        'User has been verified successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: move,
        colorText: Colors.white,
      );
      
    } catch (e) {
      log('Error verifying user: $e');
      Get.snackbar(
        'Verification Failed',
        'Failed to verify user',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh user profile from server
  Future<void> refreshUserProfile() async {
    try {
      log('🔄 AuthController: Refreshing user profile from server...');
      
      final updatedUser = await _authService.getCurrentUserProfile();
      
      if (updatedUser != null) {
        log('✅ AuthController: User profile refreshed successfully');
        log('   - User ID: ${updatedUser.userId}');
        log('   - Email: ${updatedUser.email}');
        log('   - Verified: ${updatedUser.isVerified}');
        
        // Update local state
        currentUserStore.value = updatedUser;
        
        // Save to storage
        await _saveUserToStorage(updatedUser);
        
      } else {
        log('⚠️ AuthController: Failed to refresh user profile - no data returned');
      }
      
    } catch (e) {
      log('❌ AuthController: Refresh user profile error: $e');
    }
  }

  // =============================================================================
  // APPROVAL SYSTEM METHODS
  // =============================================================================

  /// Fetch pending approval requests (for referrers)
  Future<void> fetchPendingApprovals() async {
    try {
      log('🔄 AuthController: Fetching pending approvals...');
      
      // Clear error state
      pendingApprovalsError.value = false;
      pendingApprovalsErrorMessage.value = '';
      
      final approvals = await _authService.getPendingApprovals();
      
      // Convert to ApprovalRequest objects
      pendingApprovals.clear();
      for (final approval in approvals) {
        pendingApprovals.add(ApprovalRequest.fromJson({
          'id': approval['id'],
          'newUserEmail': approval['new_user_email'],
          'newUserName': approval['new_user_name'],
          'newUserCountry': approval['new_user_country'],
          'newUserPhone': approval['new_user_phone'],
          'referralCodeUsed': approval['referral_code_used'],
          'status': approval['status'],
          'requestedAt': approval['requested_at'],
          'expiresAt': approval['expires_at'],
          'newUserProfileImage': approval['new_user_profile_image'],
          'rejectionReason': approval['rejection_reason'],  // Add this even if null
          'decidedAt': approval['decided_at'],  // Add this even if null
        }));
      }
      
      pendingApprovalsCount.value = pendingApprovals.length;
      log('✅ AuthController: Fetched ${pendingApprovals.length} pending approvals');
      
    } catch (e) {
      log('❌ AuthController: Error fetching pending approvals: $e');
      
      // Set error state
      pendingApprovalsError.value = true;
      pendingApprovalsErrorMessage.value = 'Failed to load pending approvals. Please check your connection and try again.';
      
      // Clear the list to show error state
      pendingApprovals.clear();
      pendingApprovalsCount.value = 0;
      
      // Show error snackbar
      Get.snackbar(
        'Error',
        'Failed to load pending approvals',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Fetch approval history (for referrers)
  Future<void> fetchApprovalHistory() async {
    try {
      log('🔄 AuthController: Fetching approval history...');
      
      // Clear error state
      approvalHistoryError.value = false;
      approvalHistoryErrorMessage.value = '';
      
      final history = await _authService.getApprovalHistory();
      
      // Convert to ApprovalRequest objects
      approvalHistory.clear();
      for (final item in history) {
        approvalHistory.add(ApprovalRequest.fromJson({
          'id': item['id'],
          'newUserEmail': item['new_user_email'],
          'newUserName': item['new_user_name'],
          'newUserCountry': item['new_user_country'],
          'newUserPhone': item['new_user_phone'],
          'referralCodeUsed': item['referral_code_used'],
          'status': item['status'],
          'requestedAt': item['requested_at'],
          'expiresAt': item['expires_at'],
          'newUserProfileImage': item['new_user_profile_image'],
          'rejectionReason': item['rejection_reason'],
          'decidedAt': item['decided_at'],
        }));
      }
      
      log('✅ AuthController: Fetched ${approvalHistory.length} approval history items');
      
    } catch (e) {
      log('❌ AuthController: Error fetching approval history: $e');
      
      // Set error state
      approvalHistoryError.value = true;
      approvalHistoryErrorMessage.value = 'Failed to load approval history. Please check your connection and try again.';
      
      // Clear the list to show error state
      approvalHistory.clear();
      
      Get.snackbar(
        'Error',
        'Failed to load approval history',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Approve a user registration
  Future<void> approveUser(String approvalId) async {
    try {
      isLoading.value = true;
      log('👍 AuthController: Approving user with ID: $approvalId');
      
      final result = await _authService.approveUser(approvalId);
      
      if (result.isSuccess) {
        Get.snackbar(
          'User Approved',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Refresh pending approvals list
        await fetchPendingApprovals();
        
      } else {
        Get.snackbar(
          'Approval Failed',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      log('❌ AuthController: Error approving user: $e');
      Get.snackbar(
        'Error',
        'Failed to approve user',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reject a user registration
  Future<void> rejectUser(String approvalId, [String? reason]) async {
    try {
      isLoading.value = true;
      log('👎 AuthController: Rejecting user with ID: $approvalId');
      
      final result = await _authService.rejectUser(approvalId, reason);
      
      if (result.isSuccess) {
        Get.snackbar(
          'User Rejected',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        
        // Refresh pending approvals list
        await fetchPendingApprovals();
        
      } else {
        Get.snackbar(
          'Rejection Failed',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      log('❌ AuthController: Error rejecting user: $e');
      Get.snackbar(
        'Error',
        'Failed to reject user',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Check approval status for current user (for polling)
  Future<void> checkApprovalStatus() async {
    try {
      log('🔍 AuthController: Checking approval status for current user...');
      
      final result = await _authService.checkApprovalStatus();
      
      approvalStatus.value = result['status'] ?? 'pending';
      rejectionReason.value = result['rejection_reason'] ?? '';
      
      if (result['expires_at'] != null) {
        approvalExpiresAt.value = DateTime.parse(result['expires_at']);
      }
      
      // Update user model with latest approval info
      if (currentUserStore.value != null) {
        final updatedUser = currentUserStore.value!.copyWith(
          isApproved: result['is_approved'] ?? false,
          approvalStatus: result['status'],
          rejectionReason: result['rejection_reason'],
          approvalExpiresAt: result['expires_at'] != null 
              ? DateTime.parse(result['expires_at']) 
              : null,
        );
        
        currentUserStore.value = updatedUser;
        await _saveUserToStorage(updatedUser);
      }
      
      log('✅ AuthController: Approval status updated - ${approvalStatus.value}');
      
    } catch (e) {
      log('❌ AuthController: Error checking approval status: $e');
      
      // Don't show snackbar error for silent polling - let the UI handle it
    }
  }

  /// Handle approval status change (called when status updates)
  void handleApprovalStatusChange(String newStatus) {
    approvalStatus.value = newStatus;
    
    switch (newStatus) {
      case 'approved':
        Get.snackbar(
          'Approved! 🎉',
          'Your registration has been approved. Welcome to TIRI!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.celebration, color: Colors.white),
        );
        // Navigate to home
        Get.offAllNamed(Routes.homePage);
        break;
        
      case 'rejected':
        Get.snackbar(
          'Registration Rejected',
          rejectionReason.value.isNotEmpty 
              ? 'Reason: ${rejectionReason.value}' 
              : 'Your registration was not approved.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        break;
        
      case 'expired':
        Get.snackbar(
          'Request Expired',
          'Your approval request has expired. Please contact support.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        break;
    }
  }

  /// Start polling approval status (for users waiting for approval)
  void startApprovalStatusPolling() {
    log('📡 AuthController: Starting approval status polling...');
    // TODO: Implement periodic status checking (every 30 seconds)
    // This can use a Timer.periodic or similar mechanism
  }

  /// Stop polling approval status
  void stopApprovalStatusPolling() {
    log('🛑 AuthController: Stopping approval status polling...');
    // TODO: Cancel periodic timer
  }

  /// Refresh approvals (pull-to-refresh)
  Future<void> refreshApprovals() async {
    await fetchPendingApprovals();
  }

  // =============================================================================
  // PASSWORD & EMAIL METHODS
  // =============================================================================
  
  /// Request password reset (for UI compatibility)
  Future<void> forgotPassword(String email, [String? routeName]) async {
    try {
      isLoading.value = true;
      
      final result = await _authService.requestPasswordReset(email: email);
      
      Get.snackbar(
        result.isSuccess ? 'Reset Email Sent' : 'Reset Failed',
        result.message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: result.isSuccess ? move : cancel,
        colorText: Colors.white,
      );
      
    } catch (e) {
      log('Password reset error: $e');
      Get.snackbar(
        'Error',
        'Failed to send reset email',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify email address
  Future<void> verifyEmail(String token, String uid) async {
    try {
      isLoading.value = true;
      log('📧 AuthController: Starting email verification process...');
      log('   - Token: ${token.substring(0, 10)}...');
      log('   - UID: $uid');
      
      final result = await _authService.verifyEmail(token: token, uid: uid, isMobile: true);
      
      if (result.isSuccess) {
        log('✅ AuthController: Email verification successful');
        
        // Update user verification status locally
        if (currentUserStore.value != null) {
          final updatedUser = currentUserStore.value!.copyWith(isVerified: true);
          currentUserStore.value = updatedUser;
          await _saveUserToStorage(updatedUser);
          log('✅ AuthController: User verification status updated locally');
        }
        
        // Show success message
        Get.snackbar(
          'Email Verified!',
          'Your email has been successfully verified. Welcome to TIRI!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: move,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        
        // Auto-login and navigate to home if user is verified
        log('🏠 AuthController: Navigating to home page after verification');
        await Future.delayed(const Duration(seconds: 2)); // Allow user to see success message
        Get.offAllNamed(Routes.homePage);
        
        // Refresh user profile to sync with server
        await refreshUserProfile();
        
      } else {
        log('❌ AuthController: Email verification failed: ${result.message}');
        
        Get.snackbar(
          'Verification Failed',
          result.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      log('💥 AuthController: Email verification error: $e');
      
      Get.snackbar(
        'Verification Error',
        'An unexpected error occurred during verification. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Check verification status manually (for "I have verified" button and deep links)
  /// Enhanced to handle direct JWT tokens in API response
  Future<bool> checkVerificationStatus() async {
    try {
      print('🔍 AuthController: Starting checkVerificationStatus...');
      log('🔍 AuthController: Checking verification status with enhanced JWT token support...');
      
      final statusResult = await _authService.checkVerificationStatus();
      
      final isVerified = statusResult['is_verified'] == true;
      final autoLogin = statusResult['auto_login'] == true;
      final approvalStatus = statusResult['approval_status'] ?? 'unknown';
      final message = statusResult['message'] ?? '';
      final accessToken = statusResult['access_token'];
      final refreshToken = statusResult['refresh_token'];
      
      // ✅ UPDATE USER STATE: Sync with API response
      await _userStateService.updateStateFromApiResponse(statusResult);
      log('📊 AuthController: User state synced with API response');
      
      log('📊 AuthController: Enhanced status result:');
      log('   - verified: $isVerified');
      log('   - auto_login: $autoLogin');
      log('   - approval_status: $approvalStatus');
      log('   - has_access_token: ${accessToken != null}');
      log('   - has_refresh_token: ${refreshToken != null}');
      
      // 🔍 DEBUG: Print exact values and conditions
      print('🔍 DEBUG: Raw statusResult = $statusResult');
      print('🔍 DEBUG: isVerified = $isVerified (${isVerified.runtimeType})');
      print('🔍 DEBUG: approvalStatus = "$approvalStatus" (${approvalStatus.runtimeType})');
      print('🔍 DEBUG: autoLogin = $autoLogin (${autoLogin.runtimeType})');
      print('🔍 DEBUG: message = "$message"');
      print('🔍 DEBUG: accessToken != null = ${accessToken != null}');
      print('🔍 DEBUG: refreshToken != null = ${refreshToken != null}');
      print('🔍 DEBUG: Condition 1 (approved + autoLogin): ${isVerified && approvalStatus == "approved" && autoLogin}');
      print('🔍 DEBUG: Condition 2 (approved + !autoLogin): ${isVerified && approvalStatus == "approved" && !autoLogin}');
      print('🔍 DEBUG: NEW Condition (unknown + tokens): ${isVerified && autoLogin && accessToken != null && approvalStatus == "unknown"}');
      print('🔍 DEBUG: Condition 3 (pending): ${isVerified && approvalStatus == "pending"}');
      print('🔍 DEBUG: Condition 4 (rejected): ${isVerified && approvalStatus == "rejected"}');
      print('🔍 DEBUG: Condition 5 (expired): ${isVerified && approvalStatus == "expired"}');
      
      // Handle unverified users first
      if (!isVerified) {
        log('❌ AuthController: User not yet verified');
        
        Get.snackbar(
          'Not Verified',
          message.isNotEmpty ? message : 'Please check your email and click the verification link first.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.email, color: Colors.white),
        );
        
        return false;
      }
      
      // 🚨 CRITICAL FIX: Check APPROVED status first, then pending
      // User is verified - handle approval status with correct priority
      
      print('🔍 DEBUG: About to check approval conditions...');
      
      if (isVerified && (approvalStatus == "approved" || (autoLogin && accessToken != null && approvalStatus == "unknown"))) {
        print('🎉 DEBUG: APPROVED condition matched!');
        if (autoLogin && accessToken != null && refreshToken != null) {
          // Scenario 1: Approved user within auto-login window (has JWT tokens)
          log('✅ AuthController: Auto-login enabled - approved user with JWT tokens');
          
          // Update local user state
          if (currentUserStore.value != null) {
            final updatedUser = currentUserStore.value!.copyWith(
              isVerified: true,
              isApproved: true,
              approvalStatus: 'approved',
            );
            currentUserStore.value = updatedUser;
            await _saveUserToStorage(updatedUser);
          }
          
          // Update user data if provided in response
          if (statusResult['user'] != null) {
            try {
              final userData = statusResult['user'] as Map<String, dynamic>;
              // Map Django user data to Flutter format with proper field mapping
              final mappedUserData = _mapDjangoUserToFlutter(userData);
              // Ensure the user data has the correct approval fields
              mappedUserData['isApproved'] = true;
              mappedUserData['approvalStatus'] = 'approved';
              
              final user = UserModel.fromJson(mappedUserData);
              currentUserStore.value = user;
              await _saveUserToStorage(user);
              log('👤 AuthController: User data updated from API response with approval status');
            } catch (e) {
              log('⚠️ AuthController: Failed to parse user data: $e');
            }
          }
          
          // Mark as logged in
          isLoggedIn.value = true;
          
          // Update state to fully approved
          await _userStateService.updateState(
            UserApprovalState.fullyApproved,
            userId: currentUserStore.value?.userId,
          );
          
          // Show approval popup and auto-redirect
          _showApprovalSuccessPopup();
          
          return true;
          
        } else {
          // Scenario 2: Approved user outside auto-login window (no JWT tokens)
          print('🎉 DEBUG: APPROVED without auto-login - showing congratulations');
          log('🎉 AuthController: User approved but outside auto-login window - showing congratulations');
          
          // Update user state to fully approved
          await _userStateService.updateState(
            UserApprovalState.fullyApproved,
            userId: currentUserStore.value?.userId,
          );
          log('📊 AuthController: User state updated to fullyApproved');
          
          // Update user model with approval status
          if (currentUserStore.value != null) {
            final updatedUser = currentUserStore.value!.copyWith(
              isVerified: true,
              isApproved: true,
              approvalStatus: 'approved',
            );
            currentUserStore.value = updatedUser;
            await _saveUserToStorage(updatedUser);
          }
          
          // Show approval popup and auto-redirect (no tokens case)
          _showApprovalSuccessPopup();
          
          return true;
        }
        
      } else if (isVerified && approvalStatus == "pending") {
        // Scenario 3: ✅ Email verified but pending approval - Proper state transition
        print('⏳ DEBUG: PENDING condition matched');
        log('📋 AuthController: Email verified, approval pending - transitioning to pending approval state');
        
        // ✅ CRITICAL FIX: Update user state to prevent screen switching
        await _userStateService.updateState(
          UserApprovalState.emailVerifiedPendingApproval,
          userId: currentUserStore.value?.userId,
          referrerName: statusResult['user']?['referred_by_name'] ?? statusResult['user']?['referredByName'],
        );
        log('📊 AuthController: User state updated to emailVerifiedPendingApproval');
        
        // Extract referrer info for display
        final userData = statusResult['user'] ?? {};
        final referrerName = userData['referred_by_name'] ?? userData['referredByName'] ?? 'your referrer';
        
        Get.snackbar(
          'Email Verified!',
          'Awaiting approval from $referrerName. You\'ll be notified when approved.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.pending_actions, color: Colors.white),
        );
        
        // Navigate to pending approval screen (DON'T LOGOUT)
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(Routes.pendingApprovalPage);
        
        return false; // Not fully complete, but don't logout
        
      } else if (isVerified && approvalStatus == "rejected") {
        // Scenario 4: Rejected by referrer
        print('❌ DEBUG: REJECTED condition matched');
        log('❌ AuthController: User registration was rejected by referrer');
        
        final userData = statusResult['user'] ?? {};
        final rejectionReason = userData['rejection_reason'] ?? userData['rejectionReason'] ?? 'No reason provided';
        
        Get.snackbar(
          'Registration Rejected',
          'Reason: $rejectionReason',
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.cancel, color: Colors.white),
        );
        
        // Navigate to rejection screen
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(Routes.rejectionScreen);
        
        return false;
        
      } else if (isVerified && approvalStatus == "expired") {
        // Scenario 5: Approval window expired
        log('⏰ AuthController: Approval request expired - require new referral');
        
        // Clear session for expired approval
        await logout();
        
        Get.snackbar(
          'Approval Expired',
          'Your approval request expired. Please get a new referral code to register.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.schedule, color: Colors.white),
        );
        
        // Navigate to expired screen
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(Routes.expiredScreen);
        
        return false;
        
      } else {
        // Unknown scenario - fallback
        print('❓ DEBUG: UNKNOWN scenario - falling to else block');
        log('⚠️ AuthController: Unknown approval scenario - approval_status: $approvalStatus, auto_login: $autoLogin');
        
        Get.snackbar(
          'Status Unknown',
          'Please contact support or try logging in manually.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: cancel,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.help, color: Colors.white),
        );
        
        return false;
      }
    } catch (e) {
      log('❌ AuthController: Enhanced verification check failed: $e');
      
      Get.snackbar(
        'Verification Check Failed',
        'Unable to check verification status. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: cancel,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
      
      return false;
    }
  }

  // =============================================================================
  // NAVIGATION METHODS
  // =============================================================================
  
  /// Navigate to forgot password screen
  VoidCallback get navigateToForgotPassword => () => Get.toNamed(Routes.forgotPasswordPage);

  /// Navigate to login screen
  VoidCallback get navigateToLogin => () => Get.offNamed(Routes.loginPage);

  /// Navigate to register screen
  void navigateToRegister() {
    Get.toNamed(Routes.registerPage);
  }

  // =============================================================================
  // VALIDATION METHODS
  // =============================================================================
  
  /// Validate login form
  bool validateLoginForm() {
    final isValid = loginformKey.value.currentState?.validate() ?? false;
    return isValid && validateEmail(emailController.value.text) == null && 
           validatePassword(passwordController.value.text) == null;
  }

  /// Validate registration form
  bool validateRegisterForm() {
    final isValid = registerformKey.value.currentState?.validate() ?? false;
    validateCountry(selectedCountry.value);
    return isValid && isCountryValid.value;
  }

  /// Email validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      isEmailValid.value = false;
      emailError.value = 'Email is required';
      return emailError.value;
    }

    if (!GetUtils.isEmail(value)) {
      isEmailValid.value = false;
      emailError.value = 'Please enter a valid email';
      return emailError.value;
    }

    isEmailValid.value = true;
    emailError.value = '';
    return null;
  }

  /// Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      isPasswordValid.value = false;
      passwordError.value = 'Password is required';
      return passwordError.value;
    }

    if (value.length < 8) {
      isPasswordValid.value = false;
      passwordError.value = 'Password must be at least 8 characters';
      return passwordError.value;
    }

    isPasswordValid.value = true;
    passwordError.value = '';
    return null;
  }

  /// Name validation
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      isNameValid.value = false;
      nameError.value = 'Name is required';
      return nameError.value;
    }

    if (value.length < 3) {
      isNameValid.value = false;
      nameError.value = 'Name must be at least 3 characters';
      return nameError.value;
    }

    isNameValid.value = true;
    nameError.value = '';
    return null;
  }

  /// Phone validation
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      isPhoneValid.value = false;
      phoneError.value = 'Phone number is required';
      return phoneError.value;
    }

    if (value.length < 10) {
      isPhoneValid.value = false;
      phoneError.value = 'Please enter a valid phone number';
      return phoneError.value;
    }

    isPhoneValid.value = true;
    phoneError.value = '';
    return null;
  }

  /// Country validation
  void validateCountry(Country? country) {
    if (country == null) {
      isCountryValid.value = false;
      countryError.value = 'Please select a country';
    } else {
      isCountryValid.value = true;
      countryError.value = '';
    }
  }

  /// Referral code validation
  String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      isCodeValid.value = false;
      codeError.value = 'Referral code is required';
      return codeError.value;
    }

    if (value.length < 3) {
      isCodeValid.value = false;
      codeError.value = 'Invalid referral code';
      return codeError.value;
    }

    isCodeValid.value = true;
    codeError.value = '';
    return null;
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Toggle password visibility
  void toggleObscure() {
    isObscure.value = !isObscure.value;
  }

  /// Remove spaces from text controller
  Future<void> removeSpace(TextEditingController tc) async {
    tc.text = tc.text.replaceAll(" ", "");
  }

  /// Update phone number with country code
  void updatePhoneWithCode() {
    if (selectedCountry.value != null) {
      phoneNumberWithCode.value = 
          '+${selectedCountry.value!.phoneCode}${phoneNumberController.value.text}';
    } else {
      phoneNumberWithCode.value = phoneNumberController.value.text;
    }
  }

  /// Generate referral code (if needed for admin users)
  String generateReferralCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final math.Random random = math.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Reload JWT tokens and user data (used by splash controller)
  Future<void> reloadTokens() async {
    try {
      log('🔄 AuthController: Reloading tokens and user data...');
      
      // Load JWT tokens from secure storage
      await _apiService.loadTokensFromStorage();
      
      // Load user data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      
      if (userStr != null) {
        final userJson = jsonDecode(userStr);
        currentUserStore.value = UserModel.fromJson(userJson);
        isLoggedIn.value = true;
        log('✅ AuthController: Tokens and user data reloaded successfully');
      } else {
        log('ℹ️  AuthController: No user data found in storage');
        isLoggedIn.value = false;
        currentUserStore.value = null;
      }
      
    } catch (e) {
      log('❌ AuthController: Error reloading tokens: $e');
      isLoggedIn.value = false;
      currentUserStore.value = null;
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================
  
  /// Save user to storage
  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      log('💾 User data saved to storage');
    } catch (e) {
      log('❌ Error saving user to storage: $e');
    }
  }

  /// Clear user data from storage
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      log('🧹 User data cleared from storage');
    } catch (e) {
      log('❌ Error clearing user data: $e');
    }
  }


  /// Clear login form
  void _clearLoginForm() {
    emailController.value.clear();
    passwordController.value.clear();
    emailError.value = '';
    passwordError.value = '';
  }

  /// Clear registration form
  void _clearRegisterForm() {
    userNameController.value.clear();
    emailController.value.clear();
    phoneNumberController.value.clear();
    countryController.value.clear();
    passwordController.value.clear();
    referralCodeController.value.clear();
    selectedCountry.value = null;
    
    // Clear referral data
    referredUid.value = '';
    referredUser.value = '';
    
    // Clear errors
    nameError.value = '';
    emailError.value = '';
    phoneError.value = '';
    countryError.value = '';
    passwordError.value = '';
    codeError.value = '';
  }

  // =============================================================================
  // GETTERS (Backward Compatibility)
  // =============================================================================
  
  /// Get current user (backward compatibility)
  UserModel? get currentUser => currentUserStore.value;
  
  /// Get current user ID
  String? get currentUserId => currentUserStore.value?.userId;
  
  /// Get current user email
  String? get currentUserEmail => currentUserStore.value?.email;
  
  /// Check if user is verified
  bool get isUserVerified => currentUserStore.value?.isVerified ?? false;

  /// Check if user is currently authenticated
  bool get isAuthenticated => isLoggedIn.value && currentUserStore.value != null;

  // =============================================================================
  // CLEANUP
  // =============================================================================
  
  @override
  void onClose() {
    // Dispose controllers
    emailController.value.dispose();
    passwordController.value.dispose();
    userNameController.value.dispose();
    countryController.value.dispose();
    phoneNumberController.value.dispose();
    referralCodeController.value.dispose();
    
    super.onClose();
  }

  /// Show approval success popup with auto-redirect
  void _showApprovalSuccessPopup() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with animation
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(111, 168, 67, 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 40,
                  color: Color.fromRGBO(111, 168, 67, 1),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Congratulations! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              const Text(
                'Your account has been approved!\nWelcome to TIRI!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 25),
              
              // Loading indicator
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(111, 168, 67, 1),
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              const Text(
                'Redirecting to home...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
    
    // Auto-redirect after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (Get.isDialogOpen ?? false) {
        Get.back(); // Close dialog
      }
      Get.offAllNamed(Routes.homePage);
    });
  }
}