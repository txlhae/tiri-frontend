// lib/services/auth_guard.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/auth_service.dart';

/// 🔒 AuthGuard - Critical Security Service
///
/// Prevents authentication bypass by enforcing verification/approval status
/// before allowing access to protected screens.
///
/// Features:
/// - Real-time verification status validation
/// - Automatic redirect to appropriate screen based on user state
/// - Prevents unverified/unapproved users from accessing home page
/// - Synchronizes local and backend user state
class AuthGuard {
  static AuthGuard? _instance;
  static AuthGuard get instance => _instance ??= AuthGuard._internal();

  AuthGuard._internal();

  /// 🚨 CRITICAL: Validate user access before showing protected screens
  ///
  /// Returns true if user should have access, false if they should be redirected
  /// Automatically redirects to appropriate screen if access denied
  static Future<bool> validateAccess({
    required String attemptedRoute,
    bool showSnackbar = true,
    bool duringInitialization = false,
  }) async {
    try {
      

      final authController = Get.find<AuthController>();
      final authService = Get.find<AuthService>();

      // Check if user is logged in with tokens
      if (!authController.isLoggedIn.value || authController.currentUserStore.value == null) {
        
        if (!duringInitialization) {
          _redirectToLogin();
        }
        return false;
      }

      final user = authController.currentUserStore.value!;
      
      
      
      

      // 🚨 CRITICAL CHECK: Both email verified AND referrer approved required for home access
      if (attemptedRoute == Routes.homePage || _isProtectedRoute(attemptedRoute)) {
        if (!user.isVerified) {
          
          if (!duringInitialization) {
            _redirectToEmailVerification('Email verification required');
          }
          return false;
        }

        if (!user.isApproved) {
          
          if (!duringInitialization) {
            _redirectToPendingApproval('Referrer approval required');
          }
          return false;
        }

        // Double-check with backend to ensure state is current
        try {
          
          final statusResult = await authService.checkVerificationStatus();

          final backendVerified = statusResult['is_verified'] == true;
          final backendApproved = statusResult['is_approved'] == true || statusResult['approval_status'] == 'approved';

          // If backend shows different state, sync local state
          if (backendVerified != user.isVerified || backendApproved != user.isApproved) {
            
            
            

            // Update local user state to match backend
            final updatedUser = user.copyWith(
              isVerified: backendVerified,
              isApproved: backendApproved,
            );
            authController.currentUserStore.value = updatedUser;
            await authController.saveUserToStorage(updatedUser);

            // Recheck access with updated state
            if (!backendVerified) {
              if (!duringInitialization) {
                _redirectToEmailVerification('Email verification required');
              }
              return false;
            }
            if (!backendApproved) {
              if (!duringInitialization) {
                _redirectToPendingApproval('Referrer approval required');
              }
              return false;
            }
          }
        } catch (e) {
          
          // Continue with local state if backend check fails
        }
      }

      
      return true;

    } catch (e) {
      
      if (!duringInitialization) {
        _redirectToLogin();
      }
      return false;
    }
  }

  /// Check if route requires full authentication (both verified + approved)
  static bool _isProtectedRoute(String route) {
    final protectedRoutes = [
      Routes.homePage,
      Routes.profilePage,
      // Add other protected routes as needed
    ];

    return protectedRoutes.contains(route);
  }

  /// Redirect to login page
  static void _redirectToLogin() {
    // 🚨 FIX: Delay navigation to ensure Get context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          'Authentication Required',
          'Please log in to continue',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color.fromRGBO(176, 48, 48, 1),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.offAllNamed(Routes.loginPage);
      } catch (e) {
        
        // Fallback: Just navigate without snackbar
        try {
          Get.offAllNamed(Routes.loginPage);
        } catch (e2) {
          
        }
      }
    });
  }

  /// Redirect to email verification page
  static void _redirectToEmailVerification(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          'Email Verification Required',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.offAllNamed(Routes.emailVerificationPage);
      } catch (e) {
        
        try {
          Get.offAllNamed(Routes.emailVerificationPage);
        } catch (e2) {
          
        }
      }
    });
  }

  /// Redirect to pending approval page
  static void _redirectToPendingApproval(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          'Approval Pending',
          message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.offAllNamed(Routes.pendingApprovalPage);
      } catch (e) {
        
        try {
          Get.offAllNamed(Routes.pendingApprovalPage);
        } catch (e2) {
          
        }
      }
    });
  }

  /// Force refresh user state from backend
  static Future<void> refreshUserState() async {
    try {
      

      final authController = Get.find<AuthController>();
      await authController.refreshUserProfile();

      
    } catch (e) {
      
    }
  }
}
