import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/dialog_widgets/logout_dialog.dart';
import 'package:tiri/services/firebase_notification_service.dart';
import 'package:tiri/services/auth_guard.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TabController? tabController;
  final TextEditingController searchController = TextEditingController();
  final RxBool hasSearchText = false.obs;
  // Rx<String> selectedFilter = "Recent Posts".obs;

  @override
  void onInit() {
    super.onInit();

    log('🏠 HomeController: Initializing home page controller', name: 'HOME_CONTROLLER');

    // Initialize home page components
    // Note: AuthGuard validation moved to HomeScreen widget initState
    _initializeHomePage();
  }

  /// Initialize home page components
  void _initializeHomePage() {
    log('🏠🔥🔥🔥 HomeController: Setting up FCM token registration!', name: 'HOME_CONTROLLER');
    _setupFCMTokenOnHomeLoad();

    searchController.addListener(() {
      hasSearchText.value = searchController.text.isNotEmpty;
    });
    tabController = TabController(length: 2, vsync: this);

    tabController?.addListener(() {
      searchController.clear(); // Clear search box on tab change
      hasSearchText.value = false;
      final requestController = Get.find<RequestController>();
      if (tabController?.index == 0) {
        // Community Posts tab
        requestController.communityRequests.clear();
        requestController.hasSearchedCommunity.value = false; // reset
      } else if (tabController?.index == 1) {
        // My Posts tab
        requestController.myPostRequests.clear();
        requestController.hasSearchedMyPosts.value = false; // reset
      }
    });
  }

  Future<void> _setupFCMTokenOnHomeLoad() async {
    try {
      log('🏠🚀 HomeController: Setting up FCM token on home page load...', name: 'HOME_CONTROLLER');
      
      if (Get.isRegistered<FirebaseNotificationService>()) {
        log('🏠✅ HomeController: Found FirebaseNotificationService, setting up full FCM flow...', name: 'HOME_CONTROLLER');
        final firebaseService = Get.find<FirebaseNotificationService>();
        
        // 🔥 CRITICAL FIX: Use setupPushNotifications instead of registerTokenWithBackend
        // This ensures permissions are requested before token registration
        final success = await firebaseService.setupPushNotifications();
        
        if (success) {
          log('🏠🎉 FCM setup completed successfully with backend from home page!', name: 'HOME_CONTROLLER');
        } else {
          log('🏠❌ FCM setup failed from home page - check permissions and Firebase config', name: 'HOME_CONTROLLER');
        }
      } else {
        log('🏠❌ FirebaseNotificationService not registered with GetX', name: 'HOME_CONTROLLER');
      }
    } catch (e) {
      log('🏠❌ Error setting up FCM token on home load: $e', name: 'HOME_CONTROLLER');
    }
  }

  // Show confirmation dialog
  void showConfirmationDialog(int index) {
    log("Go for request $index");
    Get.dialog(
      const LogoutDialog(
        questionText: "Are you sure you want to go?",
        submitText: "Yes",
        routeText: Routes.homePage,
      ),
    );
  }

  // Navigate to profile
  void navigateToProfile() {
    Get.toNamed(
      Routes.profilePage,
    );
  }

  @override
  void onClose() {
    tabController?.dispose();
    searchController.dispose();
    super.onClose();
  }
}
