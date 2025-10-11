// lib/services/request_service.dart
// 🚨 FIXED: Django field mapping adapter for correct JSON parsing
// Prompt 33.1 - CRITICAL FIX: Changed PUT to PATCH for status updates

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:tiri/models/category_model.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/services/api_service.dart';

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
  /// Submit bulk feedback for multiple volunteers
  Future<Map<String, dynamic>?> submitBulkFeedback({
    required String requestId,
    required List<Map<String, dynamic>> feedbackList,
  }) async {
    try {
      
      final requestData = {
        'request_id': requestId,
        'feedback_list': feedbackList,
      };
      
      
      final response = await _apiService.post(
        '/api/feedback/bulk_submit/',
        data: requestData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to submit feedback: ${response.statusMessage}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a request (mark as completed)
  Future<Map<String, dynamic>?> completeRequest(String requestId, {String? notes}) async {
    try {
      
      // Try with empty JSON object (some APIs expect valid JSON)
      final response = await _apiService.post(
        '/api/requests/$requestId/complete/',
        data: <String, dynamic>{},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        
        // Extract error message from response if available
        String errorMessage = 'Failed to complete request';
        if (response.data is Map && response.data['detail'] != null) {
          errorMessage = response.data['detail'];
        } else if (response.data is Map && response.data['error'] != null) {
          errorMessage = response.data['error'];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
        
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch requests where the current user is a volunteer (My Helps)
  Future<List<RequestModel>> fetchMyVolunteeredRequests() async {
    try {
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        return [];
      }

      final response = await _apiService.get('/api/requests/?view=my_volunteering');
      if (response.statusCode == 401) {
        return [];
      }
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ?
          (responseData['results'] ?? responseData['data'] ?? []) :
          (responseData is List ? responseData : []);
        final List<RequestModel> requests = requestsJson
            .map((djangoJson) {
              try {
                final flutterJson = _mapDjangoToFlutter(djangoJson as Map<String, dynamic>);
                return RequestModelExtension.fromJsonWithRequester(flutterJson);
              } catch (e) {
                return null;
              }
            })
            .whereType<RequestModel>()
            .toList();
        if (requests.isEmpty) {
        }
        return requests;
      } else {
        return [];
      }
    } catch (e, stack) {
      return [];
    }
  }
  
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

      // 🔍 COMPREHENSIVE DEBUG: Log volunteers_assigned structure

      if (djangoJson['volunteers_assigned'] is List) {
        final volunteersAssigned = djangoJson['volunteers_assigned'] as List;
        for (int i = 0; i < volunteersAssigned.length; i++) {
          final va = volunteersAssigned[i];
          if (va is Map) {
          }
        }
      } else {
      }

      // 📋 Django → Flutter Field Mapping
      final mappedAcceptedUsers = _mapAcceptedUsers(djangoJson);

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
        'acceptedUser': mappedAcceptedUsers,
        'feedbackList': [], // Will be populated later if needed

        // Include requester data for extension to parse
        'requester': djangoJson['requester'],

        // 🎯 CRITICAL: Preserve user_request_status for volunteer workflow
        'user_request_status': djangoJson['user_request_status'],

        // Add feedback and completion data
        'feedback': djangoJson['feedback'],
        'completed_at': djangoJson['completed_at']?.toString(),
        'completion_confirmed_by_requester': djangoJson['completion_confirmed_by_requester'],
      };


      // Debug: Show entire final JSON structure for debugging
      flutterJson.forEach((key, value) {
        if (key == 'acceptedUser') {
        } else {
        }
      });

      return flutterJson;
      
    } catch (e) {
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
      case 'accepted':
        return 'accepted';
      case 'in_progress':
      case 'inprogress':
        return 'inprogress';
      case 'completed':
      case 'complete':
        return 'complete';
      case 'cancelled':
        return 'cancelled';
      case 'expired':
      case 'delayed':
        return 'delayed';  // Map both expired and delayed to delayed status
      case 'incomplete':
        return 'incomplete';
      default:
        return 'pending';
    }
  }
  
  /// Map accepted users/volunteers from Django format
  /// FIXED: Only includes volunteers with status "approved" - Updated for exact JSON structure
  List<Map<String, dynamic>> _mapAcceptedUsers(Map<String, dynamic> djangoJson) {
    try {
      // Handle Django volunteers_assigned structure: [{"volunteer": {...}, "status": "approved"}]
      if (djangoJson['volunteers_assigned'] is List) {
        final volunteersAssigned = djangoJson['volunteers_assigned'] as List;

        // Process each volunteer assignment
        final approvedVolunteers = <Map<String, dynamic>>[];

        for (int i = 0; i < volunteersAssigned.length; i++) {
          final volunteerAssignment = volunteersAssigned[i];

          if (volunteerAssignment is! Map) {
            continue;
          }

          final assignment = volunteerAssignment as Map<String, dynamic>;
          final status = assignment['status'];
          final volunteerData = assignment['volunteer'];


          // Check if approved
          if (status == 'approved') {

            if (volunteerData is Map<String, dynamic>) {
              // Map the volunteer data to Flutter format
              final mappedVolunteer = _mapDjangoUserToFlutter(volunteerData);

              if (mappedVolunteer.isNotEmpty) {
                approvedVolunteers.add(mappedVolunteer);
              } else {
              }
            } else {
            }
          } else {
          }
        }

        return approvedVolunteers;
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
      return [];
    }
  }
  
  /// Map Django user object to Flutter UserModel format
  /// FIXED: Updated to match exact JSON response structure
  Map<String, dynamic> _mapDjangoUserToFlutter(dynamic djangoUser) {
    if (djangoUser is! Map) {
      return {};
    }

    final userMap = djangoUser as Map<String, dynamic>;

    // Map according to actual JSON response structure
    final mappedUser = {
      'userId': userMap['id']?.toString() ?? '',
      'username': userMap['full_name'] ?? userMap['username'] ?? 'Unknown User',
      'email': userMap['email']?.toString() ?? '',
      'imageUrl': userMap['profile_image_url'],
      // Add additional fields from backend response
      'firstName': userMap['full_name']?.toString().split(' ').first ?? '',
      'lastName': userMap['full_name']?.toString().split(' ').skip(1).join(' ') ?? '',
      'averageRating': userMap['average_rating'] ?? 0.0,
      'totalHoursHelped': userMap['total_hours_helped'] ?? 0,
      'locationDisplay': userMap['location_display'] ?? '',
      'isVerified': userMap['is_verified'] ?? false,
    };

    return mappedUser;
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
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        return [];
      }
      
      final response = await _apiService.get('/api/requests/');
      
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
        
        
        return requests;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch current user's requests
  /// 🚨 ENHANCED: Now includes Django field mapping  
  Future<List<RequestModel>> fetchMyRequests() async {
    try {
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        return [];
      }
      
      final response = await _apiService.get('/api/requests/?view=my_requests');
      
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
        
        return requests;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Get single request by ID
  /// 🚨 ENHANCED: Now includes Django field mapping
  Future<RequestModel?> getRequest(String requestId) async {
    try {
      
      final response = await _apiService.get('/api/requests/$requestId/');
      
      // Enhanced debug logging for API response
      
      if (response.statusCode == 200 && response.data != null) {
        try {
          // 🔍 DEBUG: Log raw Django response
          
          // Check if user_request_status exists in response
          final rawData = response.data as Map<String, dynamic>;
          if (rawData.containsKey('user_request_status')) {
            final userRequestStatus = rawData['user_request_status'] as Map<String, dynamic>?;
            if (userRequestStatus?.containsKey('message_content') == true) {
            }
            // Check other possible message field names
            final possibleMessageFields = ['message_to_requester', 'volunteer_message', 'message', 'user_message'];
            for (final field in possibleMessageFields) {
              if (userRequestStatus?.containsKey(field) == true) {
              }
            }
          }
          
          // 🎯 APPLY FIELD MAPPING
          final flutterJson = _mapDjangoToFlutter(response.data as Map<String, dynamic>);
          
          final RequestModel request = RequestModelExtension.fromJsonWithRequester(flutterJson);
          
          return request;
          
        } catch (parseError) {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Create new request
  /// 🚨 FIXED: Using correct endpoint /api/requests/
  Future<bool> createRequest(Map<String, dynamic> requestData) async {
    try {
      
      final response = await _apiService.post('/api/requests/', data: requestData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      
      // 🚨 CRITICAL: Extract DioException details to see actual Django errors
      if (e is DioException) {
        
        // Extract field-specific errors from Django
        if (e.response?.data is Map) {
          final errors = e.response!.data as Map;
          errors.forEach((field, error) {
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
      
      // 🚨 KEY FIX: Use PATCH instead of PUT for partial updates
      final response = await _apiService.patch('/api/requests/$requestId/', data: requestData);
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Delete request
  /// 🚨 FIXED: Using correct endpoint /api/requests/{id}/
  Future<bool> deleteRequest(String requestId) async {
    try {
      
      final response = await _apiService.delete('/api/requests/$requestId/');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Request to volunteer for a request
  /// Sends a volunteer request to the Django backend
  Future<bool> requestToVolunteer(String requestId, String message) async {
    try {
      
      final requestData = {'message_to_requester': message};
      
      // Also try alternative field names that the backend might expect
      final alternativeData = {
        'message_to_requester': message,
        'message_content': message,
        'volunteer_message': message,
        'message': message,
      };
      
      final response = await _apiService.post(
        '/api/requests/$requestId/accept/', 
        data: alternativeData
      );
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Cancel volunteer request for a request
  /// Cancels an existing volunteer request via Django backend
  Future<bool> cancelVolunteerRequest(String requestId, {String? reason}) async {
    try {
      if (reason != null) {
      }
      
      // Prepare request data with optional reason
      final Map<String, dynamic> requestData = {};
      if (reason != null && reason.isNotEmpty) {
        requestData['reason'] = reason;
      }
      
      
      final response = await _apiService.post(
        '/api/requests/$requestId/cancel_acceptance/',
        data: requestData.isNotEmpty ? requestData : null,
      );
      
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      
      // Enhanced error logging for Dio errors
      if (e.toString().contains('DioError') || e.runtimeType.toString().contains('Dio')) {
        try {
          final dioError = e as dynamic;
        } catch (castError) {
        }
      }
      
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

      final response = await _apiService.get('/api/profile/users/$userId/');
      
      if (response.statusCode == 200 && response.data != null) {
        // Apply user field mapping if needed
        final userData = response.data as Map<String, dynamic>;
        final flutterUserData = _mapDjangoUserToFlutter(userData);
        final UserModel user = UserModel.fromJson(flutterUserData);
        
        return user;
      } else {
        return null;
      }
    } catch (e) {
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
        
        return requests;
      } else {
        return [];
      }
    } catch (e) {
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
      
      final response = await _apiService.get('/api/dashboard/');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Approve a volunteer request for a specific request
  /// ✅ NEW: Allows request owners to approve pending volunteer requests
  Future<bool> approveVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      
      final response = await _apiService.post(
        '/api/requests/$requestId/approve-volunteer/', 
        data: {'volunteer_id': volunteerUserId}
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Reject a volunteer request for a specific service request
  /// ✅ NEW: Enterprise-grade reject volunteer functionality
  Future<bool> rejectVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      
      final response = await _apiService.post(
        '/api/requests/$requestId/reject-volunteer/', 
        data: {'volunteer_id': volunteerUserId}
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get volunteer requests for a specific request
  /// ✅ NEW: Retrieves pending volunteer requests for approval workflow
  Future<List<Map<String, dynamic>>> getVolunteerRequests(String requestId) async {
    try {
      
      final response = await _apiService.get('/api/requests/$requestId/volunteer-requests/');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final requests = data['volunteer_requests'] as List<dynamic>? ?? [];
        
        
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
          return mapped;
        }).toList();
        
        return mappedRequests;
        
      } else {
        return [];
      }
    } catch (e) {
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
      
      final response = await _apiService.get('/api/categories/');
      
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> categoriesJson = responseData is Map ? 
          (responseData['results'] ?? responseData['data'] ?? []) : 
          (responseData is List ? responseData : []);
        
        
        final List<CategoryModel> categories = categoriesJson
            .map((categoryJson) => CategoryModel.fromJson(categoryJson as Map<String, dynamic>))
            .toList();
        
        
        return categories;
      } else {
        return [];
      }
    } catch (e) {
      
      // 🚨 Enhanced error logging for category fetching
      if (e is DioException) {
      }
      
      return [];
    }
  }
  
  /// Start a request manually (for request owners)
  /// POST /api/requests/{request_id}/start-request/
  Future<Map<String, dynamic>?> startRequest(String requestId) async {
    try {

      final response = await _apiService.post(
        '/api/requests/$requestId/start-request/',
        data: {},  // Empty data as per API spec
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      } else {

        // Extract error message from response
        String errorMessage = 'Failed to start request';
        if (response.data is Map) {
          errorMessage = response.data['error'] ??
                        response.data['detail'] ??
                        response.data['message'] ??
                        errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {

      // Enhanced error logging
      if (e is DioException) {

        // Extract meaningful error message
        if (e.response?.data is Map) {
          final errorData = e.response!.data as Map;
          final errorMsg = errorData['error'] ?? errorData['detail'] ?? 'Failed to start request';
          throw Exception(errorMsg);
        }
      }

      rethrow;
    }
  }

  /// Start a delayed request during grace period (Start Anyway)
  /// POST /api/requests/{request_id}/start-anyway/
  Future<Map<String, dynamic>?> startRequestAnyway(String requestId) async {
    try {

      final response = await _apiService.post(
        '/api/requests/$requestId/start-anyway/',
        data: {},  // Empty data as per API spec
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>?;
      } else {

        // Extract error message from response
        String errorMessage = 'Failed to start request during grace period';
        if (response.data is Map) {
          errorMessage = response.data['error'] ??
                        response.data['detail'] ??
                        response.data['message'] ??
                        errorMessage;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {

      // Enhanced error logging
      if (e is DioException) {

        // Extract meaningful error message
        if (e.response?.data is Map) {
          final errorData = e.response!.data as Map;
          final errorMsg = errorData['error'] ?? errorData['detail'] ?? 'This endpoint is only for delayed requests';
          throw Exception(errorMsg);
        }
      }

      rethrow;
    }
  }

  /// Complete request and submit feedback for all volunteers
  /// POST /api/requests/{request_id}/complete/
  Future<Map<String, dynamic>?> completeRequestWithFeedback(
    String requestId,
    List<Map<String, dynamic>> feedbackList,
    {String? completionNotes}
  ) async {
    try {
      
      final requestData = {
        'feedback_list': feedbackList,
        if (completionNotes?.isNotEmpty == true) 'completion_notes': completionNotes,
      };
      
      
      final response = await _apiService.post(
        '/api/requests/$requestId/complete/', 
        data: requestData
      );
      
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      
      // Enhanced error logging for debugging
      if (e is DioException) {
      }
      
      return null;
    }
  }
  
  // =============================================================================
  // PLACEHOLDER METHODS (For backward compatibility)
  // =============================================================================
  
  /// File upload placeholder - will be implemented later
  Future<String> uploadFile(File file, String path) async {
    return 'placeholder-url';
  }
  
  /// File deletion placeholder
  Future<void> deleteFile(String path) async {
  }
  
  /// Get file URL placeholder  
  Future<String> getFileUrl(String path) async {
    return 'placeholder-url';
  }
}