import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/dialog_widgets/referral_dialog.dart';

class ExpiredScreen extends StatelessWidget {
  const ExpiredScreen({super.key});

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
                    // Expired icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.orange,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        size: 50,
                        color: Colors.orange,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Status message
                    const Text(
                      'Approval Request Expired',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    const Text(
                      'Your approval request has expired after 7 days.\n'
                      'Your referrer did not respond within the time limit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Info box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'What happened?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Approval requests automatically expire after 7 days to keep the system moving. This doesn\'t mean you were rejected - your referrer may have simply missed the notification.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Options
                    Column(
                      children: [
                        const Text(
                          'What would you like to do next?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Try same referral code again
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            buttonText: 'Try Same Referral Code Again',
                            onButtonPressed: () {
                              if (authController.referredUid.value.isNotEmpty) {
                                _showConfirmationDialog(
                                  context, 
                                  authController,
                                  'Try Again with Same Code?',
                                  'This will start a new 7-day approval period with ${authController.referredUser.value}.',
                                  () => _restartWithSameCode(authController),
                                );
                              }
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Try different referral code
                        OutlinedButton(
                          onPressed: () {
                            // Clear current referral data
                            authController.referredUser.value = '';
                            authController.referredUid.value = '';
                            authController.approvalStatus.value = 'pending';
                            authController.rejectionReason.value = '';
                            
                            // Show referral dialog
                            Get.dialog(const RefferalDialog());
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
                            'Try Different Referral Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contact support
                        TextButton(
                          onPressed: () {
                            Get.toNamed(Routes.contactUsPage);
                          },
                          child: const Text(
                            'Contact Support for Assistance',
                            style: TextStyle(
                              color: Color.fromRGBO(0, 140, 170, 1),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
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

  void _showConfirmationDialog(
    BuildContext context,
    AuthController authController,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(111, 168, 67, 1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _restartWithSameCode(AuthController authController) {
    // Navigate back to registration with the same referral code
    // The system will create a new approval request
    authController.navigateToRegister();
    
    Get.snackbar(
      'Starting Fresh',
      'A new approval request will be sent to ${authController.referredUser.value}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color.fromRGBO(111, 168, 67, 1),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}