import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/email_sent_controller.dart';
import 'package:kind_clock/controllers/home_controller.dart';
import 'package:kind_clock/controllers/image_controller.dart';
import 'package:kind_clock/controllers/notification_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/controllers/request_details_controller.dart';
import 'package:kind_clock/controllers/splash_controller.dart';
import 'package:kind_clock/services/api_service.dart';
import 'package:kind_clock/services/auth_service.dart';
import 'package:kind_clock/services/firebase_storage.dart'; // TEMPORARY - Will be removed in migration

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // NEW: Django Enterprise Services
    Get.put<ApiService>(ApiService());
    Get.put<AuthService>(AuthService());
    
    // TEMPORARY: Keep Firebase service until migration complete
    // TODO: Remove this when RequestController is migrated to Django
    Get.put<FirebaseStorageService>(FirebaseStorageService());
    
    // EXISTING: Keep all controllers
    Get.put<AuthController>(AuthController());
    Get.put<SplashController>(SplashController());
    Get.put<EmailSentController>(EmailSentController());
    Get.put<HomeController>(HomeController());
    Get.put<ImageController>(ImageController());
    Get.put<RequestController>(RequestController());
    Get.put<NotificationController>(NotificationController());
    Get.put<RequestDetailsController>(RequestDetailsController());
  }
}