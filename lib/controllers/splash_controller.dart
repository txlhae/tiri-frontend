import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';

class SplashController extends GetxController {
  final authController = Get.find<AuthController>();
  final userName = ''.obs;

  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () {
      try {
        // TEMPORARY: Use Django auth instead of Firebase
        // Check if user is logged in via Django AuthController
        if (authController.isLoggedIn.value && authController.currentUserStore.value != null) {
          log("User is logged in via Django: ${authController.currentUserStore.value?.email}");

          // 🔧 PHASE 3 FIX: Bypass verification check temporarily to get to home screen
          // TODO: Fix verification field mapping in Phase 4
          log('✅ PHASE 3: Bypassing verification check - going directly to home screen');
          log('User verification status: ${authController.currentUserStore.value!.isVerified}');
          
          // Always go to home page for logged-in users during Phase 3 testing
          Get.offAllNamed(Routes.homePage);
          
          /* ORIGINAL VERIFICATION LOGIC - Will be restored in Phase 4
          if (authController.currentUserStore.value!.isVerified) {
            log('User is verified: ${authController.currentUserStore.value!.isVerified}');
            Get.offAllNamed(Routes.homePage);
          } else {
            log('User not verified, going to verify page');
            
            // Load referrer info if needed
            if (authController.currentUserStore.value!.referralUserId != null) {
              authController
                  .fetchUser(authController.currentUserStore.value!.referralUserId!)
                  .then((value) {
                if (value != null) {
                  userName.value = value.username;
                }
              }).catchError((error) {
                log("Error fetching referrer details: $error");
                userName.value = "Unknown";
              });
            }
            
            Get.offAllNamed(Routes.verifyPendingPage, arguments: {
              'referredUser': userName.value,
            });
          }
          */
        } else {
          // No user logged in, go to onboarding
          log('No user logged in, going to onboarding');
          Get.offAllNamed(Routes.onboardingPage);
        }
      } catch (e, stackTrace) {
        log("Error in splash screen navigation: $e", stackTrace: stackTrace);
        // Fallback to onboarding
        Get.offAllNamed(Routes.onboardingPage);
      }
    });
    super.onInit();
  }
}
