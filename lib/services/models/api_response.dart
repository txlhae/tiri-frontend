/// API Response Models for Django Backend Integration
/// Provides generic response wrappers and data models
library api_response;

import 'dart:convert';

/// Generic API response wrapper for all HTTP operations
/// Provides consistent structure for success and error responses
class ApiResponse<T> {
  /// Indicates if the API call was successful
  final bool success;
  
  /// Response data (null for failed responses)
  final T? data;
  
  /// Human-readable message from the server
  final String? message;
  
  /// HTTP status code
  final int? statusCode;
  
  /// Error details (null for successful responses)
  final ApiError? error;
  
  /// Response metadata (pagination, headers, etc.)
  final Map<String, dynamic>? metadata;
  
  /// Timestamp when the response was received
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.error,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory constructor for successful responses
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  /// Factory constructor for error responses
  factory ApiResponse.error({
    required ApiError error,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message ?? error.message,
      statusCode: statusCode ?? error.statusCode,
      metadata: metadata,
    );
  }

  /// Factory constructor from JSON response
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, 
    T Function(dynamic)? fromJsonT,
  ) {
    final success = json['success'] ?? true;
    final statusCode = json['status_code'] ?? json['status'];
    
    if (success && json.containsKey('data')) {
      // Successful response with data
      final data = fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?;
      return ApiResponse.success(
        data: data!,
        message: json['message'],
        statusCode: statusCode,
        metadata: json['metadata'],
      );
    } else {
      // Error response
      final error = ApiError.fromJson(json);
      return ApiResponse.error(
        error: error,
        message: json['message'],
        statusCode: statusCode,
        metadata: json['metadata'],
      );
    }
  }

  /// Convert response to JSON
  Map<String, dynamic> toJson({Map<String, dynamic> Function(T)? toJsonT}) {
    return {
      'success': success,
      'data': data != null && toJsonT != null ? toJsonT(data!) : data,
      'message': message,
      'status_code': statusCode,
      'error': error?.toJson(),
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if response has data
  bool get hasData => success && data != null;

  /// Check if response has error
  bool get hasError => !success && error != null;

  /// Get data or throw error
  T getDataOrThrow() {
    if (hasData) {
      return data!;
    } else if (hasError) {
      throw error!.toException();
    } else {
      throw Exception('Response has no data and no error');
    }
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, statusCode: $statusCode, message: $message}';
  }
}

/// Error details for failed API responses
class ApiError {
  /// Error type/code
  final String type;
  
  /// Human-readable error message
  final String message;
  
  /// HTTP status code
  final int? statusCode;
  
  /// Detailed error information
  final Map<String, dynamic>? details;
  
  /// Field-specific validation errors
  final Map<String, List<String>>? fieldErrors;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;

  ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
    this.fieldErrors,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory constructor from JSON error response
  factory ApiError.fromJson(Map<String, dynamic> json) {
    // Handle Django REST framework error format
    String type = json['error'] ?? json['code'] ?? 'unknown_error';
    String message = json['message'] ?? json['detail'] ?? 'An error occurred';
    
    // Extract field errors if present
    Map<String, List<String>>? fieldErrors;
    if (json.containsKey('errors') && json['errors'] is Map) {
      fieldErrors = {};
      final errors = json['errors'] as Map<String, dynamic>;
      errors.forEach((key, value) {
        if (value is List) {
          fieldErrors![key] = List<String>.from(value);
        } else {
          fieldErrors![key] = [value.toString()];
        }
      });
    }

    return ApiError(
      type: type,
      message: message,
      statusCode: json['status_code'] ?? json['status'],
      details: json['details'],
      fieldErrors: fieldErrors,
    );
  }

  /// Convert error to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'status_code': statusCode,
      'details': details,
      'field_errors': fieldErrors,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to appropriate exception
  Exception toException() {
    // This will be integrated with api_exceptions.dart in Phase 2
    return Exception('$type: $message');
  }

  @override
  String toString() {
    return 'ApiError{type: $type, message: $message, statusCode: $statusCode}';
  }
}

/// Paginated response wrapper for list endpoints
class PaginatedResponse<T> {
  /// List of items for current page
  final List<T> results;
  
  /// Total number of items across all pages
  final int totalCount;
  
  /// Current page number (1-based)
  final int currentPage;
  
  /// Total number of pages
  final int totalPages;
  
  /// Number of items per page
  final int pageSize;
  
  /// Whether there is a next page
  final bool hasNext;
  
  /// Whether there is a previous page
  final bool hasPrevious;
  
  /// URL for next page (if available)
  final String? nextPageUrl;
  
  /// URL for previous page (if available)
  final String? previousPageUrl;

  PaginatedResponse({
    required this.results,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
    this.nextPageUrl,
    this.previousPageUrl,
  });

  /// Factory constructor from Django REST framework pagination format
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final results = (json['results'] as List)
        .map((item) => fromJsonT(item as Map<String, dynamic>))
        .toList();
    
    final totalCount = json['count'] ?? 0;
    final pageSize = results.length;
    final totalPages = pageSize > 0 ? (totalCount / pageSize).ceil() : 1;
    
    return PaginatedResponse<T>(
      results: results,
      totalCount: totalCount,
      currentPage: json['current_page'] ?? 1,
      totalPages: totalPages,
      pageSize: pageSize,
      hasNext: json['next'] != null,
      hasPrevious: json['previous'] != null,
      nextPageUrl: json['next'],
      previousPageUrl: json['previous'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson({Map<String, dynamic> Function(T)? toJsonT}) {
    return {
      'results': toJsonT != null 
          ? results.map((item) => toJsonT(item)).toList()
          : results,
      'count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'page_size': pageSize,
      'has_next': hasNext,
      'has_previous': hasPrevious,
      'next': nextPageUrl,
      'previous': previousPageUrl,
    };
  }

  /// Check if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Check if this is the last page
  bool get isLastPage => currentPage == totalPages;

  /// Check if response has any results
  bool get hasResults => results.isNotEmpty;

  /// Get the range of items shown (e.g., "1-20 of 100")
  String getDisplayRange() {
    if (totalCount == 0) return '0 of 0';
    
    final start = (currentPage - 1) * pageSize + 1;
    final end = (start + results.length - 1).clamp(start, totalCount);
    
    return '$start-$end of $totalCount';
  }

  @override
  String toString() {
    return 'PaginatedResponse{page: $currentPage/$totalPages, items: ${results.length}/$totalCount}';
  }
}

/// Response wrapper for operations that don't return data
class EmptyResponse {
  /// Success message
  final String? message;
  
  /// HTTP status code
  final int? statusCode;
  
  /// Additional metadata
  final Map<String, dynamic>? metadata;

  EmptyResponse({
    this.message,
    this.statusCode,
    this.metadata,
  });

  /// Factory constructor from JSON
  factory EmptyResponse.fromJson(Map<String, dynamic> json) {
    return EmptyResponse(
      message: json['message'],
      statusCode: json['status_code'] ?? json['status'],
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'status_code': statusCode,
      'metadata': metadata,
    };
  }
}

/// Response wrapper for count/statistics endpoints
class CountResponse {
  /// The count value
  final int count;
  
  /// Additional breakdown by category/type
  final Map<String, int>? breakdown;
  
  /// Metadata
  final Map<String, dynamic>? metadata;

  CountResponse({
    required this.count,
    this.breakdown,
    this.metadata,
  });

  /// Factory constructor from JSON
  factory CountResponse.fromJson(Map<String, dynamic> json) {
    // Handle different JSON formats
    final count = json['count'] ?? json['total'] ?? json['value'] ?? 0;
    
    Map<String, int>? breakdown;
    if (json.containsKey('breakdown')) {
      breakdown = Map<String, int>.from(json['breakdown']);
    }

    return CountResponse(
      count: count,
      breakdown: breakdown,
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'breakdown': breakdown,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'CountResponse{count: $count, breakdown: $breakdown}';
  }
}

/// Utility class for response parsing and validation
class ResponseParser {
  /// Parse a JSON string into ApiResponse
  static ApiResponse<T> parseJsonResponse<T>(
    String jsonString,
    T Function(dynamic)? fromJsonT,
  ) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, fromJsonT);
    } catch (e) {
      return ApiResponse.error(
        error: ApiError(
          type: 'parse_error',
          message: 'Failed to parse JSON response: $e',
        ),
      );
    }
  }

  /// Validate response structure
  static bool isValidResponse(Map<String, dynamic> json) {
    // Basic validation - should have either data or error
    return json.containsKey('data') || 
           json.containsKey('error') || 
           json.containsKey('message');
  }

  /// Extract pagination info from response headers
  static Map<String, dynamic>? extractPaginationFromHeaders(
    Map<String, dynamic> headers,
  ) {
    final linkHeader = headers['link'] ?? headers['Link'];
    if (linkHeader == null) return null;

    // Parse Link header for pagination URLs
    // Format: <url>; rel="next", <url>; rel="prev"
    final links = <String, String>{};
    final linkParts = linkHeader.split(',');
    
    for (final part in linkParts) {
      final match = RegExp(r'<([^>]+)>;\s*rel="([^"]+)"').firstMatch(part.trim());
      if (match != null) {
        links[match.group(2)!] = match.group(1)!;
      }
    }

    return links.isNotEmpty ? links : null;
  }
}

/// TODO: Phase 2 Integration Points
/// - Add integration with api_exceptions.dart for proper error mapping
/// - Implement response caching with cache metadata
/// - Add response validation and schema checking
/// - Create specialized response types for different endpoints
/// - Add response compression and decompression support
/// - Implement response time tracking and performance metrics
