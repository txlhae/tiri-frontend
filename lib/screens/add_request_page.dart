import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/notification_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/models/category_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class AddRequestPage extends StatelessWidget {
  const AddRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final RequestController controller = Get.find<RequestController>();
    final NotificationController notificationController =
        Get.find<NotificationController>();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 140, 170, 1),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    )),
                height: 180,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomBackButton(
                          controller: controller,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add request',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                color: const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: controller.categoryError.value != null 
                                      ? Colors.red 
                                      : Colors.grey.shade300,
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
                                        hint: Text(
                                          controller.categories.isEmpty 
                                              ? "No categories available - Add one below"
                                              : "Select Category",
                                          style: TextStyle(
                                            color: controller.categories.isEmpty ? Colors.orange : Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                        items: [
                                          // Regular category items
                                          ...controller.categories.map((category) {
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
                                          }),
                                          // Add separator if categories exist
                                          if (controller.categories.isNotEmpty)
                                            const DropdownMenuItem<CategoryModel>(
                                              enabled: false,
                                              value: null,
                                              child: Divider(),
                                            ),
                                          // Add Category option
                                          const DropdownMenuItem<CategoryModel>(
                                            value: null,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Add New Category',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onChanged: (CategoryModel? newValue) {
                                          if (newValue == null) {
                                            // User selected "Add New Category"
                                            controller.showAddCategoryDialog(context);
                                          } else {
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
                            // Show helpful text when no categories are loaded
                            if (controller.categories.isEmpty && !controller.isLoadingCategories.value)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, left: 15.0),
                                child: Text(
                                  "Tap 'Add New Category' to create your first category",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                    Obx(() => Column(
                          children: [
                            CustomFormField(
                              hintText: "Location",
                              haveObscure: false,
                              textController:
                                  controller.locationController.value,
                            ),
                            if (controller.locationError.value != null)
                              Text(controller.locationError.value!,
                                  style: const TextStyle(color: Colors.red)),
                          ],
                        )),
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
                                // add this:
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
                                  : const SizedBox()
                                  ),    
                                  ] 
                                 )         
                                )      
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
                            controller.saveRequest().then((success) {
                              if (success) {
                                notificationController.loadNotification();
                              }
                            });
                          }
                        },
                      )),
                    ),
                  ],
                ),
              ),
           
          ),
        );
      
  }
}

