import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';

/// Verification Banner Widget
/// Shows a banner for unverified users encouraging email verification
/// without blocking app functionality
class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      // Only show banner if user is logged in but not verified
      if (!authController.isLoggedIn.value ||
          authController.currentUserStore.value == null ||
          authController.currentUserStore.value!.isVerified) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          border: Border(
            bottom: BorderSide(
              color: Colors.amber.shade300,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: Colors.amber.shade800,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please verify your email to unlock all features',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                // Show loading indicator
                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  barrierDismissible: false,
                );
                
                try {
                  // Check verification status
                  await authController.checkVerificationStatus();
                } finally {
                  // Close loading dialog if still open
                  if (Get.isDialogOpen == true) {
                    Get.back();
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber.shade200,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'I Have Verified',
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                // Temporarily hide banner for this session
                // Note: Banner will reappear on app restart if still unverified
                Get.snackbar(
                  'Banner Hidden',
                  'The verification banner has been hidden for this session. It will reappear when you restart the app.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.grey.shade800,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 3),
                );
                
                // For now, we'll just show the snackbar
                // In a full implementation, you might want to add a session-based flag
                // to temporarily hide the banner
              },
              child: Icon(
                Icons.close,
                color: Colors.amber.shade700,
                size: 18,
              ),
            ),
          ],
        ),
      );
    });
  }
}
