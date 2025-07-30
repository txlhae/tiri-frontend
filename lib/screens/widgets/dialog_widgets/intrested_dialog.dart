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
  final TextEditingController messageController = TextEditingController();

  Future<void> interestUpdate() async {
    try {
      log('🙋 Sending volunteer request for: ${widget.request.requestId}');
      
      // Get message from text controller
      final message = messageController.text.trim();
      
      // Call the new volunteer request method
      await requestController.requestToVolunteer(
        widget.request.requestId, 
        message.isEmpty ? "I would like to volunteer for this request." : message
      );
      
      log('✅ Volunteer request sent successfully');
      // Refresh data to get updated status
      await requestController.refreshRequests();
    } catch (error) {
      log('💥 Error in volunteer request: $error');
      rethrow;
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
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
          height: MediaQuery.of(context).size.height * 0.35,
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
              // Optional message text field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Optional message to requester",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12.0),
                  ),
                ),
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
                        Get.back(); // Close dialog first
                        Get.toNamed(Routes.homePage); // Navigate to home screen
                        Get.snackbar(
                          'Success',
                          'Volunteer request sent successfully',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                      },
                    ).onError(
                      (error, stackTrace) {
                        Get.back(); // Close dialog
                        Get.snackbar(
                          'Error',
                          'Failed to send volunteer request: $error',
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

