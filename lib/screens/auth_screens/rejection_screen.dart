import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/referral_dialog.dart';

class RejectionScreen extends StatelessWidget {
  const RejectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_named.png',
                    width: 100,
                    height: 40,
                  ),
                ],
              ),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rejection icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(220, 53, 69, 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromRGBO(220, 53, 69, 1),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 50,
                        color: Color.fromRGBO(220, 53, 69, 1),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Status message
                    const Text(
                      'Registration Not Approved',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text(
                      'Unfortunately, your registration was not approved by the referrer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Rejection reason (if provided)
                    Obx(() {
                      if (authController.rejectionReason.value.isNotEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(220, 53, 69, 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromRGBO(220, 53, 69, 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reason:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color.fromRGBO(220, 53, 69, 1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                authController.rejectionReason.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Container();
                    }),
                    
                    const SizedBox(height: 40),
                    
                    // Options
                    Column(
                      children: [
                        const Text(
                          'What would you like to do?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Try different referral code button
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            buttonText: 'Try Different Referral Code',
                            onButtonPressed: () {
                              // Clear current referral data
                              authController.referredUser.value = '';
                              authController.referredUid.value = '';
                              authController.approvalStatus.value = 'pending';
                              authController.rejectionReason.value = '';
                              
                              // Show referral dialog
                              Get.dialog(const RefferalDialog());
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Contact referrer button
                        if (authController.referredUser.value.isNotEmpty)
                          OutlinedButton(
                            onPressed: () {
                              _showContactReferrerDialog(context, authController);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color.fromRGBO(0, 140, 170, 1),
                              side: const BorderSide(
                                color: Color.fromRGBO(0, 140, 170, 1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Contact Referrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 15),
                        
                        // Contact support button
                        TextButton(
                          onPressed: () {
                            Get.toNamed(Routes.contactUsPage);
                          },
                          child: const Text(
                            'Contact Support for Help',
                            style: TextStyle(
                              color: Color.fromRGBO(0, 140, 170, 1),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Back to login
                        TextButton(
                          onPressed: () {
                            authController.logout();
                          },
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactReferrerDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Referrer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your referrer: ${authController.referredUser.value}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'We recommend reaching out to your referrer to discuss your registration and address any concerns they may have.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Tips for contacting your referrer:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Be polite and professional\n'
                '• Ask for specific feedback\n'
                '• Show you\'re willing to improve\n'
                '• Clarify any misunderstandings',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}