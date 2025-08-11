import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';

/// Dedicated Email Verification Screen
/// 
/// Shown after successful registration to guide users through email verification.
/// Users cannot access the main app until verification is completed.
/// 
/// Features:
/// - Professional verification UI
/// - "I have verified" functionality
/// - Loading states and error handling
/// - Blocks access until verification succeeds
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late final AuthController authController;
  final RxBool isCheckingVerification = false.obs;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
  }

  /// Handle "I have verified" button press
  Future<void> handleVerificationCheck() async {
    try {
      log('🔍 EmailVerificationScreen: User clicked "I have verified"');
      
      isCheckingVerification.value = true;
      
      // Call the enhanced verification check method
      final success = await authController.checkVerificationStatus();
      
      if (success) {
        log('✅ EmailVerificationScreen: Verification successful - navigating to home');
        
        // Success is handled by AuthController - it navigates to home and shows success message
        // No additional action needed here
        
      } else {
        log('❌ EmailVerificationScreen: Verification failed - staying on screen');
        
        // Show additional guidance for failed verification
        Get.snackbar(
          'Verification Pending',
          'Please check your email and click the verification link. If you can\'t find it, check your spam folder.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
          icon: const Icon(Icons.email_outlined, color: Colors.white),
        );
      }
      
    } catch (e) {
      log('❌ EmailVerificationScreen: Error during verification check: $e');
      
      Get.snackbar(
        'Verification Error',
        'Unable to check verification status. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isCheckingVerification.value = false;
    }
  }

  /// Handle resend verification email
  Future<void> handleResendEmail() async {
    try {
      log('📧 EmailVerificationScreen: Resending verification email');
      
      final userEmail = authController.currentUserStore.value?.email;
      if (userEmail == null) {
        Get.snackbar(
          'Error',
          'Unable to find your email address',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // TODO: Implement resend verification email API call
      // For now, show a placeholder message
      Get.snackbar(
        'Email Sent',
        'A new verification email has been sent to $userEmail',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.email, color: Colors.white),
      );
      
    } catch (e) {
      log('❌ EmailVerificationScreen: Error resending email: $e');
      
      Get.snackbar(
        'Resend Failed',
        'Unable to resend verification email. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // Main content
              Expanded(
                child: _buildContent(),
              ),
              
              // Bottom actions
              _buildActions(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header section
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 140, 170, 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.email_outlined,
              size: 40,
              color: Color.fromRGBO(0, 140, 170, 1),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Verify Your Email',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final userEmail = authController.currentUserStore.value?.email ?? 'your email';
            return Text(
              'We sent a verification link to\n$userEmail',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build the main content section
  Widget _buildContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success checkmark icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 60,
            color: Colors.green.shade600,
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Main message
        const Text(
          'Registration Successful!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 15),
        
        const Text(
          'An email has been sent to verify your account.\n\nPlease check your email and click the verification link to continue.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 20),
        
        // Email not received help
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive an email?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            TextButton(
              onPressed: handleResendEmail,
              child: const Text(
                'Resend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(0, 140, 170, 1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build the action buttons section
  Widget _buildActions() {
    return Column(
      children: [
        // I have verified button
        Obx(() => CustomButton(
          buttonText: isCheckingVerification.value 
              ? "Checking..." 
              : "I Have Verified",
          onButtonPressed: isCheckingVerification.value 
              ? () {} // Disabled state
              : () => handleVerificationCheck(), // Convert Future to void function
        )),
        
        const SizedBox(height: 15),
        
        // Back to login option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Need to use a different account?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            TextButton(
              onPressed: () {
                // Clear current session and go back to login
                authController.logout();
              },
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(0, 140, 170, 1),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
