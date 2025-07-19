import 'dart:developer';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
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

    //  Fetch fresh data for other users
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

      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
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
              Column(
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
                                  user:
                                      authController.currentUserStore.value!));
                            },
                            child: SvgPicture.asset(
                              "assets/icons/edit_icon.svg",
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  buildAvatar(user.imageUrl, context),
                  const SizedBox(height: 20),
                  isCurrentUser
                      ? Text(
                          "Hi, ${user.username}!",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        )
                      : Text(
                          "${user.username} ",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                  const SizedBox(height: 5),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: buildStatsRow(user.hours, user.rating,
                        key: ValueKey("${user.hours}_${user.rating}")),
                  ),
                  const SizedBox(height: 15),
                  if (isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30.0),
                            child: DottedBorder(
                              color: Colors.white,
                              strokeWidth: 1.5,
                              dashPattern: const [4, 4],
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(12),
                              padding: const EdgeInsets.all(0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "Your Referral Code",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          authController.currentUserStore.value
                                                  ?.referralCode ??
                                              "GGGGGG",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0),
                                      child: Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.white,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(
                                          text: authController.currentUserStore
                                                  .value?.referralCode ??
                                              "GGGGGG",
                                        ));
                                        Get.rawSnackbar(
                                          message: "Copied!",
                                          duration: const Duration(
                                              milliseconds: 1500),
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor:
                                              Colors.black.withOpacity(0.7),
                                          margin: const EdgeInsets.all(8),
                                          borderRadius: 4,
                                          animationDuration:
                                              const Duration(milliseconds: 200),
                                          isDismissible: true,
                                          maxWidth: 80,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                        );
                                      },
                                      child: const Row(
                                        children: [
                                          Text(
                                            "Copy",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Icon(
                                            Icons.copy,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 50,
                          ),
                          const ProfileNavButton(
                            buttonText: "My helps",
                            navDestination: Routes.myHelpsPage,
                            icon: 'assets/icons/help_icon.svg',
                            haveDialog: false,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const ProfileNavButton(
                            buttonText: "Feedbacks",
                            navDestination: Routes.feedbackPage,
                            icon: 'assets/icons/feedback_icon.svg',
                            haveDialog: false,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const ProfileNavButton(
                            buttonText: "Privacy and security",
                            navDestination: Routes.privacyandsecurityPage,
                            icon: 'assets/icons/about_icon.svg',
                            haveDialog: false,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const ProfileNavButton(
                            buttonText: "Contact us",
                            navDestination: Routes.contactUsPage,
                            icon: 'assets/icons/contact_icon.svg',
                            haveDialog: false,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          const ProfileNavButton(
                            buttonText: "Logout",
                            navDestination: Routes.loginPage,
                            icon: 'assets/icons/logout_icon.svg',
                            haveDialog: true,
                           dialog: LogoutDialog(questionText: "Are you sure you want to logout?",
                         submitText: "Logout",
                         routeText : Routes.loginPage,),
                         ),
                      const SizedBox(
                        height: 20,
                      ),
                        ProfileNavButton(
                        buttonText: "Delete",
                        navDestination: Routes.loginPage,
                        icon: 'assets/icons/delete_icon.svg',
                        haveDialog: true,
                        dialog: DeleteDialog(),
                        )
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (!isCurrentUser)
                    Obx(() {
                      if (requestController.isFeedbackLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final feedbackList = requestController.fullFeedbackList;

                      if (feedbackList.isEmpty) {
                        return const Center(child: Text("No feedback yet"));
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "What others say:",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ...feedbackList.map((item) {
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
                        ],
                      );
                    })
                ],
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
}
