
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';
import 'package:tiri/screens/widgets/navigate_row.dart';

class RefferalDialog extends StatefulWidget {
  const RefferalDialog({super.key});

  @override
  State<RefferalDialog> createState() => _RefferalDialogState();
}

class _RefferalDialogState extends State<RefferalDialog> {
  final referralCodeController = TextEditingController();
  final requestController = Get.find<RequestController>();
  final authController = Get.find<AuthController>();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Got a referral code from a friend or recruiter? Enter it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black),
              ),
              const SizedBox(height: 16),
              CustomFormField(
                hintText: "Referral code",
                haveObscure: false,
                textController: referralCodeController,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: CustomButton(
                  buttonText: "Verify",
                  onButtonPressed: () async {
                    await authController
                        .fetchUserByReferralCode(referralCodeController.text)
                        .then(
                      (value) {
                        if (value != null) {
                          authController.referredUid.value = value.userId;
                          authController.referredUser.value = value.username;
                          Get.back();
                          authController.navigateToRegister();
                        } else {
                          Get.snackbar(
                            'Error',
                            'Not a valid user',
                            snackPosition: SnackPosition.TOP,
                            duration: const Duration(seconds: 3),
                            backgroundColor:
                                const Color.fromRGBO(220, 53, 69, 1),
                            colorText: Colors.white,
                          );
                        }
                      },
                    ).onError(
                      (error, stackTrace) {
                        Get.snackbar(
                          'Error',
                          'Not a valid user',
                          snackPosition: SnackPosition.TOP,
                          duration: const Duration(seconds: 3),
                          backgroundColor: const Color.fromRGBO(220, 53, 69, 1),
                          colorText: Colors.white,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // OR divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              // QR Scanner Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color.fromRGBO(0, 140, 170, 1), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(Routes.qrScannerPage, arguments: {'mode': 'referral'});
                    },
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color.fromRGBO(0, 140, 170, 1),
                    ),
                    label: const Text(
                      'SCAN QR CODE',
                      style: TextStyle(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              NavigateRow(
                textData: "Already have an account?",
                buttonTextData: "Login Here",
                onButtonPressed: () => Get.back(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
