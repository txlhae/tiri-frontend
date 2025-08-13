import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with TickerProviderStateMixin {
  late AuthController authController;
  Timer? _statusCheckTimer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
    
    // No automatic polling - only check when button is clicked
  }

  // Removed automatic polling - now only checks when button is clicked

  void _checkApprovalStatus() async {
    try {
      log('🔍 PendingApprovalScreen: Check Status button clicked');
      
      // Use checkVerificationStatus which returns full approval info  
      final isApproved = await authController.checkVerificationStatus();
      
      log('📊 PendingApprovalScreen: checkVerificationStatus returned: $isApproved');
      
      if (isApproved) {
        // User is approved! 
        log('✅ PendingApprovalScreen: User approved');
        
        // The checkVerificationStatus method handles all navigation and notifications
        
      } else {
        // User is not approved yet - check for other status changes
        log('⏳ PendingApprovalScreen: Still not approved, checking status: ${authController.approvalStatus.value}');
        
        // Handle rejection or expiration cases
        switch (authController.approvalStatus.value) {
          case 'rejected':
            log('❌ PendingApprovalScreen: User rejected - navigating to rejection screen');
            Get.offAllNamed(Routes.rejectionScreen);
            break;
          case 'expired':
            log('⏰ PendingApprovalScreen: Approval expired - navigating to expired screen');
            Get.offAllNamed(Routes.expiredScreen);
            break;
          case 'pending':
          default:
            // Still pending, stay on current screen
            log('⏳ PendingApprovalScreen: Still pending approval');
            break;
        }
      }
    } catch (e) {
      log('❌ PendingApprovalScreen: Error in _checkApprovalStatus: $e');
      
      // Show user-friendly error
      Get.snackbar(
        'Check Failed',
        'Unable to check status. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel(); // Just in case
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Obx(() {
            return Column(
              children: [
                const SizedBox(height: 40),
                      // Animated waiting icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(111, 168, 67, 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color.fromRGBO(111, 168, 67, 1),
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.hourglass_empty,
                                size: 50,
                                color: Color.fromRGBO(111, 168, 67, 1),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Status message
                      const Text(
                        'Waiting for Approval',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Referrer info
                      if (authController.referredUser.value.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(3, 80, 135, 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Referred by: ${authController.referredUser.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Description
                      const Text(
                        'Your email has been verified successfully! ✅\n\n'
                        'Now waiting for approval from your referrer.\n'
                        'You will be notified once they review your registration.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Countdown timer
                      if (authController.approvalExpiresAt.value != null)
                        _buildCountdownTimer(),
                      
                      const SizedBox(height: 30),
                      
                      // Progress indicators
                      _buildProgressIndicators(),
                      
                      const SizedBox(height: 40),
                      
                      // Refresh button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          buttonText: 'Check Status',
                          onButtonPressed: _checkApprovalStatus,
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Contact support button
                      TextButton(
                        onPressed: () {
                          Get.toNamed(Routes.contactUsPage);
                        },
                        child: const Text(
                          'Need help? Contact Support',
                          style: TextStyle(
                            color: Color.fromRGBO(0, 140, 170, 1),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                
                const SizedBox(height: 40),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    if (authController.approvalExpiresAt.value == null) {
      return Container();
    }

    final expiresAt = authController.approvalExpiresAt.value!;
    final now = DateTime.now();
    
    if (expiresAt.isBefore(now)) {
      return const Text(
        'Request has expired',
        style: TextStyle(
          fontSize: 16,
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final difference = expiresAt.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    
    String timeText;
    Color timeColor;
    
    if (days > 0) {
      timeText = 'Expires in $days days, $hours hours';
      timeColor = days > 1 ? Colors.green : Colors.orange;
    } else if (hours > 0) {
      timeText = 'Expires in $hours hours';
      timeColor = hours > 12 ? Colors.orange : Colors.red;
    } else {
      final minutes = difference.inMinutes;
      timeText = 'Expires in $minutes minutes';
      timeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: timeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: timeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            color: timeColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              color: timeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Column(
      children: [
        const Text(
          'Registration Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildProgressStep(
          icon: Icons.code,
          title: 'Referral Code Valid',
          isCompleted: true,
        ),
        
        const SizedBox(height: 12),
        
        _buildProgressStep(
          icon: Icons.person_add,
          title: 'Account Created',
          isCompleted: true,
        ),
        
        const SizedBox(height: 12),
        
        _buildProgressStep(
          icon: Icons.email_outlined,
          title: 'Email Verified',
          isCompleted: authController.isUserVerified,
        ),
        
        const SizedBox(height: 12),
        
        _buildProgressStep(
          icon: Icons.approval,
          title: 'Referrer Approval',
          isCompleted: authController.approvalStatus.value == 'approved',
          isPending: authController.approvalStatus.value == 'pending',
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String title,
    required bool isCompleted,
    bool isPending = false,
  }) {
    Color color;
    Widget iconWidget;
    
    if (isCompleted) {
      color = const Color.fromRGBO(111, 168, 67, 1);
      iconWidget = const Icon(
        Icons.check_circle,
        color: Color.fromRGBO(111, 168, 67, 1),
        size: 24,
      );
    } else if (isPending) {
      color = Colors.orange;
      iconWidget = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
        ),
      );
    } else {
      color = Colors.grey;
      iconWidget = Icon(
        icon,
        color: Colors.grey,
        size: 24,
      );
    }

    return Row(
      children: [
        iconWidget,
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}