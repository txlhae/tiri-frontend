import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/home_controller.dart';
import 'package:tiri/controllers/notification_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/home_widgets/community_requests.dart';
import 'package:tiri/screens/widgets/home_widgets/my_requests.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    final AuthController authController = Get.find<AuthController>();
    final RequestController requestController = Get.find<RequestController>();
    final NotificationController notificationController = Get.find<NotificationController>();

    // 🚨 SAFETY FIX: Ensure requests are loaded when HomeScreen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if we have user but no requests and not currently loading
      if (authController.isLoggedIn.value && 
          authController.currentUserStore.value != null &&
          requestController.requestList.isEmpty && 
          requestController.myRequestList.isEmpty &&
          !requestController.isLoading.value) {
        log("🚨 HomeScreen: Detected empty requests - triggering reload");
        requestController.loadRequests();
      }
    });

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: 150,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(3, 80, 135, 1),
                      Color.fromRGBO(0, 140, 170, 1)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20))),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (authController.currentUserStore.value != null) {
                              log(authController.currentUserStore.value!
                                  .toJson()
                                  .toString());
                              homeController.navigateToProfile();
                            }
                          },
                          child: Row(
                            children: [
                              Obx(
                                () => authController.currentUserStore.value !=
                                            null &&
                                        authController.currentUserStore.value!
                                                .imageUrl !=
                                            null &&
                                        authController.currentUserStore.value!
                                            .imageUrl!.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundColor: Colors.white,
                                        backgroundImage: NetworkImage(
                                            authController.currentUserStore
                                                .value!.imageUrl!),
                                      )
                                    : const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.person,
                                          color: Color.fromRGBO(3, 80, 135, 1),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Hi,",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Obx(() => SizedBox(
                                    width: 160, // 🚨 FIXED: Increased width for longer usernames to prevent truncation
                                    child: Text(
                                      authController.currentUserStore.value
                                              ?.username ??
                                          "Guest",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Get.snackbar(
                            "Coming Soon!",
                            "We're working on this feature. Stay tuned!",
                            duration: const Duration(milliseconds: 1000),
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                          );
                        },
                        child: const Row(
                          children: [
                            Text(
                              "Location",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.location_on,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Obx(() {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () async {
                              await notificationController.markAllAsRead(); 
                              Get.toNamed(Routes.notificationsPage);
                            },
                            icon: const Icon(Icons.notifications, color: Colors.white),
                          ),
                          if (notificationController.unreadCount.value > 0)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                    ],
                  ),
                  TabBar.secondary(
                    labelStyle: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    controller: homeController.tabController,
                    unselectedLabelStyle: const TextStyle(
                      color: Color.fromRGBO(218, 218, 218, 1),
                    ),
                    tabs: const <Widget>[
                      Tab(text: 'Community Posts'),
                      Tab(text: 'My Posts'),
                    ],
                    dividerColor: Colors.transparent,
                    indicatorColor: Colors.transparent,
                  ),
                ],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: homeController.tabController.animation!,
              builder: (context, animation, child) {
                double value = animation;
                final int transitioningIndex = value.floor();
                final double transitioningValue = value - transitioningIndex;
                final bool isTransitioning = transitioningValue > 0.0;
                final int firstIndex = transitioningIndex;
                final int visualIndex = isTransitioning
                    ? firstIndex
                    : homeController.tabController.index;

                // Make the container shrink faster than it grows
                final bool isRemovingIcon =
                    visualIndex == 1 || (isTransitioning && firstIndex == 0);
                final animationDuration = isRemovingIcon
                    ? const Duration(milliseconds: 50) // Faster when removing
                    : const Duration(milliseconds: 100); // Slower when adding

                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          height: 36,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  onFieldSubmitted: (location) async {
                                    final selectedTab =
                                        homeController.tabController.index;
                                    if (selectedTab == 0) {
                                      // Community tab
                                      await requestController
                                          .fetchRequestsByLocation(
                                              location.trim().toLowerCase());
                                    } else if (selectedTab == 1) {
                                      // My Posts tab
                                      await requestController
                                          .fetchMyRequestsByLocation(
                                              location.trim().toLowerCase());
                                    }
                                                  },
                                  controller: homeController.searchController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    fillColor:
                                        const Color.fromRGBO(246, 248, 249, 1),
                                    filled: true,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SvgPicture.asset(
                                        'assets/icons/search_icon.svg',
                                        fit: BoxFit.scaleDown,
                                        color: const Color(0xFF008CAA),
                                      ),
                                    ),
                                    suffixIcon: Obx(() {
                                      return homeController.hasSearchText.value
                                          ? IconButton(
                                              icon: const Icon(Icons.clear,
                                                  size: 20,
                                                  color: Color(0xFF008CAA)),
                                              onPressed: () {
                                                homeController.searchController
                                                    .clear();
                                                final selectedTab =
                                                    homeController
                                                        .tabController.index;
                                                if (selectedTab == 0) {
                                                  requestController
                                                      .communityRequests
                                                      .clear();
                                                  requestController
                                                      .hasSearchedCommunity
                                                      .value = false;
                                                } else if (selectedTab == 1) {
                                                  requestController
                                                      .myPostRequests
                                                      .clear();
                                                  requestController
                                                      .hasSearchedMyPosts
                                                      .value = false;
                                                }
                                              },
                                            )
                                          : const SizedBox.shrink();
                                    }),
                                    hintText: "Search by location",
                                    hintStyle: const TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: animationDuration,
                        width: visualIndex == 0 ? 50 : 0,
                        curve: isRemovingIcon
                            ? Curves.easeInQuart
                            : Curves.easeOutQuart,
                        child: AnimatedOpacity(
                          opacity: visualIndex == 0 ? 1.0 : 0.0,
                          duration: isRemovingIcon
                              ? const Duration(
                                  milliseconds:
                                      30) // Very fast opacity change when removing
                              : const Duration(
                                  milliseconds:
                                      80), // Slightly slower when showing
                          curve:
                              isRemovingIcon ? Curves.easeIn : Curves.easeOut,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 10 * (visualIndex == 0 ? 1 : 0),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (visualIndex == 0) {
                                  requestController.showFilterDialog(context);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SvgPicture.asset(
                                    "assets/icons/filter_icon.svg",
                                    fit: BoxFit.scaleDown,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: TabBarView(
                controller: homeController.tabController,
                children: const <Widget>[
                  CommunityRequests(),
                  MyRequests(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: GestureDetector(
          onTap: () {
            log("Add Request");
            Get.toNamed(Routes.addRequestPage);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: const Color.fromRGBO(36, 50, 139, 1),
            ),
            child: const Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
//