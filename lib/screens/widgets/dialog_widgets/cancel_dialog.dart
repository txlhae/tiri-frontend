
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/models/notification_model.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_cancel.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class CancelDialog extends StatefulWidget {
  final String questionText;
  final String submitText;
  final RequestModel request;
  const CancelDialog(
      {super.key,
      required this.questionText,
      required this.submitText,
      required this.request});

  @override
  State<CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<CancelDialog> {
  final reasonController = TextEditingController();
  final requestController = Get.find<RequestController>();
  final authController = Get.find<AuthController>();
  final RxnString reasonError = RxnString(null);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: SizedBox(
          height: widget.request.acceptedUser.isNotEmpty
              ? MediaQuery.of(context).size.height * 0.4
              : MediaQuery.of(context).size.height * 0.25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: SvgPicture.asset(
                      'assets/icons/close_icon.svg',
                      fit: BoxFit.cover,
                      height: 20,
                      width: 20,
                    ),
                  ),
                ],
              ),
              Text(
                widget.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              if (widget.request.acceptedUser.isNotEmpty)
                Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomFormField(
                      hintText: "Reason to cancel",
                      haveObscure: false,
                      textController: reasonController,
                      isdescription: true,
                    ),
                    if (reasonError.value != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0, left: 4.0),
                        child: Text(
                          reasonError.value!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                )),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: CustomButton(
                  buttonText: "Proceed to cancel",
                  onButtonPressed: () async {
                    if (widget.request.acceptedUser.isNotEmpty && reasonController.text.trim().isEmpty) {
                              reasonError.value = "Reason is required";
                              return;
                            } else {
                              reasonError.value = null;
                            }
                    try {
                      final currentUserId = authController.currentUserStore.value!.userId;

                      final isAcceptedUser =
                          widget.request.acceptedUser.isNotEmpty &&
                              widget.request.acceptedUser
                                  .any((user) => user.userId == currentUserId);

                      final isRequester =  widget.request.userId == currentUserId;

                      if (isRequester) {
                        // For request owners: DELETE the request entirely
                        await requestController.deleteRequest(widget.request.requestId);
                      } else {
                        // For accepted volunteers: Update request to remove them
                        // Update accepted users list
                        List<UserModel> updatedAcceptedUsers =
                            widget.request.acceptedUser;

                        if (isAcceptedUser) {
                          updatedAcceptedUsers = widget.request.acceptedUser
                              .where((user) => user.userId != currentUserId)
                              .toList();
                        }

                        // Update request status
                        final newStatus = RequestStatus.values.firstWhere((e) => e.name == requestController.determineRequestStatus(widget.request), orElse: () => RequestStatus.pending);

                        // Build updated request model
                        RequestModel requestUpdate = RequestModel(
                          requestId: widget.request.requestId,
                          userId: widget.request.userId,
                          title: widget.request.title,
                          description: widget.request.description,
                          location: widget.request.location,
                          timestamp: widget.request.timestamp,
                          requestedTime: widget.request.requestedTime,
                          status: newStatus,
                          acceptedUser: updatedAcceptedUsers,
                          numberOfPeople: widget.request.numberOfPeople,
                          hoursNeeded: widget.request.hoursNeeded
                        );

                        await requestController.controllerUpdateRequest(
                            widget.request.requestId, requestUpdate);
                      }

                      // Notifications
                      if (isRequester && widget.request.acceptedUser.isNotEmpty) {
                        for (var user in widget.request.acceptedUser) {
                          // Create notification for accepted users
                          NotificationModel(
                            body:
                                "'${widget.request.title}' has been cancelled by the requester. Reason: ${reasonController.text}",
                            timestamp: DateTime.now(),
                            isUserWaiting: false,
                            userId: user.userId,
                            status: RequestStatus.cancelled
                                .toString()
                                .split(".")
                                .last,
                            notificationId: DateTime.now()
                                .millisecondsSinceEpoch
                                .toString(),
                          );
                          // await store.saveNotification(notification);
                        }
                      } else if (isAcceptedUser) {
                        // Create notification for requester
                        NotificationModel(
                          body:
                              "Your request '${widget.request.title}' was cancelled by a helper. Reason: ${reasonController.text}",
                          timestamp: DateTime.now(),
                          isUserWaiting: false,
                          userId: widget.request.userId,
                          status: RequestStatus.cancelled
                              .toString()
                              .split(".")
                              .last,
                          notificationId:
                              DateTime.now().millisecondsSinceEpoch.toString(),
                        );
                        // await store.saveNotification(notification);
                        // REMOVED: Firebase dependency
                      }

                      Get.back();
                    } catch (e) {
      // Error handled silently
                      Get.snackbar("Error",
                          "Failed to cancel request. Please try again.");
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: CustomCancel(
                  buttonText: 'No',
                  onButtonPressed: () {
                    Get.back();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}




