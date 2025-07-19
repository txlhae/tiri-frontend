import 'package:get/get.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/screens/add_feedback_page.dart';
import 'package:kind_clock/screens/add_request_page.dart';
import 'package:kind_clock/screens/auth_screens/email_sent_splash.dart';
import 'package:kind_clock/screens/auth_screens/forgot_password_screen.dart';
import 'package:kind_clock/screens/auth_screens/onboarding_screen.dart';
import 'package:kind_clock/screens/auth_screens/verify_pending_screen.dart';
import 'package:kind_clock/screens/chat_page.dart';
import 'package:kind_clock/screens/contact_us.dart';
import 'package:kind_clock/screens/edit_add_request_page.dart';
import 'package:kind_clock/screens/feedback.dart';
import 'package:kind_clock/screens/home_screen.dart';
import 'package:kind_clock/screens/auth_screens/login_screen.dart';
import 'package:kind_clock/screens/notifications_page.dart';
import 'package:kind_clock/screens/privacy_and_security.dart';
import 'package:kind_clock/screens/profile_screen.dart';
import 'package:kind_clock/screens/auth_screens/register_screen.dart';
import 'package:kind_clock/screens/request_details.dart';
import 'package:kind_clock/screens/auth_screens/splash_screen.dart';
import 'package:kind_clock/screens/my_helps.dart';

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
          VerifyPendingScreen(referredUser: Get.arguments['referredUser']),
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
      page: () => RequestDetails(request: Get.arguments['request']),
    ),
    GetPage(
      name: Routes.editAddRequestPage,
      page: () => EditAddRequestPage(request: Get.arguments['request']),
    ),
    GetPage(
      name: Routes.profilePage,
      page: () => const ProfileScreen(),
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
      name: Routes.notificationsPage,
      page: () => const NotificationsPage(),
    ),
    GetPage(
      name: Routes.feedbackPage,
      page: () => Feedback(),
    ),
    GetPage(
  name: Routes.addfeedbackPage,
  page: () => AddFeedbackPage(
    request: Get.arguments['request'] ?? '',
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

  ];
}
