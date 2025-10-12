import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/dialog_widgets/logout_dialog.dart';
import 'package:tiri/services/firebase_notification_service.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  TabController? tabController;
  final TextEditingController searchController = TextEditingController();
  final RxBool hasSearchText = false.obs;
  // Rx<String> selectedFilter = "Recent Posts".obs;

  @override
  void onInit() {
    super.onInit();


    // Initialize home page components
    // Note: AuthGuard validation moved to HomeScreen widget initState
    _initializeHomePage();
  }

  /// Initialize home page components
  void _initializeHomePage() {
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
      
      if (Get.isRegistered<FirebaseNotificationService>()) {
        final firebaseService = Get.find<FirebaseNotificationService>();
        
        // 🔥 CRITICAL FIX: Use setupPushNotifications instead of registerTokenWithBackend
        // This ensures permissions are requested before token registration
        final success = await firebaseService.setupPushNotifications();
        
        if (success) {
        } else {
        }
      } else {
      }
    } catch (e) {
      // Failed to accept request
    }
  }

  // Show confirmation dialog
  void showConfirmationDialog(int index) {
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
