import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_form_field.dart';
import 'package:kind_clock/screens/widgets/navigate_row.dart';

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     GestureDetector(
              //       onTap: () => Get.back(),
              //       child: SvgPicture.asset(
              //                   'assets/icons/close_icon.svg',
              //                   fit: BoxFit.cover,
              //                   height: 20,
              //                   width: 20,
              //                 ),
              //     ),
              //   ],
              // ),
              const Text(
                'Got a referral code from a friend or recruiter? Enter it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black),
              ),
              CustomFormField(
                hintText: "Referral code",
                haveObscure: false,
                textController: referralCodeController,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: CustomButton(
                  buttonText: "Verify",
                  onButtonPressed: () async {
                    await authController
                        .fetchUserByReferralCode(referralCodeController.text)
                        .then(
                      (value) {
                        log("User is: ${value.toString()}");
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
                        log(error.toString());
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
