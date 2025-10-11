import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
class QrCodeDialog extends StatelessWidget {
  final String referralCode;
  final String username;
  final String userId;
  final GlobalKey _qrKey = GlobalKey();

  QrCodeDialog({
    super.key,
    required this.referralCode,
    required this.username,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging to track the issue
    
    final qrData = "REFERRAL:$referralCode:$userId";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Your Referral QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(3, 80, 135, 1),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // QR Code Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(0, 140, 170, 1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // QR Code
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            referralCode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Color.fromRGBO(3, 80, 135, 1),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Scan to join TIRI with $username\'s referral',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _shareQrCode(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text(
                  'Share QR Code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Share this QR code with friends! They can scan it to sign up with your referral automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 140, 170, 1)),
              ),
              SizedBox(height: 16),
              Text(
                'Preparing to share...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Capture QR code as image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/referral_qr_${DateTime.now().millisecondsSinceEpoch}.png';
      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      // Close loading dialog
      Get.back();
      
      // Share the image with message
      const shareText = '''🎉 Join TIRI - The Community Help App! 🎉

Scan this QR code to sign up with my referral and become part of our amazing community where neighbors help neighbors.

✨ Get help with daily tasks
✨ Offer your skills to others
✨ Build stronger communities

Download TIRI now and let's help each other! 

#TIRI #CommunityHelp #Neighbors''';

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: shareText,
        subject: 'Join TIRI with my referral!',
      );

      // Clean up temporary file after a delay
      Future.delayed(const Duration(seconds: 30), () {
        try {
          if (imageFile.existsSync()) {
            imageFile.deleteSync();
          }
        } catch (e) {
          // Ignore cleanup errors
        }
      });

    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Failed to share QR code. Please try again.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}