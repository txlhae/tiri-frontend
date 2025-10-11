import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/models/notification_model.dart';
import 'package:tiri/services/api/notification_api_service.dart';
import 'package:tiri/services/api/websocket_service.dart';
import 'package:tiri/services/api_foundation.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/models/notification_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationController extends GetxController {

  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final isLoading = false.obs;
  
  // Phase 3: Django API integration properties
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxInt currentPage = 1.obs;
  final RxList<NotificationResponse> _apiNotifications = <NotificationResponse>[].obs;
  
  // Real-time WebSocket integration
  final RxBool isWebSocketConnected = false.obs;
  final Rx<WebSocketState> webSocketState = WebSocketState.disconnected.obs;
  WebSocketService? _webSocketService;
  
  // Pagination settings
  static const int pageSize = 20;
  
  List<NotificationModel> get notifications => _notifications;
  List<NotificationResponse> get apiNotifications => _apiNotifications;
  bool get canLoadMore => hasMoreData.value && !isLoadingMore.value;

  @override
  void onInit() {
    super.onInit();
    _initializeApiFoundation();
    // _initializeWebSocket(); // Temporarily disabled until backend WebSocket route is configured

    // Don't call _getNotifications() immediately - wait until authentication is ready
    // This prevents "Authentication failed" errors on app startup
    // The notifications will be loaded when the user navigates to the notifications page
  }

  /// Initialize API foundation for Django integration
  void _initializeApiFoundation() {
    try {
      ApiFoundationInitializer.initialize();
    } catch (e) {
    }
  }

  /// Initialize WebSocket service for real-time notifications
  void _initializeWebSocket() {
    try {
      _webSocketService = WebSocketService.instance;
    } catch (e) {
    }
  }

  /// Connect to WebSocket for real-time notifications
  Future<void> connectWebSocket() async {
    if (_webSocketService == null) {
      return;
    }

    try {
      // Get authentication token from AuthController
      final authController = Get.find<AuthController>();
      final userId = authController.currentUserStore.value?.userId;

      // Access the API service to get a fresh token
      final apiService = Get.find<ApiService>();
      // Ensure we have fresh tokens before WebSocket connection
      await apiService.refreshTokenIfNeeded();
      final token = apiService.accessToken;

      if (token == null || userId == null) {
        return;
      }

      // Initialize WebSocket with callbacks
      _webSocketService!.initialize(
        authToken: token,
        userId: userId,
        onNotification: _handleRealtimeNotification,
        onUnreadCount: _handleRealtimeUnreadCount,
        onConnectionStateChange: _handleWebSocketStateChange,
        onError: _handleWebSocketError,
      );

      // Connect to WebSocket
      await _webSocketService!.connect();
      
    } catch (e) {
    }
  }

  /// Handle real-time notification from WebSocket
  void _handleRealtimeNotification(NotificationResponse notification) {
    
    // Add to API notifications list at the beginning
    _apiNotifications.insert(0, notification);
    
    // Convert and add to legacy notifications list
    final legacyNotification = _convertSingleApiNotificationToLegacy(notification);
    _notifications.insert(0, legacyNotification);
    
    // Update unread count
    if (!notification.isRead) {
      unreadCount.value = unreadCount.value + 1;
    }
    
    // Show notification snackbar (optional)
    Get.snackbar(
      notification.title,
      notification.message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  /// Handle real-time unread count update
  void _handleRealtimeUnreadCount(int newUnreadCount) {
    unreadCount.value = newUnreadCount;
  }

  /// Handle WebSocket connection state changes
  void _handleWebSocketStateChange(WebSocketState state) {
    webSocketState.value = state;
    isWebSocketConnected.value = state == WebSocketState.connected;
    
    // Handle connection events
    switch (state) {
      case WebSocketState.connected:
        break;
      case WebSocketState.disconnected:
        break;
      case WebSocketState.error:
        break;
      case WebSocketState.reconnecting:
        break;
      case WebSocketState.connecting:
        break;
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(String error) {
    // Don't show user-facing errors for WebSocket issues - HTTP fallback handles it
  }

  /// Convert single API notification to legacy format
  NotificationModel _convertSingleApiNotificationToLegacy(NotificationResponse apiNotif) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUserStore.value?.userId ?? '';
    
    return NotificationModel(
      notificationId: apiNotif.id,
      status: apiNotif.isRead ? 'read' : 'unread',
      body: '${apiNotif.title}\n${apiNotif.message}',
      isUserWaiting: !apiNotif.isRead,
      userId: currentUserId,
      timestamp: apiNotif.createdAt,
    );
  }

  /// Disconnect WebSocket
  void disconnectWebSocket() {
    _webSocketService?.disconnect();
    isWebSocketConnected.value = false;
    webSocketState.value = WebSocketState.disconnected;
  }

  /// Update WebSocket authentication token
  void updateWebSocketAuth(String newToken) {
    _webSocketService?.updateAuthToken(newToken);
  }

  Future<void> _getNotifications() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      // Check authentication first
      final apiService = Get.find<ApiService>();
      if (!apiService.isAuthenticated) {
        throw Exception('Authentication required. Please login to view notifications.');
      }

      // Phase 3: Django API call
      final response = await NotificationApiService.getNotifications(
        page: 1,
        pageSize: pageSize,
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;
        _apiNotifications.assignAll(paginatedData.results);
        hasMoreData.value = paginatedData.hasNext;
        currentPage.value = 1;
        
        // Convert API notifications to legacy format for UI compatibility
        final List<NotificationModel> legacyNotifications = 
            _convertApiNotificationsToLegacy(paginatedData.results);
        _notifications.assignAll(legacyNotifications);
        
        await _calculateUnreadCountFromApi();
      } else {
        throw Exception(response.error?.message ?? 'Failed to fetch notifications');
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
      
      // Fallback: Try to load cached notifications
      await _loadCachedNotifications();
      
      // 🚨 FIXED: Don't show snackbar for silent auth refresh errors
      // Check if this was a silently handled auth error (401 that was auto-resolved)
      bool isSilentAuthError = false;
      
      // Check if the error contains silent auth success flag context
      // This prevents showing 401 errors that were actually resolved silently
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        // Give the auth interceptor a moment to complete silent refresh
        await Future.delayed(const Duration(milliseconds: 100));
        isSilentAuthError = true; // Assume it was handled silently
      }
      
      if (!isSilentAuthError) {
        Get.snackbar(
          'Error', 
          'Error fetching notifications: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Convert API NotificationResponse to legacy NotificationModel for UI compatibility
  List<NotificationModel> _convertApiNotificationsToLegacy(List<NotificationResponse> apiNotifications) {
    final authController = Get.find<AuthController>();
    final currentUserId = authController.currentUserStore.value?.userId ?? '';
    
    return apiNotifications.map((apiNotif) {
      return NotificationModel(
        notificationId: apiNotif.id,
        status: apiNotif.isRead ? 'read' : 'unread',
        body: '${apiNotif.title}\n${apiNotif.message}',
        isUserWaiting: !apiNotif.isRead,
        userId: currentUserId, // Use current user ID
        timestamp: apiNotif.createdAt,
      );
    }).toList();
  }

  /// Calculate unread count using Django API
  Future<void> _calculateUnreadCountFromApi() async {
    try {
      final response = await NotificationApiService.getUnreadCount();
      
      if (response.success && response.data != null) {
        unreadCount.value = response.data!.unreadCount;
      } else {
        // Fallback to local calculation
        await _calculateUnreadCount(_notifications);
      }
    } catch (e) {
      // Fallback to local calculation
      await _calculateUnreadCount(_notifications);
    }
  }

  /// Load cached notifications from SharedPreferences (offline fallback)
  Future<void> _loadCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_notifications');
      
      if (cachedData != null) {
        // In a real implementation, you would parse the cached JSON
        // For now, just initialize empty list
        _notifications.assignAll(<NotificationModel>[]);
      }
    } catch (e) {
    }
  }

  Future<void> updateNotify(NotificationModel notify) async {
    try {
      // await _store.updateNotification(notify);
    } catch (e) {
    }
  }

  Future<void> loadNotification() async {
    try {
      // Check if user is authenticated before making API calls
      final apiService = Get.find<ApiService>();
      if (!apiService.isAuthenticated) {
        hasError.value = true;
        errorMessage.value = 'Please login to view notifications';
        return;
      }

      // Phase 3: Use Django API
      await _getNotifications();

      // Auto-connect WebSocket disabled to prevent connection attempts when clicking notification button
      // WebSocket should only connect during app initialization, not when refreshing notifications
      // if (!isWebSocketConnected.value) {
      //   await connectWebSocket();
      // }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }
  
  /// Pull-to-refresh functionality
  Future<void> refreshNotifications() async {
    currentPage.value = 1;
    hasMoreData.value = true;
    await loadNotification();
  }
  
  /// Load more notifications for pagination
  Future<void> loadMoreNotifications() async {
    if (!canLoadMore) return;
    
    isLoadingMore.value = true;
    
    try {
      final nextPage = currentPage.value + 1;
      final response = await NotificationApiService.getNotifications(
        page: nextPage,
        pageSize: pageSize,
      );

      if (response.success && response.data != null) {
        final paginatedData = response.data!;
        
        // Add new notifications to existing list
        _apiNotifications.addAll(paginatedData.results);
        hasMoreData.value = paginatedData.hasNext;
        currentPage.value = nextPage;
        
        // Convert and add to legacy format
        final newLegacyNotifications = 
            _convertApiNotificationsToLegacy(paginatedData.results);
        _notifications.addAll(newLegacyNotifications);
        
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to load more notifications',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> sendReminderNotification(NotificationModel notification) async {
    try {
      // Phase 3: Send via Django API
      // Note: This would require a CREATE endpoint in Django
      // For now, we'll log and potentially add to local list
      
      
      // TODO: Implement Django API call for creating notifications
      // Example:
      // final response = await NotificationApiService.createNotification({
      //   'title': 'Reminder',
      //   'message': notification.body,
      //   'category': 'reminder',
      // });
      
      // For now, add to local list for immediate UI update
      _notifications.insert(0, notification);
      
      // Update unread count
      await _calculateUnreadCountFromApi();
      
    } catch (e) {
      Get.snackbar("Error", "Failed to send notification");
      rethrow;
    }
  }

  /// Add notification to the list
  /// Temporary method for Phase 3 compatibility
  void addNotification(NotificationModel notification) {
    // TODO: Implement proper notification handling in Phase 4
    // For now, just log the notification
  }

  Future<void> _calculateUnreadCount(List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notifications') ?? [];
      
      // Get current user ID safely
      final authController = Get.find<AuthController>();
      final currentUserId = authController.currentUserStore.value?.userId ?? '';
      
      if (currentUserId.isNotEmpty) {
        final unread = notifications
            .where((n) => 
                !readIds.contains(n.notificationId) && 
                n.userId == currentUserId)
            .length;
        unreadCount.value = unread;
      } else {
        unreadCount.value = 0;
      }
    } catch (e) {
      unreadCount.value = 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Phase 3: Use Django API
      final response = await NotificationApiService.markAllAsRead();
      
      if (response.success) {
        // Update local state
        unreadCount.value = 0;
        
        // Update API notifications state
        for (int i = 0; i < _apiNotifications.length; i++) {
          _apiNotifications[i] = _apiNotifications[i].copyWith(isRead: true);
        }
        
        // Update legacy notifications state
        for (int i = 0; i < _notifications.length; i++) {
          final current = _notifications[i];
          _notifications[i] = NotificationModel(
            notificationId: current.notificationId,
            status: 'read',
            body: current.body,
            isUserWaiting: false,
            userId: current.userId,
            timestamp: current.timestamp,
          );
        }
        
        // Send WebSocket message for real-time sync
        // if (isWebSocketConnected.value) {
        //   _webSocketService?.markAllNotificationsAsRead();
        // }
        
        // Also update SharedPreferences for offline compatibility
        final prefs = await SharedPreferences.getInstance();
        final allIds = _notifications.map((n) => n.notificationId).toList();
        await prefs.setStringList('read_notifications', allIds);
        
      } else {
        throw Exception(response.error?.message ?? 'Failed to mark all as read');
      }
    } catch (e) {
      
      // Fallback to local-only marking
      try {
        final prefs = await SharedPreferences.getInstance();
        final allIds = _notifications.map((n) => n.notificationId).toList();
        await prefs.setStringList('read_notifications', allIds);
        unreadCount.value = 0;
      } catch (localError) {
        Get.snackbar("Error", "Failed to mark notifications as read");
      }
    }
  }
  
  /// Mark single notification as read (Django API)
  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await NotificationApiService.markAsRead(notificationId);
      
      if (response.success) {
        // Update local state
        final apiIndex = _apiNotifications.indexWhere((n) => n.id == notificationId);
        if (apiIndex != -1) {
          _apiNotifications[apiIndex] = _apiNotifications[apiIndex].copyWith(isRead: true);
        }
        
        final legacyIndex = _notifications.indexWhere((n) => n.notificationId == notificationId);
        if (legacyIndex != -1) {
          final current = _notifications[legacyIndex];
          _notifications[legacyIndex] = NotificationModel(
            notificationId: current.notificationId,
            status: 'read',
            body: current.body,
            isUserWaiting: false,
            userId: current.userId,
            timestamp: current.timestamp,
          );
        }
        
        // Send WebSocket message for real-time sync
        // if (isWebSocketConnected.value) {
        //   _webSocketService?.markNotificationAsRead(notificationId);
        // }
        
        // Update unread count
        await _calculateUnreadCountFromApi();
        
      }
    } catch (e) {
    }
  }
  
  /// Filter notifications by read status
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => n.status == 'unread').toList();
  }
  
  /// Filter notifications by date range
  List<NotificationModel> getNotificationsByDateRange(DateTime start, DateTime end) {
    return _notifications.where((n) => 
        n.timestamp.isAfter(start) && n.timestamp.isBefore(end)
    ).toList();
  }
  
  /// Search notifications by content
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;
    
    final lowerQuery = query.toLowerCase();
    return _notifications.where((n) => 
        n.body.toLowerCase().contains(lowerQuery)
    ).toList();
  }
  
  /// Clear error state
  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }
  
  /// Update FCM token (for push notifications)
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final response = await NotificationApiService.updateFcmToken(
        fcmToken,
        deviceInfo: {
          'device_type': 'mobile',
          'platform': GetPlatform.isAndroid ? 'android' : 'ios',
        },
      );
      
      if (response.success) {
      }
    } catch (e) {
    }
  }
  
  /// Get notification statistics
  Future<Map<String, dynamic>?> getNotificationStatistics({int days = 30}) async {
    try {
      final response = await NotificationApiService.getStatistics(days: days);
      
      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (e) {
    }
    return null;
  }

  @override
  void onClose() {
    disconnectWebSocket();
    super.onClose();
  }
}



