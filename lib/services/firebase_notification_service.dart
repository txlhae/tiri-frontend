// lib/services/firebase_notification_service.dart

import 'dart:convert';
import 'dart:developer';
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
        log('⚠️ INIT CHECK: FirebaseNotificationService already initialized, returning early', name: 'FIREBASE_NOTIFICATIONS');
        return;
      }

      log('🚀 INIT START: Initializing FirebaseNotificationService', name: 'FIREBASE_NOTIFICATIONS');

      // Ensure Firebase is initialized
      if (Firebase.apps.isEmpty) {
        log('❌ INIT FAILED: Firebase not initialized - skipping FCM setup', name: 'FIREBASE_NOTIFICATIONS');
        _isInitialized = false;
        return;
      }
      
      log('✅ INIT CHECK: Firebase apps available: ${Firebase.apps.length}', name: 'FIREBASE_NOTIFICATIONS');

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
      log('🎉 FirebaseNotificationService initialized successfully', name: 'FIREBASE_NOTIFICATIONS');

    } catch (e) {
      log('Error initializing FirebaseNotificationService: $e', name: 'FIREBASE_NOTIFICATIONS');
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

    log('Local notifications initialized', name: 'FIREBASE_NOTIFICATIONS');
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

    log('Firebase messaging handlers set up', name: 'FIREBASE_NOTIFICATIONS');
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
        log('Saved data loaded - FCM token: ${_fcmToken != null ? "available" : "missing"}, Permission: $_hasNotificationPermission, Last registered: ${_lastRegisteredToken != null ? "available" : "missing"}', name: 'FIREBASE_NOTIFICATIONS');
      }
    } catch (e) {
      log('Error loading saved data: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  // =============================================================================
  // PERMISSION MANAGEMENT
  // =============================================================================
  
  /// Request notification permissions from the user
  Future<bool> requestNotificationPermissions() async {
    try {
      log('📱 DETAILED PERMISSIONS: Starting permission request', name: 'FIREBASE_NOTIFICATIONS');
      log('📱 DETAILED PERMISSIONS: Platform: ${Platform.operatingSystem}', name: 'FIREBASE_NOTIFICATIONS');

      // For Android 13+ (API 33+), use permission_handler
      if (Platform.isAndroid) {
        log('📱 DETAILED PERMISSIONS: Android platform detected, requesting notification permission', name: 'FIREBASE_NOTIFICATIONS');
        
        // Check current status first
        final currentStatus = await Permission.notification.status;
        log('📱 DETAILED PERMISSIONS: Current Android permission status: $currentStatus', name: 'FIREBASE_NOTIFICATIONS');
        
        final status = await Permission.notification.request();
        log('📱 DETAILED PERMISSIONS: Android permission request result: $status', name: 'FIREBASE_NOTIFICATIONS');
        
        _hasNotificationPermission = status == PermissionStatus.granted;
        log('📱 DETAILED PERMISSIONS: Android _hasNotificationPermission set to: $_hasNotificationPermission', name: 'FIREBASE_NOTIFICATIONS');
      } 
      // For iOS, use Firebase messaging
      else if (Platform.isIOS) {
        log('📱 DETAILED PERMISSIONS: iOS platform detected, requesting Firebase permissions', name: 'FIREBASE_NOTIFICATIONS');
        
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          announcement: false,
        );
        
        log('📱 DETAILED PERMISSIONS: iOS permission request result: ${settings.authorizationStatus}', name: 'FIREBASE_NOTIFICATIONS');
        
        _hasNotificationPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
                                   settings.authorizationStatus == AuthorizationStatus.provisional;
        log('📱 DETAILED PERMISSIONS: iOS _hasNotificationPermission set to: $_hasNotificationPermission', name: 'FIREBASE_NOTIFICATIONS');
      }

      // Save permission status
      log('📱 DETAILED PERMISSIONS: Saving permission status to secure storage', name: 'FIREBASE_NOTIFICATIONS');
      await _secureStorage.write(
        key: _notificationPermissionKey, 
        value: _hasNotificationPermission.toString(),
      );
      log('📱 DETAILED PERMISSIONS: Permission status saved', name: 'FIREBASE_NOTIFICATIONS');

      log('📱 DETAILED PERMISSIONS: Final result - Notification permissions ${_hasNotificationPermission ? "granted" : "denied"}', name: 'FIREBASE_NOTIFICATIONS');
      return _hasNotificationPermission;

    } catch (e) {
      log('💥 DETAILED PERMISSIONS: Error requesting notification permissions: $e', name: 'FIREBASE_NOTIFICATIONS');
      log('💥 DETAILED PERMISSIONS: Stack trace: ${StackTrace.current}', name: 'FIREBASE_NOTIFICATIONS');
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
      log('Error checking notification permissions: $e', name: 'FIREBASE_NOTIFICATIONS');
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
      log('Error getting app version: $e', name: 'FIREBASE_NOTIFICATIONS');
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
      print('🔑 DEBUG getFCMToken: Starting FCM token retrieval');
      print('🔑 DEBUG getFCMToken: _hasNotificationPermission = $_hasNotificationPermission');
      
      if (!_hasNotificationPermission) {
        print('❌ DEBUG getFCMToken: No notification permission - cannot get FCM token');
        return null;
      }

      print('🔑 DEBUG getFCMToken: Calling _firebaseMessaging.getToken()...');
      final token = await _firebaseMessaging.getToken();
      print('🔑 DEBUG getFCMToken: _firebaseMessaging.getToken() returned: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');
      
      if (token != null) {
        print('🔑 DEBUG getFCMToken: Token is not null, saving to storage and cache');
        _fcmToken = token;
        await _secureStorage.write(key: _fcmTokenKey, value: token);
        print('🔑 DEBUG getFCMToken: Token saved successfully');
      } else {
        print('❌ DEBUG getFCMToken: Token is NULL - this is the problem!');
      }
      
      return token;
    } catch (e) {
      print('💥 DEBUG getFCMToken: Exception caught: $e');
      print('💥 DEBUG getFCMToken: Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Register FCM token with backend API
  Future<bool> registerTokenWithBackend() async {
    try {
      log('🚀 STARTING FCM TOKEN REGISTRATION WITH BACKEND...', name: 'FIREBASE_NOTIFICATIONS');
      
      // Get FCM token first to check for duplicates
      final token = await getFCMToken();
      if (token == null) {
        log('❌ No FCM token available for registration', name: 'FIREBASE_NOTIFICATIONS');
        return false;
      }
      
      // Check if token is the same as last registered token
      if (_lastRegisteredToken == token) {
        log('🔄 DEDUPLICATION: Same token already registered, checking cooldown period', name: 'FIREBASE_NOTIFICATIONS');
        
        // Check cooldown period
        if (_lastRegistrationTime != null) {
          final timeSinceLastRegistration = DateTime.now().difference(_lastRegistrationTime!).inMilliseconds;
          if (timeSinceLastRegistration < _registrationCooldownMs) {
            final remainingCooldown = (_registrationCooldownMs - timeSinceLastRegistration) / 1000;
            log('⏰ DEDUPLICATION: Skipping registration - cooldown active (${remainingCooldown.toStringAsFixed(1)}s remaining)', name: 'FIREBASE_NOTIFICATIONS');
            return true; // Return true because token is already registered
          }
        }
      }
      
      log('✅ DEDUPLICATION: Token check passed - proceeding with registration', name: 'FIREBASE_NOTIFICATIONS');
      
      // Check if user is authenticated using lazy loading
      try {
        final AuthService authService = Get.find<AuthService>();
        log('✅ Found AuthService, checking token validity...', name: 'FIREBASE_NOTIFICATIONS');
        log('🔍 DEBUG: authService.hasValidTokens = ${authService.hasValidTokens}', name: 'FIREBASE_NOTIFICATIONS');
        log('🔍 DEBUG: authService.runtimeType = ${authService.runtimeType}', name: 'FIREBASE_NOTIFICATIONS');
        
        if (!authService.hasValidTokens) {
          log('❌ User not authenticated - hasValidTokens = false, cannot register FCM token', name: 'FIREBASE_NOTIFICATIONS');
          log('🔍 DEBUG: Will retry after short delay to allow tokens to be set...', name: 'FIREBASE_NOTIFICATIONS');
          
          // Wait a short time for tokens to be set after login
          await Future.delayed(const Duration(milliseconds: 500));
          
          log('🔄 RETRY: Checking authentication again after delay...', name: 'FIREBASE_NOTIFICATIONS');
          if (!authService.hasValidTokens) {
            log('❌ Still not authenticated after retry - aborting FCM token registration', name: 'FIREBASE_NOTIFICATIONS');
            return false;
          }
          log('✅ Authentication valid after retry!', name: 'FIREBASE_NOTIFICATIONS');
        }
        
        log('✅ User has valid tokens, proceeding with FCM registration...', name: 'FIREBASE_NOTIFICATIONS');
      } catch (e) {
        log('❌ AuthService not available - cannot register FCM token: $e', name: 'FIREBASE_NOTIFICATIONS');
        return false;
      }

      log('✅ FCM token obtained: ${token.substring(0, 20)}...', name: 'FIREBASE_NOTIFICATIONS');

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
      
      log('📋 Registration data prepared:', name: 'FIREBASE_NOTIFICATIONS');
      log('   - Device Type: $deviceType', name: 'FIREBASE_NOTIFICATIONS');
      log('   - Device Name: $deviceName', name: 'FIREBASE_NOTIFICATIONS');
      log('   - App Version: $appVersion', name: 'FIREBASE_NOTIFICATIONS');

      // Register with backend
      print('🌐 BACKEND DEBUG: Calling POST /api/notifications/device-tokens/register/');
      print('🌐 BACKEND DEBUG: Request data: {token: ${token.substring(0, 20)}..., device_type: $deviceType, device_name: $deviceName, app_version: $appVersion}');
      
      final response = await _apiService.post(
        '/api/notifications/device-tokens/register/',
        data: {
          'token': token,
          'device_type': deviceType,
          'device_name': deviceName,
          'app_version': appVersion,
        },
      );

      print('📡 BACKEND DEBUG: API response status: ${response.statusCode}');
      print('📡 BACKEND DEBUG: API response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        log('🎉 FCM token registered successfully: ${data['message'] ?? "Success"}', name: 'FIREBASE_NOTIFICATIONS');
        
        // Track successful registration to prevent duplicates
        _lastRegisteredToken = token;
        _lastRegistrationTime = DateTime.now();
        await _secureStorage.write(key: _lastRegisteredTokenKey, value: token);
        
        log('📝 DEDUPLICATION: Registration tracking updated', name: 'FIREBASE_NOTIFICATIONS');
        return true;
      }

      log('❌ Failed to register FCM token - HTTP ${response.statusCode}', name: 'FIREBASE_NOTIFICATIONS');
      log('❌ Response data: ${response.data}', name: 'FIREBASE_NOTIFICATIONS');
      return false;

    } catch (e) {
      log('💥 Error registering FCM token with backend: $e', name: 'FIREBASE_NOTIFICATIONS');
      log('💥 Stack trace: ${StackTrace.current}', name: 'FIREBASE_NOTIFICATIONS');
      return false;
    }
  }

  /// Remove FCM token from backend on logout
  Future<bool> removeTokenFromBackend() async {
    try {
      try {
        final AuthService authService = Get.find<AuthService>();
        if (!authService.hasValidTokens) {
          log('User not authenticated - skipping token removal', name: 'FIREBASE_NOTIFICATIONS');
          return true; // Not an error if user is already logged out
        }
      } catch (e) {
        log('AuthService not available - skipping token removal: $e', name: 'FIREBASE_NOTIFICATIONS');
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
        log('FCM tokens removed successfully: ${data['message'] ?? "Success"}', name: 'FIREBASE_NOTIFICATIONS');
        return true;
      }

      log('Failed to remove FCM tokens - HTTP ${response.statusCode}', name: 'FIREBASE_NOTIFICATIONS');
      return false;

    } catch (e) {
      log('Error removing FCM tokens from backend: $e', name: 'FIREBASE_NOTIFICATIONS');
      return false;
    }
  }

  /// Handle FCM token refresh
  void _onTokenRefresh(String token) async {
    try {
      log('FCM token refreshed: ${token.substring(0, 20)}...', name: 'FIREBASE_NOTIFICATIONS');
      
      _fcmToken = token;
      await _secureStorage.write(key: _fcmTokenKey, value: token);
      
      // Re-register with backend if user is authenticated
      try {
        final AuthService authService = Get.find<AuthService>();
        if (authService.hasValidTokens) {
          await registerTokenWithBackend();
        }
      } catch (e) {
        log('AuthService not available during token refresh: $e', name: 'FIREBASE_NOTIFICATIONS');
      }
    } catch (e) {
      log('Error handling token refresh: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  // =============================================================================
  // NOTIFICATION HANDLERS
  // =============================================================================
  
  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) async {
    try {
      log('Received foreground message: ${message.notification?.title}', name: 'FIREBASE_NOTIFICATIONS');
      
      // Show local notification for foreground messages
      await _showLocalNotification(message);
      
      // Handle any custom data processing
      _processNotificationData(message);
      
    } catch (e) {
      log('Error handling foreground message: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  /// Handle notification tapped (from Firebase message)
  void _handleNotificationTapped(RemoteMessage message) {
    try {
      log('Notification tapped: ${message.notification?.title}', name: 'FIREBASE_NOTIFICATIONS');
      
      _processNotificationClick(message.data);
      
    } catch (e) {
      log('Error handling notification tap: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  /// Handle local notification tapped
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    try {
      log('Local notification tapped: ${notificationResponse.payload}', name: 'FIREBASE_NOTIFICATIONS');
      
      if (notificationResponse.payload != null) {
        final data = jsonDecode(notificationResponse.payload!);
        _processNotificationClick(data);
      }
      
    } catch (e) {
      log('Error handling local notification tap: $e', name: 'FIREBASE_NOTIFICATIONS');
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

      log('Local notification shown: ${notification.title}', name: 'FIREBASE_NOTIFICATIONS');

    } catch (e) {
      log('Error showing local notification: $e', name: 'FIREBASE_NOTIFICATIONS');
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
          log('Processing new message notification', name: 'FIREBASE_NOTIFICATIONS');
          break;
          
        case 'request_update':
          // Handle service request update
          log('Processing request update notification', name: 'FIREBASE_NOTIFICATIONS');
          break;
          
        case 'approval_needed':
          // Handle approval needed notification
          log('Processing approval needed notification', name: 'FIREBASE_NOTIFICATIONS');
          break;
          
        default:
          log('Processing generic notification', name: 'FIREBASE_NOTIFICATIONS');
      }
      
    } catch (e) {
      log('Error processing notification data: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  /// Process notification click actions and navigation
  void _processNotificationClick(Map<String, dynamic> data) {
    try {
      final clickAction = data['click_action'] as String?;
      
      if (clickAction == null) {
        log('No click action specified in notification', name: 'FIREBASE_NOTIFICATIONS');
        return;
      }

      log('Processing click action: $clickAction', name: 'FIREBASE_NOTIFICATIONS');

      // Handle different click actions
      if (clickAction.startsWith('open_chat:')) {
        final chatId = clickAction.split(':')[1];
        // Navigate to chat screen
        // Get.toNamed('/chat', arguments: {'chatId': chatId});
        log('Navigate to chat: $chatId', name: 'FIREBASE_NOTIFICATIONS');
        
      } else if (clickAction.startsWith('open_request:')) {
        final requestId = clickAction.split(':')[1];
        // Navigate to request details screen
        // Get.toNamed('/request-details', arguments: {'requestId': requestId});
        log('Navigate to request: $requestId', name: 'FIREBASE_NOTIFICATIONS');
        
      } else if (clickAction.startsWith('open_approval:')) {
        final approvalId = clickAction.split(':')[1];
        // Navigate to approval screen
        // Get.toNamed('/approvals', arguments: {'approvalId': approvalId});
        log('Navigate to approval: $approvalId', name: 'FIREBASE_NOTIFICATIONS');
        
      } else {
        log('Unknown click action: $clickAction', name: 'FIREBASE_NOTIFICATIONS');
      }
      
    } catch (e) {
      log('Error processing notification click: $e', name: 'FIREBASE_NOTIFICATIONS');
    }
  }

  // =============================================================================
  // PUBLIC API METHODS
  // =============================================================================
  
  /// Complete setup flow for push notifications
  Future<bool> setupPushNotifications() async {
    print('🔥🔥🔥 setupPushNotifications() CALLED - THIS SHOULD ALWAYS PRINT!');
    try {
      print('🔥🔥🔥 INSIDE TRY BLOCK');
      print('🚀 DETAILED FCM SETUP: Starting complete push notification setup flow');

      // 1. Ensure service is initialized
      print('🔧 DETAILED FCM SETUP: Step 1 - Checking service initialization');
      print('🔧 DETAILED FCM SETUP: _isInitialized = $_isInitialized');
      if (!_isInitialized) {
        print('⚠️ DETAILED FCM SETUP: Service not initialized, initializing now...');
        await initialize();
        print('⚠️ DETAILED FCM SETUP: After initialize(), _isInitialized = $_isInitialized');
        if (!_isInitialized) {
          print('❌ DETAILED FCM SETUP: Failed to initialize service');
          return false;
        }
      }
      print('✅ DETAILED FCM SETUP: Service initialization check passed');

      // 2. Request permissions
      print('📱 DETAILED FCM SETUP: Step 2 - Requesting notification permissions');
      final hasPermission = await requestNotificationPermissions();
      print('🔍 DETAILED FCM SETUP: Permission request result: $hasPermission');
      if (!hasPermission) {
        print('❌ DETAILED FCM SETUP: Push notification setup failed - no permission granted');
        return false;
      }
      print('✅ DETAILED FCM SETUP: Notification permissions granted');

      // 3. Get FCM token
      print('🔑 DETAILED FCM SETUP: Step 3 - Getting FCM token');
      final token = await getFCMToken();
      if (token == null) {
        print('❌ DETAILED FCM SETUP: Push notification setup failed - no FCM token obtained');
        return false;
      }
      print('✅ DETAILED FCM SETUP: FCM token obtained: ${token.substring(0, 20)}...');

      // 4. Register with backend
      print('🌐 DETAILED FCM SETUP: Step 4 - Registering token with backend');
      final registered = await registerTokenWithBackend();
      print('🔍 DETAILED FCM SETUP: Backend registration result: $registered');
      if (!registered) {
        print('❌ DETAILED FCM SETUP: Push notification setup failed - backend registration failed');
        return false;
      }
      print('✅ DETAILED FCM SETUP: Backend registration successful');

      print('🎉 DETAILED FCM SETUP: Push notifications setup completed successfully');
      return true;

    } catch (e) {
      print('🔥🔥🔥 CAUGHT EXCEPTION IN setupPushNotifications: $e');
      log('💥 DETAILED FCM SETUP: Error setting up push notifications: $e', name: 'FIREBASE_NOTIFICATIONS');
      log('💥 DETAILED FCM SETUP: Stack trace: ${StackTrace.current}', name: 'FIREBASE_NOTIFICATIONS');
      return false;
    }
  }

  /// Send test notification (for debugging)
  Future<bool> sendTestNotification() async {
    try {
      try {
        final AuthService authService = Get.find<AuthService>();
        if (!authService.hasValidTokens) {
          log('User not authenticated - cannot send test notification', name: 'FIREBASE_NOTIFICATIONS');
          return false;
        }
      } catch (e) {
        log('AuthService not available - cannot send test notification: $e', name: 'FIREBASE_NOTIFICATIONS');
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
        log('Test notification sent: ${data['message'] ?? "Success"}', name: 'FIREBASE_NOTIFICATIONS');
        return true;
      }

      log('Failed to send test notification - HTTP ${response.statusCode}', name: 'FIREBASE_NOTIFICATIONS');
      return false;

    } catch (e) {
      log('Error sending test notification: $e', name: 'FIREBASE_NOTIFICATIONS');
      return false;
    }
  }

  /// Clean up on logout
  Future<void> cleanup() async {
    try {
      log('Cleaning up Firebase notifications', name: 'FIREBASE_NOTIFICATIONS');

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

      log('Firebase notifications cleanup completed', name: 'FIREBASE_NOTIFICATIONS');

    } catch (e) {
      log('Error during Firebase notifications cleanup: $e', name: 'FIREBASE_NOTIFICATIONS');
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