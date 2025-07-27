// lib/services/request_service.dart

import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/services/api_service.dart';
import 'package:kind_clock/config/api_config.dart';

/// Enterprise RequestService for TIRI application
/// 
/// Features:
/// - Django backend integration
/// - Complete request lifecycle management
/// - User dashboard statistics
/// - Location-based filtering
/// - Proper error handling and logging
/// - Backward compatibility with existing RequestController
class RequestService extends GetxController {
  // =============================================================================
  // SERVICES
  // =============================================================================
  
  /// Enterprise API service for HTTP requests
  late ApiService _apiService;

  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    
    if (ApiConfig.enableLogging) {
      log('RequestService initialized with Django backend integration', name: 'REQUEST');
    }
  }

  // =============================================================================
  // REQUEST FETCHING METHODS
  // =============================================================================
  
  /// Fetch all community requests from Django backend
  /// 
  /// Replaces: FirebaseStorageService.fetchRequests()
  /// Django API: GET /api/requests/
  Future<List<RequestModel>> fetchRequests() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Fetching community requests from Django API', name: 'REQUEST');
      }

      final response = await _apiService.get('/requests/');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> requestsData = response.data['results'] ?? response.data;
        
        final requests = requestsData
            .map((json) => RequestModel.fromJson(json))
            .toList();
        
        if (ApiConfig.enableLogging) {
          log('Successfully fetched ${requests.length} community requests', name: 'REQUEST');
        }
        
        return requests;
      }
      
      log('Failed to fetch requests: Invalid response', name: 'REQUEST');
      return [];
      
    } catch (e) {
      log('Error fetching requests: $e', name: 'REQUEST');
      return [];
    }
  }

  /// Fetch user's own requests from Django backend
  /// 
  /// Django API: GET /api/requests/?view=my_requests
  Future<List<RequestModel>> fetchMyRequests() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Fetching user requests from Django API', name: 'REQUEST');
      }

      final response = await _apiService.get('/requests/', queryParameters: {
        'view': 'my_requests',
      });
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> requestsData = response.data['results'] ?? response.data;
        
        final requests = requestsData
            .map((json) => RequestModel.fromJson(json))
            .toList();
        
        if (ApiConfig.enableLogging) {
          log('Successfully fetched ${requests.length} user requests', name: 'REQUEST');
        }
        
        return requests;
      }
      
      log('Failed to fetch my requests: Invalid response', name: 'REQUEST');
      return [];
      
    } catch (e) {
      log('Error fetching my requests: $e', name: 'REQUEST');
      return [];
    }
  }

  /// Fetch user dashboard statistics from Django backend
  /// 
  /// Django API: GET /api/dashboard/
  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Fetching dashboard stats from Django API', name: 'REQUEST');
      }

      final response = await _apiService.get('/dashboard/');
      
      if (response.statusCode == 200 && response.data != null) {
        if (ApiConfig.enableLogging) {
          log('Successfully fetched dashboard stats', name: 'REQUEST');
        }
        
        return response.data as Map<String, dynamic>;
      }
      
      log('Failed to fetch dashboard stats: Invalid response', name: 'REQUEST');
      return null;
      
    } catch (e) {
      log('Error fetching dashboard stats: $e', name: 'REQUEST');
      return null;
    }
  }

  // =============================================================================
  // REQUEST MANAGEMENT METHODS
  // =============================================================================
  
  /// Create new request in Django backend
  /// 
  /// Replaces: FirebaseStorageService.createRequest()
  /// Django API: POST /api/requests/
  Future<RequestModel?> createRequest(RequestModel request) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Creating request in Django API: ${request.title}', name: 'REQUEST');
      }

      final response = await _apiService.post(
        '/requests/',
        data: request.toJson(),
      );
      
      if (response.statusCode == 201 && response.data != null) {
        final createdRequest = RequestModel.fromJson(response.data);
        
        if (ApiConfig.enableLogging) {
          log('Successfully created request: ${createdRequest.requestId}', name: 'REQUEST');
        }
        
        return createdRequest;
      }
      
      log('Failed to create request: Invalid response', name: 'REQUEST');
      return null;
      
    } catch (e) {
      log('Error creating request: $e', name: 'REQUEST');
      return null;
    }
  }

  /// Update existing request in Django backend
  /// 
  /// Replaces: FirebaseStorageService.updateRequest()
  /// Django API: PUT /api/requests/{id}/
  Future<bool> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Updating request in Django API: $requestId', name: 'REQUEST');
      }

      final response = await _apiService.put(
        '/requests/$requestId/',
        data: updates,
      );
      
      if (response.statusCode == 200) {
        if (ApiConfig.enableLogging) {
          log('Successfully updated request: $requestId', name: 'REQUEST');
        }
        
        return true;
      }
      
      log('Failed to update request: ${response.statusCode}', name: 'REQUEST');
      return false;
      
    } catch (e) {
      log('Error updating request: $e', name: 'REQUEST');
      return false;
    }
  }

  /// Get specific request details from Django backend
  /// 
  /// Django API: GET /api/requests/{id}/
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Fetching request details from Django API: $requestId', name: 'REQUEST');
      }

      final response = await _apiService.get('/requests/$requestId/');
      
      if (response.statusCode == 200 && response.data != null) {
        final request = RequestModel.fromJson(response.data);
        
        if (ApiConfig.enableLogging) {
          log('Successfully fetched request: ${request.title}', name: 'REQUEST');
        }
        
        return request;
      }
      
      log('Failed to fetch request: Invalid response', name: 'REQUEST');
      return null;
      
    } catch (e) {
      log('Error fetching request: $e', name: 'REQUEST');
      return null;
    }
  }

  // =============================================================================
  // SEARCH AND FILTERING METHODS
  // =============================================================================
  
  /// Search requests with filters
  /// 
  /// Django API: GET /api/requests/?search=...&location=...
  Future<List<RequestModel>> searchRequests({
    String? searchQuery,
    String? location,
    String? status,
    int? limit,
  }) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Searching requests with query: $searchQuery', name: 'REQUEST');
      }

      final queryParameters = <String, dynamic>{};
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParameters['search'] = searchQuery;
      }
      
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      }
      
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      
      if (limit != null) {
        queryParameters['limit'] = limit.toString();
      }

      final response = await _apiService.get(
        '/requests/',
        queryParameters: queryParameters,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> requestsData = response.data['results'] ?? response.data;
        
        final requests = requestsData
            .map((json) => RequestModel.fromJson(json))
            .toList();
        
        if (ApiConfig.enableLogging) {
          log('Found ${requests.length} requests matching search criteria', name: 'REQUEST');
        }
        
        return requests;
      }
      
      log('Failed to search requests: Invalid response', name: 'REQUEST');
      return [];
      
    } catch (e) {
      log('Error searching requests: $e', name: 'REQUEST');
      return [];
    }
  }

  // =============================================================================
  // USER INTERACTION METHODS
  // =============================================================================
  
  /// Accept a request as volunteer
  /// 
  /// Django API: POST /api/requests/{id}/accept/
  Future<bool> acceptRequest(String requestId) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Accepting request: $requestId', name: 'REQUEST');
      }

      final response = await _apiService.post('/requests/$requestId/accept/');
      
      if (response.statusCode == 200) {
        if (ApiConfig.enableLogging) {
          log('Successfully accepted request: $requestId', name: 'REQUEST');
        }
        
        return true;
      }
      
      log('Failed to accept request: ${response.statusCode}', name: 'REQUEST');
      return false;
      
    } catch (e) {
      log('Error accepting request: $e', name: 'REQUEST');
      return false;
    }
  }

  /// Complete a request
  /// 
  /// Django API: POST /api/requests/{id}/complete/
  Future<bool> completeRequest(String requestId) async {
    try {
      if (ApiConfig.enableLogging) {
        log('Completing request: $requestId', name: 'REQUEST');
      }

      final response = await _apiService.post('/requests/$requestId/complete/');
      
      if (response.statusCode == 200) {
        if (ApiConfig.enableLogging) {
          log('Successfully completed request: $requestId', name: 'REQUEST');
        }
        
        return true;
      }
      
      log('Failed to complete request: ${response.statusCode}', name: 'REQUEST');
      return false;
      
    } catch (e) {
      log('Error completing request: $e', name: 'REQUEST');
      return false;
    }
  }

  // =============================================================================
  // USER PROFILE METHODS
  // =============================================================================
  
  /// Get user profile and statistics
  /// 
  /// Django API: GET /api/profile/me/
  Future<UserModel?> getUserProfile() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Fetching user profile from Django API', name: 'REQUEST');
      }

      final response = await _apiService.get('/profile/me/');
      
      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data);
        
        if (ApiConfig.enableLogging) {
          log('Successfully fetched user profile: ${user.email}', name: 'REQUEST');
        }
        
        return user;
      }
      
      log('Failed to fetch user profile: Invalid response', name: 'REQUEST');
      return null;
      
    } catch (e) {
      log('Error fetching user profile: $e', name: 'REQUEST');
      return null;
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Check if RequestService is properly connected to Django
  Future<bool> healthCheck() async {
    try {
      if (ApiConfig.enableLogging) {
        log('Performing RequestService health check', name: 'REQUEST');
      }

      final response = await _apiService.get('/requests/');
      
      final isHealthy = response.statusCode == 200;
      
      if (ApiConfig.enableLogging) {
        log('RequestService health check: ${isHealthy ? "HEALTHY" : "UNHEALTHY"}', name: 'REQUEST');
      }
      
      return isHealthy;
      
    } catch (e) {
      log('RequestService health check failed: $e', name: 'REQUEST');
      return false;
    }
  }

  /// Get service status and statistics
  Map<String, dynamic> getServiceInfo() {
    return {
      'service_name': 'RequestService',
      'backend_type': 'Django',
      'api_base_url': ApiConfig.apiBaseUrl,
      'version': '1.0.0',
      'features': [
        'Community requests',
        'User requests',
        'Dashboard stats',
        'Search and filtering',
        'Request management',
        'User interactions',
      ],
    };
  }
}

// =============================================================================
// REQUEST RESULT CLASSES
// =============================================================================

/// Result class for request operations
class RequestResult {
  final bool isSuccess;
  final RequestModel? request;
  final List<RequestModel>? requests;
  final String message;
  final Map<String, dynamic>? data;

  RequestResult._({
    required this.isSuccess,
    this.request,
    this.requests,
    required this.message,
    this.data,
  });

  /// Create successful result with single request
  factory RequestResult.success({
    RequestModel? request,
    List<RequestModel>? requests,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return RequestResult._(
      isSuccess: true,
      request: request,
      requests: requests,
      message: message,
      data: data,
    );
  }

  /// Create failed result
  factory RequestResult.failure({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return RequestResult._(
      isSuccess: false,
      message: message,
      data: data,
    );
  }

  @override
  String toString() {
    return 'RequestResult(isSuccess: $isSuccess, message: $message, requestCount: ${requests?.length ?? (request != null ? 1 : 0)})';
  }
}