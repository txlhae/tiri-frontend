import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';

/// Service for managing account status and routing logic
/// 
/// This service handles:
/// - Local storage of account status
/// - App startup routing decisions
/// - Status expiration checking
/// - Account deletion warnings
class AccountStatusService {
  // =============================================================================
  // SINGLETON PATTERN
  // =============================================================================
  
  static AccountStatusService? _instance;
  static AccountStatusService get instance => _instance ??= AccountStatusService._internal();
  
  factory AccountStatusService() => instance;
  
  AccountStatusService._internal() {
    _initializeService();
  }

  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================
  
  late FlutterSecureStorage _secureStorage;

  // =============================================================================
  // SECURE STORAGE KEYS
  // =============================================================================
  
  static const String _accountStatusKey = 'account_status_cache';
  static const String _lastStatusCheckKey = 'last_status_check';

  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  void _initializeService() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  // =============================================================================
  // ACCOUNT STATUS STORAGE
  // =============================================================================
  
  /// Store account status for offline reference
  Future<void> storeAccountStatus(RegistrationStatusResponse status) async {
    try {
      final statusData = {
        'status': status.accountStatus,
        'next_step': status.nextStep,
        'can_access_app': status.registrationStage.canAccessApp,
        'is_email_verified': status.registrationStage.isEmailVerified,
        'is_approved': status.registrationStage.isApproved,
        'has_referral': status.registrationStage.hasReferral,
        'warning': status.warning?.toJson(),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _secureStorage.write(
        key: _accountStatusKey, 
        value: jsonEncode(statusData),
      );
      
      await _secureStorage.write(
        key: _lastStatusCheckKey,
        value: DateTime.now().toIso8601String(),
      );
      
    } catch (e) {
    }
  }

  /// Get stored account status if still valid (< 1 hour old)
  Future<Map<String, dynamic>?> getStoredAccountStatus() async {
    try {
      final statusString = await _secureStorage.read(key: _accountStatusKey);
      final lastCheckString = await _secureStorage.read(key: _lastStatusCheckKey);
      
      if (statusString == null || lastCheckString == null) {
        return null;
      }
      
      final lastCheck = DateTime.parse(lastCheckString);
      final oneHour = const Duration(hours: 1);
      
      if (DateTime.now().difference(lastCheck) > oneHour) {
        // Status is too old, clear it
        await clearAccountStatus();
        return null;
      }
      
      final statusData = jsonDecode(statusString) as Map<String, dynamic>;
      
      return statusData;
    } catch (e) {
      return null;
    }
  }

  /// Clear stored account status
  Future<void> clearAccountStatus() async {
    try {
      await _secureStorage.delete(key: _accountStatusKey);
      await _secureStorage.delete(key: _lastStatusCheckKey);
    } catch (e) {
    }
  }

  // =============================================================================
  // ROUTING LOGIC
  // =============================================================================
  
  /// Determine the appropriate route based on account status
  String getRouteForStatus(String nextStep) {
    switch (nextStep) {
      case 'verify_email':
        return '/email-verification';
      case 'waiting_for_approval':
        return '/approval-pending';
      case 'approval_rejected':
        return '/approval-rejected';
      case 'complete_profile':
        return '/complete-profile';
      case 'ready':
        return '/home';
      default:
        return '/auth';
    }
  }

  /// Get user-friendly message for account status
  String getStatusMessage(String accountStatus, String nextStep) {
    switch (nextStep) {
      case 'verify_email':
        return 'Please verify your email address to continue.';
      case 'waiting_for_approval':
        return 'Your account is pending approval from your referrer.';
      case 'approval_rejected':
        return 'Your account application was rejected. Please contact your referrer or find a new one.';
      case 'complete_profile':
        return 'Please complete your profile to get started.';
      case 'ready':
        return 'Welcome! Your account is ready to use.';
      default:
        return 'Please complete the registration process.';
    }
  }

  /// Check if account deletion warning should be shown
  bool shouldShowDeletionWarning(AuthWarning? warning) {
    if (warning == null) return false;
    
    try {
      final deletionDate = DateTime.parse(warning.deletionDate);
      final now = DateTime.now();
      final timeUntilDeletion = deletionDate.difference(now);
      
      // Show warning if deletion is within 48 hours
      return timeUntilDeletion.inHours <= 48 && timeUntilDeletion.inHours > 0;
    } catch (e) {
      return false;
    }
  }

  /// Calculate time remaining until deletion
  String getTimeUntilDeletion(AuthWarning warning) {
    try {
      final deletionDate = DateTime.parse(warning.deletionDate);
      final now = DateTime.now();
      final timeUntilDeletion = deletionDate.difference(now);
      
      if (timeUntilDeletion.inDays > 0) {
        return '${timeUntilDeletion.inDays} day${timeUntilDeletion.inDays == 1 ? '' : 's'}';
      } else if (timeUntilDeletion.inHours > 0) {
        return '${timeUntilDeletion.inHours} hour${timeUntilDeletion.inHours == 1 ? '' : 's'}';
      } else if (timeUntilDeletion.inMinutes > 0) {
        return '${timeUntilDeletion.inMinutes} minute${timeUntilDeletion.inMinutes == 1 ? '' : 's'}';
      } else {
        return 'Less than a minute';
      }
    } catch (e) {
      return 'Soon';
    }
  }

  /// Get progress percentage for account setup
  double getSetupProgress(RegistrationStage stage) {
    double progress = 0.0;
    
    // Email verification: 50%
    if (stage.isEmailVerified) {
      progress += 0.5;
    }
    
    // Approval (if has referral): 30%
    if (stage.hasReferral) {
      if (stage.isApproved) {
        progress += 0.3;
      }
    } else {
      // No referral needed, add the 30%
      progress += 0.3;
    }
    
    // Can access app: 20%
    if (stage.canAccessApp) {
      progress += 0.2;
    }
    
    return progress;
  }

  /// Get list of completed and pending setup steps
  Map<String, List<Map<String, dynamic>>> getSetupSteps(RegistrationStage stage) {
    final steps = <Map<String, dynamic>>[
      {
        'key': 'email_verification',
        'label': 'Verify Email',
        'completed': stage.isEmailVerified,
        'current': !stage.isEmailVerified,
      },
    ];
    
    if (stage.hasReferral) {
      steps.add({
        'key': 'approval',
        'label': 'Get Approval',
        'completed': stage.isApproved,
        'current': stage.isEmailVerified && !stage.isApproved,
      });
    }
    
    steps.add({
      'key': 'complete',
      'label': 'Complete Setup',
      'completed': stage.canAccessApp,
      'current': stage.isEmailVerified && (!stage.hasReferral || stage.isApproved) && !stage.canAccessApp,
    });
    
    final completed = steps.where((step) => step['completed'] == true).toList();
    final pending = steps.where((step) => step['completed'] == false).toList();
    
    return {
      'completed': completed,
      'pending': pending,
      'all': steps,
    };
  }
}