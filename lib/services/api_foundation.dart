// API Foundation Initialization - Phase 1  
// Call this during app startup to initialize the HTTP service layer

import 'package:flutter/foundation.dart';
import 'api/api_client.dart';
import '../config/api_config.dart';

/// Initialize the API foundation during app startup
/// Call this method in your main.dart or app initialization
class ApiFoundationInitializer {
  
  /// Initialize API client with default configuration
  static void initialize({
    String? customBaseUrl,
    String? authToken,
    bool enableRetry = true,
    int maxRetries = 3,
  }) {
    try {
      // Initialize API client
      ApiClient.initialize(
        baseUrl: customBaseUrl ?? ApiConfig.apiBaseUrl,
        authToken: authToken,
        enableRetry: enableRetry,
        maxRetries: maxRetries,
      );
      
      if (kDebugMode) {
      }
      
    } catch (e) {
      // Error handled silently
      if (kDebugMode) {
      }
      rethrow;
    }
  }
  
  /// Initialize with authentication token
  static void initializeWithAuth(String authToken) {
    initialize(authToken: authToken);
  }
  
  /// Set authentication token after initialization
  static void setAuthToken(String token) {
    ApiClient.setAuthToken(token);
    if (kDebugMode) {
    }
  }
  
  /// Clear authentication token
  static void clearAuthToken() {
    ApiClient.setAuthToken(null);
    if (kDebugMode) {
    }
  }
  
  /// Check if API client is ready
  static bool get isReady => ApiClient.isInitialized;
  
  /// Get current configuration status
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': ApiClient.isInitialized,
      'base_url': ApiClient.baseUrl,
      'environment': ApiConfig.environment,
      'has_auth_token': ApiClient.authToken != null,
    };
  }
}

/// Example usage in main.dart:
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize API Foundation
///   ApiFoundationInitializer.initialize();
///   
///   runApp(MyApp());
/// }
/// ```
/// 
/// Example usage with authentication:
/// 
/// ```dart
/// // After user login
/// final token = await authService.login(email, password);
/// ApiFoundationInitializer.setAuthToken(token);
/// ```
