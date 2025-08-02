/// Usage Examples for API Foundation Components - Phase 1
/// Demonstrates how to use the HTTP service layer foundation
library api_usage_examples;

import 'package:flutter/material.dart';
import '../lib/services/api/api_client.dart';
import '../lib/services/models/api_response.dart';
import '../lib/services/exceptions/api_exceptions.dart';
import '../lib/config/api_config.dart';

/// Example usage of the API foundation components
class ApiUsageExamples {
  
  /// Example: Initialize the API client
  static void initializeApiClient() {
    // Initialize API client with default configuration
    ApiClient.initialize(
      baseUrl: ApiConfig.apiBaseUrl,
      enableRetry: true,
      maxRetries: 3,
    );
    
    print('✅ API Client initialized successfully');
  }

  /// Example: Set authentication token
  static void setAuthenticationToken() {
    const token = 'your-jwt-token-here';
    ApiClient.setAuthToken(token);
    
    print('✅ Authentication token set');
  }

  /// Example: Make a simple GET request
  static Future<void> makeGetRequest() async {
    try {
      // Make a GET request to fetch notifications
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/notifications/',
        queryParams: {
          'page': 1,
          'limit': 20,
          'is_read': false,
        },
      );

      if (response.success && response.data != null) {
        print('✅ GET request successful');
        print('Data: ${response.data}');
      } else {
        print('❌ GET request failed: ${response.error?.message}');
      }
    } catch (e) {
      print('❌ Exception during GET request: $e');
    }
  }

  /// Example: Make a POST request with data
  static Future<void> makePostRequest() async {
    try {
      final requestData = {
        'title': 'New Notification',
        'message': 'This is a test notification',
        'category': 'general',
      };

      final response = await ApiClient.post<Map<String, dynamic>>(
        '/notifications/',
        data: requestData,
      );

      if (response.success) {
        print('✅ POST request successful');
        print('Created notification: ${response.data}');
      } else {
        print('❌ POST request failed: ${response.error?.message}');
      }
    } catch (e) {
      print('❌ Exception during POST request: $e');
    }
  }

  /// Example: Handle different types of API errors
  static Future<void> handleApiErrors() async {
    try {
      // This request will likely fail for demonstration
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/invalid-endpoint/',
      );

      if (!response.success && response.error != null) {
        final error = response.error!;
        
        switch (error.type) {
          case 'network_error':
            print('🌐 Network error: Check your internet connection');
            break;
          case 'authentication_error':
            print('🔐 Authentication error: Please login again');
            break;
          case 'validation_error':
            print('📝 Validation error: ${error.message}');
            if (error.fieldErrors != null) {
              error.fieldErrors!.forEach((field, errors) {
                print('  - $field: ${errors.join(', ')}');
              });
            }
            break;
          case 'server_error':
            print('🚨 Server error: Please try again later');
            break;
          default:
            print('❓ Unknown error: ${error.message}');
        }
      }
    } catch (e) {
      print('❌ Exception during error handling demo: $e');
    }
  }

  /// Example: Work with paginated responses
  static Future<void> handlePaginatedResponse() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/notifications/',
        queryParams: {
          'page': 1,
          'limit': 10,
        },
      );

      if (response.success && response.data != null) {
        // Parse as paginated response
        final paginatedData = PaginatedResponse.fromJson(
          response.data!,
          (json) => json, // Notification model parser will be added in Phase 2
        );

        print('✅ Paginated response received');
        print('Total items: ${paginatedData.totalCount}');
        print('Current page: ${paginatedData.currentPage}/${paginatedData.totalPages}');
        print('Items on this page: ${paginatedData.results.length}');
        print('Has next page: ${paginatedData.hasNext}');
        print('Display range: ${paginatedData.getDisplayRange()}');
      }
    } catch (e) {
      print('❌ Exception during paginated request: $e');
    }
  }

  /// Example: Upload a file
  static Future<void> uploadFile() async {
    try {
      // Note: Replace with actual file path
      const filePath = '/path/to/your/file.jpg';
      
      final response = await ApiClient.uploadFile<Map<String, dynamic>>(
        '/upload/',
        filePath,
        'file',
        additionalData: {
          'description': 'Profile picture',
          'category': 'avatar',
        },
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('📤 Upload progress: $progress%');
        },
      );

      if (response.success) {
        print('✅ File uploaded successfully');
        print('Response: ${response.data}');
      } else {
        print('❌ File upload failed: ${response.error?.message}');
      }
    } catch (e) {
      print('❌ Exception during file upload: $e');
    }
  }

  /// Example: Handle request cancellation
  static Future<void> handleRequestCancellation() async {
    final cancelToken = ApiClient.createCancelToken();
    
    try {
      // Start a request
      final futureResponse = ApiClient.get<Map<String, dynamic>>(
        '/slow-endpoint/',
        cancelToken: cancelToken,
      );

      // Cancel the request after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (!ApiClient.isCancelled(cancelToken)) {
          cancelToken.cancel('Request cancelled by user');
          print('🛑 Request cancelled');
        }
      });

      final response = await futureResponse;
      
      if (response.success) {
        print('✅ Request completed before cancellation');
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        print('🛑 Request was cancelled successfully');
      } else {
        print('❌ Exception during cancellation demo: $e');
      }
    }
  }

  /// Example: Custom error handling with try-catch
  static Future<void> customErrorHandling() async {
    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/protected-endpoint/',
      );

      final data = response.getDataOrThrow(); // Throws if error
      print('✅ Data received: $data');
      
    } on NetworkException catch (e) {
      print('🌐 Network error: ${e.message}');
      if (e.errorType == NetworkErrorType.timeout) {
        print('  Suggestion: Check your internet connection');
      }
    } on AuthenticationException catch (e) {
      print('🔐 Authentication error: ${e.message}');
      if (e.isTokenExpired) {
        print('  Suggestion: Please login again');
      }
    } on ValidationException catch (e) {
      print('📝 Validation error: ${e.message}');
      print('  Formatted message: ${e.getFormattedMessage()}');
    } on RateLimitException catch (e) {
      print('⏱️ Rate limit exceeded: ${e.message}');
      print('  Retry after: ${e.retryAfterSeconds} seconds');
    } on ServerException catch (e) {
      print('🚨 Server error: ${e.message}');
      if (e.isRetryable) {
        print('  Suggestion: This error can be retried');
      }
    } on ApiException catch (e) {
      print('❓ API error: ${e.message}');
      print('  Status code: ${e.statusCode}');
    } catch (e) {
      print('❌ Unexpected error: $e');
    }
  }
}

/// Flutter widget example showing API integration
class ApiExampleWidget extends StatefulWidget {
  const ApiExampleWidget({super.key});

  @override
  State<ApiExampleWidget> createState() => _ApiExampleWidgetState();
}

class _ApiExampleWidgetState extends State<ApiExampleWidget> {
  bool _isLoading = false;
  String _status = 'Ready';
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  /// Initialize API client
  void _initializeApi() {
    ApiClient.initialize();
    setState(() {
      _status = 'API Client initialized';
    });
  }

  /// Fetch notifications from API
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching notifications...';
    });

    try {
      final response = await ApiClient.get<Map<String, dynamic>>(
        '/notifications/',
        queryParams: {
          'limit': 10,
          'is_read': false,
        },
      );

      if (response.success && response.data != null) {
        final paginatedData = PaginatedResponse.fromJson(
          response.data!,
          (json) => json,
        );

        setState(() {
          _notifications = paginatedData.results;
          _status = 'Loaded ${_notifications.length} notifications';
        });
      } else {
        setState(() {
          _status = 'Error: ${response.error?.message ?? 'Unknown error'}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Mark notification as read
  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await ApiClient.post<Map<String, dynamic>>(
        '/notifications/$notificationId/mark_as_read/',
      );

      if (response.success) {
        setState(() {
          _status = 'Notification marked as read';
        });
        // Refresh the list
        _fetchNotifications();
      } else {
        setState(() {
          _status = 'Error marking as read: ${response.error?.message}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Exception marking as read: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Foundation Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_status',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fetchNotifications,
                    child: const Text('Fetch Notifications'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => ApiUsageExamples.makePostRequest(),
                  child: const Text('Test POST'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading)
              const CircularProgressIndicator(),
            
            // Notifications list
            Expanded(
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Card(
                    child: ListTile(
                      title: Text(notification['title'] ?? 'No title'),
                      subtitle: Text(notification['message'] ?? 'No message'),
                      trailing: notification['is_read'] == false
                          ? IconButton(
                              icon: const Icon(Icons.mark_email_read),
                              onPressed: () => _markAsRead(
                                notification['id'].toString(),
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.green),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TODO: Phase 2 Integration Points
/// - Add real notification models and parsing
/// - Integrate with actual notification controller
/// - Add proper error handling UI components
/// - Implement offline support and caching
/// - Add real-time updates via WebSocket
/// - Create reusable API service classes
/// - Add request logging and analytics
/// - Implement proper loading states and error recovery
