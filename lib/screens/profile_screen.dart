// File: lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/chat_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/feedback_model.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/dialog_widgets/delete_dialog.dart';
import 'package:tiri/screens/widgets/dialog_widgets/edit_dialog.dart';
import 'package:tiri/screens/widgets/dialog_widgets/logout_dialog.dart';
import 'package:tiri/screens/widgets/dialog_widgets/qr_code_dialog.dart';
import 'package:tiri/screens/widgets/profile_nav_button.dart';
import 'package:tiri/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final Rxn<UserModel> shownUser = Rxn<UserModel>();
  final RequestController requestController = Get.find<RequestController>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = authController.currentUserStore.value!;
      final targetUserId = widget.user?.userId ?? currentUser.userId;

      // Always fetch fresh data - no caching
      final apiService = Get.find<ApiService>();
      final response = await apiService.get('/api/profile/users/$targetUserId/');

      if (response.statusCode == 200 && response.data != null) {
        final apiData = response.data as Map<String, dynamic>;

        // Create user directly with fresh API data
        final freshUser = UserModel(
          userId: apiData['userId']?.toString() ?? targetUserId,
          email: apiData['email']?.toString() ?? '',
          username: apiData['full_name'] ?? apiData['username'] ?? 'Unknown',
          imageUrl: apiData['profile_image'],
          phoneNumber: apiData['phone_number']?.toString(),
          country: apiData['country'],
          referralCode: apiData['referralCode'],  // ← Clean - no fallbacks
          rating: (apiData['average_rating'] as num?)?.toDouble(),
          hours: (apiData['total_hours_helped'] as num?)?.toInt(),
          createdAt: apiData['created_at'] != null ? DateTime.parse(apiData['created_at']) : null,
          isVerified: apiData['is_verified'] ?? false,
          isApproved: apiData['is_approved'] ?? false,
          approvalStatus: apiData['approval_status'],
          rejectionReason: apiData['rejection_reason'],
          approvalExpiresAt: apiData['approval_expires_at'] != null ? DateTime.parse(apiData['approval_expires_at']) : null,
        );

        shownUser.value = freshUser;
      }

      // Fetch feedback
      await requestController.fetchProfileFeedback(targetUserId);
    } catch (e) {
      // Error handled silently
      // Failed to fetch profile data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = shownUser.value;
      if (user == null) return const Center(child: CircularProgressIndicator());

      final isCurrentUser =
          user.userId == authController.currentUserStore.value!.userId;

      // Referral code section: improved readability and design alignment

      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(3, 80, 135, 1),
                Color.fromRGBO(0, 140, 170, 1),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                left: 0,
                child: SvgPicture.asset(
                  'assets/images/profile_ellipse_bottom.svg',
                  height: 300,
                ),
              ),
              Positioned(
                top: 0,
                left: 40,
                child: SvgPicture.asset(
                  'assets/images/profile_ellipse_stack.svg',
                  height: 250,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 10.0),
                            child: Row(
                              children: [
                                CustomBackButton(controller: authController),
                                const Spacer(),
                              // QR Code Scanner Button
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => Get.toNamed('/qrScanner'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Color.fromRGBO(3, 80, 135, 1),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (isCurrentUser)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    Get.dialog(EditDialog(
                                        user: authController.currentUserStore.value!));
                                  },
                                  child: SvgPicture.asset(
                                    "assets/icons/edit_icon.svg",
                                  ),
                                ),
                              if (!isCurrentUser)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _openChatWithUser(user),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color.fromRGBO(3, 80, 135, 1),
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        buildAvatar(user.imageUrl, context),
                        const SizedBox(height: 20),
                        // Display user's full name
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Stats row with reactive user data
                        Obx(() {
                          final currentUser = shownUser.value;
                          if (currentUser == null) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final displayHours = currentUser.hours ?? 0;
                          final displayRating = currentUser.rating ?? 0.0;

                          return buildStatsRow(displayHours, displayRating);
                        }),
                        const SizedBox(height: 15),
                        // CURRENT USER LAYOUT
                        if (isCurrentUser) ...[
                          // Referral Code Section (improved design)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Referral Code",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            user.referralCode?.toString() ?? 'null',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                              letterSpacing: 2.5,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Debug logging

                                              Get.dialog(QrCodeDialog(
                                                referralCode: user.referralCode?.toString() ?? 'null',
                                                username: user.username,
                                                userId: user.userId,
                                              ));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.qr_code,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              await Clipboard.setData(ClipboardData(text: user.referralCode?.toString() ?? 'null'));
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Referral code copied to clipboard!',
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  duration: const Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary,
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.08),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                'Copy',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          // Profile Menu Navigation (only for current user)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Column(
                              children: [
                                ProfileNavButton(
                                  icon: 'assets/icons/help_icon.svg',
                                  buttonText: 'My Helps',
                                  navDestination: Routes.myHelpsPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                // Approval Dashboard - only show for users with referral capability
                                Obx(() {
                                  if (authController.pendingApprovalsCount.value > 0) {
                                    // Show with badge if there are pending approvals
                                    return Column(
                                      children: [
                                        Stack(
                                          children: [
                                            ProfileNavButton(
                                              icon: 'assets/icons/star_icon.svg',
                                              buttonText: 'Manage Approvals',
                                              navDestination: Routes.approvalDashboardPage,
                                              haveDialog: false,
                                            ),
                                            // Notification badge
                                            Positioned(
                                              right: 20,
                                              top: 15,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${authController.pendingApprovalsCount.value}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  } else {
                                    // Check if user has ever had approvals (has referral code)
                                    final currentUser = authController.currentUserStore.value;
                                    if (currentUser?.referralCode != null && 
                                        currentUser!.referralCode!.isNotEmpty) {
                                      return Column(
                                        children: [
                                          ProfileNavButton(
                                            icon: 'assets/icons/star_icon.svg',
                                            buttonText: 'Manage Approvals',
                                            navDestination: Routes.approvalDashboardPage,
                                            haveDialog: false,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    }
                                  }
                                  return Container(); // Don't show if no referral capability
                                }),
                                ProfileNavButton(
                                  icon: 'assets/icons/feedback_icon.svg',
                                  buttonText: 'Feedbacks',
                                  navDestination: Routes.feedbackPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/contact_icon.svg',
                                  buttonText: 'Contact us',
                                  navDestination: Routes.contactUsPage,
                                  haveDialog: false,
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/logout_icon.svg',
                                  buttonText: 'Logout',
                                  navDestination: '',
                                  haveDialog: true,
                                  dialog: LogoutDialog(
                                    questionText: 'Are you sure you want to logout?',
                                    submitText: 'Logout',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ProfileNavButton(
                                  icon: 'assets/icons/delete_icon.svg',
                                  buttonText: 'Delete account',
                                  navDestination: '',
                                  haveDialog: true,
                                  dialog: DeleteDialog(),
                                ),
                                // Removed final SizedBox(height: 20) to avoid extra white space
                              ],
                            ),
                          ),
                        ] else ...[
                          // OTHER USER LAYOUT - only show feedback section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  const Text(
                                    "What others say:",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Obx(() {

                                    if (requestController.profileFeedbackList.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Text(
                                          'No feedback yet',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      );
                                    }

                                    return Column(
                                      children: requestController.profileFeedbackList.take(2).map((item) {
                                        final feedback = item['feedback'] as FeedbackModel;
                                        final username = item['username'];
                                        final title = item['title'];
                                        return GestureDetector(
                                          onTap: () => _showFeedbackDetails(feedback, username, title),
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        "Given by: $username",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color.fromRGBO(3, 80, 135, 1),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Colors.grey[400],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  feedback.review.length > 100
                                                    ? '${feedback.review.substring(0, 100)}...'
                                                    : feedback.review,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black87,
                                                    height: 1.4,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        "${feedback.rating} ⭐",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color.fromRGBO(3, 80, 135, 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        "${feedback.hours} hrs",
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color.fromRGBO(3, 80, 135, 1),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }),
                                  const SizedBox(height: 10),
                                  if (requestController.profileFeedbackList.length > 2)
                                    GestureDetector(
                                      onTap: () => _showAllFeedback(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "View all ${requestController.profileFeedbackList.length} reviews",
                                              style: const TextStyle(
                                                color: Color.fromRGBO(3, 80, 135, 1),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.arrow_forward,
                                              size: 16,
                                              color: Color.fromRGBO(3, 80, 135, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Removed final SizedBox(height: 20) to avoid extra white space
                        ],
                      ],
                    ),
                  ),
                ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget buildAvatar(String? imageUrl, BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(70),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0.0, 1.0),
                blurRadius: 10.0,
                spreadRadius: 3.0,
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          left: 5,
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            foregroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(
                    Icons.person,
                    size: 80,
                    color: Color.fromRGBO(3, 80, 135, 1),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget buildStatsRow(int? hours, double? rating, {Key? key}) {
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/cup_icon.svg',
          height: 20,
          width: 20,
        ),
        const SizedBox(width: 5),
        Text(
          "${hours ?? 0} hrs",
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        const SizedBox(width: 10),
        SvgPicture.asset(
          'assets/icons/star_icon.svg',
          height: 20,
          width: 20,
        ),
        const SizedBox(width: 5),
        Text(
          (rating ?? 0.0).toStringAsFixed(1),
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
      ],
    );
  }

  /// Show feedback details in a popup
  void _showFeedbackDetails(FeedbackModel feedback, String username, String title) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Feedback Details",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(3, 80, 135, 1),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(3, 80, 135, 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color.fromRGBO(3, 80, 135, 1),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Given by: $username",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color.fromRGBO(3, 80, 135, 1),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Review:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      feedback.review,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${feedback.rating}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const Text(
                            "Rating",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(3, 80, 135, 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color.fromRGBO(3, 80, 135, 1),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${feedback.hours}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(3, 80, 135, 1),
                            ),
                          ),
                          const Text(
                            "Hours",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline,
                          color: Color.fromRGBO(3, 80, 135, 1),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Service:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${feedback.timestamp.day}/${feedback.timestamp.month}/${feedback.timestamp.year}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show all feedback in a popup
  void _showAllFeedback() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "All Reviews (${requestController.profileFeedbackList.length})",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(3, 80, 135, 1),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: requestController.profileFeedbackList.map((item) {
                      final feedback = item['feedback'] as FeedbackModel;
                      final username = item['username'];
                      final title = item['title'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Given by: $username",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromRGBO(3, 80, 135, 1),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${feedback.timestamp.day}/${feedback.timestamp.month}/${feedback.timestamp.year}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feedback.review,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${feedback.rating} ⭐",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(3, 80, 135, 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${feedback.hours} hrs",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromRGBO(3, 80, 135, 1),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "For: $title",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Open chat with the user being viewed
  Future<void> _openChatWithUser(UserModel user) async {
    try {
      final currentUserId = authController.currentUserStore.value?.userId;
      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'Unable to get current user information',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }


      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        barrierDismissible: false,
      );

      // Create or get chat room using existing ChatController
      final chatController = Get.put(ChatController());

      final roomId = await chatController.createOrGetChatRoom(
        currentUserId,
        user.userId,
        // No serviceRequestId for direct messaging
      );


      // Close loading dialog
      Get.back();

      // Navigate to chat page

      Get.toNamed(
        Routes.chatPage,
        arguments: {
          'chatRoomId': roomId,
          'receiverId': user.userId,
          'receiverName': user.username,
          'receiverProfilePic': user.imageUrl ?? " ",
        },
      );


    } catch (e) {
      // Error handled silently

      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to open chat. Please try again.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    }
  }

}