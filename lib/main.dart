import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tiri/domain/core/di/app_binding.dart';
import 'package:tiri/infrastructure/navigation.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/deep_link_service.dart';
import 'package:tiri/services/firebase_notification_service.dart';
import 'package:tiri/services/app_startup_handler.dart';
import 'firebase_options.dart';

void main() async {
  print('🔥 FCM DEBUG: Starting main() function...');
  WidgetsFlutterBinding.ensureInitialized();
  print('🔥 FCM DEBUG: WidgetsFlutterBinding initialized');
  
  // Initialize Firebase with proper error handling
  try {
    print('🔥 FCM DEBUG: Starting Firebase initialization...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ FCM DEBUG: Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('✅ FCM DEBUG: Firebase already initialized (duplicate app)');
    } else {
      print('❌ FCM DEBUG: Firebase initialization error: $e');
    }
    // Continue app initialization even if Firebase fails
  }
  
  // Initialize services with fixed circular dependency issue
  try {
    print('🔧 FCM DEBUG: Starting service initialization...');
    
    print('📱 FCM DEBUG: Initializing DeepLinkService...');
    await Get.putAsync(() async => DeepLinkService());
    print('✅ FCM DEBUG: DeepLinkService initialized');
    
    print('🔥 FCM DEBUG: Initializing FirebaseNotificationService...');
    final firebaseService = FirebaseNotificationService.instance;
    await firebaseService.initialize();
    Get.put(firebaseService, permanent: true);
    print('✅ FCM DEBUG: FirebaseNotificationService initialized and registered with GetX');
    
    print('🎉 FCM DEBUG: All services initialized successfully');
  } catch (e) {
    print('❌ FCM DEBUG: Service initialization error: $e');
    print('📝 FCM DEBUG: Stack trace: ${StackTrace.current}');
    // Continue app initialization even if services fail
  }
  
  print('🔥 FCM DEBUG: About to run app...');
  runApp(const MyApp());
  print('🔥 FCM DEBUG: App started successfully');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _initialRoute = Routes.splashPage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    try {
      print('🚀 MyApp: Determining initial route...');

      // Wait a bit for services to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      // Determine the correct initial route
      final initialRoute = await AppStartupHandler.determineInitialRoute();

      print('✅ MyApp: Initial route determined: $initialRoute');

      if (mounted) {
        setState(() {
          _initialRoute = initialRoute;
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ MyApp: Error determining initial route: $e');

      // Fallback to splash page on error
      if (mounted) {
        setState(() {
          _initialRoute = Routes.splashPage;
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      defaultTransition: Transition.noTransition,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      title: 'TIRI',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'LexendDeca',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      getPages: Navigation.routes,
      initialRoute: _isInitialized ? _initialRoute : Routes.splashPage,
      home: _isInitialized ? null : const _LoadingScreen(),
    );
  }
}

/// Simple loading screen shown while determining initial route
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.fromRGBO(0, 140, 170, 1),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading TIRI...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'LexendDeca',
              ),
            ),
          ],
        ),
      ),
    );
  }
}