import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: SplashController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/images/logo_named.png'),
                      fit: BoxFit.cover)),
              height: 400,
              width: 400,
            ),
          ),
        );
      },
    );
  }
}
