// File: lib/screens/profile_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/chat_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/feedback_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/delete_dialog.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/edit_dialog.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/logout_dialog.dart';
import 'package:kind_clock/screens/widgets/profile_nav_button.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final Rxn<UserModel> shownUser = Rxn<UserModel>();
  final RequestController requestController = Get.find<RequestController>();

  @override
  void initState() {
    super.initState();
    final currentUser = authController.currentUserStore.value!;
    final initialUser = widget.user ?? currentUser;
    shownUser.value = initialUser;

    // Fetch fresh data for other users
    if (widget.user != null && widget.user!.userId != currentUser.userId) {
      authController.fetchUser(widget.user!.userId).then((freshUser) {
        if (freshUser != null) {
          shownUser.value = freshUser;
          requestController.fetchProfileFeedback(freshUser.userId);
        }
      });
    } else {
      requestController.fetchProfileFeedback(currentUser.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = shownUser.value;
      if (user == null) return const Center(child: CircularProgressIndicator());

      final isCurrentUser =
          user.userId == authController.currentUserStore.value!.userId;

      // Referral code section: improved readability and design alignment

      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(3, 80, 135, 1),
                Color.fromRGBO(0, 140, 170, 1),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: 0,
                child: SvgPicture.asset(
                  'assets/images/profile_ellipse_bottom.svg',
                  height: 300,
                ),
              ),
              Positioned(
                top: 0,
                left: 40,
                child: SvgPicture.asset(
                  'assets/images/profile_ellipse_stack.svg',
                  height: 250,
                ),
              ),
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 30.0),
                          child: Row(
                            children: [
                              CustomBackButton(controller: authController),
                              const Spacer(),
                              if (isCurrentUser)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    log("Edit");
                                    Get.dialog(EditDialog(
                                        user: authController.currentUserStore.value!));
                                  },
                                  child: SvgPicture.asset(
                                    "assets/icons/edit_icon.svg",
                                  ),
                                ),
                              if (!isCurrentUser)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _openChatWithUser(user),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color.fromRGBO(3, 80, 135, 1),
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildAvatar(user.imageUrl, context),
                        const SizedBox(height: 20),
                        // Username display fix: prefer name/fullName if available, else username
                        // ...existing code...
                        const SizedBox(height: 5),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: buildStatsRow(user.hours, user.rating,
                              key: ValueKey("${user.hours}_${user.rating}")),
                        ),
                        const SizedBox(height: 15),
                        // CURRENT USER LAYOUT
                        if (isCurrentUser) ...[
                          // Referral Code Section (improved design)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Referral Code",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        user.referralCode?.toString() ?? 'null',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                          letterSpacing: 2.5,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await Clipboard.setData(ClipboardData(text: user.referralCode?.toString() ?? 'null'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Referral code copied to clipboard!',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            'Copy',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          // Profile Menu Navigation (only for current user)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Column(
                              children: [
                                ProfileNavButton(
                                  icon: 'assets/icons/help_icon.svg',
                                  buttonText: 'My Helps',
                                  navDestination: Routes.myHelpsPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/feedback_icon.svg',
                                  buttonText: 'Feedbacks',
                                  navDestination: Routes.feedbackPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/contact_icon.svg',
                                  buttonText: 'Contact us',
                                  navDestination: Routes.contactUsPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/logout_icon.svg',
                                  buttonText: 'Logout',
                                  navDestination: '',
                                  haveDialog: true,
                                  dialog: LogoutDialog(
                                    questionText: 'Are you sure you want to logout?',
                                    submitText: 'Logout',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/delete_icon.svg',
                                  buttonText: 'Delete account',
                                  navDestination: '',
                                  haveDialog: true,
                                  dialog: DeleteDialog(),
                                ),
                                // Removed final SizedBox(height: 20) to avoid extra white space
                              ],
                            ),
                          ),
                        ] else ...[
                          // OTHER USER LAYOUT - only show feedback section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    "What others say:",
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Obx(() => Column(
                                    children: requestController.profileFeedbackList.map((item) {
                                      final feedback = item['feedback'] as FeedbackModel;
                                      final username = item['username'];
                                      final title = item['title'];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 7, horizontal: 25),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: Text(
                                                  "Given by: $username",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                feedback.review,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Rating: ${feedback.rating} ⭐ | Hours: ${feedback.hours}",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    "For : $title",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${feedback.timestamp.day}/${feedback.timestamp.month}/${feedback.timestamp.year}",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          // Removed final SizedBox(height: 20) to avoid extra white space
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar(String? imageUrl, BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(70),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0.0, 1.0),
                blurRadius: 10.0,
                spreadRadius: 3.0,
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            foregroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 80,
                    color: Color.fromRGBO(3, 80, 135, 1),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget buildStatsRow(int? hours, double? rating, {Key? key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/cup_icon.svg',
          height: 20,
          width: 20,
        ),
        const SizedBox(width: 5),
        Text(
          "${hours ?? 0} hrs",
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(width: 10),
        SvgPicture.asset(
          'assets/icons/star_icon.svg',
          height: 20,
          width: 20,
        ),
        const SizedBox(width: 5),
        Text(
          (rating ?? 0.0).toStringAsFixed(1),
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  /// Open chat with the user being viewed
  Future<void> _openChatWithUser(UserModel user) async {
    try {
      final currentUserId = authController.currentUserStore.value?.userId;
      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'Unable to get current user information',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }

      // Show loading indicator
      Get.dialog(
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Opening chat...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Create or get chat room using existing ChatController
      final chatController = Get.put(ChatController());
      final roomId = await chatController.createOrGetChatRoom(
        currentUserId,
        user.userId,
        // No serviceRequestId for direct messaging
      );

      // Close loading dialog
      Get.back();

      // Navigate to chat page
      Get.toNamed(
        Routes.chatPage,
        arguments: {
          'chatRoomId': roomId,
          'receiverId': user.userId,
          'receiverName': user.username,
          'receiverProfilePic': user.imageUrl ?? " ",
        },
      );

    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Failed to open chat. Please try again.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    }
  }
}