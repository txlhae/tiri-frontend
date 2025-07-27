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
import 'package:kind_clock/services/request_service.dart'; // NEW: Django RequestService
import 'package:kind_clock/services/firebase_storage.dart'; // DEPRECATED: Will be removed

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // =============================================================================
    // PHASE 3: DJANGO ENTERPRISE SERVICES
    // =============================================================================
    
    // Core Django services (already working from Phase 2)
    Get.put<ApiService>(ApiService());
    Get.put<AuthService>(AuthService());
    
    // NEW: Django RequestService for home screen integration
    Get.put<RequestService>(RequestService());
    
    // =============================================================================
    // DEPRECATED: FIREBASE SERVICES (TO BE REMOVED)
    // =============================================================================
    
    // TEMPORARY: Keep Firebase service for backward compatibility during migration
    // TODO: Remove this when RequestController migration is complete
    Get.put<FirebaseStorageService>(FirebaseStorageService());
    
    // =============================================================================
    // EXISTING: FLUTTER CONTROLLERS (ALL PRESERVED)
    // =============================================================================
    
    // Authentication controllers (fully working with Django)
    Get.put<AuthController>(AuthController());
    
    // UI controllers
    Get.put<SplashController>(SplashController());
    Get.put<EmailSentController>(EmailSentController());
    Get.put<HomeController>(HomeController());
    Get.put<ImageController>(ImageController());
    
    // Request controllers (being migrated to Django in this phase)
    Get.put<RequestController>(RequestController());
    Get.put<RequestDetailsController>(RequestDetailsController());
    
    // Notification controller
    Get.put<NotificationController>(NotificationController());
  }
}

// =============================================================================
// MIGRATION NOTES - PHASE 3: HOME SCREEN INTEGRATION
// =============================================================================

/*
PHASE 3 PROGRESS:
✅ RequestService created with full Django integration
✅ AppBinding updated to register RequestService
🔄 Next: Update RequestController to use RequestService instead of Firebase
🔄 Next: Test home screen with live Django data
🔄 Next: Remove FirebaseStorageService dependency

SERVICES ARCHITECTURE:
┌─────────────────────────────────────────────────────────────┐
│                    TIRI SERVICES LAYER                      │
├─────────────────────────────────────────────────────────────┤
│ ✅ ApiService (Enterprise HTTP client with JWT tokens)     │
│ ✅ AuthService (Django authentication integration)         │
│ ✅ RequestService (Django request management) - NEW!       │
│ 🗑️ FirebaseStorageService (Deprecated stub)               │
└─────────────────────────────────────────────────────────────┘

CONTROLLERS USING SERVICES:
┌─────────────────────────────────────────────────────────────┐
│ ✅ AuthController → AuthService → Django /api/auth/        │
│ 🔄 RequestController → RequestService → Django /api/       │
│ ✅ HomeController → Navigation management                   │
└─────────────────────────────────────────────────────────────┘

DJANGO API ENDPOINTS INTEGRATED:
✅ POST /api/auth/login/              - Authentication
✅ POST /api/auth/register/           - User registration  
✅ POST /api/auth/verify-referral/    - Referral validation
✅ GET  /api/profile/me/              - User profile
🆕 GET  /api/requests/                - Community requests
🆕 GET  /api/requests/?view=my_requests - User requests
🆕 GET  /api/dashboard/               - Dashboard stats
🆕 POST /api/requests/                - Create request
🆕 PUT  /api/requests/{id}/           - Update request

PHASE 3 OBJECTIVES:
1. ✅ Create RequestService with Django integration
2. ✅ Register RequestService in AppBinding  
3. 🔄 Update RequestController to use RequestService
4. 🔄 Test home screen data loading
5. 🔄 Remove Firebase dependencies
6. 🔄 Verify end-to-end home screen functionality

BACKWARD COMPATIBILITY:
- All existing UI components preserved
- Same method signatures maintained
- Gradual migration approach
- Firebase stub kept during transition
*/