
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/image_controller.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class EditDialog extends StatefulWidget {
  final UserModel user;

  const EditDialog({super.key, required this.user});

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  final AuthController authController = Get.find<AuthController>();
  final ImageController imageController = Get.find<ImageController>();

  @override
  void initState() {
    super.initState();
    // Initialize text controllers only once
    authController.userNameController.value.text = widget.user.username;
    authController.countryController.value.text = widget.user.country ?? '';
    authController.phoneNumberController.value.text =
        widget.user.phoneNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    String image = widget.user.imageUrl ?? '';
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 16 : 40,
        vertical: 24,
      ),
      child: authController.isloading.value
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: screenWidth < 600 ? screenWidth - 32 : 400,
                maxHeight: screenHeight * 0.8,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 20.0, 
                  horizontal: screenWidth < 400 ? 16.0 : 25.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: SvgPicture.asset(
                              'assets/icons/close_icon.svg',
                              fit: BoxFit.cover,
                              height: 20,
                              width: 20,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Obx(() {
                            return GestureDetector(
                              onTap: () {
                                imageController.pickImage();
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(70),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0.0, 1.0), //(x,y)
                                          blurRadius: 5.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 5,
                                    left: 5,
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          (imageController.pickedImage.value !=
                                                  null)
                                              ? FileImage(imageController
                                                  .pickedImage.value!)
                                              : (image.isNotEmpty
                                                  ? NetworkImage(image)
                                                  : null),
                                      child:
                                          (imageController.pickedImage.value ==
                                                      null &&
                                                  image.isEmpty)
                                              ? const Icon(Icons.person,
                                                  size: 30, color: Colors.grey)
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Click to change profile picture",
                        style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: Colors.black),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomFormField(
                        hintText: "User Name",
                        haveObscure: false,
                        textController: authController.userNameController.value,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomFormField(
                        hintText: "Location",
                        haveObscure: false,
                        textController: authController.countryController.value,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      CustomFormField(
                        hintText: "Phone Number",
                        haveObscure: false,
                        textController:
                            authController.phoneNumberController.value,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Obx(
                        () {
                          final pickedImage = imageController.pickedImage.value;

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 30.0),
                            child: CustomButton(
                              buttonText: "Edit",
                              onButtonPressed: () async {
                                if (pickedImage != null) {
                                  await imageController
                                      .uploadImage(
                                          widget.user.userId, pickedImage)
                                      .then(
                                    (value) async {
                                      await authController
                                          .editUser(widget.user, value)
                                          .then(
                                        (value) {
                                          Get.back();
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  await authController
                                      .editUser(
                                          widget.user, widget.user.imageUrl ?? "")
                                      .then(
                                    (value) {
                                      Get.back();
                                    },
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
