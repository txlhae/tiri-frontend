/// User State Management Service for TIRI Application
/// 
/// Handles persistent storage of user approval status to optimize app performance
/// and provide correct routing without unnecessary API calls.
/// 
/// This service eliminates 401 errors for pending approval users and improves
/// startup performance for approved users.
library;

import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// User approval state enumeration
enum UserApprovalState {
  /// User not logged in
  notLoggedIn,
  
  /// User logged in but email not verified
  emailUnverified,
  
  /// Email verified but pending approval from referrer
  emailVerifiedPendingApproval,
  
  /// Fully approved and can access all app features
  fullyApproved,
  
  /// Registration rejected by referrer
  rejected,
  
  /// Approval request expired
  expired,
  
  /// Unknown state (corrupted data or error)
  unknown,
}

/// Extension to convert enum to string and vice versa
extension UserApprovalStateExtension on UserApprovalState {
  String get value {
    switch (this) {
      case UserApprovalState.notLoggedIn:
        return 'not_logged_in';
      case UserApprovalState.emailUnverified:
        return 'email_unverified';
      case UserApprovalState.emailVerifiedPendingApproval:
        return 'email_verified_pending_approval';
      case UserApprovalState.fullyApproved:
        return 'fully_approved';
      case UserApprovalState.rejected:
        return 'rejected';
      case UserApprovalState.expired:
        return 'expired';
      case UserApprovalState.unknown:
        return 'unknown';
    }
  }
  
  static UserApprovalState fromString(String value) {
    switch (value) {
      case 'not_logged_in':
        return UserApprovalState.notLoggedIn;
      case 'email_unverified':
        return UserApprovalState.emailUnverified;
      case 'email_verified_pending_approval':
        return UserApprovalState.emailVerifiedPendingApproval;
      case 'fully_approved':
        return UserApprovalState.fullyApproved;
      case 'rejected':
        return UserApprovalState.rejected;
      case 'expired':
        return UserApprovalState.expired;
      default:
        return UserApprovalState.unknown;
    }
  }
}

/// User State Data Container
class UserStateData {
  final UserApprovalState state;
  final DateTime lastUpdated;
  final String? userId;
  final bool hasShownCongratulations;
  final String? referrerName;
  final String? rejectionReason;
  
  const UserStateData({
    required this.state,
    required this.lastUpdated,
    this.userId,
    this.hasShownCongratulations = false,
    this.referrerName,
    this.rejectionReason,
  });
  
  Map<String, dynamic> toJson() => {
    'state': state.value,
    'lastUpdated': lastUpdated.toIso8601String(),
    'userId': userId,
    'hasShownCongratulations': hasShownCongratulations,
    'referrerName': referrerName,
    'rejectionReason': rejectionReason,
  };
  
  factory UserStateData.fromJson(Map<String, dynamic> json) => UserStateData(
    state: UserApprovalStateExtension.fromString(json['state'] ?? 'unknown'),
    lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    userId: json['userId'],
    hasShownCongratulations: json['hasShownCongratulations'] ?? false,
    referrerName: json['referrerName'],
    rejectionReason: json['rejectionReason'],
  );
  
  UserStateData copyWith({
    UserApprovalState? state,
    DateTime? lastUpdated,
    String? userId,
    bool? hasShownCongratulations,
    String? referrerName,
    String? rejectionReason,
  }) => UserStateData(
    state: state ?? this.state,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    userId: userId ?? this.userId,
    hasShownCongratulations: hasShownCongratulations ?? this.hasShownCongratulations,
    referrerName: referrerName ?? this.referrerName,
    rejectionReason: rejectionReason ?? this.rejectionReason,
  );
}

/// Singleton service for managing user approval state
class UserStateService {
  static UserStateService? _instance;
  static UserStateService get instance => _instance ??= UserStateService._internal();
  
  factory UserStateService() => instance;
  UserStateService._internal();
  
  // =============================================================================
  // CONSTANTS
  // =============================================================================
  
  static const String _stateKey = 'user_approval_state';
  static const String _logTag = 'USER_STATE';
  
  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================
  
  UserStateData? _currentState;
  
  // =============================================================================
  // PUBLIC METHODS
  // =============================================================================
  
  /// Initialize the service and load stored state
  Future<void> initialize() async {
    try {
      await _loadStateFromStorage();
      log('🚀 UserStateService: Initialized successfully', name: _logTag);
      log('   - Current state: ${_currentState?.state.value ?? 'none'}', name: _logTag);
    } catch (e) {
      log('❌ UserStateService: Initialization failed: $e', name: _logTag);
    }
  }
  
  /// Get current user approval state
  UserStateData? get currentState => _currentState;
  
  /// Get current user approval state enum
  UserApprovalState get currentApprovalState => _currentState?.state ?? UserApprovalState.notLoggedIn;
  
  /// Check if user is fully approved (can access all features)
  bool get isFullyApproved => currentApprovalState == UserApprovalState.fullyApproved;
  
  /// Check if user needs to show congratulations
  bool get shouldShowCongratulations => 
      currentApprovalState == UserApprovalState.fullyApproved && 
      (_currentState?.hasShownCongratulations == false);
  
  /// Update user state with new data
  Future<void> updateState(UserApprovalState newState, {
    String? userId,
    String? referrerName,
    String? rejectionReason,
    bool? hasShownCongratulations,
  }) async {
    try {
      log('🔄 UserStateService: Updating state from ${currentApprovalState.value} to ${newState.value}', name: _logTag);
      
      _currentState = UserStateData(
        state: newState,
        lastUpdated: DateTime.now(),
        userId: userId ?? _currentState?.userId,
        hasShownCongratulations: hasShownCongratulations ?? _currentState?.hasShownCongratulations ?? false,
        referrerName: referrerName ?? _currentState?.referrerName,
        rejectionReason: rejectionReason,
      );
      
      await _saveStateToStorage();
      log('✅ UserStateService: State updated successfully', name: _logTag);
      
    } catch (e) {
      log('❌ UserStateService: Failed to update state: $e', name: _logTag);
    }
  }
  
  /// Mark congratulations as shown to prevent repeated display
  Future<void> markCongratulationsShown() async {
    if (_currentState != null) {
      await updateState(
        _currentState!.state,
        hasShownCongratulations: true,
      );
    }
  }
  
  /// Clear all state data (used during logout)
  Future<void> clearState() async {
    try {
      log('🧹 UserStateService: Clearing all state data', name: _logTag);
      
      _currentState = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stateKey);
      
      log('✅ UserStateService: State cleared successfully', name: _logTag);
      
    } catch (e) {
      log('❌ UserStateService: Failed to clear state: $e', name: _logTag);
    }
  }
  
  /// Determine if API call is needed based on current state
  bool shouldMakeVerificationApiCall() {
    final state = currentApprovalState;
    
    // Only make API call for pending approval users
    final needsApiCall = state == UserApprovalState.emailVerifiedPendingApproval;
    
    log('🔍 UserStateService: API call needed? $needsApiCall (state: ${state.value})', name: _logTag);
    return needsApiCall;
  }
  
  /// Get appropriate route based on current state
  String getRouteForCurrentState() {
    final state = currentApprovalState;
    String route;
    
    switch (state) {
      case UserApprovalState.notLoggedIn:
        route = '/login';
        break;
      case UserApprovalState.emailUnverified:
        route = '/emailVerification';
        break;
      case UserApprovalState.emailVerifiedPendingApproval:
        route = '/pendingApproval';
        break;
      case UserApprovalState.fullyApproved:
        route = '/home';
        break;
      case UserApprovalState.rejected:
        route = '/rejection';
        break;
      case UserApprovalState.expired:
        route = '/expired';
        break;
      case UserApprovalState.unknown:
      default:
        route = '/login';
        break;
    }
    
    log('🗺️  UserStateService: Route for state ${state.value}: $route', name: _logTag);
    return route;
  }
  
  /// Update state based on API response from verification-status endpoint
  Future<void> updateStateFromApiResponse(Map<String, dynamic> response) async {
    try {
      final isVerified = response['is_verified'] == true;
      final approvalStatus = response['approval_status'] ?? 'unknown';
      final autoLogin = response['auto_login'] == true;
      final userData = response['user'] ?? {};
      
      log('📡 UserStateService: Processing API response:', name: _logTag);
      log('   - is_verified: $isVerified', name: _logTag);
      log('   - approval_status: $approvalStatus', name: _logTag);
      log('   - auto_login: $autoLogin', name: _logTag);
      
      UserApprovalState newState;
      String? referrerName;
      String? rejectionReason;
      
      if (!isVerified) {
        // 🚨 CRITICAL FIX: Prevent downgrading verified users due to API inconsistency
        // Only downgrade to emailUnverified if current state is lower than emailVerifiedPendingApproval
        final currentState = currentApprovalState;
        
        if (currentState == UserApprovalState.emailVerifiedPendingApproval || 
            currentState == UserApprovalState.fullyApproved) {
          // Don't downgrade already verified users - assume API response is stale/incorrect
          log('⚠️ UserStateService: API says not verified but user is already verified. Keeping current state.', name: _logTag);
          return; // Don't update state - maintain current verified status
        } else {
          // Safe to set as unverified
          newState = UserApprovalState.emailUnverified;
        }
      } else {
        switch (approvalStatus) {
          case 'pending':
            newState = UserApprovalState.emailVerifiedPendingApproval;
            referrerName = userData['referred_by_name'] ?? userData['referredByName'];
            break;
          case 'approved':
            newState = UserApprovalState.fullyApproved;
            break;
          case 'rejected':
            newState = UserApprovalState.rejected;
            rejectionReason = userData['rejection_reason'] ?? userData['rejectionReason'];
            break;
          case 'expired':
            newState = UserApprovalState.expired;
            break;
          default:
            newState = UserApprovalState.unknown;
            break;
        }
      }
      
      await updateState(
        newState,
        userId: userData['id'] ?? userData['userId'],
        referrerName: referrerName,
        rejectionReason: rejectionReason,
      );
      
    } catch (e) {
      log('❌ UserStateService: Failed to process API response: $e', name: _logTag);
    }
  }
  
  /// Check if state data is stale and might need refresh
  bool isStateStale({Duration maxAge = const Duration(hours: 1)}) {
    if (_currentState == null) return true;
    
    final age = DateTime.now().difference(_currentState!.lastUpdated);
    final isStale = age > maxAge;
    
    log('⏰ UserStateService: State age: ${age.inMinutes}min, stale: $isStale', name: _logTag);
    return isStale;
  }
  
  // =============================================================================
  // PRIVATE METHODS
  // =============================================================================
  
  /// Load state from persistent storage
  Future<void> _loadStateFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      
      if (stateJson != null) {
        final stateMap = jsonDecode(stateJson) as Map<String, dynamic>;
        _currentState = UserStateData.fromJson(stateMap);
        log('📱 UserStateService: State loaded from storage', name: _logTag);
        log('   - State: ${_currentState!.state.value}', name: _logTag);
        log('   - Last updated: ${_currentState!.lastUpdated}', name: _logTag);
      } else {
        log('ℹ️  UserStateService: No stored state found', name: _logTag);
      }
      
    } catch (e) {
      log('❌ UserStateService: Failed to load state from storage: $e', name: _logTag);
      // Clear corrupted data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_stateKey);
        _currentState = null;
      } catch (_) {}
    }
  }
  
  /// Save current state to persistent storage
  Future<void> _saveStateToStorage() async {
    try {
      if (_currentState == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(_currentState!.toJson());
      await prefs.setString(_stateKey, stateJson);
      
      log('💾 UserStateService: State saved to storage', name: _logTag);
      
    } catch (e) {
      log('❌ UserStateService: Failed to save state to storage: $e', name: _logTag);
    }
  }
}