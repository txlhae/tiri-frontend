import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final bool isFromRegister;
  const ForgotPasswordScreen({super.key,this.isFromRegister = false});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController emailController;
  late final AuthController controller;
  // TODO: Replace with your backend auth service
  // late final auth = YourAuthService.instance;
  late final bool isFromRegister;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    controller = Get.find<AuthController>();
     isFromRegister = widget.isFromRegister;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

   Future<void> checkEmailVerified() async {
    try {
      log('🔍 ForgotPasswordScreen: Checking email verification status...');
      
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );
      
      // Use the new verification check method
      final authController = Get.find<AuthController>();
      await authController.checkVerificationStatus();
      
      // Close loading dialog
      Get.back();
      
      // The AuthController handles navigation and messages
      // No need to do anything else here
      
    } catch (e) {
      Get.back(); // Close loading dialog if still open
      log('❌ ForgotPasswordScreen: Error checking verification: $e');
      
      Get.snackbar(
        "Verification Check Failed", 
        "Unable to check verification status. Please try again.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          _buildHeader(), // Keep your existing header method

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: isFromRegister
                          ? _buildVerifyEmailContent()
                          : _buildForgotPasswordForm(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Container(
                    decoration: const BoxDecoration(
                      color:  Color.fromRGBO(0, 140, 170, 1),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                  height: 180,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 30.0),
                    child: 
                        Column(
                          children: [
                            Align(
                            alignment: Alignment.topLeft,
                            child: CustomBackButton(controller: controller),),
                             Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                     const SizedBox(width: 20,),
                    Text(isFromRegister ?
                        'Verify your email':'Forgot Password ?',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                 ],
               ),
             ),
            );
           } 

  Widget _buildForgotPasswordForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: controller.forgotPassworformKey.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Center(
              child: Column(
                children: [
                  Container( decoration:  BoxDecoration(
                      color: const Color.fromRGBO(22, 178, 217, .2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: SvgPicture.asset("assets/icons/key_icon.svg",height: 50,width: 50,),
                    ),
                 const SizedBox(height: 10,),
                 const Text(
                    "No worries, we’ll send you the\nreset instructions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Email", style: TextStyle(color: Colors.black)),
            const SizedBox(height: 5),
            CustomFormField(
              hintText: 'Enter email',
              haveObscure: false,
              textController: emailController,
              validator: controller.validateEmail,
            ),
            const SizedBox(height: 20),
            CustomButton(
              buttonText: "Reset password",
              onButtonPressed: () {
                controller.forgotPassword(
                    emailController.text, Routes.emailSentSplashPage);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyEmailContent() {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                "An email has been sent to verify your account.",
                style: TextStyle(fontSize: 15, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                buttonText: "I have verified",
                onButtonPressed: () {
                  checkEmailVerified();
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}
