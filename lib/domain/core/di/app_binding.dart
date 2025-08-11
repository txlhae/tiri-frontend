import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/chat_controller.dart';
import 'package:tiri/controllers/email_sent_controller.dart';
import 'package:tiri/controllers/home_controller.dart';
import 'package:tiri/controllers/image_controller.dart';
import 'package:tiri/controllers/notification_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/controllers/request_details_controller.dart';
import 'package:tiri/controllers/splash_controller.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/auth_service.dart';
import 'package:tiri/services/request_service.dart';
import 'package:tiri/services/deep_link_service.dart';
import 'package:tiri/services/user_state_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // PHASE 3: Django Enterprise Services
    Get.put<ApiService>(ApiService());
    Get.put<AuthService>(AuthService());
    Get.put<RequestService>(RequestService());
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    Get.put<UserStateService>(UserStateService(), permanent: true);
    
    // PHASE 3: All controllers with Django integration
    Get.put<AuthController>(AuthController());
    Get.put<ChatController>(ChatController());
    Get.put<SplashController>(SplashController());
    Get.put<EmailSentController>(EmailSentController());
    Get.put<HomeController>(HomeController());
    Get.put<ImageController>(ImageController());
    Get.put<RequestController>(RequestController());
    Get.put<NotificationController>(NotificationController());
    Get.put<RequestDetailsController>(RequestDetailsController());
  }
}
