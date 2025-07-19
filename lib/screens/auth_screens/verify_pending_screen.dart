import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/infrastructure/routes.dart';

class VerifyPendingScreen extends StatefulWidget {
  final String? referredUser;
  const VerifyPendingScreen({super.key, this.referredUser});

  @override
  State<VerifyPendingScreen> createState() => _VerifyPendingScreenState();
}

class _VerifyPendingScreenState extends State<VerifyPendingScreen> {
  @override
  void initState() {
    Timer(const Duration(seconds: 4), () {
      Get.offAllNamed(Routes.loginPage);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          height: 200,
          width: 250,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 40, color: Colors.green),
              Text(
                'Congratulations!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                'Your account Registered Succesfully.\nWaiting for approval.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
