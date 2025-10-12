// lib/services/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../config/api_config.dart';

/// Network connectivity states
enum ConnectivityState {
  online,
  offline,
  serverOffline,
  checking,
}

/// Comprehensive connectivity service for network and server monitoring
///
/// Features:
/// - Real-time internet connectivity detection
/// - Backend server reachability checks
/// - Automatic retry mechanisms
/// - Connection state broadcasting
class ConnectivityService extends GetxService {
  // =============================================================================
  // SINGLETON PATTERN
  // =============================================================================

  static ConnectivityService? _instance;
  static ConnectivityService get instance => _instance ??= ConnectivityService._internal();

  factory ConnectivityService() => instance;

  ConnectivityService._internal();

  // =============================================================================
  // PRIVATE PROPERTIES
  // =============================================================================

  final Connectivity _connectivity = Connectivity();
  late Dio _dio;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _serverCheckTimer;

  // =============================================================================
  // REACTIVE STATE
  // =============================================================================

  final currentState = ConnectivityState.checking.obs;
  final isOnline = false.obs;
  final isServerReachable = false.obs;
  final lastChecked = DateTime.now().obs;
  final errorMessage = ''.obs;

  // =============================================================================
  // CONFIGURATION
  // =============================================================================

  static const Duration _serverCheckTimeout = Duration(seconds: 3);
  static const Duration _serverCheckInterval = Duration(minutes: 2);
  static const int _maxRetries = 1;

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeService();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _serverCheckTimer?.cancel();
    super.onClose();
  }

  /// Initialize the connectivity service
  Future<void> _initializeService() async {
    try {

      // Initialize Dio for server checks
      _dio = Dio(BaseOptions(
        connectTimeout: _serverCheckTimeout,
        receiveTimeout: _serverCheckTimeout,
        sendTimeout: _serverCheckTimeout,
      ));

      // Perform initial connectivity check
      await checkConnectivity();

      // Start listening to connectivity changes
      _startConnectivityListener();

      // Periodic server checks disabled - only check on startup and network changes
      // _startPeriodicServerChecks();

    } catch (e) {
      _updateState(ConnectivityState.offline, 'Failed to initialize connectivity service');
    }
  }

  // =============================================================================
  // CONNECTIVITY MONITORING
  // =============================================================================

  /// Start listening to connectivity changes
  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _handleConnectivityChange(results);
      },
      onError: (error) {
        _updateState(ConnectivityState.offline, 'Connectivity monitoring failed');
      },
    );
  }

  /// Handle connectivity state changes
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    try {
      final hasConnection = results.any((result) =>
        result != ConnectivityResult.none
      );

      if (hasConnection) {
        isOnline.value = true;

        // Check if server is reachable
        await _checkServerReachability();
      } else {
        isOnline.value = false;
        isServerReachable.value = false;
        _updateState(ConnectivityState.offline, 'No internet connection');
      }
    } catch (e) {
      _updateState(ConnectivityState.offline, 'Failed to check connectivity');
    }
  }

  /// Start periodic server reachability checks
  void _startPeriodicServerChecks() {
    _serverCheckTimer = Timer.periodic(_serverCheckInterval, (timer) async {
      if (isOnline.value) {
        await _checkServerReachability();
      }
    });
  }

  // =============================================================================
  // SERVER REACHABILITY
  // =============================================================================

  /// Check if the backend server is reachable
  Future<void> _checkServerReachability() async {
    try {

      currentState.value = ConnectivityState.checking;

      // Try to reach the server with retries
      final isReachable = await _pingServerWithRetry();

      if (isReachable) {
        isServerReachable.value = true;
        _updateState(ConnectivityState.online, 'Connected');
      } else {
        isServerReachable.value = false;
        _updateState(ConnectivityState.serverOffline, 'Server offline - unable to reach backend');
      }

      lastChecked.value = DateTime.now();
    } catch (e) {
      isServerReachable.value = false;
      _updateState(ConnectivityState.serverOffline, 'Server offline - unable to reach backend');
    }
  }

  /// Ping server with retry mechanism
  Future<bool> _pingServerWithRetry() async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {

        // Try to reach the server health endpoint or base URL
        final response = await _dio.get(
          '${ApiConfig.baseUrl}/api/health/',
          options: Options(
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != null && response.statusCode! < 500) {
          return true;
        }
      } catch (e) {

        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
        }
      }
    }

    return false;
  }

  // =============================================================================
  // PUBLIC API
  // =============================================================================

  /// Perform a comprehensive connectivity check
  Future<ConnectivityState> checkConnectivity() async {
    try {

      currentState.value = ConnectivityState.checking;

      // Check internet connectivity first
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasInternet = connectivityResults.any((result) =>
        result != ConnectivityResult.none
      );

      if (!hasInternet) {
        isOnline.value = false;
        isServerReachable.value = false;
        _updateState(ConnectivityState.offline, 'Not connected to the internet');
        return ConnectivityState.offline;
      }

      isOnline.value = true;

      // Check server reachability
      await _checkServerReachability();

      return currentState.value;
    } catch (e) {
      _updateState(ConnectivityState.offline, 'Failed to check connectivity');
      return ConnectivityState.offline;
    }
  }

  /// Force a server reachability check
  Future<bool> checkServerReachability() async {
    if (!isOnline.value) {
      return false;
    }

    await _checkServerReachability();
    return isServerReachable.value;
  }

  /// Wait for connectivity to be restored
  Future<bool> waitForConnectivity({
    Duration timeout = const Duration(seconds: 30),
  }) async {

    final completer = Completer<bool>();
    Timer? timeoutTimer;
    StreamSubscription? stateSubscription;

    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    // Listen for connectivity restoration
    stateSubscription = currentState.listen((state) {
      if (state == ConnectivityState.online && !completer.isCompleted) {
        completer.complete(true);
      }
    });

    // Check current state first
    if (currentState.value == ConnectivityState.online) {
      completer.complete(true);
    }

    final result = await completer.future;

    // Cleanup
    timeoutTimer.cancel();
    stateSubscription.cancel();

    return result;
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Update connectivity state and notify listeners
  void _updateState(ConnectivityState state, String message) {
    currentState.value = state;
    errorMessage.value = message;
    lastChecked.value = DateTime.now();

  }

  /// Get user-friendly connectivity status message
  String getStatusMessage() {
    switch (currentState.value) {
      case ConnectivityState.online:
        return 'Connected';
      case ConnectivityState.offline:
        return 'Not connected to the internet';
      case ConnectivityState.serverOffline:
        return 'Server offline - unable to reach backend';
      case ConnectivityState.checking:
        return 'Checking connection...';
    }
  }

  /// Check if we should retry failed operations
  bool get shouldRetryOperations => currentState.value == ConnectivityState.online;

  /// Check if the device has internet but server is unreachable
  bool get hasInternetButServerOffline =>
      isOnline.value && !isServerReachable.value;

  // =============================================================================
  // GETTERS
  // =============================================================================

  /// Current connectivity state
  ConnectivityState get state => currentState.value;

  /// Whether device is connected to internet
  bool get hasInternet => isOnline.value;

  /// Whether backend server is reachable
  bool get hasServerConnection => isServerReachable.value;

  /// Whether app can make API calls
  bool get canMakeApiCalls => hasInternet && hasServerConnection;

  /// Last connectivity check timestamp
  DateTime get lastCheckTime => lastChecked.value;

  /// Current error message if any
  String get currentError => errorMessage.value;
}