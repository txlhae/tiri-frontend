import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_cancel.dart';

class DeleteDialog extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  // Text controllers for email and password input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  DeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Account?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to delete your account? Once you confirm, your data will be gone.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            CustomCancel(
              buttonText: 'Cancel',
              onButtonPressed: () => Get.back(),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(30),
              ),
              child: CustomButton(
                buttonText: 'Delete Account',
                onButtonPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text;

                  if (email.isEmpty || password.isEmpty) {
                    Get.snackbar("Error", "Email and password are required");
                    return;
                  }

                  await authController.deleteUserAccount(
                    email: email,
                    password: password,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
