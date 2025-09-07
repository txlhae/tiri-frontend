import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/user_state_service.dart';
import 'package:tiri/services/notification_permission_service.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/account_status_service.dart';
import 'package:tiri/models/auth_models.dart';

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
  late final AuthService _authService;
  late final AccountStatusService _accountStatusService;
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
    _authService = Get.find<AuthService>();
    _accountStatusService = AccountStatusService.instance;
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

  /// TEMPORARILY DISABLED: Enhanced app initialization with new account status system
  Future<void> _performEnhancedInitialization() async {
    log('🚨 ALERT: Enhanced initialization was called - this should not happen!', name: 'SPLASH');
    // Immediately fall back to legacy flow instead of trying the enhanced flow
    await _performSmartInitialization();
    return;
    try {
      log('🚀 SplashController: Starting enhanced initialization', name: 'SPLASH');
      
      // Step 1: Initialize services
      initializationStatus.value = 'Loading services...';
      await _authService.initialize();
      await _userStateService.initialize();
      
      // Step 2: Load tokens from storage FIRST (this was missing!)
      initializationStatus.value = 'Loading stored tokens...';
      final apiService = Get.find<ApiService>();
      await apiService.loadTokensFromStorage();
      log('🔐 Tokens loaded from storage - isAuthenticated: ${apiService.isAuthenticated}', name: 'SPLASH');
      
      // Step 2a: Try to refresh tokens if they exist but might be expired
      if (apiService.isAuthenticated) {
        initializationStatus.value = 'Refreshing tokens...';
        log('🔄 Attempting token refresh...', name: 'SPLASH');
        final refreshSuccess = await apiService.refreshTokenIfNeeded();
        log('🔄 Token refresh result: $refreshSuccess', name: 'SPLASH');
        
        // 🚨 FIX: If token refresh succeeds, update auth state and user data
        if (refreshSuccess) {
          log('✅ Token refreshed successfully - updating authentication state', name: 'SPLASH');
          
          // Load user data from storage and mark as logged in
          await _authController.reloadTokens();
          
          // If user is now authenticated, route to home page immediately
          if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
            log('🏠 User authenticated after token refresh - routing to home', name: 'SPLASH');
            initializationStatus.value = 'Welcome back!';
            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAllNamed(Routes.homePage);
            return;
          }
        }
      }
      
      // Step 3: Request notification permissions on first launch
      initializationStatus.value = 'Checking permissions...';
      await NotificationPermissionService.requestNotificationPermissionOnFirstLaunch();
      
      // Step 4: Check for stored tokens (now they should be loaded!)
      initializationStatus.value = 'Checking authentication...';
      final hasTokens = _authService.hasValidTokens;
      log('🔍 hasValidTokens result: $hasTokens', name: 'SPLASH');
      
      if (!hasTokens) {
        log('🔓 SplashController: No tokens found - routing to onboarding', name: 'SPLASH');
        _routeToOnboarding();
        return;
      }
      
      // TEMPORARILY DISABLED: Check account status with registration status endpoint (endpoint doesn't exist)
      log('⚠️ SplashController: Registration status endpoint disabled - falling back to legacy flow', name: 'SPLASH');
      // Don't try to call the non-existent endpoint, go straight to legacy flow
      await _performSmartInitialization();
      return;
      
      // UNREACHABLE CODE - COMMENTED OUT
      // // Step 5: Cache the status locally
      // await _accountStatusService.storeAccountStatus(registrationStatus);
      // 
      // // Step 6: Show deletion warning if needed
      // if (_accountStatusService.shouldShowDeletionWarning(registrationStatus.warning)) {
      //   _showDeletionWarning(registrationStatus.warning!);
      // }
      // 
      // // Step 7: Route based on next step
      // await _routeBasedOnNextStep(registrationStatus);
      
    } catch (e, stackTrace) {
      log('❌ SplashController: Enhanced initialization failed: $e', stackTrace: stackTrace, name: 'SPLASH');
      await _handleEnhancedInitializationError();
    } finally {
      isInitializing.value = false;
    }
  }

  /// Route user based on the next step from registration status
  Future<void> _routeBasedOnNextStep(RegistrationStatusResponse status) async {
    final nextStep = status.nextStep;
    log('🗺️ SplashController: Routing for next step: $nextStep', name: 'SPLASH');
    
    final message = _accountStatusService.getStatusMessage(status.accountStatus, nextStep);
    
    initializationStatus.value = message;
    await Future.delayed(const Duration(milliseconds: 500));
    
    switch (nextStep) {
      case 'verify_email':
        Get.offAllNamed(Routes.emailVerificationPage);
        break;
      case 'waiting_for_approval':
        Get.offAllNamed(Routes.pendingApprovalPage);
        break;
      case 'approval_rejected':
        Get.offAllNamed(Routes.rejectionScreen);
        break;
      case 'complete_profile':
        // TODO: Add profile completion route when available
        Get.offAllNamed(Routes.homePage);
        break;
      case 'ready':
        Get.offAllNamed(Routes.homePage);
        break;
      default:
        log('⚠️ Unknown next step: $nextStep', name: 'SPLASH');
        Get.offAllNamed(Routes.onboardingPage);
    }
  }

  /// Handle token expiry by clearing data and routing to onboarding
  Future<void> _handleTokenExpiry() async {
    log('🚨 SplashController: Tokens appear to be expired', name: 'SPLASH');
    initializationStatus.value = 'Session expired...';
    
    // Clear all cached data
    await _authService.logout();
    await _accountStatusService.clearAccountStatus();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _routeToOnboarding();
  }

  /// Route to onboarding screen
  void _routeToOnboarding() {
    initializationStatus.value = 'Welcome!';
    Get.offAllNamed(Routes.onboardingPage);
  }

  /// Show deletion warning to user
  void _showDeletionWarning(AuthWarning warning) {
    final timeRemaining = _accountStatusService.getTimeUntilDeletion(warning);
    
    Get.snackbar(
      '⚠️ Action Required',
      'Your account will be deleted in $timeRemaining. ${warning.message}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 8),
      icon: const Icon(Icons.warning, color: Colors.white),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
    );
  }

  /// TEMPORARILY DISABLED: Handle enhanced initialization errors
  Future<void> _handleEnhancedInitializationError() async {
    log('🚨 ALERT: Enhanced initialization error handler was called - this should not happen!', name: 'SPLASH');
    // Fall back to regular error handling instead
    await _handleInitializationError();
    return;
    log('🚨 SplashController: Handling enhanced initialization error', name: 'SPLASH');
    
    initializationStatus.value = 'Loading...';
    
    try {
      // Try to use cached account status
      final cachedStatus = await _accountStatusService.getStoredAccountStatus();
      
      if (cachedStatus != null) {
        log('📱 SplashController: Using cached account status', name: 'SPLASH');
        final nextStep = cachedStatus['next_step'] as String;
        final route = _accountStatusService.getRouteForStatus(nextStep);
        
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(route);
        return;
      }
      
      // Fall back to legacy initialization
      await _performSmartInitialization();
      
    } catch (e) {
      log('❌ SplashController: Even enhanced error handling failed: $e', name: 'SPLASH');
      // Ultimate fallback
      _routeToOnboarding();
    }
  }

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
      
      // 🚨 FIX: If user is authenticated after token reload, route directly to home
      if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
        log('🏠 User authenticated after reload - routing to home', name: 'SPLASH');
        initializationStatus.value = 'Welcome back!';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.homePage);
        return;
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
      default:
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
  // CONGRATULATIONS FLOW
  // =============================================================================

  /// Show congratulations flow for newly approved users
  Future<void> _showCongratulationsFlow() async {
    try {
      initializationStatus.value = 'Congratulations! 🎉';
      
      // Show congratulations snackbar
      Get.snackbar(
        '🎉 Welcome to TIRI!',
        'Your registration has been approved! Welcome to the community!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color.fromRGBO(111, 168, 67, 1),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.celebration, color: Colors.white, size: 28),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
      
      // Mark congratulations as shown
      await _userStateService.markCongratulationsShown();
      
      // Wait for snackbar to show, then navigate
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(Routes.homePage);
      
      log('✅ SplashController: Congratulations flow completed', name: 'SPLASH');
      
    } catch (e) {
      log('❌ SplashController: Congratulations flow failed: $e', name: 'SPLASH');
      // Fallback to direct home navigation
      Get.offAllNamed(Routes.homePage);
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
}
