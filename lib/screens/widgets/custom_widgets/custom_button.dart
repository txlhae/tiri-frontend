import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/screens/auth_screens/register_screen.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
  });

  final String buttonText;
  final void Function() onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final requestController = Get.find<RequestController>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onButtonPressed,
      child: Container(
          decoration: BoxDecoration(
              color: const Color.fromRGBO(3, 80, 135, 1),
              borderRadius: BorderRadius.circular(30)),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
            ),
            child: Obx(
              () {
                return Center(
                  child: imageController.isLoading.value ||
                          authController.isloading.value ||
                          requestController.isLoading.value
                      ? const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )),
                        )
                      : Text(
                          buttonText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                );
              },
            ),
          )),
    );
  }
}
