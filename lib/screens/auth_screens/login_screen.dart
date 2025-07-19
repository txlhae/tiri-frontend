import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/screens/auth_screens/register_screen.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_form_field.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/referral_dialog.dart';
import 'package:kind_clock/screens/widgets/navigate_row.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Obx(
                () {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SvgPicture.asset(
                          'assets/images/auth_back_two.svg',
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: SvgPicture.asset(
                          'assets/images/auth_back_one.svg',
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/logo_white.png',
                              width: 50,
                              height: 40,
                            ),
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                            const Text(
                              'Login Now',
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: controller.loginformKey.value,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 200,
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      "Email",
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                CustomFormField(
                                  hintText: 'Enter email',
                                  haveObscure: false,
                                  textController:
                                      authController.emailController.value,
                                  validator: controller.validateEmail,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      "Password",
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                CustomFormField(
                                  hintText: 'Enter password',
                                  haveObscure: true,
                                  textController:
                                      authController.passwordController.value,
                                  validator: controller.validatePassword,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                        onPressed:
                                            controller.navigateToForgotPassword,
                                        child: const Text(
                                          "Forgot password?",
                                          style: TextStyle(
                                              color: Color.fromRGBO(
                                                  0, 140, 170, 1),
                                              fontWeight: FontWeight.bold),
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                CustomButton(
                                  buttonText: "Login",
                                  onButtonPressed: () {
                                    authController
                                        .removeSpace(authController
                                            .emailController.value)
                                        .then(
                                      (value) {
                                        authController
                                            .removeSpace(authController
                                                .passwordController.value)
                                            .then(
                                          (value) {
                                            controller.login(
                                                authController
                                                    .emailController.value.text,
                                                authController
                                                    .passwordController
                                                    .value
                                                    .text,
                                                Routes.homePage);
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                NavigateRow(
                                  // onButtonPressed: controller.navigateToRegister,
                                  onButtonPressed: () {
                                    Get.dialog(const RefferalDialog());
                                  },
                                  buttonTextData: 'Register here',
                                  textData: 'Do not have an account?',
                                ),
                                // const Text(
                                //   "Or",
                                //   style: TextStyle(
                                //       color: Colors.black, fontSize: 15),
                                // ),
                                // const SizedBox(
                                //   height: 20,
                                // ),
                                // const CustomSocialLogin(
                                //     socialMedia: "Login with google",
                                //     imagePath: 'assets/images/google_icon.png'),
                                // const SizedBox(
                                //   height: 10,
                                // ),
                                // const CustomSocialLogin(
                                //     socialMedia: "Login with facebook",
                                //     imagePath:
                                //         'assets/images/facebook_icon.png'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
