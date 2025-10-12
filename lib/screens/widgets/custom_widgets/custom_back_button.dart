import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';

class CustomBackButton extends StatelessWidget {
  final bool? isClose;
  final VoidCallback? onPressed;
  final GetxController controller;

  const CustomBackButton({super.key, this.onPressed, required this.controller, this.isClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (controller is RequestController) {
            (controller as RequestController).clearFields();
          }
          Get.back();
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: const Color.fromRGBO(235, 237, 237, 0.5),
            child: SvgPicture.asset(
              'assets/icons/back_button_new.svg',
              width: 15,
              height: 15,
            ),
          ),
        ),
      ),
    );
  }
}
