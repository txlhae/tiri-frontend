
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/models/notification_model.dart';
import 'package:tiri/models/request_model.dart';
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
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 10),
              Text(
                widget.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
                  ],
                )),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
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
                      } else if (isAcceptedUser) {
                        // For accepted volunteers: Cancel their volunteer request
                        await requestController.cancelVolunteerRequest(
                          widget.request.requestId,
                          reason: reasonController.text.trim(),
                        );
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
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
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




