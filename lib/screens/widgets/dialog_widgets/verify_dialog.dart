
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_cancel.dart';

class VerifyDialog extends StatefulWidget {
  final UserModel acceptedUser;
  const VerifyDialog({
    super.key,
    required this.acceptedUser,
  });

  @override
  State<VerifyDialog> createState() => _VerifyDialogState();
}

class _VerifyDialogState extends State<VerifyDialog> {
  final authController = Get.find<AuthController>();
  Future<void> verifyUserData() async {
    try {
      await authController.verifyUser(widget.acceptedUser);
    } catch (error) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (authController.isloading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                'Are you sure you want to verify this request?',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                    Get.back();
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40.0, vertical: 5.0),
                child: CustomButton(
                  buttonText: 'Verify',
                  onButtonPressed: () async {
                    await verifyUserData().then(
                      (value) {
                        Get.back();
                        Get.snackbar(
                          'Success',
                          'User verified successfully',
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
                          'Failed to update request: $error',
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
