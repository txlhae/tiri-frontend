import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/verification_status_widget.dart';

class VerifyPendingScreen extends StatefulWidget {
  final String? referredUser;
  const VerifyPendingScreen({super.key, this.referredUser});

  @override
  State<VerifyPendingScreen> createState() => _VerifyPendingScreenState();
}

class _VerifyPendingScreenState extends State<VerifyPendingScreen> {
  Timer? _autoNavigationTimer;

  @override
  void initState() {
    super.initState();
    
    // Auto-navigate to login after 30 seconds if no action taken
    _autoNavigationTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        Get.offAllNamed(Routes.loginPage);
      }
    });
  }

  @override
  void dispose() {
    _autoNavigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Icon(
                      Icons.verified,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Description
                  const Text(
                    'Your account has been registered successfully.\nPlease verify your email to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Verification Widget
                  VerificationStatusWidget(
                    title: 'Email Verification Required',
                    description: 'We\'ve sent a verification email to your address. Please check your email and click the verification link.',
                    buttonText: 'I have verified my email',
                    onVerificationSuccess: () {
                      // Navigation is handled by the AuthController
                      _autoNavigationTimer?.cancel();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Manual Login Option
                  TextButton(
                    onPressed: () {
                      _autoNavigationTimer?.cancel();
                      Get.offAllNamed(Routes.loginPage);
                    },
                    child: const Text(
                      'Skip for now and login manually',
                      style: TextStyle(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
