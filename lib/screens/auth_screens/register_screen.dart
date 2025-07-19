import 'package:country_picker/country_picker.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/image_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_form_field.dart';
import 'package:kind_clock/screens/widgets/navigate_row.dart';
import 'package:kind_clock/services/firebase_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

final AuthController authController = Get.find<AuthController>();
final ImageController imageController = Get.find<ImageController>();
final FirebaseStorageService store = Get.find<FirebaseStorageService>();

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(
        () {
          return SingleChildScrollView(
            child: Column(
              children: [
                DeferredPointerHandler(
                  child: Stack(
                    clipBehavior: Clip.none,
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
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
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
                              'Register Now',
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 20),
                            Form(
                              key: authController.registerformKey.value,
                              child: Column(
                                children: [
                                  if (authController
                                      .referredUser.value.isNotEmpty)
                                    Column(
                                      children: [
                                        const SizedBox(height: 30),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  color: const Color.fromRGBO(
                                                      3, 80, 135, 1)),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Text(
                                                  "Referred by: ${authController.referredUser.value}",
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    )
                                  else
                                    const Row(
                                      children: [
                                        Text("No User found with this code"),
                                      ],
                                    ),
                                  const SizedBox(height: 20),
                                  CustomFormField(
                                    hintText: 'Enter name',
                                    haveObscure: false,
                                    textController:
                                        authController.userNameController.value,
                                        validator: authController.validateName,
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                  onTap: () {
                                    showCountryPicker(
                                    context: context,
                                    showPhoneCode: false,
                                    showSearch: true,
                                    countryListTheme: const CountryListThemeData(
                                        flagSize: 25,
                                        backgroundColor: Colors.white,
                                        textStyle: TextStyle(fontSize: 16, color: Colors.black),
                                        bottomSheetHeight: 500,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          topRight: Radius.circular(20),
                                        ),
                                      inputDecoration: InputDecoration(
                                        labelText: 'Search',
                                        hintText: 'Type to search',
                                        prefixIcon: Icon(Icons.search),
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    onSelect: (Country country) {
                                      authController.selectedCountry.value = country;
                                      authController.countryController.value.text = country.name;
                                      authController.updatePhoneWithCode();
                                    },
                                  );
                                 },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: authController.countryController.value,
                                      decoration: InputDecoration(
                                        labelText: 'Country',
                                        hintText: 'Select your country',
                                        errorText: authController.isCountryValid.value
                                            ? null
                                            : authController.countryError.value,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                                CustomFormField(
                                hintText: 'Phone Number',
                                haveObscure: false,
                                textController: authController.phoneNumberController.value,
                                validator: authController.validatePhone,
                                isphone: true,
                                selectedCountry: authController.selectedCountry.value,
                              ),
                              const SizedBox(height: 20),
                                  CustomFormField(
                                    hintText: 'Enter email',
                                    haveObscure: false,
                                    textController:
                                        authController.emailController.value,
                                    validator: authController.validateEmail,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Password must be at least 8 characters long,\n'
                                    'include an uppercase letter, a lowercase letter,\n'
                                    'a number, and a special character (!@#\$&*~)',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(height: 10),
                                  CustomFormField(
                                    hintText: 'Enter password',
                                    haveObscure: true,
                                    textController:
                                        authController.passwordController.value,
                                    validator: authController.validatePassword,
                                  ),
                                  const SizedBox(height: 20),
                                  DeferPointer(
                                    child: CustomButton(
                                      buttonText: "Register",
                                      onButtonPressed: () async {
                                        authController.register(
                                          authController
                                              .userNameController.value.text,
                                          authController
                                              .phoneNumberController.value.text,
                                          authController
                                              .countryController.value.text,
                                          authController
                                              .emailController.value.text,
                                          authController.referredUid.value,
                                          authController
                                              .passwordController.value.text,
                                          Routes.homePage,
                                          null,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  NavigateRow(
                                    textData: "Already have an account?",
                                    buttonTextData: "Login Here",
                                    onButtonPressed:
                                        authController.navigateToLogin,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
