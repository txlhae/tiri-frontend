import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/logout_dialog.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final TabController tabController;
  final TextEditingController searchController = TextEditingController();
  final RxBool hasSearchText = false.obs;
  // Rx<String> selectedFilter = "Recent Posts".obs;

  @override
  void onInit() {
    searchController.addListener(() {
      hasSearchText.value = searchController.text.isNotEmpty;
    });
    tabController = TabController(length: 3, vsync: this);

    tabController.addListener(() {
      searchController.clear(); // Clear search box on tab change
      hasSearchText.value = false;
      final requestController = Get.find<RequestController>();
      if (tabController.index == 0) {
        // Community Posts tab
        requestController.communityRequests.clear();
        requestController.hasSearchedCommunity.value = false; // reset
      } else if (tabController.index == 1) {
        // My Posts tab
        requestController.myPostRequests.clear();
        requestController.hasSearchedMyPosts.value = false; // reset
      } else if (tabController.index == 2) {
        // My Applications tab - no special handling needed for now
        // The MyApplicationsScreen handles its own data loading
      }
    });

    super.onInit();
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
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
