import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import '../../controllers/email_sent_controller.dart';

class EmailSentSplash extends StatefulWidget {
  const EmailSentSplash({super.key});

  @override
  State<EmailSentSplash> createState() => _EmailSentSplashState();
}

class _EmailSentSplashState extends State<EmailSentSplash> {
  @override
  void initState() {
    Timer(const Duration(seconds: 4), () {
      Get.offAllNamed(Routes.loginPage);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EmailSentController>(
      init: EmailSentController(),
      builder: (controller) {
        double circleSize = 140;
        double iconSize = 108;

        return ScaleTransition(
          scale: controller.scaleAnimation,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/sent_icon.svg',
                      height: circleSize,
                      width: iconSize,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Password reset mail sent to your mail ID",
                      style: TextStyle(
                          fontWeight: FontWeight.w300, color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Visit your email and reset the password",
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
