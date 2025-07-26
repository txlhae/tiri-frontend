import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/domain/core/di/app_binding.dart';
import 'package:kind_clock/infrastructure/navigation.dart';
import 'package:kind_clock/infrastructure/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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