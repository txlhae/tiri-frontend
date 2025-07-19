import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/notification_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/controllers/request_details_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/screens/profile_screen.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/intrested_dialog.dart';
import 'package:kind_clock/screens/widgets/request_widgets/details_card.dart';
import 'package:kind_clock/screens/widgets/request_widgets/details_row.dart';
import 'package:kind_clock/screens/widgets/request_widgets/status_row.dart';
import 'package:kind_clock/services/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';

class RequestDetails extends StatefulWidget {
  final RequestModel request;

  const RequestDetails({super.key, required this.request});

  @override
  State<RequestDetails> createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  final RequestController requestController = Get.find<RequestController>();
  final AuthController authController = Get.find<AuthController>();
  final NotificationController notificationController =
      Get.put(NotificationController());
  final FirebaseStorageService store = Get.find<FirebaseStorageService>();
  late final RequestDetailsController detailsController;

  @override
  void initState() {
    super.initState();
    detailsController = Get.put(RequestDetailsController());
    detailsController.loadRequestDetails(widget.request);
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = detailsController.requestModel.value ?? widget.request;
    return Scaffold(
      backgroundColor: Colors.white,
      body: DeferredPointerHandler(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 140, 170, 1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              height: 150,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomBackButton(
                        controller: requestController,
                      ),
                    ],
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Request Details',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Obx(() {
                    if (detailsController.isLoading.value) {
                      return _buildLoadingContent();
                    }

                    return _buildLoadedContent();
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 10),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedContent() {
    final request = detailsController.requestModel.value ?? widget.request;
    final currentUserId = authController.currentUserStore.value!.userId; 

    return Column(
      children: [
        DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (request.userId ==
                          authController.currentUserStore.value!.userId &&
                      request.status != RequestStatus.complete &&
                      request.status != RequestStatus.expired &&
                      request.requestedTime.isAfter(DateTime.now()))
                    IconButton(
                      onPressed: () {
                        Get.toNamed(
                          Routes.editAddRequestPage,
                          arguments: {'request': request},
                        );
                      },
                      icon:
                          SvgPicture.asset('assets/icons/edit_underscore.svg'),
                    ),
                    if (currentUserId != detailsController.posterUserId.value)
                             CircleAvatar(
                               backgroundColor:  Colors.grey[300],
                                 child: IconButton(
                                 icon: SvgPicture.asset('assets/icons/message.svg'),
                                 tooltip: "Chat with Poster",
                                 onPressed: () async {
                                   final roomId = requestController.getChatRoomId(
                                   currentUserId,
                                   detailsController.posterUserId.value,
                                   );
                                   Get.toNamed(
                                   Routes.chatPage,
                                   arguments: {
                                     'chatRoomId': roomId,
                                     'receiverId': detailsController.posterUserId.value,
                                     'receiverName': detailsController.posterUsername.value,
                                     'receiverProfilePic': " ",
                                   },
                             );
                           },
                       ),
                      ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Description:",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                request.description,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 10),
              const Text(
                "Date and Time",
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
              const SizedBox(height: 5),
              Text(
                detailsController.formatDateTime(request.requestedTime),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
                const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.person,
                label: "Posted by",
                value: detailsController.posterUsername.value,
              ),
              const SizedBox(height: 16),
              DetailsRow(
                icon: Icons.person,
                label: "Reffered by",
                value: detailsController.referrerUsername.value,
              ),
              const SizedBox(height: 16),
              DetailsRow(
                icon: Icons.location_on,
                label: "Location",
                value: request.location,
              ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.access_time,
                label: "Posted on",
                value: detailsController.formatDateTime(request.timestamp),
              ),
              const SizedBox(height: 12),
              StatusRow(
                label: "Status",
                status: request.status.toString().split(".").last.toUpperCase(),
              ),
              const SizedBox(height: 16),   
                DetailsRow(
                  icon: Icons.timer,
                  label: "Hours Needed",
                  value: (request.hoursNeeded ?? 1).toString(),
                ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.group,
                label: "No. of People wanted ",
                value: request.numberOfPeople?.toString() ?? '0',
              ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.people_outline,
                label: "Accepted Users",
                value: (request.acceptedUser?.length ?? 0).toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (requestController.isHelper.value)
          const DetailsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailsRow(
                  icon: Icons.feedback,
                  label: "Feedback",
                  value:
                      "You have been amazing in this program. I had lot of fun",
                ),
                SizedBox(height: 12),
                DetailsRow(
                  icon: Icons.timer,
                  label: "Hours helped",
                  value: "5 hours helped",
                ),
                SizedBox(height: 12),
                DetailsRow(
                  icon: Icons.star,
                  label: "Rating",
                  value: "4/5",
                ),
              ],
            ),
          ),
               if (((request.status == RequestStatus.accepted &&
                request.acceptedUser != null && 
                request.acceptedUser!.isNotEmpty  ) ||
            request.status == RequestStatus.incomplete ||
            request.status == RequestStatus.inprogress || 
            request.status == RequestStatus.complete) &&
            (request.userId == currentUserId || request.acceptedUser.any((user) => user.userId == currentUserId)))
          Column(
            children: [
              DetailsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Accepted By:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                              ...request.acceptedUser!.map((user) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: DetailsRow(
                                          icon: Icons.person,
                                          label: "Name",
                                          value: user.username,
                                        ),
                                      ),
                                      if (user.userId != currentUserId)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.account_circle, color: Colors.blue),
                                              tooltip: "View Profile",
                                              onPressed: () {
                                                Get.to(() => ProfileScreen(user: user));
                                              },
                                            ),
                                         if (currentUserId == detailsController.posterUserId.value)
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                              tooltip: "Chat",
                                              onPressed: () async {
                                                final roomId = requestController.getChatRoomId(
                                                  currentUserId,
                                                  user.userId,
                                                );
                                                Get.toNamed(
                                                  Routes.chatPage,
                                                  arguments: {
                                                    'chatRoomId': roomId,
                                                    'receiverId': user.userId,
                                                    'receiverName': user.username,
                                                    'receiverProfilePic':user.imageUrl ?? " ",
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DetailsRow(
                                    icon: Icons.email,
                                    label: "Email",
                                    value: user.email,
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(thickness: 1, color: Colors.grey),
                                  const SizedBox(height: 12),
                                ],
                              )),
                    const SizedBox(height: 15),
                    //completed and feedback button
                    if ((request.status == RequestStatus.accepted || request.status == RequestStatus.incomplete ) &&
                        authController.currentUserStore.value!.userId ==
                            request.userId &&
                        request.requestedTime.isBefore(DateTime.now()))
                      DeferPointer(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (request.feedbackList == null) {
                              Get.toNamed(
                                Routes.addfeedbackPage,
                                arguments: {'request': request},
                              )?.then((_) => detailsController.refreshData());
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: request.feedbackList == null
                                  ? const Color.fromRGBO(3, 80, 135, 1)
                                  : Colors.grey,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                request.feedbackList == null
                                    ? "Complete/Add feedback"
                                    : "Feedback added",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    //reminder notification button
                    if ((request.status == RequestStatus.accepted || request.status == RequestStatus.incomplete) &&
                        request.acceptedUser.any((user) =>
                            user.userId ==
                                authController.currentUserStore.value!.userId &&
                            request.requestedTime.isBefore(DateTime.now())))
                      DeferPointer(
                        child: GestureDetector(
                          onTap: () {
                            final newNotification = NotificationModel(
                              notificationId: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              status: "",
                              body: 'Please provide feedback for "${request.title}" accepted by ${authController.currentUserStore.value!.username}',
                              isUserWaiting: false,
                              userId: request.userId,
                              timestamp: DateTime.now(),
                            );
                            try {
                              notificationController
                                  .sendReminderNotification(newNotification);
                              //  print("Reminder notification sent");
                            } catch (e) {
                              print("Error: $e");
                            }

                            Get.snackbar(
                              'Reminder Sent',
                              'Notification sent to the requester!',
                              duration: const Duration(seconds: 3),
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.black87,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.orange,
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Text(
                              "Reminder for feedback",
                              style: TextStyle(color: Colors.white),
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
        //intereseted button
        if (request.userId != authController.currentUserStore.value!.userId &&
            !request.acceptedUser.any((user) =>
                user.userId == authController.currentUserStore.value!.userId) &&
            request.acceptedUser.length < request.numberOfPeople)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: DeferPointer(
              child: CustomButton(
                buttonText: "Interested",
                onButtonPressed: () {
                  Get.dialog(
                    IntrestedDialog(
                      questionText: "Are you interested?",
                      submitText: "Yes",
                      request: request,
                      acceptedUser: authController.currentUserStore.value!,
                    ),
                  ).then((_) => detailsController.refreshData());
                },
              ),
            ),
          ),
      ],
    );
  }
}
