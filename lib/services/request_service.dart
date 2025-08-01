// lib/services/request_service.dart
// 🚨 FIXED: Django field mapping adapter for correct JSON parsing
// Prompt 33.1 - CRITICAL FIX: Changed PUT to PATCH for status updates

import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:kind_clock/models/category_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/services/api_service.dart';

/// Enterprise RequestService with Django Field Mapping
/// 
/// 🚨 SOLUTION: Transforms Django JSON to Flutter RequestModel format
/// - Maps Django "id" → Flutter "requestId"
/// - Maps Django "requester" → Flutter "userId" 
/// - Maps Django "volunteers_needed" → Flutter "numberOfPeople"
/// - Handles Django datetime formats → Flutter DateTime
/// 
/// Features:
/// - JWT authentication
/// - Request CRUD operations  
/// - Location-based filtering
/// - Real-time data from Django backend
/// - Django-to-Flutter JSON transformation
class RequestService extends GetxController {
  
  // =============================================================================
  // DEPENDENCIES
  // =============================================================================
  
  final ApiService _apiService = Get.find<ApiService>();
  
  // =============================================================================
  // 🚨 DJANGO FIELD MAPPING SOLUTION
  // =============================================================================
  
  /// Transform Django JSON response to Flutter RequestModel format
  /// 🎯 CORE FIX: Maps Django field names to Flutter expected field names
  Map<String, dynamic> _mapDjangoToFlutter(Map<String, dynamic> djangoJson) {
    try {
      // 🔍 Debug: Log original Django structure
      log('🔄 MAPPING Django JSON: ${djangoJson.keys.toList()}');
      
      // 📋 Django → Flutter Field Mapping
      final flutterJson = <String, dynamic>{
        // Core ID mapping
        'requestId': djangoJson['id']?.toString() ?? '',
        'userId': _extractUserId(djangoJson),
        
        // Content fields (likely same names)
        'title': djangoJson['title'] ?? '',
        'description': djangoJson['description'] ?? '',
        'location': _buildLocationString(djangoJson),
        
        // DateTime fields (handle Django format)
        'timestamp': _parseDjangoDateTime(djangoJson['created_at'] ?? djangoJson['timestamp']),
        'requestedTime': _parseDjangoDateTime(djangoJson['date_needed'] ?? djangoJson['requested_time']),
        
        // Status mapping
        'status': _mapDjangoStatus(djangoJson['status']),
        
        // Volunteer/People mapping
        'numberOfPeople': djangoJson['volunteers_needed'] ?? djangoJson['number_of_people'] ?? 1,
        'hoursNeeded': djangoJson['estimated_hours'] ?? djangoJson['hours_needed'] ?? 1,
        
        // User arrays (accepted volunteers)
        'acceptedUser': _mapAcceptedUsers(djangoJson),
        'feedbackList': [], // Will be populated later if needed
        
        // Include requester data for extension to parse
        'requester': djangoJson['requester'],
        
        // 🎯 CRITICAL: Preserve user_request_status for volunteer workflow
        'user_request_status': djangoJson['user_request_status'],
      };
      
      log('✅ MAPPED to Flutter: ${flutterJson.keys.toList()}');
      return flutterJson;
      
    } catch (e) {
      log('❌ MAPPING ERROR: $e');
      log('Django JSON structure: $djangoJson');
      // Return minimal valid structure to prevent crashes
      return _createFallbackRequest(djangoJson);
    }
  }
  
  /// Extract user ID from Django response
  String _extractUserId(Map<String, dynamic> djangoJson) {
    // Try multiple possible Django field structures
    if (djangoJson['requester'] is Map) {
      return djangoJson['requester']['id']?.toString() ?? '';
    }
    if (djangoJson['user'] is Map) {
      return djangoJson['user']['id']?.toString() ?? '';
    }
    return djangoJson['user_id']?.toString() ?? 
           djangoJson['requester_id']?.toString() ?? '';
  }
  
  /// Build location string from Django address components
  String _buildLocationString(Map<String, dynamic> djangoJson) {
    List<String> locationParts = [];
    
    // Add address if available
    if (djangoJson['address'] != null && djangoJson['address'].toString().isNotEmpty) {
      locationParts.add(djangoJson['address'].toString());
    }
    
    // Add city if available
    if (djangoJson['city'] != null && djangoJson['city'].toString().isNotEmpty) {
      locationParts.add(djangoJson['city'].toString());
    }
    
    // Add state if available
    if (djangoJson['state'] != null && djangoJson['state'].toString().isNotEmpty) {
      locationParts.add(djangoJson['state'].toString());
    }
    
    // Join with commas, or use fallback
    String location = locationParts.join(', ');
    
    // Fallback to legacy location field or default
    if (location.isEmpty) {
      location = djangoJson['location']?.toString() ?? 'Location not specified';
    }
    
    return location;
  }
  
  /// Parse Django datetime strings to Flutter DateTime
  String _parseDjangoDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now().toIso8601String();
    }
    
    try {
      if (dateValue is String) {
        // Handle Django datetime format
        final dateTime = DateTime.parse(dateValue);
        return dateTime.toIso8601String();
      }
      return DateTime.now().toIso8601String();
    } catch (e) {
      log('⚠️ DateTime parse error: $e');
      return DateTime.now().toIso8601String();
    }
  }
  
  /// Map Django status to Flutter RequestStatus
  String _mapDjangoStatus(dynamic status) {
    if (status == null) return 'pending';
    
    final statusStr = status.toString().toLowerCase();
    
    // Django → Flutter status mapping
    switch (statusStr) {
      case 'open':
      case 'pending':
        return 'pending';
      case 'in_progress':
      case 'inprogress':
        return 'inprogress';
      case 'completed':
      case 'complete':
        return 'complete';
      case 'cancelled':
        return 'cancelled';
      case 'expired':
        return 'expired';
      default:
        return 'pending';
    }
  }
  
  /// Map accepted users/volunteers from Django format
  List<Map<String, dynamic>> _mapAcceptedUsers(Map<String, dynamic> djangoJson) {
    try {
      // Handle various Django volunteer structures
      if (djangoJson['volunteers_assigned'] is List) {
        return (djangoJson['volunteers_assigned'] as List)
            .map((v) => _mapDjangoUserToFlutter(v))
            .toList();
      }
      if (djangoJson['volunteers'] is List) {
        return (djangoJson['volunteers'] as List)
            .map((v) => _mapDjangoUserToFlutter(v))
            .toList();
      }
      if (djangoJson['accepted_users'] is List) {
        return (djangoJson['accepted_users'] as List)
            .map((v) => _mapDjangoUserToFlutter(v))
            .toList();
      }
      return [];
    } catch (e) {
      log('⚠️ Error mapping accepted users: $e');
      return [];
    }
  }
  
  /// Map Django user object to Flutter UserModel format
  Map<String, dynamic> _mapDjangoUserToFlutter(dynamic djangoUser) {
    if (djangoUser is! Map) return {};
    
    final userMap = djangoUser as Map<String, dynamic>;
    return {
      'userId': userMap['id']?.toString() ?? '',
      'username': userMap['username'] ?? userMap['full_name'] ?? 'Unknown', // Fixed: Use 'username' key
      'email': userMap['email']?.toString() ?? '', // Fixed: Handle null email properly
      'imageUrl': userMap['profile_image_url'] ?? userMap['profile_image'],
      // Add other UserModel fields as needed
    };
  }
  
  /// Create fallback request when mapping fails
  Map<String, dynamic> _createFallbackRequest(Map<String, dynamic> originalJson) {
    return {
      'requestId': originalJson['id']?.toString() ?? 'unknown',
      'userId': 'unknown',
      'title': originalJson['title'] ?? 'Unknown Request',
      'description': originalJson['description'] ?? 'No description available',
      'location': originalJson['location'] ?? 'Unknown location',
      'timestamp': DateTime.now().toIso8601String(),
      'requestedTime': DateTime.now().add(Duration(days: 1)).toIso8601String(),
      'status': 'pending',
      'numberOfPeople': 1,
      'hoursNeeded': 1,
      'acceptedUser': [],
      'feedbackList': [],
    };
  }
  
  // =============================================================================
  // REQUEST OPERATIONS (Enhanced with Field Mapping)
  // =============================================================================
  
  /// Fetch all community requests from Django backend
  /// 🚨 ENHANCED: Now includes Django field mapping
  Future<List<RequestModel>> fetchRequests() async {
    try {
      log('🔍 RequestService: Fetching community requests from Django API');
      
      final response = await _apiService.get('/api/requests/');
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        log('📥 Raw Django requests: ${requestsJson.length}');
        
        // 🎯 APPLY FIELD MAPPING
        final List<RequestModel> requests = requestsJson
            .map((djangoJson) {
              final flutterJson = _mapDjangoToFlutter(djangoJson as Map<String, dynamic>);
              return RequestModelExtension.fromJsonWithRequester(flutterJson);
            })
            .toList();
        
        log('✅ RequestService: Mapped ${requests.length} community requests');
        log('📋 Sample mapped request: ${requests.isNotEmpty ? requests[0].title : 'None'}');
        
        return requests;
      } else {
        log('❌ RequestService: Failed to fetch requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error fetching requests - $e');
      return [];
    }
  }
  
  /// Fetch current user's requests
  /// 🚨 ENHANCED: Now includes Django field mapping  
  Future<List<RequestModel>> fetchMyRequests() async {
    try {
      log('🔍 RequestService: Fetching user requests from Django API');
      
      final response = await _apiService.get('/api/requests/?view=my_requests');
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        log('📥 Raw Django user requests: ${requestsJson.length}');
        
        // 🎯 APPLY FIELD MAPPING
        final List<RequestModel> requests = requestsJson
            .map((djangoJson) {
              final flutterJson = _mapDjangoToFlutter(djangoJson as Map<String, dynamic>);
              return RequestModelExtension.fromJsonWithRequester(flutterJson);
            })
            .toList();
        
        log('✅ RequestService: Mapped ${requests.length} user requests');
        return requests;
      } else {
        log('❌ RequestService: Failed to fetch user requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error fetching user requests - $e');
      return [];
    }
  }
  
  /// Get single request by ID
  /// 🚨 ENHANCED: Now includes Django field mapping
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      log('🔍 RequestService: Fetching request $requestId from Django API');
      
      final response = await _apiService.get('/api/requests/$requestId/');
      
      // Enhanced debug logging for API response
      print('🌐 API URL: ${response.requestOptions.uri}');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Headers: ${response.headers}');
      print('🌐 Raw Response Data Type: ${response.data.runtimeType}');
      print('🌐 Raw Response: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        try {
          // 🔍 DEBUG: Log raw Django response
          log('🔍 DEBUG: Raw Django response for request $requestId:');
          log('${response.data}');
          
          // Check if user_request_status exists in response
          final rawData = response.data as Map<String, dynamic>;
          log('🔍 DEBUG: user_request_status in response: ${rawData.containsKey('user_request_status')}');
          if (rawData.containsKey('user_request_status')) {
            final userRequestStatus = rawData['user_request_status'] as Map<String, dynamic>?;
            log('🔍 DEBUG: user_request_status value: ${rawData['user_request_status']}');
            log('🔍 DEBUG: ALL user_request_status KEYS: ${userRequestStatus?.keys.toList()}');
            log('🔍 DEBUG: message_content in user_request_status: ${userRequestStatus?.containsKey('message_content')}');
            if (userRequestStatus?.containsKey('message_content') == true) {
              log('🔍 DEBUG: message_content value: "${userRequestStatus!['message_content']}"');
            }
            // Check other possible message field names
            final possibleMessageFields = ['message_to_requester', 'volunteer_message', 'message', 'user_message'];
            for (final field in possibleMessageFields) {
              if (userRequestStatus?.containsKey(field) == true) {
                log('🔍 DEBUG: $field value: "${userRequestStatus![field]}"');
              }
            }
          }
          
          // 🎯 APPLY FIELD MAPPING
          print('🔄 Applying Django to Flutter field mapping...');
          final flutterJson = _mapDjangoToFlutter(response.data as Map<String, dynamic>);
          print('✅ Field mapping completed successfully');
          print('🔍 Mapped JSON: $flutterJson');
          
          print('🏗️ Creating RequestModel from mapped JSON...');
          final RequestModel request = RequestModelExtension.fromJsonWithRequester(flutterJson);
          print('✅ RequestModel created successfully');
          
          log('✅ RequestService: Mapped request $requestId successfully');
          return request;
          
        } catch (parseError) {
          print('❌ JSON Parse Error: $parseError');
          print('❌ Parse Error Stack Trace: ${parseError.toString()}');
          print('❌ Failed to parse response data: ${response.data}');
          return null;
        }
      } else {
        log('❌ RequestService: Failed to fetch request $requestId - Status: ${response.statusCode}');
        print('❌ Response body: ${response.data}');
        return null;
      }
    } catch (e) {
      log('💥 RequestService: Error fetching request $requestId - $e');
      print('💥 Full error stack trace: $e');
      return null;
    }
  }
  
  /// Create new request
  /// 🚨 FIXED: Using correct endpoint /api/requests/
  Future<bool> createRequest(Map<String, dynamic> requestData) async {
    try {
      log('📝 RequestService: Creating new request via Django API');
      log('Request data: $requestData');
      
      final response = await _apiService.post('/api/requests/', data: requestData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        log('✅ RequestService: Created request successfully');
        return true;
      } else {
        log('❌ RequestService: Failed to create request - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error creating request - $e');
      print('🚨 [SERVICE DEBUG] Error creating request - $e');
      
      // 🚨 CRITICAL: Extract DioException details to see actual Django errors
      if (e is DioException) {
        print('🚨 [SERVICE DEBUG] DioException detected!');
        print('🚨 [SERVICE DEBUG] HTTP Status: ${e.response?.statusCode}');
        print('🚨 [SERVICE DEBUG] Django Response: ${e.response?.data}');
        print('🚨 [SERVICE DEBUG] Request URL: ${e.requestOptions.path}');
        print('🚨 [SERVICE DEBUG] Request Data: ${e.requestOptions.data}');
        
        // Extract field-specific errors from Django
        if (e.response?.data is Map) {
          final errors = e.response!.data as Map;
          print('🚨 [SERVICE DEBUG] === DJANGO FIELD ERRORS ===');
          errors.forEach((field, error) {
            print('🚨 [SERVICE DEBUG] Field "$field": $error');
          });
        }
      }
      
      return false;
    }
  }
  
  /// Update existing request
  /// 🚨 CRITICAL FIX: Changed PUT to PATCH for partial updates
  Future<bool> updateRequest(String requestId, Map<String, dynamic> requestData) async {
    try {
      log('🔄 RequestService: Updating request $requestId via Django API (PATCH)');
      log('Update data: $requestData');
      
      // 🚨 KEY FIX: Use PATCH instead of PUT for partial updates
      final response = await _apiService.patch('/api/requests/$requestId/', data: requestData);
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Updated request $requestId successfully via PATCH');
        return true;
      } else {
        log('❌ RequestService: Failed to update request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error updating request $requestId - $e');
      return false;
    }
  }
  
  /// Delete request
  /// 🚨 FIXED: Using correct endpoint /api/requests/{id}/
  Future<bool> deleteRequest(String requestId) async {
    try {
      log('🗑️ RequestService: Deleting request $requestId via Django API');
      
      final response = await _apiService.delete('/api/requests/$requestId/');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        log('✅ RequestService: Deleted request $requestId successfully');
        return true;
      } else {
        log('❌ RequestService: Failed to delete request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error deleting request $requestId - $e');
      return false;
    }
  }
  
  /// Request to volunteer for a request
  /// Sends a volunteer request to the Django backend
  Future<bool> requestToVolunteer(String requestId, String message) async {
    try {
      log('🙋 RequestService: Requesting to volunteer for request $requestId via Django API');
      log('Message to requester: "$message"');
      log('Message length: ${message.length} characters');
      
      final requestData = {'message_to_requester': message};
      log('🔍 SENDING DATA: $requestData');
      
      // Also try alternative field names that the backend might expect
      final alternativeData = {
        'message_to_requester': message,
        'message_content': message,
        'volunteer_message': message,
        'message': message,
      };
      log('🔍 TRYING ALTERNATIVE DATA FORMAT: $alternativeData');
      
      final response = await _apiService.post(
        '/api/requests/$requestId/accept/', 
        data: alternativeData
      );
      
      log('🌐 RESPONSE STATUS: ${response.statusCode}');
      log('🌐 RESPONSE DATA: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ RequestService: Successfully requested to volunteer for request $requestId');
        return true;
      } else {
        log('❌ RequestService: Failed to request volunteer for request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error requesting to volunteer for request $requestId - $e');
      return false;
    }
  }
  
  /// Cancel volunteer request for a request
  /// Cancels an existing volunteer request via Django backend
  Future<bool> cancelVolunteerRequest(String requestId) async {
    try {
      log('❌ RequestService: Canceling volunteer request for request $requestId via Django API');
      
      final response = await _apiService.post('/api/requests/$requestId/cancel-acceptance/');
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Successfully canceled volunteer request for request $requestId');
        return true;
      } else {
        log('❌ RequestService: Failed to cancel volunteer request for request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error canceling volunteer request for request $requestId - $e');
      return false;
    }
  }
  
  // =============================================================================
  // USER OPERATIONS (For RequestController compatibility)
  // =============================================================================
  
  /// Get user by ID
  /// 🚨 FIXED: Using correct endpoint /api/profile/users/{id}/
  Future<UserModel?> getUser(String userId) async {
    try {
      log('👤 RequestService: Fetching user $userId from Django API');
      
      final response = await _apiService.get('/api/profile/users/$userId/');
      
      if (response.statusCode == 200 && response.data != null) {
        // Apply user field mapping if needed
        final userData = response.data as Map<String, dynamic>;
        final flutterUserData = _mapDjangoUserToFlutter(userData);
        final UserModel user = UserModel.fromJson(flutterUserData);
        
        log('✅ RequestService: Fetched user $userId successfully');
        return user;
      } else {
        log('❌ RequestService: Failed to fetch user $userId - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('💥 RequestService: Error fetching user $userId - $e');
      return null;
    }
  }
  
  // =============================================================================
  // SEARCH & FILTERING (Enhanced with Field Mapping)
  // =============================================================================
  
  /// Search requests by query
  /// 🚨 ENHANCED: Now includes Django field mapping
  Future<List<RequestModel>> searchRequests(String query, {String? location}) async {
    try {
      log('🔍 RequestService: Searching requests for: "$query"');
      
      String endpoint = '/api/requests/?search=$query';
      if (location != null && location.isNotEmpty) {
        endpoint += '&location=$location';
      }
      
      final response = await _apiService.get(endpoint);
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        // 🎯 APPLY FIELD MAPPING
        final List<RequestModel> requests = requestsJson
            .map((djangoJson) {
              final flutterJson = _mapDjangoToFlutter(djangoJson as Map<String, dynamic>);
              return RequestModelExtension.fromJsonWithRequester(flutterJson);
            })
            .toList();
        
        log('✅ RequestService: Found ${requests.length} requests for "$query"');
        return requests;
      } else {
        log('❌ RequestService: Failed to search requests - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error searching requests - $e');
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
      log('📊 RequestService: Fetching dashboard stats from Django API');
      
      final response = await _apiService.get('/api/dashboard/');
      
      if (response.statusCode == 200 && response.data != null) {
        log('✅ RequestService: Fetched dashboard stats successfully');
        return response.data as Map<String, dynamic>;
      } else {
        log('❌ RequestService: Failed to fetch dashboard stats - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('💥 RequestService: Error fetching dashboard stats - $e');
      return null;
    }
  }

  /// Approve a volunteer request for a specific request
  /// ✅ NEW: Allows request owners to approve pending volunteer requests
  Future<bool> approveVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      log('✅ RequestService: Approving volunteer $volunteerUserId for request $requestId via Django API');
      
      final response = await _apiService.post(
        '/api/requests/$requestId/approve-volunteer/', 
        data: {'volunteer_id': volunteerUserId}
      );
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Successfully approved volunteer $volunteerUserId for request $requestId');
        return true;
      } else {
        log('❌ RequestService: Failed to approve volunteer $volunteerUserId for request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error approving volunteer $volunteerUserId for request $requestId - $e');
      return false;
    }
  }

  /// Reject a volunteer request for a specific service request
  /// ✅ NEW: Enterprise-grade reject volunteer functionality
  Future<bool> rejectVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      log('❌ RequestService: Rejecting volunteer $volunteerUserId for request $requestId via Django API');
      
      final response = await _apiService.post(
        '/api/requests/$requestId/reject-volunteer/', 
        data: {'volunteer_id': volunteerUserId}
      );
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Successfully rejected volunteer $volunteerUserId for request $requestId');
        return true;
      } else {
        log('❌ RequestService: Failed to reject volunteer $volunteerUserId for request $requestId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error rejecting volunteer $volunteerUserId for request $requestId - $e');
      return false;
    }
  }

  /// Get volunteer requests for a specific request
  /// ✅ NEW: Retrieves pending volunteer requests for approval workflow
  Future<List<Map<String, dynamic>>> getVolunteerRequests(String requestId) async {
    try {
      log('📋 RequestService: Fetching volunteer requests for request $requestId via Django API');
      print('📋 RequestService: Fetching volunteer requests for request $requestId via Django API'); // Force print
      
      final response = await _apiService.get('/api/requests/$requestId/volunteer-requests/');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final requests = data['volunteer_requests'] as List<dynamic>? ?? [];
        
        log('✅ RequestService: Found ${requests.length} volunteer requests for request $requestId');
        print('✅ RequestService: Found ${requests.length} volunteer requests for request $requestId'); // Force print
        log('📊 Raw response data: $data');
        print('📊 Raw response data: $data'); // Force print
        
        // Convert to list of maps with proper field mapping for actual backend structure
        final mappedRequests = requests.map((request) {
          final requestData = request as Map<String, dynamic>;
          final mapped = {
            'id': requestData['id'],
            'volunteer': requestData['volunteer'], // Backend uses 'volunteer' not 'user'
            'message': requestData['message'] ?? '', // Backend uses 'message' not 'message_to_requester'
            'status': requestData['status'],
            'applied_at': requestData['applied_at'], // Backend uses 'applied_at' not 'requested_at'
            'estimated_arrival': requestData['estimated_arrival'],
          };
          log('📝 Mapped volunteer request: $mapped');
          return mapped;
        }).toList();
        
        return mappedRequests;
        
      } else {
        log('❌ RequestService: Failed to fetch volunteer requests for request $requestId - Status: ${response.statusCode}');
        print('❌ RequestService: Failed to fetch volunteer requests for request $requestId - Status: ${response.statusCode}'); // Force print
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error fetching volunteer requests for request $requestId - $e');
      print('💥 RequestService: Error fetching volunteer requests for request $requestId - $e'); // Force print
      return [];
    }
  }
  
  // =============================================================================
  // CATEGORY OPERATIONS
  // =============================================================================
  
  /// Fetch all categories from Django backend
  /// Returns list of categories for request categorization
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      log('📂 RequestService: Fetching categories from Django API');
      
      final response = await _apiService.get('/api/categories/');
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> categoriesJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        log('📥 Raw Django categories: ${categoriesJson.length}');
        
        final List<CategoryModel> categories = categoriesJson
            .map((categoryJson) => CategoryModel.fromJson(categoryJson as Map<String, dynamic>))
            .toList();
        
        log('✅ RequestService: Fetched ${categories.length} categories');
        log('📋 Categories: ${categories.map((c) => c.name).toList()}');
        
        return categories;
      } else {
        log('❌ RequestService: Failed to fetch categories - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error fetching categories - $e');
      
      // 🚨 Enhanced error logging for category fetching
      if (e is DioException) {
        print('🚨 [SERVICE DEBUG] Category fetch error:');
        print('🚨 [SERVICE DEBUG] - Status Code: ${e.response?.statusCode}');
        print('🚨 [SERVICE DEBUG] - Response Data: ${e.response?.data}');
      }
      
      return [];
    }
  }
  
  // =============================================================================
  // PLACEHOLDER METHODS (For backward compatibility)
  // =============================================================================
  
  /// File upload placeholder - will be implemented later
  Future<String> uploadFile(File file, String path) async {
    log('📁 RequestService: uploadFile - placeholder method');
    return 'placeholder-url';
  }
  
  /// File deletion placeholder
  Future<void> deleteFile(String path) async {
    log('🗑️ RequestService: deleteFile - placeholder method');
  }
  
  /// Get file URL placeholder  
  Future<String> getFileUrl(String path) async {
    log('🔗 RequestService: getFileUrl - placeholder method');
    return 'placeholder-url';
  }
}