import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/screens/auth_screens/forgot_password_screen.dart';
import 'package:kind_clock/screens/auth_screens/register_screen.dart';
import 'package:kind_clock/services/firebase_auth_services.dart';
import 'package:kind_clock/services/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final FirebaseStorageService store = Get.find<FirebaseStorageService>();
  static const Color move = Color.fromRGBO(111, 168, 67, 1);
  static const Color cancel = Color.fromRGBO(176, 48, 48, 1);
  final isloading = false.obs;
  final isObscure = true.obs;
  final loginformKey = GlobalKey<FormState>().obs;
  final forgotPassworformKey = GlobalKey<FormState>().obs;
  final registerformKey = GlobalKey<FormState>().obs;

  final isCodeValid = true.obs;
  final isNameValid = true.obs;
  final isPhoneValid = true.obs;
  final isCountryValid = true.obs;
  final isEmailValid = true.obs;
  final isPasswordValid = true.obs;
  final codeError = ''.obs;
  final nameError = ''.obs;
  final phoneError = ''.obs;
  final countryError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;
  final referredUser = ''.obs;
  final referredUid = ''.obs;
  String tempName = '';
  String tempEmail = '';
  String tempPhone = '';
  String tempCountry = '';
  String tempReferralUid = '';
  String? tempImageUrl;

  final authService = Get.find<FirebaseAuthService>();

  final Rx<UserModel?> currentUserStore = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;

  final emailController = TextEditingController().obs;
  final passwordController = TextEditingController().obs;

  final userNameController = TextEditingController().obs;
  // final locationController = TextEditingController().obs;
  final countryController = TextEditingController().obs;
  final phoneNumberController = TextEditingController().obs;
  final selectedCountry = Rx<Country?>(null); 
  final phoneNumberWithCode = RxString('');


  @override
  void onInit() {
    super.onInit();
    loadUserFromStorage();
  }

  Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null) {
        final userJson = jsonDecode(userStr);
        currentUserStore.value = UserModel.fromJson(userJson);
        isLoggedIn.value = true;
      }
    } catch (e) {
      log("Error loading user data: $e");
    }
  }

  Future<void> saveUserToStorage(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      currentUserStore.value = user;
      log(currentUserStore.value!.username);
      isLoggedIn.value = true;
    } catch (e) {
      log("Error saving user data: $e");
    }
  }

  // save the data
  Future<void> fetchAndSaveUser(String userId) async {
    log("Sent Code");
    store.getUser(userId).then((value) async {
      log("The user in controller: ${value?.toJson().toString()}");
      if (value != null) {
        log('Username: ${value.username}');
        log('User fetched successfully');
        await saveUserToStorage(value);
      } else {
        log('No user found with the provided User ID in controller');
      }
    });
  }

  Future<void> clearUserData(String routeData) async {
    authService.signOut().then(
      (value) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user');
          log("Loged out as ${currentUserStore.value!.username}");
          currentUserStore.value = null;
          isLoggedIn.value = false;
          log("Now logged in is ${isLoggedIn.value}");
        } catch (e) {
          log("Error clearing user data: $e");
        }
      },
    ).then(
      (value) {
        Get.offAllNamed(routeData);
      },
    );
  }

  Future<UserModel?> fetchUser(String userId) async {
    final value = await store.getUser(userId);
    if (value != null) {
      log('User fetched successfully');
      return value;
    } else {
      log('No user found with the provided User ID in controller');
      return null;
    }
  }

  void toggleObscure() {
    isObscure.value = !isObscure.value;
    update();
  }

  Future<void> removeSpace(TextEditingController tc) async {
    tc.text = tc.text.replaceAll(" ", "");
  }

  // generate referral code
  String generateReferralCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final math.Random random = math.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // fetch and save user
  Future<UserModel?> fetchUserByReferralCode(String code) async {
    log("Sent Code");

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        log('User ID: ${userDoc.id}');

        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          UserModel user = UserModel.fromJson(userData);

          log('Username: ${user.username}');
          log('User fetched successfully');

          return user;
        } else {
          log('User data is null');
          return null;
        }
      } else {
        log('Invalid user');
        return null;
      }
    } catch (e) {
      log('Error fetching user: $e');
      return UserModel(
          email: '',
          username: 'Error fetching user',
          phoneNumber: '',
          country: '',
          userId: '',
          referralUserId: '',
          referralCode: '',
          imageUrl: '',
          createdAt: DateTime.now(),
          isVerified: true);
    }
  }

  // code validation
  String? validateCode(String? value) {
    if (value == null || value.isEmpty) {
      isCodeValid.value = false;
      codeError.value = 'Code is required';
      return passwordError.value;
    }

    if (value.length < 3) {
      isCodeValid.value = false;
      codeError.value = 'Code is incorrect';
      return passwordError.value;
    }

    isCodeValid.value = true;
    codeError.value = '';
    return null;
  }

  // name validation
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      isNameValid.value = false;
      nameError.value = 'Name is required';
      return nameError.value;
    }

    if (value.length < 3) {
      isNameValid.value = false;
      nameError.value = 'Name must be at least 3 characters';
      return nameError.value;
    }

    isNameValid.value = true;
    nameError.value = '';
    return null;
  }

  // phone validation
  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      isPhoneValid.value = false;
      phoneError.value = 'Phone is required';
      return phoneError.value;
    }

    if (int.tryParse(value) == null) {
    isPhoneValid.value = false;
    phoneError.value = 'Phone number must contain only digits';
    return phoneError.value;
    } 

    if (value.length < 10) {
      isPhoneValid.value = false;
      phoneError.value = 'Enter valid phone number';
      return phoneError.value;
    }

    isPhoneValid.value = true;
    phoneError.value = '';
    return null;
  }

  // location validation
  // String? validateLocation(String? value) {
  //   if (value == null || value.isEmpty) {
  //     isLocationValid.value = false;
  //     locationError.value = 'Location is required';
  //     return locationError.value;
  //   }

  //   if (value.length < 3) {
  //     isLocationValid.value = false;
  //     locationError.value = 'Location must have at least 3 characters';
  //     return locationError.value;
  //   }

  //   isLocationValid.value = true;
  //   locationError.value = '';
  //   return null;
  // }

  String? validateCountry(Country? country) {
  if (country == null) {
    isCountryValid.value = false;
    countryError.value = 'Please select a country';
    return countryError.value;
  }

  isCountryValid.value = true;
  countryError.value = '';
  return null;
}

  void updatePhoneWithCode() {
  if (selectedCountry.value != null) {
    final code = '+${selectedCountry.value!.phoneCode}';
    final number = phoneNumberController.value.text;
    phoneNumberWithCode.value = '$code$number';
  } else {
    phoneNumberWithCode.value = phoneNumberController.value.text;
  }
}

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      isEmailValid.value = false;
      emailError.value = 'Email is required';
      return emailError.value;
    }

    // Email format validation using regex
    bool emailValid = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);

    if (!emailValid) {
      isEmailValid.value = false;
      emailError.value = 'Enter a valid email address';
      return emailError.value;
    }

    isEmailValid.value = true;
    emailError.value = '';
    return null;
  }

  // Password validation
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      isPasswordValid.value = false;
      passwordError.value = 'Password is required';
      return passwordError.value;
    }

    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      return 'Enter a valid password';
    }
    isPasswordValid.value = true;
    passwordError.value = '';
    return null;
  }

// Login validation
  bool validateLoginForm() {
    final isValid = loginformKey.value.currentState?.validate() ?? false;
    return isValid;
  }

  void login(String email, String password, String routeName) async {
    if (!validateLoginForm()) {
      log("Error occurred while logging in");
      Get.snackbar(
        "Error",
        "Please fix the errors in the form",
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.black,
        colorText: cancel,
      );
      return;
    }

    try {
      isloading.value = true;
      User? userDet =
          await authService.signInWithEmailAndPassword(email, password);

      await store.getUser(userDet!.uid).then((value) async {
        if (!value!.isVerified) {
          isloading.value = false;
          Get.offAllNamed(Routes.verifyPendingPage, arguments: {
            'referredUser': value.referralUserId,
          });
          return;
        } else {
          // Save user and navigate
          log("User is: ${userDet.uid}");
          await fetchAndSaveUser(userDet.uid);
          Get.offAllNamed(routeName);

          // Show success message
          Get.snackbar(
            "Success!",
            "Logged in successfully",
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.white,
            colorText: move,
          );
        }
      });
    } catch (e) {
      isloading.value = false;
      Get.snackbar(
        'Error',
        'Login failed, something went wrong',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    emailController.value.text = '';
    passwordController.value.text = '';
    isloading.value = false;
  }
  //delete 
 Future<void> deleteUserAccount({required String email, required String password}) async {
  try {
    final userId = currentUserStore.value?.userId;

    if (userId == null) {
      Get.snackbar("Error", "User ID not found.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user?.reauthenticateWithCredential(credential);
    await store.deleteUser(userId);
    print("Deleted from Firestore.");
    await user?.delete();
    print("Deleted from Firebase Auth.");
    Get.offAllNamed(Routes.loginPage);
    Get.snackbar("Success", "Your account has been deleted",
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.white,
              colorText: cancel);
  } catch (e) {
    log("Error: $e");
    if (e.toString().contains('requires-recent-login')) {
      Get.snackbar("Session Expired", "Please log in again to delete your account.");
    } else {
      Get.snackbar("Error", "Failed to delete account: $e");
    }
  }
}




// logout
  Future<void> logout() async {
    await authService.signOut();
    await clearUserData(Routes.loginPage);
  }

// Register validation
  bool validateRegisterForm() {
    final isValid = registerformKey.value.currentState?.validate() ?? false;
    authController.validateCountry(authController.selectedCountry.value);

  return isValid && authController.isCountryValid.value;
  }

  void register(
      String name,
      String phoneNumber,
      String country,
      String email,
      String referralUid,
      String password,
      String routeName,
      String? imageURL) async {
    if (validateRegisterForm()) {
      isloading.value = true;
      try {
        updatePhoneWithCode();
        tempName = name;
        tempEmail = email;
        tempPhone = phoneNumber;
        tempCountry = country;
        tempReferralUid = referralUid;
        tempImageUrl = imageURL;
        User? userDet =
            await authService.createUserWithEmailAndPassword(email, password);

        if (userDet == null) {
          isloading.value = false;
          Get.snackbar("Error", "User creation failed.Please try again",
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.black,
              colorText: cancel);
          return;
        }
        await userDet.sendEmailVerification();
        isloading.value = false;
        Get.to(() =>const ForgotPasswordScreen(isFromRegister: true));

        Get.snackbar("Verify Email", "Please verify your email before proceeding",
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.white,
          colorText: move);
          } 
            on FirebaseAuthException catch (e) {
        isloading.value = false;

        if (e.code == 'email-already-in-use') {
          Get.snackbar("Email Already Registered",
              "This email is already in use. Please use a different email.",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.black,
              colorText: cancel);
        } else {
          Get.snackbar("Registration Error",
              e.message ?? "Something went wrong. Try again.",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.black,
              colorText: cancel);
        }

      }
           catch (e) {
      isloading.value = false;
      log("Registration Error: $e");
      Get.snackbar("Error", "Registration failed. Try again",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black,
        colorText: cancel);}
    } 
  }
// after email verification 
  void completeUserRegistration() async {
  User? userDet = FirebaseAuth.instance.currentUser;

  if (userDet == null || !userDet.emailVerified) return;
  String name = tempName;
  String email = tempEmail;
  String phone = tempPhone;
  String country = tempCountry;
  String referralUid = tempReferralUid;
  String? imageURL = tempImageUrl;

  String referralCode = generateReferralCode();

  final user = UserModel(
    email: email,
    username: name,
    phoneNumber: phoneNumberWithCode.value,
    country: country,
    userId: userDet.uid,
    referralUserId: referralUid,
    referralCode: referralCode,
    imageUrl: imageURL,
    createdAt: DateTime.now(),
    isVerified: false,
  );

  final notify = NotificationModel(
    notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
    status: RequestStatus.pending.toString().split(".").last,
    body: '$name needs to be verified',
    isUserWaiting: true,
    userId: userDet.uid,
    timestamp: DateTime.now(),
  );

  try {
    await store.createUserCollection(user);
    await store.saveNotification(notify);

    Get.offNamed(Routes.verifyPendingPage,
      arguments: {'referredUser': referralUid});

    Get.snackbar("Success!", "Account created",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: move);
  } catch (e) {
    log("Firestore save error: $e");
    Get.snackbar("Error", "Failed to save user data",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black,
      colorText: cancel);
  }
}


// forgot password validation
  bool validateForgotPasswordForm() {
    final isValid =
        forgotPassworformKey.value.currentState?.validate() ?? false;
    return isValid;
  }

  void forgotPassword(String email, String routeName) {
    if (validateForgotPasswordForm()) {
      authService.sendPasswordResetEmail(email).then(
        (value) {
          Get.offAllNamed(routeName);
        },
      );
    } else {
      log("Error occured while sending");
      Get.snackbar(
        "Error",
        "Please fix the errors in the form",
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.black,
        colorText: cancel,
      );
    }
  }

  void navigateToLogin() {
    Get.offNamed(Routes.loginPage);
  }

  void navigateToForgotPassword() {
    Get.toNamed(Routes.forgotPasswordPage);
  }

  void navigateToRegister() {
    Get.offNamed(Routes.registerPage);
  }

  Future<void> editUser(UserModel user, String? imageUrl) async {
    log("Updated values:");
    log("Name: ${userNameController.value.text}");
    log("Location: ${countryController.value.text}");
    log("Phone Number: ${phoneNumberController.value.text}");
    log("Outside $imageUrl");
    isloading.value = true;
    UserModel userMod = UserModel(
      username: userNameController.value.text,
      country: countryController.value.text,
      phoneNumber: phoneNumberController.value.text,
      email: user.email,
      userId: user.userId,
      referralUserId: user.referralUserId,
      imageUrl: imageUrl ?? user.imageUrl,
      referralCode: user.referralCode,
      createdAt: DateTime.now(),
      isVerified: user.isVerified,
      hours: user.hours,
      rating: user.rating,
    );
    store.updateUser(userMod.toJson(), user.userId).then(
      (value) {
        fetchAndSaveUser(user.userId);
        isloading.value = false;
      },
    );
    isloading.value = false;
  }

  Future<void> verifyUser(UserModel verifyUser) async {
    isloading.value = true;
    UserModel user = UserModel(
        username: verifyUser.username,
        country: verifyUser.country,
        phoneNumber: verifyUser.phoneNumber,
        email: verifyUser.email,
        userId: verifyUser.userId,
        referralUserId: verifyUser.referralUserId,
        imageUrl: verifyUser.imageUrl,
        referralCode: verifyUser.referralCode,
        createdAt: verifyUser.createdAt,
        isVerified: true,
        hours: verifyUser.hours,
        rating: verifyUser.rating);
    store.updateUser(user.toJson(), verifyUser.userId);
    isloading.value = false;
  }
}
