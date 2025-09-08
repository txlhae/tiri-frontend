import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tiri/controllers/auth_controller.dart';

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
                    'Scan Referral QR Code',
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
                'Position the QR code within the frame\nThe code will be scanned automatically',
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
      // Parse QR code data (expecting format like "REFERRAL:ABC123:user-uuid")
      Map<String, String> parsedData = _parseQrData(qrData);
      
      if (parsedData['referralCode'] != null) {
        log("Scanned referral code: ${parsedData['referralCode']}");
        if (parsedData['userId'] != null) {
          log("Scanned user UUID: ${parsedData['userId']}");
        }
        
        // Fetch user by referral code
        final user = await authController.fetchUserByReferralCode(parsedData['referralCode']!);
        
        if (user != null) {
          // Verify that the UUID matches if both are present
          if (parsedData['userId'] != null && parsedData['userId'] != user.userId) {
            log("Warning: QR UUID (${parsedData['userId']}) doesn't match user UUID (${user.userId})");
          }
          
          authController.referredUid.value = user.userId;
          authController.referredUser.value = user.username;
          
          // Navigate back and then to register
          Get.back();
          authController.navigateToRegister();
          
          Get.snackbar(
            'Success',
            'Referral code scanned successfully!',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
            backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
            colorText: Colors.white,
          );
        } else {
          _showErrorAndGoBack('Invalid referral code. Please try again.');
        }
      } else {
        _showErrorAndGoBack('This QR code does not contain a valid referral code.');
      }
    } catch (e) {
      log("Error processing QR code: $e");
      _showErrorAndGoBack('Failed to process QR code. Please try again.');
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