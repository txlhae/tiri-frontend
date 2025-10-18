
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/controllers/request_details_controller.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class EditAddRequestPage extends StatefulWidget {
  final RequestModel request;
  const EditAddRequestPage({super.key, required this.request});

  @override
  State<EditAddRequestPage> createState() => _EditAddRequestPageState();
}

class _EditAddRequestPageState extends State<EditAddRequestPage> {
  final requestController = Get.find<RequestController>();
  final detailsController = Get.find<RequestDetailsController>();

 bool _initialized = false; // Add this to prevent repeat execution

@override
void didChangeDependencies() {
  super.didChangeDependencies();

  if (_initialized) return;
  _initialized = true;

  final requestedTime = widget.request.requestedTime ?? widget.request.timestamp;

  requestController.selectedDate.value = requestedTime;
  requestController.selectedTime.value = TimeOfDay.fromDateTime(requestedTime);

  requestController.selectedDateController.value.text =
      DateFormat('dd MMM yyyy').format(requestedTime);

  requestController.selectedTimeController.value.text =
      TimeOfDay.fromDateTime(requestedTime).format(context);

  requestController.selectedDateTime.value = requestedTime;

  // Fill other form fields
  requestController.titleController.value.text = widget.request.title;
  requestController.descriptionController.value.text = widget.request.description;
  requestController.locationController.value.text = widget.request.location ?? '';
  requestController.numberOfPeopleController.value.text =
      widget.request.numberOfPeople.toString();
      requestController.hoursNeededController.value.text =
    widget.request.hoursNeeded.toString();

}

  void updateRequestClick() async {
    // Validate required fields
    if (requestController.titleController.value.text.isEmpty ||
        requestController.descriptionController.value.text.isEmpty ||
        requestController.locationController.value.text.isEmpty ||
        requestController.selectedDateController.value.text.isEmpty ||
        requestController.selectedTimeController.value.text.isEmpty) {
      Get.snackbar(
        'Error',
        'All fields including date & time must be filled!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate integer fields
    final number = requestController.validateIntField(
        controller: requestController.numberOfPeopleController.value);
    final hours = requestController.validateIntField(
        controller: requestController.hoursNeededController.value);

    // Validate volunteers needed range (1-10)
    if (number < 1 || number > 10) {
      Get.snackbar(
        'Error',
        'Number of volunteers must be between 1 and 10',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate hours range (1-24)
    if (hours < 1 || hours > 24) {
      Get.snackbar(
        'Error',
        'Estimated hours must be between 1 and 24',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate date is in the future
    if (requestController.selectedDateTime.value != null &&
        requestController.selectedDateTime.value!.isBefore(DateTime.now())) {
      Get.snackbar(
        'Error',
        'Please select a future date and time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // Create updated request model with new data
      final updatedRequest = widget.request.copyWith(
        title: requestController.titleController.value.text,
        description: requestController.descriptionController.value.text,
        location: requestController.locationController.value.text,
        requestedTime: requestController.selectedDateTime.value,
        numberOfPeople: number,
        hoursNeeded: hours,
      );

      // Call the proper update method
      final success = await requestController.updateRequest(
          widget.request.requestId, updatedRequest);

      if (success) {
        requestController.clearFields();
        detailsController.refreshData();
        Get.back();

        // Show success dialog
        _showSuccessConfirmation();
      } else {
        _showErrorConfirmation('Failed to update request');
      }
    } catch (error) {
      _showErrorConfirmation(error.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Show success confirmation dialog with animation
  void _showSuccessConfirmation() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated checkmark
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 140, 170, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Color.fromRGBO(0, 140, 170, 1),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Request updated successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // Close confirmation dialog
    });
  }

  /// Show error confirmation dialog with animation
  void _showErrorConfirmation(String errorMessage) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated error icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(176, 48, 48, 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel,
                        size: 50,
                        color: Color.fromRGBO(176, 48, 48, 1),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Update Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Auto close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // Close confirmation dialog
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        requestController.clearFields();
        return true;
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
                    bottom: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 140, 170, 1),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  height: MediaQuery.of(context).size.height < 700 ? 120 : 170,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomBackButton(
                          controller: requestController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit request',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/icons/edit_icon.svg',
                            // ignore: deprecated_member_use
                            color: Colors.white,
                          )
                        ],
                      ),
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
                              textController:
                                  requestController.titleController.value,
                            ),
                            if (requestController.titleError.value != null)
                              Text(requestController.titleError.value!,
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
                                  requestController.descriptionController.value,
                            ),
                            if (requestController.descriptionError.value !=
                                null)
                              Text(requestController.descriptionError.value!,
                                  style: const TextStyle(color: Colors.red)),
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
                          textController: requestController.selectedDateController.value,
                          iconSuffix: 'assets/icons/calender_icon.svg',
                          onTapped: () => requestController.selectDate(context),
                        )),
                  ),
                  const SizedBox(width: 15), 
                  Expanded(
                    child: Obx(() => CustomFormField(
                          hintText: 'Select Time',
                          haveObscure: false,
                          textController: requestController.selectedTimeController.value,
                          iconSuffix: 'assets/icons/clock_icon.svg',
                          onTapped: () => requestController.selectTime(context),
                        )),
                  ),
                ],
              ), 
                    const SizedBox(height: 10),
                    Obx(() => requestController.dateTimeError.value != null
                        ? Text(
                            requestController.dateTimeError.value!,
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
                                  requestController.locationController.value,
                            ),
                            if (requestController.locationError.value != null)
                              Text(requestController.locationError.value!,
                                  style: const TextStyle(color: Colors.red)),
                          ],
                        )),
                    const SizedBox(height: 20),
                    Obx(() => Column(
                      children: [
                        CustomFormField(
                          hintText: "Hours Needed",
                          haveObscure: false,
                          textController: requestController.hoursNeededController.value,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
                          onChanged: (value) => requestController.validateIntegerInput(
                            value: value,
                            fieldName: 'Hours Needed',
                          ),
                        ),
                        Obx(() => requestController.hoursNeededWarning.value.isNotEmpty
                            ? Text(
                                requestController.hoursNeededWarning.value,
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
                              hintText: "Number of People",
                              haveObscure: false,
                              textController:
                                  requestController.numberOfPeopleController.value,
                              keyboardType: TextInputType.number,                            
                               inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d'))],
                                // add this:
                                onChanged: (value) => requestController.validateIntegerInput(
                                  value: value,
                                  fieldName: 'Number of People',
                                ),

                              ),
                              Obx(() => requestController.numberOfPeopleWarning.value.isNotEmpty
                                  ? Text(
                                      requestController.numberOfPeopleWarning.value,
                                      style: const TextStyle(color: Colors.orange),
                                    )
                                  : const SizedBox()
                                  ),    
                                  ] 
                                 )         
                                ),
                    const SizedBox(
                      height: 30,
                    ),
                    Obx(
                      () {
                        return requestController.isLoading.value
                            ? const Center(
                                child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color.fromRGBO(0, 140, 170, 1),
                                ),
                              ))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      requestController.clearFields();
                                      Get.back();
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Color.fromRGBO(0, 140, 170, 1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      updateRequestClick();
                                    },
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                          color: Color.fromRGBO(3, 80, 135, 1),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                      },
                    )
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




