import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/location_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/models/category_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';
import 'package:tiri/screens/widgets/dialog_widgets/location_picker_dialog.dart';

class AddRequestPage extends StatelessWidget {
  const AddRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestController controller = Get.find<RequestController>();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: MediaQuery.of(context).size.height < 700 ? 30 : 50,
                    bottom: 20,
                  ),
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(0, 140, 170, 1),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      )),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomBackButton(
                            controller: controller,
                          ),
                          const Text(
                            'Add request',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0, 25.0, 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    Obx(() => Column(
                          children: [
                            CustomFormField(
                              hintText: "Title",
                              haveObscure: false,
                              textController: controller.titleController.value,
                            ),
                            if (controller.titleError.value != null)
                              Text(controller.titleError.value!,
                                  style: const TextStyle(color: Colors.red)),
                          ],
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    Obx(() => Column(
                          children: [
                            CustomFormField(
                              hintText: "Description",
                              isdescription: true,
                              haveObscure: false,
                              textController:
                                  controller.descriptionController.value,
                            ),
                            if (controller.descriptionError.value != null)
                              Text(controller.descriptionError.value!,
                                  style: const TextStyle(color: Colors.red)),
                          ],
                        )),
                    const SizedBox(
                      height: 20,
                    ),
                    // Category Selection
                    Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: controller.categoryError.value != null
                                      ? Colors.red
                                      : Colors.black,
                                  width: 0.5,
                                ),
                              ),
                              child: controller.isLoadingCategories.value
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 10),
                                          Text("Loading categories..."),
                                        ],
                                      ),
                                    )
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButton<CategoryModel>(
                                        value: controller.selectedCategory.value,
                                        hint: const Text(
                                          "Select Category",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        items: controller.categories.map((category) {
                                          return DropdownMenuItem<CategoryModel>(
                                            value: category,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  category.icon,
                                                  color: category.color,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    category.displayText,
                                                    style: const TextStyle(fontSize: 16),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (CategoryModel? newValue) {
                                          if (newValue != null) {
                                            controller.selectedCategory.value = newValue;
                                            controller.categoryError.value = null; // Clear error on selection
                                          }
                                        },
                                      ),
                                    ),
                            ),
                            if (controller.categoryError.value != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 15.0),
                                child: Text(
                                  controller.categoryError.value!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        )),
                    const SizedBox(
                      height: 10,
                    ),
               Row(
                children: [
                  Expanded(
                    child: Obx(() => CustomFormField(
                          hintText: 'Select Date',
                          haveObscure: false,
                          textController: controller.selectedDateController.value,
                          iconSuffix: 'assets/icons/calender_icon.svg',
                          onTapped: () => controller.selectDate(context),
                        )),
                  ),
                  const SizedBox(width: 15), 
                  Expanded(
                    child: Obx(() => CustomFormField(
                          hintText: 'Select Time',
                          haveObscure: false,
                          textController: controller.selectedTimeController.value,
                          iconSuffix: 'assets/icons/clock_icon.svg',
                          onTapped: () => controller.selectTime(context),
                        )),
                  ),
                ],
              ), 
                const SizedBox(height: 10),
                Obx(() => controller.dateTimeError.value != null
                    ? Text(
                        controller.dateTimeError.value!,
                        style: const TextStyle(color: Colors.red),
                      )
                    : const SizedBox()),

                    const SizedBox(
                      height: 20,
                    ),
                    // Location Selection
                    Obx(() {
                      // Ensure LocationController is registered
                      if (!Get.isRegistered<LocationController>()) {
                        Get.put(LocationController(), permanent: true);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location button with skip option
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: controller.isLocationOptional.value
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => LocationPickerDialog(
                                              initialLocation: controller.selectedRequestLocation.value,
                                              onLocationSelected: (location) {
                                                controller.selectedRequestLocation.value = location;
                                                controller.locationError.value = null;
                                              },
                                            ),
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: controller.isLocationOptional.value
                                          ? Colors.grey.shade300
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: controller.locationError.value != null
                                            ? Colors.red
                                            : Colors.black,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: controller.isLocationOptional.value
                                              ? Colors.grey.shade400
                                              : (controller.selectedRequestLocation.value != null
                                                  ? const Color.fromRGBO(0, 140, 170, 1)
                                                  : Colors.grey),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            controller.isLocationOptional.value
                                                ? 'Location not required'
                                                : (controller.selectedRequestLocation.value != null
                                                    ? (controller.selectedRequestLocation.value!.displayName ??
                                                       '${controller.selectedRequestLocation.value!.locality ?? controller.selectedRequestLocation.value!.subLocality ?? ''}, ${controller.selectedRequestLocation.value!.administrativeArea ?? ''}')
                                                    : 'Select Location'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: controller.isLocationOptional.value
                                                  ? Colors.grey.shade500
                                                  : (controller.selectedRequestLocation.value != null
                                                      ? Colors.black87
                                                      : Colors.grey.shade600),
                                            ),
                                          ),
                                        ),
                                        if (!controller.isLocationOptional.value)
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Skip location button
                              GestureDetector(
                                onTap: () {
                                  controller.isLocationOptional.value = !controller.isLocationOptional.value;
                                  if (controller.isLocationOptional.value) {
                                    controller.locationError.value = null;
                                    controller.selectedRequestLocation.value = null;
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: controller.isLocationOptional.value
                                        ? Colors.red.shade50
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: controller.isLocationOptional.value
                                          ? Colors.red.shade300
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Icon(
                                    controller.isLocationOptional.value
                                        ? Icons.close
                                        : Icons.location_off,
                                    color: controller.isLocationOptional.value
                                        ? Colors.red.shade700
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (controller.locationError.value != null && !controller.isLocationOptional.value)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, left: 15.0),
                              child: Text(
                                controller.locationError.value!,
                                style: const TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Obx(() => Column(
                      children: [
                        CustomFormField(
                          hintText: "Hours Needed : 1",
                          haveObscure: false,
                          textController: controller.hoursNeededController.value,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
                          onChanged: (value) => controller.validateIntegerInput(
                            value: value,
                            fieldName: 'Hours Needed',
                          ),
                        ),
                        Obx(() => controller.hoursNeededWarning.value.isNotEmpty
                            ? Text(
                                controller.hoursNeededWarning.value,
                                style: const TextStyle(color: Colors.orange),
                              )
                            : const SizedBox(),
                        ),
                      ],
                    )),
             const SizedBox(height: 20),
                    Obx(() => Column(
                      children: [
                        CustomFormField(
                          hintText: "Number of People  : 1",
                          haveObscure: false,
                          textController:
                              controller.numberOfPeopleController.value,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
                          onChanged: (value) => controller.validateIntegerInput(
                            value: value,
                            fieldName: 'Number of People',
                          ),
                        ),
                        Obx(() => controller.numberOfPeopleWarning.value.isNotEmpty
                            ? Text(
                                controller.numberOfPeopleWarning.value,
                                style: const TextStyle(color: Colors.orange),
                              )
                            : const SizedBox(),
                        ),
                      ],
                    )),
                        const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 60.0),
                      child: Obx(() => CustomButton(
                        buttonText: controller.isLoading.value ? "Creating..." : "Create Request",
                        onButtonPressed: () {
                          if (!controller.isLoading.value) {
                            controller.saveRequest();
                          }
                        },
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

