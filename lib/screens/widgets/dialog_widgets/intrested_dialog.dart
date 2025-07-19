import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_cancel.dart';

class IntrestedDialog extends StatefulWidget {
  final String questionText;
  final String submitText;
  final RequestModel request;
  final UserModel acceptedUser;
  const IntrestedDialog({
    super.key,
    required this.questionText,
    required this.submitText,
    required this.request,
    required this.acceptedUser,
  });

  @override
  State<IntrestedDialog> createState() => _IntrestedDialogState();
}

class _IntrestedDialogState extends State<IntrestedDialog> {
  final requestController = Get.find<RequestController>();

  Future<void> interestUpdate() async {
    log('AcceptedUser type: ${widget.acceptedUser.runtimeType}');
    try {
      // Get the current list of accepted users (null-safe)
      final currentAcceptedUsers = widget.request.acceptedUser ?? [];

      // Check if this user is already in the list
      final alreadyAccepted = currentAcceptedUsers.any(
        (user) => user.userId == widget.acceptedUser.userId,
      );

      // Add the user only if they aren't already accepted
      final updatedAcceptedUsers = alreadyAccepted
          ? currentAcceptedUsers
          : [...currentAcceptedUsers, widget.acceptedUser];

      final updatedRequest = RequestModel(
        requestId: widget.request.requestId,
        userId: widget.request.userId,
        title: widget.request.title,
        description: widget.request.description,
        location: widget.request.location,
        timestamp: widget.request.timestamp,
        requestedTime: widget.request.requestedTime,
        status: requestController.determineRequestStatus(
            widget.request, updatedAcceptedUsers),
        acceptedUser: updatedAcceptedUsers,
        numberOfPeople: widget.request.numberOfPeople,
        hoursNeeded: widget.request.hoursNeeded
      );

      await requestController.controllerUpdateRequest(
        widget.request.requestId,
        updatedRequest,
      );

      log('Request updated');
    } catch (error) {
      log('Error in interested dialog: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (requestController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                widget.questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5.0),
                child: CustomCancel(
                  buttonText: 'No',
                  onButtonPressed: () {
                    log("No");
                    Get.back();
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5.0),
                child: CustomButton(
                  buttonText: widget.submitText,
                  onButtonPressed: () async {
                    await interestUpdate().then(
                      (value) {
                        Get.toNamed(
                            Routes.homePage); // Navigate to home screen();
                        Get.snackbar(
                          'Success',
                          'Request accepted successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      },
                    ).onError(
                      (error, stackTrace) {
                        Get.back();
                        Get.snackbar(
                          'Error',
                          'Failed to accept request: $error',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
