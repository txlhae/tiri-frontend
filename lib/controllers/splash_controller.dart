import 'dart:async';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/user_state_service.dart';
import 'package:tiri/services/notification_permission_service.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/connectivity_service.dart';

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
  late final ConnectivityService _connectivityService;
  
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
    _connectivityService = Get.find<ConnectivityService>();

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

      // Step 1: Check network connectivity first
      initializationStatus.value = 'Checking connection...';
      final connectivityState = await _connectivityService.checkConnectivity();

      if (connectivityState == ConnectivityState.offline) {
        initializationStatus.value = 'Not connected to the internet';
        await Future.delayed(const Duration(seconds: 3));
        // Show offline screen or retry
        await _handleOfflineState();
        return;
      } else if (connectivityState == ConnectivityState.serverOffline) {
        initializationStatus.value = 'Server offline - unable to reach backend';
        await Future.delayed(const Duration(seconds: 3));
        // Show server offline screen or retry
        await _handleServerOfflineState();
        return;
      }


      // Step 2: Initialize user state service
      initializationStatus.value = 'Loading user state...';
      await _userStateService.initialize();

      // Step 3: Request notification permissions on first launch
      initializationStatus.value = 'Checking permissions...';
      await NotificationPermissionService.requestNotificationPermissionOnFirstLaunch();

      // Step 4: Load authentication tokens and user data
      initializationStatus.value = 'Checking authentication...';
      await _authController.reloadTokens(); // Load JWT tokens

      // 🚨 CRITICAL FIX: Check verification status before routing (only if connected)
      if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
        initializationStatus.value = 'Checking account status...';

        try {
          // Verify connectivity before making API call
          if (!_connectivityService.canMakeApiCalls) {
            throw Exception('No network connectivity for API calls');
          }

          // Call verification-status API to check auto_login
          final authService = Get.find<AuthService>();
          final statusResult = await authService.checkVerificationStatus();

          final autoLogin = statusResult['auto_login'] == true;

          if (autoLogin) {
            initializationStatus.value = 'Welcome back!';
            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAllNamed(Routes.homePage);
            return;
          } else {
            initializationStatus.value = 'Please login again...';

            // Clear all local data and cache
            await _clearAllUserData();

            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAllNamed(Routes.loginPage);
            return;
          }
        } catch (e) {

          // Check if it's a connectivity issue
          if (!_connectivityService.canMakeApiCalls) {
            await _handleConnectivityError();
            return;
          }

          // Otherwise treat as auth failure
          await _clearAllUserData();
          Get.offAllNamed(Routes.loginPage);
          return;
        }
      }
      
      // Step 4: Determine routing strategy based on current state
      final currentState = _userStateService.currentApprovalState;

      await _routeBasedOnState(currentState);

    } catch (e) {
      
      // Fallback routing on error
      await _handleInitializationError();
    } finally {
      isInitializing.value = false;
    }
  }

  /// Route user based on their current approval state
  Future<void> _routeBasedOnState(UserApprovalState state) async {
    
    switch (state) {
      case UserApprovalState.notLoggedIn:
        await _handleNotLoggedIn();
        break;
        
      case UserApprovalState.emailUnverified:
        await _handleEmailUnverified();
        break;
        
      case UserApprovalState.emailVerifiedPendingApproval:
        await _handlePendingApproval();
        break;
        
      case UserApprovalState.fullyApproved:
        await _handleFullyApproved();
        break;
        
      case UserApprovalState.rejected:
        await _handleRejected();
        break;
        
      case UserApprovalState.expired:
        await _handleExpired();
        break;
        
      case UserApprovalState.unknown:
        // Check if user is actually logged in despite unknown state
        if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
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
    initializationStatus.value = 'Welcome!';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.onboardingPage);
  }

  /// Handle email unverified state  
  Future<void> _handleEmailUnverified() async {
    initializationStatus.value = 'Please verify your email...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    // Use the consistent EmailVerificationScreen instead of VerifyPendingScreen
    Get.offAllNamed(Routes.emailVerificationPage);
  }

  /// Handle pending approval state with optional API check
  Future<void> _handlePendingApproval() async {
    initializationStatus.value = 'Checking approval status...';
    
    // 🚨 CRITICAL FIX: Minimize API calls for verified users to prevent state corruption
    // Only make API calls if state is older than 10 minutes to check for approval changes
    final stateIsVeryOld = _userStateService.isStateStale(maxAge: const Duration(minutes: 10));
    final shouldMakeApiCall = stateIsVeryOld;
    
    if (shouldMakeApiCall) {
      
      try {
        final success = await _authController.checkVerificationStatus();
        
        if (success) {
          // Status changed to approved - let AuthController handle routing
          return;
        }
        
        // Still pending - route to pending screen
        initializationStatus.value = 'Awaiting approval...';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.pendingApprovalPage);
        
      } catch (e) {
        initializationStatus.value = 'Awaiting approval...';
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.pendingApprovalPage);
      }
    } else {
      // No API call needed - direct routing to maintain consistent state
      initializationStatus.value = 'Awaiting approval...';
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.pendingApprovalPage);
    }
  }

  /// Handle fully approved state with congratulations flow
  Future<void> _handleFullyApproved() async {
    
    // Always go directly to home page for approved users
    // The approval congratulations are handled in the AuthController when status changes
    initializationStatus.value = 'Welcome back!';
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.homePage);
  }

  /// Handle rejected state
  Future<void> _handleRejected() async {
    initializationStatus.value = 'Registration status...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.rejectionScreen);
  }

  /// Handle expired state
  Future<void> _handleExpired() async {
    initializationStatus.value = 'Registration status...';
    
    await Future.delayed(const Duration(milliseconds: 500));
    Get.offAllNamed(Routes.expiredScreen);
  }

  /// Handle unknown state (fallback)
  Future<void> _handleUnknownState() async {
    
    // Check basic authentication as fallback
    if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
      initializationStatus.value = 'Loading...';
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(Routes.homePage);
    } else {
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
    
    initializationStatus.value = 'Initializing...';
    
    try {
      // Try basic authentication check as fallback
      if (_authController.isLoggedIn.value && _authController.currentUserStore.value != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.homePage);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed(Routes.onboardingPage);
      }
    } catch (e) {
      // Ultimate fallback
      Get.offAllNamed(Routes.onboardingPage);
    }
  }

  // =============================================================================
  // CONNECTIVITY ERROR HANDLERS
  // =============================================================================

  /// Handle offline state with retry option
  Future<void> _handleOfflineState() async {

    // For now, retry after showing message
    initializationStatus.value = 'Retrying in 5 seconds...';
    await Future.delayed(const Duration(seconds: 5));

    // Retry initialization
    await _performSmartInitialization();
  }

  /// Handle server offline state with retry option
  Future<void> _handleServerOfflineState() async {

    // For now, retry after showing message
    initializationStatus.value = 'Retrying connection...';
    await Future.delayed(const Duration(seconds: 5));

    // Retry initialization
    await _performSmartInitialization();
  }

  /// Handle connectivity errors during operations
  Future<void> _handleConnectivityError() async {

    final currentState = _connectivityService.currentState.value;

    if (currentState == ConnectivityState.offline) {
      initializationStatus.value = 'Not connected to the internet';
      await _handleOfflineState();
    } else if (currentState == ConnectivityState.serverOffline) {
      initializationStatus.value = 'Server offline - unable to reach backend';
      await _handleServerOfflineState();
    } else {
      // Unknown connectivity issue - try fallback
      initializationStatus.value = 'Connection issue - trying again...';
      await Future.delayed(const Duration(seconds: 3));
      await _performSmartInitialization();
    }
  }

  // =============================================================================
  // GETTERS FOR UI
  // =============================================================================

  /// Get current initialization status for display
  String get currentStatus => initializationStatus.value;

  /// Check if initialization is still in progress
  bool get isStillInitializing => isInitializing.value;

  /// Get current connectivity state for UI
  ConnectivityState get connectivityState => _connectivityService.currentState.value;

  /// Get connectivity status message
  String get connectivityMessage => _connectivityService.getStatusMessage();

  /// Clear all user data and cache
  Future<void> _clearAllUserData() async {
    try {

      // Clear auth controller data
      await _authController.logout();

      // Clear API service tokens
      final apiService = Get.find<ApiService>();
      await apiService.clearTokens();

      // Clear user state service
      await _userStateService.clearState();
      
    } catch (e) {
    }
  }
}
