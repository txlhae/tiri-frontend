import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/domain/core/di/app_binding.dart';
import 'package:tiri/infrastructure/navigation.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize deep linking service early
  await Get.putAsync(() async => DeepLinkService());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      defaultTransition: Transition.noTransition,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      title: 'Kind Clock',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'LexendDeca',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
        ),
      ),
      getPages: Navigation.routes,
      initialRoute: Routes.splashPage,
    );
  }
}