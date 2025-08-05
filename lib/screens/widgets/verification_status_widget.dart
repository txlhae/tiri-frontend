import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';

/// Widget for handling email verification status checks
/// Used in verification pending screens and forgot password flows
class VerificationStatusWidget extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onVerificationSuccess;
  
  const VerificationStatusWidget({
    Key? key,
    this.title = 'Verify Your Email',
    this.description = 'Please check your email and click the verification link, then tap the button below.',
    this.buttonText = 'I have verified',
    this.onVerificationSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Obx(() => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status Icon
        Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(22, 178, 217, .2),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Icon(
            Icons.mark_email_unread,
            size: 50,
            color: const Color.fromRGBO(0, 140, 170, 1),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Description
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Verification Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authController.isLoading.value 
                ? null 
                : () async {
                    final success = await authController.checkVerificationStatus();
                    if (success) {
                      onVerificationSuccess?.call();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: authController.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Help Text
        const Text(
          'Didn\'t receive the email? Check your spam folder or contact support.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    ));
  }
}
