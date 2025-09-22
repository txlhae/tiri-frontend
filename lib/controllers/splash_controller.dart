import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/user_state_service.dart';
import 'package:tiri/services/notification_permission_service.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/api_service.dart';

/// Smart Splash Controller with State-Based Routing
/// 
/// This controller implements optimized app initialization logic to:
/// - Eliminate 401 errors for pending approval users
/// - Reduce unnecessary API calls for approved users  
/// - Provide correct routing based on user approval state
/// - Show congratulations flow for newly approved users
class SplashController extends GetxController {
  // =============================================================================
  // SERVICES & CONTROLLERS
  // =============================================================================
  
  late final AuthController _authController;
  late final UserStateService _userStateService;
  
  // =============================================================================
  // REACTIVE STATE
  // =============================================================================
  
  final isInitializing = true.obs;
  final initializationStatus = 'Starting app...'.obs;

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _userStateService = Get.find<UserStateService>();

    // Start smart initialization after splash delay
    Timer(const Duration(seconds: 2), () {
      // Use legacy initialization since enhanced flow depends on endpoint that doesn't exist yet
      _performSmartInitialization();
    });
  }

  // =============================================================================
  // SMART INITIALIZATION LOGIC
  // =============================================================================


  /// Perform optimized app initialization with state-based routing
  Future<void> _performSmartInitialization() async {
    try {
      log('🚀 SplashController: Starting smart initialization', name: 'SPLASH');
      
      // Step 1: Initialize user state service
      initializationStatus.value = 'Loading user state...';
      await _userStateService.initialize();
      
      // Step 2: Request notification permissions on first launch
      initializationStatus.value = 'Checking permissions...';
      await NotificationPermissionService.requestNotificationPermissionOnFirstLaunch();
      
      // Step 3: Load authentication tokens and user data
      initializationStatus.value = 'Checking authentication...';
      log('🔄 DEBUG: About to reload tokens...');
      await _authController.reloadTokens(); // Load JWT tokens
      log('🔄 DEBUG: Tokens reloaded. IsLoggedIn: ${_authController.isLoggedIn.value}');
      
      // 🚨 CRITICAL FIX: Check verification status before routing
      if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
        log('🔍 User has tokens - checking verification status before routing...', name: 'SPLASH');
        initializationStatus.value = 'Checking account status...';

        try {
          // Call verification-status API to check auto_login
          final authService = Get.find<AuthService>();
          final statusResult = await authService.checkVerificationStatus();

          final autoLogin = statusResult['auto_login'] == true;
          log('📊 Verification status result: auto_login = $autoLogin', name: 'SPLASH');

          if (autoLogin) {
            log('✅ Auto-login enabled - routing to home', name: 'SPLASH');
            initializationStatus.value = 'Welcome back!';
            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAllNamed(Routes.homePage);
            return;
          } else {
            log('❌ Auto-login disabled - clearing data and routing to login', name: 'SPLASH');
            initializationStatus.value = 'Please login again...';

            // Clear all local data and cache
            await _clearAllUserData();

            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAllNamed(Routes.loginPage);
            return;
          }
        } catch (e) {
          log('⚠️ Verification status check failed: $e - routing to login', name: 'SPLASH');
          await _clearAllUserData();
          Get.offAllNamed(Routes.loginPage);
          return;
        }
      }
      
      // Step 4: Determine routing strategy based on current state
      final currentState = _userStateService.currentApprovalState;
      log('📊 SplashController: Current user state: ${currentState.value}', name: 'SPLASH');
      
      await _routeBasedOnState(currentState);
      
    } catch (e, stackTrace) {
      log('❌ SplashController: Initialization failed: $e', stackTrace: stackTrace, name: 'SPLASH');
      
      // Fallback routing on error
      await _handleInitializationError();
    } finally {
      isInitializing.value = false;
    }
  }

  /// Route user based on their current approval state
  Future<void> _routeBasedOnState(UserApprovalState state) async {
    log('🗺️  SplashController: Routing for state: ${state.value}', name: 'SPLASH');
    log('🗺️  DEBUG SplashController: Current state = ${state.value}');
    
    switch (state) {
      case UserApprovalState.notLoggedIn:
        log('🗺️  DEBUG: Handling notLoggedIn state');
        await _handleNotLoggedIn();
        break;
        
      case UserApprovalState.emailUnverified:
        log('🗺️  DEBUG: Handling emailUnverified state');
        await _handleEmailUnverified();
        break;
        
      case UserApprovalState.emailVerifiedPendingApproval:
        log('🗺️  DEBUG: Handling emailVerifiedPendingApproval state');
        await _handlePendingApproval();
        break;
        
      case UserApprovalState.fullyApproved:
        log('🗺️  DEBUG: Handling fullyApproved state - should go to home');
        await _handleFullyApproved();
        break;
        
      case UserApprovalState.rejected:
        await _handleRejected();
        break;
        
      case UserApprovalState.expired:
        await _handleExpired();
        break;
        
      case UserApprovalState.unknown:
        log('🗺️  DEBUG: Handling unknown state - checking if user is actually logged in');
        // Check if user is actually logged in despite unknown state
        if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
          log('🗺️  DEBUG: User is logged in despite unknown state - going to home');
          await _handleFullyApproved();
        } else {
          await _handleUnknownState();
        }
        break;
    }
  }

  // =============================================================================
  // STATE-SPECIFIC ROUTING HANDLERS
  // =============================================================================

  /// Handle not logged in state
  Future<void> _handleNotLoggedIn() async {
    log('🔓 SplashController: User not logged in - routing to onboarding', name: 'SPLASH');
    initializationStatus.value = 'Welcome!';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.onboardingPage);
  }

  /// Handle email unverified state  
  Future<void> _handleEmailUnverified() async {
    log('📧 SplashController: Email unverified - routing to email verification screen', name: 'SPLASH');
    initializationStatus.value = 'Please verify your email...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    // Use the consistent EmailVerificationScreen instead of VerifyPendingScreen
    Get.offAllNamed(Routes.emailVerificationPage);
  }

  /// Handle pending approval state with optional API check
  Future<void> _handlePendingApproval() async {
    log('⏳ SplashController: Pending approval - checking current status', name: 'SPLASH');
    initializationStatus.value = 'Checking approval status...';
    
    // 🚨 CRITICAL FIX: Minimize API calls for verified users to prevent state corruption
    // Only make API calls if state is older than 10 minutes to check for approval changes
    final stateIsVeryOld = _userStateService.isStateStale(maxAge: const Duration(minutes: 10));
    final shouldMakeApiCall = stateIsVeryOld;
    
    if (shouldMakeApiCall) {
      log('📡 SplashController: State is old - making API call to check approval status', name: 'SPLASH');
      
      try {
        final success = await _authController.checkVerificationStatus();
        
        if (success) {
          // Status changed to approved - let AuthController handle routing
          log('✅ SplashController: Approval status changed - AuthController handling routing', name: 'SPLASH');
          return;
        }
        
        // Still pending - route to pending screen
        log('⏳ SplashController: Still pending approval - routing to pending screen', name: 'SPLASH');
        initializationStatus.value = 'Awaiting approval...';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.pendingApprovalPage);
        
      } catch (e) {
        log('❌ SplashController: API call failed, routing to pending screen anyway: $e', name: 'SPLASH');
        initializationStatus.value = 'Awaiting approval...';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.pendingApprovalPage);
      }
    } else {
      // No API call needed - direct routing to maintain consistent state
      log('⚡ SplashController: No API call needed - direct routing to pending screen (preserving verified state)', name: 'SPLASH');
      initializationStatus.value = 'Awaiting approval...';
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.pendingApprovalPage);
    }
  }

  /// Handle fully approved state with congratulations flow
  Future<void> _handleFullyApproved() async {
    log('🎉 SplashController: User fully approved', name: 'SPLASH');
    
    // Always go directly to home page for approved users
    // The approval congratulations are handled in the AuthController when status changes
    log('✅ SplashController: Routing approved user directly to home', name: 'SPLASH');
    initializationStatus.value = 'Welcome back!';
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.homePage);
  }

  /// Handle rejected state
  Future<void> _handleRejected() async {
    log('❌ SplashController: User registration rejected - routing to rejection screen', name: 'SPLASH');
    initializationStatus.value = 'Registration status...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.rejectionScreen);
  }

  /// Handle expired state
  Future<void> _handleExpired() async {
    log('⏰ SplashController: Approval request expired - routing to expired screen', name: 'SPLASH');
    initializationStatus.value = 'Registration status...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.expiredScreen);
  }

  /// Handle unknown state (fallback)
  Future<void> _handleUnknownState() async {
    log('❓ SplashController: Unknown state - checking authentication fallback', name: 'SPLASH');
    
    // Check basic authentication as fallback
    if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
      log('🔐 SplashController: User authenticated but state unknown - routing to home', name: 'SPLASH');
      initializationStatus.value = 'Loading...';
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.homePage);
    } else {
      log('🔓 SplashController: No authentication - routing to onboarding', name: 'SPLASH');
      initializationStatus.value = 'Welcome!';
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.onboardingPage);
    }
  }


  // =============================================================================
  // ERROR HANDLING
  // =============================================================================

  /// Handle initialization errors with graceful fallback
  Future<void> _handleInitializationError() async {
    log('🚨 SplashController: Handling initialization error with fallback', name: 'SPLASH');
    
    initializationStatus.value = 'Initializing...';
    
    try {
      // Try basic authentication check as fallback
      if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
        log('🔐 SplashController: Fallback - user authenticated, going to home', name: 'SPLASH');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.homePage);
      } else {
        log('🔓 SplashController: Fallback - no authentication, going to onboarding', name: 'SPLASH');
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.onboardingPage);
      }
    } catch (e) {
      log('❌ SplashController: Even fallback failed: $e', name: 'SPLASH');
      // Ultimate fallback
      Get.offAllNamed(Routes.onboardingPage);
    }
  }

  // =============================================================================
  // GETTERS FOR UI
  // =============================================================================
  
  /// Get current initialization status for display
  String get currentStatus => initializationStatus.value;
  
  /// Check if initialization is still in progress
  bool get isStillInitializing => isInitializing.value;

  /// Clear all user data and cache
  Future<void> _clearAllUserData() async {
    try {
      log('🗑️ SplashController: Clearing all user data and cache...', name: 'SPLASH');

      // Clear auth controller data
      await _authController.logout();

      // Clear API service tokens
      final apiService = Get.find<ApiService>();
      await apiService.clearTokens();

      // Clear user state service
      await _userStateService.clearState();
      
      log('✅ SplashController: All user data cleared successfully', name: 'SPLASH');
    } catch (e) {
      log('❌ SplashController: Error clearing user data: $e', name: 'SPLASH');
    }
  }
}
