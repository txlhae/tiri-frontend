import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_cancel.dart';

class LogoutDialog extends StatelessWidget {
  final String questionText;
  final String submitText;
  final String? routeText;
  const LogoutDialog(
      {super.key,
      required this.questionText,
      required this.submitText,
      this.routeText});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Column(
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
              SvgPicture.asset(
                'assets/icons/logout_picture.svg',
                height: 180,
                width: 100,
              ),
              const Text(
                "Come back soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              Text(
                questionText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 10.0),
                child: CustomCancel(
                  buttonText: 'Cancel',
                  onButtonPressed: () {
                    log("No");
                    Get.back();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 40.0, vertical: 10.0),
                child: CustomButton(
                  buttonText: 'Logout',
                  onButtonPressed: () {
                    controller.logout();
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
