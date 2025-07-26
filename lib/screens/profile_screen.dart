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
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.all(16),
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
                                                "Rating: ${feedback.rating} ? | Hours: ${feedback.hours}",
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
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Add any additional widgets here if needed
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
