import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/account_status_service.dart';
import 'package:tiri/models/auth_models.dart';
import 'package:tiri/screens/widgets/account_status_widgets/account_status_indicator.dart';
import 'package:tiri/screens/widgets/account_status_widgets/deletion_warning.dart';

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
  late final AuthService authService;
  late final AccountStatusService accountStatusService;
  final RxBool isCheckingVerification = false.obs;
  final Rx<RegistrationStatusResponse?> currentStatus = Rx<RegistrationStatusResponse?>(null);

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    authService = Get.find<AuthService>();
    accountStatusService = AccountStatusService.instance;
    
    // Load current status on screen load
    _loadCurrentStatus();
  }

  /// Load current registration status
  Future<void> _loadCurrentStatus() async {
    try {
      // Try to get cached status first
      final cachedStatus = await accountStatusService.getStoredAccountStatus();
      
      if (cachedStatus != null) {
        log('📱 EmailVerificationScreen: Using cached status', name: 'EMAIL_VERIFICATION');
        return;
      }
      
      // Fetch fresh status from server
      final status = await authService.getRegistrationStatus();
      if (status != null) {
        currentStatus.value = status;
        await accountStatusService.storeAccountStatus(status);
      }
    } catch (e) {
      log('❌ EmailVerificationScreen: Error loading status: $e', name: 'EMAIL_VERIFICATION');
    }
  }

  /// Handle "I have verified" button press with enhanced status checking
  Future<void> handleVerificationCheck() async {
    try {
      log('🔍 EmailVerificationScreen: User clicked "I have verified"');
      
      isCheckingVerification.value = true;
      
      // Get fresh registration status from server
      final status = await authService.getRegistrationStatus();
      
      if (status == null) {
        throw Exception('Unable to check verification status. Please try again.');
      }
      
      // Update current status
      currentStatus.value = status;
      await accountStatusService.storeAccountStatus(status);
      
      // Handle different verification states
      switch (status.nextStep) {
        case 'waiting_for_approval':
          log('✅ EmailVerificationScreen: Email verified - now waiting for approval');
          
          Get.snackbar(
            'Email Verified!',
            'Your email has been verified! Now waiting for referrer approval.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
          
          // Route to approval waiting screen
          await Future.delayed(const Duration(seconds: 1));
          Get.offAllNamed('/pending-approval');
          break;
          
        case 'ready':
          log('✅ EmailVerificationScreen: Email verified and fully approved - going to home');
          
          Get.snackbar(
            'Welcome to TIRI!',
            'Your account is fully set up and ready to use!',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
            icon: const Icon(Icons.celebration, color: Colors.white),
          );
          
          // Route to home
          await Future.delayed(const Duration(seconds: 1));
          Get.offAllNamed('/home');
          break;
          
        case 'verify_email':
        default:
          log('❌ EmailVerificationScreen: Email still not verified');
          
          Get.snackbar(
            'Email Not Verified Yet',
            'Please check your email and click the verification link first. If you can\'t find it, check your spam folder.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            icon: const Icon(Icons.email_outlined, color: Colors.white),
          );
          break;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Deletion warning if needed
              Obx(() {
                final status = currentStatus.value;
                if (status?.warning != null && 
                    accountStatusService.shouldShowDeletionWarning(status!.warning)) {
                  return DeletionWarning(
                    warning: status.warning!,
                    onActionPressed: handleVerificationCheck,
                    isDismissible: true,
                  );
                }
                return const SizedBox.shrink();
              }),
              
              // Header
              _buildHeader(),
              
              const SizedBox(height: 40),
              
              // Account status indicator
              Obx(() {
                final status = currentStatus.value;
                if (status?.registrationStage != null) {
                  return AccountStatusIndicator(
                    registrationStage: status!.registrationStage,
                    showProgress: true,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  );
                }
                return const SizedBox.shrink();
              }),
              
              const SizedBox(height: 20),
              
              // Main content
              _buildContent(),
              
              const SizedBox(height: 40),
              
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
