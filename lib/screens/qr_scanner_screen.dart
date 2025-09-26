import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/profile_screen.dart';
import 'package:tiri/services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final AuthController authController = Get.find<AuthController>();
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (barcodes) async {
              if (isProcessing) return;
              
              for (final barcode in barcodes.barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    isProcessing = true;
                  });
                  
                  await _processQrCode(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          // Header with back button and title
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Get.back(),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Scan User QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  Positioned(
                    top: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the user\'s QR code within the frame\nThe code will be scanned automatically',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Processing indicator
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(0, 140, 170, 1),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing QR code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _processQrCode(String qrData) async {
    try {
      log('Processing QR data: $qrData');

      // Parse QR code data (expecting format like "REFERRAL:JU5NB36B:214f1153-6e37-416b-86a2-72e392b84881")
      Map<String, String> parsedData = _parseQrData(qrData);

      if (parsedData['userId'] != null) {
        log("Scanned user UUID: ${parsedData['userId']}");

        // Navigate to user profile
        await _navigateToUserProfile(parsedData['userId']!);
      } else {
        _showErrorAndGoBack('This QR code does not contain valid user information.');
      }
    } catch (e) {
      log("Error processing QR code: $e");
      _showErrorAndGoBack('Failed to process QR code. Please try again.');
    }
  }

  /// Navigate to user profile by ID
  Future<void> _navigateToUserProfile(String userId) async {
    try {
      // Fetch user data
      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/profile/users/$userId/');

      if (response.statusCode == 200 && response.data != null) {
        final apiData = response.data as Map<String, dynamic>;

        // Create user model from API data
        final user = UserModel(
          userId: apiData['userId']?.toString() ?? userId,
          email: apiData['email']?.toString() ?? '',
          username: apiData['full_name'] ?? apiData['username'] ?? 'Unknown',
          imageUrl: apiData['profile_image'],
          phoneNumber: apiData['phone_number']?.toString(),
          country: apiData['country'],
          referralCode: apiData['referralCode'],
          rating: (apiData['average_rating'] as num?)?.toDouble(),
          hours: (apiData['total_hours_helped'] as num?)?.toInt(),
          createdAt: apiData['created_at'] != null ? DateTime.parse(apiData['created_at']) : null,
          isVerified: apiData['is_verified'] ?? false,
          isApproved: apiData['is_approved'] ?? false,
          approvalStatus: apiData['approval_status'],
          rejectionReason: apiData['rejection_reason'],
          approvalExpiresAt: apiData['approval_expires_at'] != null ? DateTime.parse(apiData['approval_expires_at']) : null,
        );

        // Navigate to profile screen
        Get.back(); // Close scanner
        Get.to(() => ProfileScreen(user: user));

        log('✅ Successfully navigated to user profile: ${user.username}');

        // Show success message
        Get.snackbar(
          'Success',
          'Successfully opened ${user.username}\'s profile!',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
          colorText: Colors.white,
        );
      } else {
        _showErrorAndGoBack('User not found');
      }
    } catch (e) {
      log('Error fetching user profile: $e');
      _showErrorAndGoBack('Failed to load user profile');
    }
  }

  Map<String, String> _parseQrData(String qrData) {
    Map<String, String> result = {};
    
    try {
      // Check if it's our format: REFERRAL:CODE:USER_UUID
      if (qrData.startsWith('REFERRAL:')) {
        List<String> parts = qrData.split(':');
        if (parts.length >= 2) {
          result['referralCode'] = parts[1];
          if (parts.length >= 3) {
            result['userId'] = parts[2];
          }
        }
      } else {
        // Try to parse as plain referral code
        if (qrData.length >= 4 && qrData.length <= 20) {
          result['referralCode'] = qrData;
        }
      }
    } catch (e) {
      log("Error parsing QR data: $e");
    }
    
    return result;
  }

  void _showErrorAndGoBack(String message) {
    Get.back();
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: const Color.fromRGBO(220, 53, 69, 1),
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}