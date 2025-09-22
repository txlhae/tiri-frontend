import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/splash_controller.dart';
import 'package:tiri/services/connectivity_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Main content area with logo
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo_named.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      height: 400,
                      width: 400,
                    ),
                  ),
                ),

                // Status and connectivity area
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status text with connectivity awareness
                        Obx(() {
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _getStatusText(controller),
                              key: ValueKey(controller.currentStatus),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(controller),
                                height: 1.4,
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 20),

                        // Connectivity indicator (includes loading spinner when checking)
                        Obx(() {
                          return _buildConnectivityIndicator(controller);
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get status text based on current state
  String _getStatusText(SplashController controller) {
    final status = controller.currentStatus;
    final connectivityState = controller.connectivityState;

    // Show specific connectivity messages
    if (status.contains('Not connected to the internet') ||
        connectivityState == ConnectivityState.offline) {
      return 'Not connected to the internet\nPlease check your connection and try again';
    } else if (status.contains('Server offline') ||
               connectivityState == ConnectivityState.serverOffline) {
      return 'Server offline - unable to reach backend\nPlease try again later';
    } else if (status.contains('Retrying')) {
      return status;
    } else if (connectivityState == ConnectivityState.checking) {
      return 'Checking connection...';
    }

    return status;
  }

  /// Get status text color based on current state
  Color _getStatusColor(SplashController controller) {
    final connectivityState = controller.connectivityState;
    final status = controller.currentStatus;

    if (connectivityState == ConnectivityState.offline ||
        status.contains('Not connected to the internet')) {
      return Colors.red.shade600;
    } else if (connectivityState == ConnectivityState.serverOffline ||
               status.contains('Server offline')) {
      return Colors.orange.shade600;
    } else if (status.contains('Welcome') || status.contains('successful')) {
      return Colors.green.shade600;
    }

    return Colors.grey.shade600;
  }

  /// Build connectivity indicator widget
  Widget _buildConnectivityIndicator(SplashController controller) {
    final connectivityState = controller.connectivityState;

    switch (connectivityState) {
      case ConnectivityState.online:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done,
              color: Colors.green.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Connected',
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case ConnectivityState.offline:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              color: Colors.red.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No Internet',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case ConnectivityState.serverOffline:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Server Offline',
              style: TextStyle(
                color: Colors.orange.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case ConnectivityState.checking:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Checking...',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}
