// lib/services/firebase_notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Firebase Cloud Messaging Service for TIRI application
/// 
/// Features:
/// - FCM token generation and management
/// - Push notification permissions
/// - Token registration with backend API
/// - Foreground/background notification handling
/// - Notification click actions and navigation
/// - Token refresh and cleanup on logout
/// - Local notification display
class FirebaseNotificationService extends GetxService {
  // =============================================================================
  // SINGLETON PATTERN
  // =============================================================================
  
  static FirebaseNotificationService? _instance;
  static FirebaseNotificationService get instance => _instance ??= FirebaseNotificationService._internal();
  
  factory FirebaseNotificationService() => instance;
  
  FirebaseNotificationService._internal();

  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================
  
  late FirebaseMessaging _firebaseMessaging;
  late FlutterLocalNotificationsPlugin _localNotifications;
  late ApiService _apiService;
  // AuthService will be loaded lazily to avoid circular dependency
  late FlutterSecureStorage _secureStorage;
  
  /// Current FCM registration token
  String? _fcmToken;
  
  /// Track initialization status
  bool _isInitialized = false;
  
  /// Track permission status
  bool _hasNotificationPermission = false;
  
  /// Cached app version info
  String? _appVersion;
  
  /// Track last registered token to prevent duplicates
  String? _lastRegisteredToken;
  
  /// Track last registration time to prevent rapid duplicate calls
  DateTime? _lastRegistrationTime;
  
  /// Minimum time between registration attempts (in milliseconds)
  static const int _registrationCooldownMs = 5000; // 5 seconds

  // =============================================================================
  // SECURE STORAGE KEYS
  // =============================================================================
  
  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationPermissionKey = 'notification_permission';
  static const String _lastRegisteredTokenKey = 'last_registered_fcm_token';

  // =============================================================================
  // NOTIFICATION CONFIGURATION
  // =============================================================================
  
  /// Android notification channel for high importance notifications
  static const AndroidNotificationChannel _highImportanceChannel = AndroidNotificationChannel(
    'tiri_high_importance', // Channel ID
    'TIRI Important', // Channel name
    description: 'High importance notifications for TIRI app',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Android notification channel for default notifications
  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'tiri_default', // Channel ID
    'TIRI Notifications', // Channel name
    description: 'Default notifications for TIRI app',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  
  /// Initialize the Firebase notification service
  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }

  /// Initialize Firebase messaging and local notifications
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        return;
      }


      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        _isInitialized = false;
        return;
      }
      

      // Initialize dependencies
      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();
      _apiService = ApiService.instance;
      // AuthService will be accessed lazily when needed
      _secureStorage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up Firebase messaging
      await _setupFirebaseMessaging();

      // Load saved data
      await _loadSavedData();

      _isInitialized = true;

    } catch (e) {
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_highImportanceChannel);
      await androidPlugin?.createNotificationChannel(_defaultChannel);
    }

  }

  /// Set up Firebase messaging handlers
  Future<void> _setupFirebaseMessaging() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapped);

    // Handle messages when app is opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTapped(initialMessage);
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

  }

  /// Load saved data from storage
  Future<void> _loadSavedData() async {
    try {
      // Load FCM token
      _fcmToken = await _secureStorage.read(key: _fcmTokenKey);
      
      // Load permission status
      final permissionString = await _secureStorage.read(key: _notificationPermissionKey);
      _hasNotificationPermission = permissionString == 'true';
      
      // Load last registered token
      _lastRegisteredToken = await _secureStorage.read(key: _lastRegisteredTokenKey);

      if (ApiConfig.enableLogging) {
      }
    } catch (e) {
    }
  }

  // =============================================================================
  // PERMISSION MANAGEMENT
  // =============================================================================
  
  /// Request notification permissions from the user
  Future<bool> requestNotificationPermissions() async {
    try {

      // For Android 13+ (API 33+), use permission_handler
      if (Platform.isAndroid) {
        
        // Check current status first
        final currentStatus = await Permission.notification.status;
        
        final status = await Permission.notification.request();
        
        _hasNotificationPermission = status == PermissionStatus.granted;
      } 
      // For iOS, use Firebase messaging
      else if (Platform.isIOS) {
        
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          announcement: false,
        );
        
        
        _hasNotificationPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                                   settings.authorizationStatus == AuthorizationStatus.provisional;
      }

      // Save permission status
      await _secureStorage.write(
        key: _notificationPermissionKey, 
        value: _hasNotificationPermission.toString(),
      );

      return _hasNotificationPermission;

    } catch (e) {
      return false;
    }
  }

  /// Check current notification permission status
  Future<bool> checkNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        _hasNotificationPermission = status == PermissionStatus.granted;
      } else if (Platform.isIOS) {
        final settings = await _firebaseMessaging.getNotificationSettings();
        _hasNotificationPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                                   settings.authorizationStatus == AuthorizationStatus.provisional;
      }

      return _hasNotificationPermission;
    } catch (e) {
      return false;
    }
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================
  
  /// Get app version information
  Future<String> _getAppVersion() async {
    if (_appVersion != null) {
      return _appVersion!;
    }
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      return _appVersion!;
    } catch (e) {
      _appVersion = '1.0.0+1'; // Fallback version
      return _appVersion!;
    }
  }
  
  /// Get device name based on platform
  Future<String> _getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Web Browser';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  // =============================================================================
  // TOKEN MANAGEMENT
  // =============================================================================
  
  /// Get FCM registration token
  Future<String?> getFCMToken() async {
    try {
      
      if (!_hasNotificationPermission) {
        return null;
      }

      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        _fcmToken = token;
        await _secureStorage.write(key: _fcmTokenKey, value: token);
      } else {
      }
      
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Register FCM token with backend API
  Future<bool> registerTokenWithBackend() async {
    try {
      
      // Get FCM token first to check for duplicates
      final token = await getFCMToken();
      if (token == null) {
        return false;
      }
      
      // Check if token is the same as last registered token
      if (_lastRegisteredToken == token) {
        
        // Check cooldown period
        if (_lastRegistrationTime != null) {
          final timeSinceLastRegistration = DateTime.now().difference(_lastRegistrationTime!).inMilliseconds;
          if (timeSinceLastRegistration < _registrationCooldownMs) {
            final remainingCooldown = (_registrationCooldownMs - timeSinceLastRegistration) / 1000;
            return true; // Return true because token is already registered
          }
        }
      }
      
      
      // Check if user is authenticated using lazy loading
      try {
        final AuthService authService = Get.find<AuthService>();
        
        if (!authService.hasValidTokens) {
          
          // Wait a short time for tokens to be set after login
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!authService.hasValidTokens) {
            return false;
          }
        }
        
      } catch (e) {
        return false;
      }


      // Determine device type
      String deviceType;
      if (Platform.isAndroid) {
        deviceType = 'android';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else {
        deviceType = 'web';
      }

      // Get device info
      final deviceName = await _getDeviceName();
      final appVersion = await _getAppVersion();
      

      // Register with backend
      
      final response = await _apiService.post(
        '/api/notifications/device-tokens/register/',
        data: {
          'token': token,
          'device_type': deviceType,
          'device_name': deviceName,
          'app_version': appVersion,
        },
      );


      if (response.statusCode == 200) {
        final data = response.data;
        
        // Track successful registration to prevent duplicates
        _lastRegisteredToken = token;
        _lastRegistrationTime = DateTime.now();
        await _secureStorage.write(key: _lastRegisteredTokenKey, value: token);
        
        return true;
      }

      return false;

    } catch (e) {
      return false;
    }
  }

  /// Remove FCM token from backend on logout
  Future<bool> removeTokenFromBackend() async {
    try {
      try {
        final AuthService authService = Get.find<AuthService>();
        if (!authService.hasValidTokens) {
          return true; // Not an error if user is already logged out
        }
      } catch (e) {
        return true; // Not an error if AuthService is not available
      }

      final response = await _apiService.post(
        '/api/notifications/device-tokens/remove/',
        data: {
          'device_type': 'all', // Remove all tokens for this user
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return true;
      }

      return false;

    } catch (e) {
      return false;
    }
  }

  /// Handle FCM token refresh
  void _onTokenRefresh(String token) async {
    try {
      
      _fcmToken = token;
      await _secureStorage.write(key: _fcmTokenKey, value: token);
      
      // Re-register with backend if user is authenticated
      try {
        final AuthService authService = Get.find<AuthService>();
        if (authService.hasValidTokens) {
          await registerTokenWithBackend();
        }
      } catch (e) {
      }
    } catch (e) {
    }
  }

  // =============================================================================
  // NOTIFICATION HANDLERS
  // =============================================================================
  
  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      
      // Show local notification for foreground messages
      await _showLocalNotification(message);
      
      // Handle any custom data processing
      _processNotificationData(message);
      
    } catch (e) {
    }
  }

  /// Handle notification tapped (from Firebase message)
  void _handleNotificationTapped(RemoteMessage message) {
    try {
      
      _processNotificationClick(message.data);
      
    } catch (e) {
    }
  }

  /// Handle local notification tapped
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      
      if (notificationResponse.payload != null) {
        final data = jsonDecode(notificationResponse.payload!);
        _processNotificationClick(data);
      }
      
    } catch (e) {
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // Determine notification channel based on priority
      final channelId = message.data['priority'] == 'high' ? 
                       _highImportanceChannel.id : 
                       _defaultChannel.id;

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == _highImportanceChannel.id ? 
          _highImportanceChannel.name : 
          _defaultChannel.name,
        channelDescription: channelId == _highImportanceChannel.id ? 
                           _highImportanceChannel.description : 
                           _defaultChannel.description,
        importance: channelId == _highImportanceChannel.id ? 
                   Importance.high : 
                   Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails();

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification with payload containing message data
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );


    } catch (e) {
    }
  }

  /// Process notification data for custom handling
  void _processNotificationData(RemoteMessage message) {
    try {
      final data = message.data;
      final notificationType = data['notification_type'];
      
      // Handle different notification types
      switch (notificationType) {
        case 'new_message':
          // Handle new chat message
          break;
          
        case 'request_update':
          // Handle service request update
          break;
          
        case 'approval_needed':
          // Handle approval needed notification
          break;
          
        default:
      }
      
    } catch (e) {
    }
  }

  /// Process notification click actions and navigation
  void _processNotificationClick(Map<String, dynamic> data) {
    try {
      final clickAction = data['click_action'] as String?;
      
      if (clickAction == null) {
        return;
      }


      // Handle different click actions
      if (clickAction.startsWith('open_chat:')) {
        final chatId = clickAction.split(':')[1];
        // Navigate to chat screen
        // Get.toNamed('/chat', arguments: {'chatId': chatId});
        
      } else if (clickAction.startsWith('open_request:')) {
        final requestId = clickAction.split(':')[1];
        // Navigate to request details screen
        // Get.toNamed('/request-details', arguments: {'requestId': requestId});
        
      } else if (clickAction.startsWith('open_approval:')) {
        final approvalId = clickAction.split(':')[1];
        // Navigate to approval screen
        // Get.toNamed('/approvals', arguments: {'approvalId': approvalId});
        
      } else {
      }
      
    } catch (e) {
    }
  }

  // =============================================================================
  // PUBLIC API METHODS
  // =============================================================================
  
  /// Complete setup flow for push notifications
  Future<bool> setupPushNotifications() async {
    try {

      // 1. Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          return false;
        }
      }

      // 2. Check permissions (don't request again - should be handled by NotificationPermissionService)
      final hasPermission = await checkNotificationPermissions();
      if (!hasPermission) {
        return false;
      }

      // 3. Get FCM token
      final token = await getFCMToken();
      if (token == null) {
        return false;
      }

      // 4. Register with backend
      final registered = await registerTokenWithBackend();
      if (!registered) {
        return false;
      }

      return true;

    } catch (e) {
      return false;
    }
  }

  /// Send test notification (for debugging)
  Future<bool> sendTestNotification() async {
    try {
      try {
        final AuthService authService = Get.find<AuthService>();
        if (!authService.hasValidTokens) {
          return false;
        }
      } catch (e) {
        return false;
      }

      final response = await _apiService.post(
        '/api/notifications/device-tokens/test/',
        data: {
          'title': 'TIRI Test Notification',
          'message': 'Push notifications are working correctly!',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return true;
      }

      return false;

    } catch (e) {
      return false;
    }
  }

  /// Clean up on logout
  Future<void> cleanup() async {
    try {

      // Remove token from backend
      await removeTokenFromBackend();

      // Clear local data
      await _secureStorage.delete(key: _fcmTokenKey);
      await _secureStorage.delete(key: _notificationPermissionKey);
      await _secureStorage.delete(key: _lastRegisteredTokenKey);
      
      // Clear instance variables
      _fcmToken = null;
      _hasNotificationPermission = false;
      _lastRegisteredToken = null;
      _lastRegistrationTime = null;


    } catch (e) {
    }
  }

  // =============================================================================
  // GETTERS
  // =============================================================================
  
  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if user has notification permission
  bool get hasNotificationPermission => _hasNotificationPermission;
  
  /// Get current FCM token
  String? get fcmToken => _fcmToken;
  
  /// Check if push notifications are fully set up
  bool get isFullySetup => _isInitialized && _hasNotificationPermission && _fcmToken != null;
}