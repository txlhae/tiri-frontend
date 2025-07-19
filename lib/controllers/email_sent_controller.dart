import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmailSentController extends GetxController
    with GetTickerProviderStateMixin {
  late AnimationController scaleController;
  late Animation<double> scaleAnimation;
  late AnimationController checkController;
  late Animation<double> checkAnimation;

  @override
  void onInit() {
    super.onInit();
    scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    scaleAnimation =
        CurvedAnimation(parent: scaleController, curve: Curves.elasticOut);

    checkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    checkAnimation =
        CurvedAnimation(parent: checkController, curve: Curves.linear);

    scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        checkController.forward();
      }
    });

    scaleController.forward();
  }

  @override
  void onClose() {
    scaleController.dispose();
    checkController.dispose();
    super.onClose();
  }
}
