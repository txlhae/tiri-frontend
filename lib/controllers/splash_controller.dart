import 'dart:async';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
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
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          log("The User is: ${authController.currentUserStore.value?.email.toString()}");

          authController
              .fetchUser(authController.currentUserStore.value!.referralUserId!)
              .then((value) {
            if (value != null) {
              userName.value = value.username;
              refresh();
            }
          }).catchError((error) {
            log("Error fetching user details: $error");
          });

          if (authController.currentUserStore.value!.isVerified) {
            log('The user is verified: ${authController.currentUserStore.value!.isVerified}');
            Get.offAllNamed(Routes.homePage);
          } else {
            log('User is: ${userName.value}');
            Get.offAllNamed(Routes.verifyPendingPage, arguments: {
              'referredUser': userName.value,
            });
          }
        } else {
          Get.offAllNamed(Routes.onboardingPage);
        }
      } catch (e, stackTrace) {
        log("Error in splash screen navigation: $e", stackTrace: stackTrace);
        Get.offAllNamed(Routes.onboardingPage);
      }
    });
    super.onInit();
  }
}
