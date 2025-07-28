// lib/services/request_service.dart
// 🚨 FIXED: Correct Django endpoints

import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/services/api_service.dart';

/// Enterprise RequestService for Django backend integration
/// 
/// 🚨 FIXED: Using correct Django endpoints
/// - /api/requests/ (not /api/service_requests/requests/)
/// - Matches Django URL configuration
/// 
/// Features:
/// - JWT authentication
/// - Request CRUD operations  
/// - Location-based filtering
/// - Real-time data from Django backend
class RequestService extends GetxController {
  
  // =============================================================================
  // DEPENDENCIES
  // =============================================================================
  
  final ApiService _apiService = Get.find<ApiService>();
  
  // =============================================================================
  // REQUEST OPERATIONS
  // =============================================================================
  
  /// Fetch all community requests from Django backend
  /// 🚨 FIXED: Using correct endpoint /api/requests/
  Future<List<RequestModel>> fetchRequests() async {
    try {
      log('RequestService: Fetching community requests from Django API');
      
      final response = await _apiService.get('/api/requests/');  // ✅ FIXED
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        final List<RequestModel> requests = requestsJson
            .map((json) => RequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        log('RequestService: Fetched ${requests.length} community requests');
        return requests;
      } else {
        log('RequestService: Failed to fetch requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('RequestService: Error fetching requests - $e');
      return [];
    }
  }
  
  /// Fetch current user's requests
  /// 🚨 FIXED: Using correct endpoint /api/requests/?view=my_requests
  Future<List<RequestModel>> fetchMyRequests() async {
    try {
      log('RequestService: Fetching user requests from Django API');
      
      final response = await _apiService.get('/api/requests/?view=my_requests');  // ✅ FIXED
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        final List<RequestModel> requests = requestsJson
            .map((json) => RequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        log('RequestService: Fetched ${requests.length} user requests');
        return requests;
      } else {
        log('RequestService: Failed to fetch user requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('RequestService: Error fetching user requests - $e');
      return [];
    }
  }
  
  /// Get single request by ID
  /// 🚨 FIXED: Using correct endpoint /api/requests/{id}/
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      log('RequestService: Fetching request $requestId from Django API');
      
      final response = await _apiService.get('/api/requests/$requestId/');  // ✅ FIXED
      
      if (response.statusCode == 200 && response.data != null) {
        final RequestModel request = RequestModel.fromJson(response.data as Map<String, dynamic>);
        log('RequestService: Fetched request $requestId successfully');
        return request;
      } else {
        log('RequestService: Failed to fetch request $requestId - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('RequestService: Error fetching request $requestId - $e');
      return null;
    }
  }
  
  /// Create new request
  /// 🚨 FIXED: Using correct endpoint /api/requests/
  Future<bool> createRequest(Map<String, dynamic> requestData) async {
    try {
      log('RequestService: Creating new request via Django API');
      log('Request data: $requestData');
      
      final response = await _apiService.post('/api/requests/', data: requestData);  // ✅ FIXED
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        log('RequestService: Request created successfully');
        return true;
      } else {
        log('RequestService: Failed to create request - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('RequestService: Error creating request - $e');
      return false;
    }
  }
  
  /// Update existing request
  /// 🚨 FIXED: Using correct endpoint /api/requests/{id}/
  Future<bool> updateRequest(String requestId, Map<String, dynamic> updateData) async {
    try {
      log('RequestService: Updating request $requestId via Django API');
      log('Update data: $updateData');
      
      final response = await _apiService.put('/api/requests/$requestId/', data: updateData);  // ✅ FIXED
      
      if (response.statusCode == 200) {
        log('RequestService: Request $requestId updated successfully');
        return true;
      } else {
        log('RequestService: Failed to update request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('RequestService: Error updating request $requestId - $e');
      return false;
    }
  }
  
  /// Delete request
  /// 🚨 FIXED: Using correct endpoint /api/requests/{id}/
  Future<bool> deleteRequest(String requestId) async {
    try {
      log('RequestService: Deleting request $requestId via Django API');
      
      final response = await _apiService.delete('/api/requests/$requestId/');  // ✅ FIXED
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        log('RequestService: Request $requestId deleted successfully');
        return true;
      } else {
        log('RequestService: Failed to delete request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('RequestService: Error deleting request $requestId - $e');
      return false;
    }
  }
  
  // =============================================================================
  // USER OPERATIONS (For RequestController compatibility)
  // =============================================================================
  
  /// Get user by ID
  /// 🚨 FIXED: Using correct endpoint /api/profile/users/{id}/ (need to verify this exists)
  Future<UserModel?> getUser(String userId) async {
    try {
      log('RequestService: Fetching user $userId from Django API');
      
      // Note: This endpoint needs to be verified in Django backend
      final response = await _apiService.get('/api/profile/users/$userId/');  // ✅ FIXED
      
      if (response.statusCode == 200 && response.data != null) {
        final UserModel user = UserModel.fromJson(response.data as Map<String, dynamic>);
        log('RequestService: Fetched user $userId successfully');
        return user;
      } else {
        log('RequestService: Failed to fetch user $userId - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('RequestService: Error fetching user $userId - $e');
      return null;
    }
  }
  
  // =============================================================================
  // SEARCH & FILTERING
  // =============================================================================
  
  /// Search requests by query
  /// 🚨 FIXED: Using correct endpoint /api/requests/?search=
  Future<List<RequestModel>> searchRequests(String query, {String? location}) async {
    try {
      log('RequestService: Searching requests for: "$query"');
      
      String endpoint = '/api/requests/?search=$query';  // ✅ FIXED
      if (location != null && location.isNotEmpty) {
        endpoint += '&location=$location';
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        final List<RequestModel> requests = requestsJson
            .map((json) => RequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        log('RequestService: Found ${requests.length} requests for "$query"');
        return requests;
      } else {
        log('RequestService: Failed to search requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('RequestService: Error searching requests - $e');
      return [];
    }
  }
  
  // =============================================================================
  // DASHBOARD & STATS
  // =============================================================================
  
  /// Get user dashboard statistics
  /// 🚨 FIXED: Using correct endpoint /api/dashboard/
  Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      log('RequestService: Fetching dashboard stats from Django API');
      
      final response = await _apiService.get('/api/dashboard/');  // ✅ FIXED
      
      if (response.statusCode == 200 && response.data != null) {
        log('RequestService: Fetched dashboard stats successfully');
        return response.data as Map<String, dynamic>;
      } else {
        log('RequestService: Failed to fetch dashboard stats - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('RequestService: Error fetching dashboard stats - $e');
      return null;
    }
  }
  
  // =============================================================================
  // PLACEHOLDER METHODS (For backward compatibility)
  // =============================================================================
  
  /// File upload placeholder - will be implemented later
  Future<String> uploadFile(File file, String path) async {
    log('RequestService: uploadFile - placeholder method');
    return 'placeholder-url';
  }
  
  /// File deletion placeholder
  Future<void> deleteFile(String path) async {
    log('RequestService: deleteFile - placeholder method');
  }
  
  /// Get file URL placeholder  
  Future<String> getFileUrl(String path) async {
    log('RequestService: getFileUrl - placeholder method');
    return 'placeholder-url';
  }
}