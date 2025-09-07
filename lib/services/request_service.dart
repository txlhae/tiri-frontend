// lib/services/request_service.dart
// 🚨 FIXED: Django field mapping adapter for correct JSON parsing
// Prompt 33.1 - CRITICAL FIX: Changed PUT to PATCH for status updates

import 'dart:developer';
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
      log('✅ RequestService: Submitting bulk feedback for request $requestId');
      
      final requestData = {
        'request_id': requestId,
        'feedback_list': feedbackList,
      };
      
      log('📤 Feedback payload: $requestData');
      
      final response = await _apiService.post(
        '/api/feedback/bulk_submit/',
        data: requestData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ RequestService: Bulk feedback submitted successfully');
        return response.data;
      } else {
        log('❌ RequestService: Failed to submit feedback - Status: ${response.statusCode}');
        throw Exception('Failed to submit feedback: ${response.statusMessage}');
      }
    } catch (e) {
      log('💥 RequestService: Error submitting bulk feedback - $e');
      rethrow;
    }
  }

  /// Complete a request (mark as completed)
  Future<Map<String, dynamic>?> completeRequest(String requestId, {String? notes}) async {
    try {
      log('✅ RequestService: Completing request $requestId');
      
      // Try with empty JSON object (some APIs expect valid JSON)
      final response = await _apiService.post(
        '/api/requests/$requestId/complete/',
        data: <String, dynamic>{},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        log('✅ RequestService: Request completed successfully');
        return response.data;
      } else {
        log('❌ RequestService: Failed to complete request - Status: ${response.statusCode}');
        log('❌ RequestService: Response headers: ${response.headers}');
        log('❌ RequestService: Response data: ${response.data}');
        log('❌ RequestService: Status message: ${response.statusMessage}');
        
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
      log('💥 RequestService: Error completing request - $e');
      rethrow;
    }
  }

  /// Fetch requests where the current user is a volunteer (My Helps)
  Future<List<RequestModel>> fetchMyVolunteeredRequests() async {
    try {
      log('🔍 [MyHelps] fetchMyVolunteeredRequests called');
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        log('❌ [MyHelps] No authentication tokens - returning empty list');
        return [];
      }

      final response = await _apiService.get('/api/requests/?view=my_volunteering');
      log('🔍 [MyHelps] API called: /api/requests/?view=my_volunteering, status: ${response.statusCode}');
      if (response.statusCode == 401) {
        log('❌ [MyHelps] Unauthorized! User is not authenticated.');
        return [];
      }
      if (response.statusCode == 200 && response.data != null) {
        final dynamic responseData = response.data;
        final List<dynamic> requestsJson = responseData is Map ?
          (responseData['results'] ?? responseData['data'] ?? []) :
          (responseData is List ? responseData : []);
        log('📥 [MyHelps] Raw Django my volunteered requests count: ${requestsJson.length}');
        final List<RequestModel> requests = requestsJson
            .map((djangoJson) {
              try {
                final flutterJson = _mapDjangoToFlutter(djangoJson as Map<String, dynamic>);
                return RequestModelExtension.fromJsonWithRequester(flutterJson);
              } catch (e) {
                log('❌ [MyHelps] Error mapping request: $e');
                return null;
              }
            })
            .whereType<RequestModel>()
            .toList();
        log('✅ [MyHelps] Mapped ${requests.length} my volunteered requests');
        if (requests.isEmpty) {
          log('⚠️ [MyHelps] No volunteered requests found for user.');
        }
        return requests;
      } else {
        log('❌ [MyHelps] Failed to fetch my volunteered requests - Status: ${response.statusCode}, Data: ${response.data}');
        return [];
      }
    } catch (e, stack) {
      log('💥 [MyHelps] Error fetching my volunteered requests - $e');
      log('💥 [MyHelps] Stack trace: $stack');
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
        
        // Add feedback and completion data
        'feedback': djangoJson['feedback'],
        'completed_at': djangoJson['completed_at']?.toString(),
        'completion_confirmed_by_requester': djangoJson['completion_confirmed_by_requester'],
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
        return 'expired';
      case 'incomplete':
        return 'incomplete';
      default:
        log('⚠️ Unknown status from Django: $status, defaulting to pending');
        return 'pending';
    }
  }
  
  /// Map accepted users/volunteers from Django format
  List<Map<String, dynamic>> _mapAcceptedUsers(Map<String, dynamic> djangoJson) {
    try {
      // Handle Django volunteers_assigned structure: [{"volunteer": {...}}]
      if (djangoJson['volunteers_assigned'] is List) {
        return (djangoJson['volunteers_assigned'] as List)
            .map((volunteerAssignment) {
              // Extract the actual volunteer object from the assignment
              final volunteerData = volunteerAssignment is Map 
                ? volunteerAssignment['volunteer']
                : volunteerAssignment;
              return _mapDjangoUserToFlutter(volunteerData);
            })
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
      log('⚠️ Django JSON structure: ${djangoJson['volunteers_assigned']}');
      return [];
    }
  }
  
  /// Map Django user object to Flutter UserModel format
  Map<String, dynamic> _mapDjangoUserToFlutter(dynamic djangoUser) {
    if (djangoUser is! Map) {
      log('⚠️ _mapDjangoUserToFlutter: djangoUser is not a Map: $djangoUser');
      return {};
    }
    
    final userMap = djangoUser as Map<String, dynamic>;
    log('🔍 Mapping Django user: ${userMap.keys.toList()}');
    log('🔍 Username: ${userMap['username']}, Full name: ${userMap['full_name']}');
    
    final mappedUser = {
      'userId': userMap['id']?.toString() ?? '',
      'username': userMap['username'] ?? userMap['full_name'] ?? 'Unknown', // Fixed: Use 'username' key
      'email': userMap['email']?.toString() ?? '', // Fixed: Handle null email properly
      'imageUrl': userMap['profile_image_url'] ?? userMap['profile_image'],
      // Add other UserModel fields as needed
    };
    
    log('✅ Mapped user: $mappedUser');
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
      log('🔍 RequestService: Fetching community requests from Django API');
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        log('❌ RequestService: No authentication tokens - returning empty list');
        return [];
      }
      
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
      
      // Check if API service is authenticated before making request
      if (!_apiService.isAuthenticated) {
        log('❌ RequestService: No authentication tokens - returning empty list');
        return [];
      }
      
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
      log('🌐 API URL: ${response.requestOptions.uri}');
      log('🌐 Status Code: ${response.statusCode}');
      log('🌐 Response Headers: ${response.headers}');
      log('🌐 Raw Response Data Type: ${response.data.runtimeType}');
      log('🌐 Raw Response: ${response.data}');
      
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
          log('🔄 Applying Django to Flutter field mapping...');
          final flutterJson = _mapDjangoToFlutter(response.data as Map<String, dynamic>);
          log('✅ Field mapping completed successfully');
          log('🔍 Mapped JSON: $flutterJson');
          
          log('🏗️ Creating RequestModel from mapped JSON...');
          final RequestModel request = RequestModelExtension.fromJsonWithRequester(flutterJson);
          log('✅ RequestModel created successfully');
          
          log('✅ RequestService: Mapped request $requestId successfully');
          return request;
          
        } catch (parseError) {
          log('❌ JSON Parse Error: $parseError');
          log('❌ Parse Error Stack Trace: ${parseError.toString()}');
          log('❌ Failed to parse response data: ${response.data}');
          return null;
        }
      } else {
        log('❌ RequestService: Failed to fetch request $requestId - Status: ${response.statusCode}');
        log('❌ Response body: ${response.data}');
        return null;
      }
    } catch (e) {
      log('💥 RequestService: Error fetching request $requestId - $e');
      log('💥 Full error stack trace: $e');
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
      log('🚨 [SERVICE DEBUG] Error creating request - $e');
      
      // 🚨 CRITICAL: Extract DioException details to see actual Django errors
      if (e is DioException) {
        log('🚨 [SERVICE DEBUG] DioException detected!');
        log('🚨 [SERVICE DEBUG] HTTP Status: ${e.response?.statusCode}');
        log('🚨 [SERVICE DEBUG] Django Response: ${e.response?.data}');
        log('🚨 [SERVICE DEBUG] Request URL: ${e.requestOptions.path}');
        log('🚨 [SERVICE DEBUG] Request Data: ${e.requestOptions.data}');
        
        // Extract field-specific errors from Django
        if (e.response?.data is Map) {
          final errors = e.response!.data as Map;
          log('🚨 [SERVICE DEBUG] === DJANGO FIELD ERRORS ===');
          errors.forEach((field, error) {
            log('🚨 [SERVICE DEBUG] Field "$field": $error');
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
  Future<bool> cancelVolunteerRequest(String requestId, {String? reason}) async {
    try {
      log('❌ RequestService: Canceling volunteer request for request $requestId via Django API');
      log('🔍 RequestService: Full URL will be: /api/requests/$requestId/cancel_acceptance/');
      if (reason != null) {
        log('📝 Cancellation reason: "$reason"');
      }
      
      // Prepare request data with optional reason
      final Map<String, dynamic> requestData = {};
      if (reason != null && reason.isNotEmpty) {
        requestData['reason'] = reason;
      }
      
      log('📤 RequestService: Sending data: $requestData');
      log('🌐 RequestService: About to make POST request...');
      
      final response = await _apiService.post(
        '/api/requests/$requestId/cancel_acceptance/',
        data: requestData.isNotEmpty ? requestData : null,
      );
      
      log('📥 RequestService: Received response - Status: ${response.statusCode}');
      log('📥 RequestService: Response data: ${response.data}');
      log('📥 RequestService: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Successfully canceled volunteer request for request $requestId');
        return true;
      } else {
        log('❌ RequestService: Failed to cancel volunteer request for request $requestId - Status: ${response.statusCode}');
        log('❌ RequestService: Response body: ${response.data}');
        return false;
      }
    } catch (e) {
      log('💥 RequestService: Error canceling volunteer request for request $requestId - $e');
      log('💥 RequestService: Error type: ${e.runtimeType}');
      
      // Enhanced error logging for Dio errors
      if (e.toString().contains('DioError') || e.runtimeType.toString().contains('Dio')) {
        log('🚨 RequestService: Dio error details:');
        try {
          final dioError = e as dynamic;
          log('🚨 RequestService: - Status Code: ${dioError.response?.statusCode}');
          log('🚨 RequestService: - Response Data: ${dioError.response?.data}');
          log('🚨 RequestService: - Request URL: ${dioError.requestOptions?.path}');
          log('🚨 RequestService: - Request Method: ${dioError.requestOptions?.method}');
          log('🚨 RequestService: - Request Data: ${dioError.requestOptions?.data}');
          log('🚨 RequestService: - Error Message: ${dioError.message}');
        } catch (castError) {
          log('🚨 RequestService: Could not cast to Dio error, raw error: $e');
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
      log('📋 RequestService: Fetching volunteer requests for request $requestId via Django API'); // Force print
      
      final response = await _apiService.get('/api/requests/$requestId/volunteer-requests/');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final requests = data['volunteer_requests'] as List<dynamic>? ?? [];
        
        log('✅ RequestService: Found ${requests.length} volunteer requests for request $requestId');
        log('✅ RequestService: Found ${requests.length} volunteer requests for request $requestId'); // Force print
        log('📊 Raw response data: $data');
        log('📊 Raw response data: $data'); // Force print
        
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
        log('❌ RequestService: Failed to fetch volunteer requests for request $requestId - Status: ${response.statusCode}'); // Force print
        return [];
      }
    } catch (e) {
      log('💥 RequestService: Error fetching volunteer requests for request $requestId - $e');
      log('💥 RequestService: Error fetching volunteer requests for request $requestId - $e'); // Force print
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
        log('🚨 [SERVICE DEBUG] Category fetch error:');
        log('🚨 [SERVICE DEBUG] - Status Code: ${e.response?.statusCode}');
        log('🚨 [SERVICE DEBUG] - Response Data: ${e.response?.data}');
      }
      
      return [];
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
      log('✅ RequestService: Completing request $requestId with feedback');
      
      final requestData = {
        'feedback_list': feedbackList,
        if (completionNotes?.isNotEmpty == true) 'completion_notes': completionNotes,
      };
      
      log('📝 Request completion data: $requestData');
      
      final response = await _apiService.post(
        '/api/requests/$requestId/complete/', 
        data: requestData
      );
      
      log('🌐 Complete request response status: ${response.statusCode}');
      log('🌐 Complete request response data: ${response.data}');
      
      if (response.statusCode == 200) {
        log('✅ RequestService: Successfully completed request $requestId');
        return response.data as Map<String, dynamic>?;
      } else {
        log('❌ RequestService: Failed to complete request $requestId - Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('💥 RequestService: Error completing request $requestId - $e');
      
      // Enhanced error logging for debugging
      if (e is DioException) {
        log('🚨 [SERVICE DEBUG] Complete request error:');
        log('🚨 [SERVICE DEBUG] - Status Code: ${e.response?.statusCode}');
        log('🚨 [SERVICE DEBUG] - Response Data: ${e.response?.data}');
        log('🚨 [SERVICE DEBUG] - Error Message: ${e.message}');
      }
      
      return null;
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