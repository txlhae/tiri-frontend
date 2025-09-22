import 'package:get/get.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/add_feedback_page.dart';
import 'package:tiri/screens/add_request_page.dart';
import 'package:tiri/screens/auth_screens/email_sent_splash.dart';
import 'package:tiri/screens/auth_screens/forgot_password_screen.dart';
import 'package:tiri/screens/auth_screens/onboarding_screen.dart';
import 'package:tiri/screens/auth_screens/verify_pending_screen.dart';
import 'package:tiri/screens/auth_screens/email_verification_screen.dart';
import 'package:tiri/screens/chat_page.dart';
import 'package:tiri/screens/contact_us.dart';
import 'package:tiri/screens/edit_add_request_page.dart';
import 'package:tiri/screens/feedback.dart';
import 'package:tiri/screens/home_screen.dart';
import 'package:tiri/screens/auth_screens/login_screen.dart';
import 'package:tiri/screens/privacy_and_security.dart';
import 'package:tiri/screens/profile_screen.dart';
import 'package:tiri/screens/auth_screens/register_screen.dart';
import 'package:tiri/screens/request_details.dart';
import 'package:tiri/screens/auth_screens/splash_screen.dart';
import 'package:tiri/screens/my_helps.dart';
import 'package:tiri/screens/auth_screens/pending_approval_screen.dart';
import 'package:tiri/screens/auth_screens/rejection_screen.dart';
import 'package:tiri/screens/auth_screens/expired_screen.dart';
import 'package:tiri/screens/my_applications_screen.dart';
import 'package:tiri/screens/approval_dashboard_screen.dart';
import 'package:tiri/screens/qr_scanner_screen.dart';

class Navigation {
  static List<GetPage> routes = [
    GetPage(
      name: Routes.splashPage,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: Routes.onboardingPage,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: Routes.verifyPendingPage,
      page: () =>
          VerifyPendingScreen(referredUser: Get.arguments?['referredUser']),
    ),
    GetPage(
      name: Routes.emailVerificationPage,
      page: () => const EmailVerificationScreen(),
    ),
    GetPage(
      name: Routes.loginPage,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: Routes.forgotPasswordPage,
      page: () => const ForgotPasswordScreen(isFromRegister: false),
    ),
    GetPage(
      name: Routes.emailSentSplashPage,
      page: () => const EmailSentSplash(),
    ),
    GetPage(
      name: Routes.registerPage,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: Routes.homePage,
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: Routes.addRequestPage,
      page: () => const AddRequestPage(),
    ),
    GetPage(
      name: Routes.requestDetailsPage,
      page: () => const RequestDetails(),
    ),
    GetPage(
      name: Routes.editAddRequestPage,
      page: () => EditAddRequestPage(request: Get.arguments?['request']),
    ),
    GetPage(
      name: Routes.profilePage,
      page: () => ProfileScreen(),
    ),
    GetPage(
      name: Routes.myHelpsPage,
      page: () => const MyHelps(),
    ),
    GetPage(
      name: Routes.privacyandsecurityPage,
      page: () => const PrivacyAndSecurity(),
    ),
    GetPage(
      name: Routes.contactUsPage,
      page: () => const ContactUs(),
    ),
    GetPage(
      name: Routes.feedbackPage,
      page: () => Feedback(),
    ),
    GetPage(
  name: Routes.addfeedbackPage,
  page: () => AddFeedbackPage(
    request: Get.arguments?['request'] ?? '',
  ),
),
    GetPage(
  name: Routes.chatPage,
  page: () {
    final args = Get.arguments ?? {};
    return ChatPage(
      chatRoomId: args['chatRoomId'] ,
      receiverId: args['receiverId'] ,
      receiverName: args['receiverName'] ,
      receiverProfilePic: args['receiverProfilePic'] ,
    );
  },
),
    GetPage(
      name: Routes.myApplicationsPage,
      page: () => const MyApplicationsScreen(),
    ),

    // =============================================================================
    // APPROVAL SYSTEM ROUTES
    // =============================================================================

    GetPage(
      name: Routes.pendingApprovalPage,
      page: () => const PendingApprovalScreen(),
    ),
    GetPage(
      name: Routes.rejectionScreen,
      page: () => const RejectionScreen(),
    ),
    GetPage(
      name: Routes.expiredScreen,
      page: () => const ExpiredScreen(),
    ),
    GetPage(
      name: Routes.approvalDashboardPage,
      page: () => const ApprovalDashboardScreen(),
    ),
    GetPage(
      name: Routes.qrScannerPage,
      page: () => const QrScannerScreen(),
    ),

  ];
}
