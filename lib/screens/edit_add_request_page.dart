
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

  void updateRequestClick() {
    if (requestController.titleController.value.text.isEmpty ||
        requestController.descriptionController.value.text.isEmpty ||
        requestController.locationController.value.text.isEmpty ||
        requestController.selectedDateController.value.text.isEmpty ||
        requestController.selectedTimeController.value.text.isEmpty
 
        ) {
      Get.snackbar(
        'Error',
        'All fields including date & time must be filled!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    final number = requestController.validateIntField(controller: requestController.numberOfPeopleController.value);

final hours = requestController.validateIntField(controller: requestController.hoursNeededController.value);


    // Recalculate status using the already validated `number`
    final updatedStatus = requestController.determineRequestStatus(widget.request.copyWith(numberOfPeople: number));

    final request = RequestModel(
      requestId: widget.request.requestId,
      userId: widget.request.userId,
      title: requestController.titleController.value.text,
      description: requestController.descriptionController.value.text,
      location: requestController.locationController.value.text,
      timestamp: DateTime.now(),
      requestedTime: requestController.selectedDateTime.value ??
          widget.request.requestedTime,
      status: RequestStatus.values.firstWhere((e) => e.name == updatedStatus, orElse: () => RequestStatus.pending),
      acceptedUser: widget.request.acceptedUser ?? [],
      numberOfPeople: number,
      hoursNeeded: hours,
    );


    requestController
        .controllerUpdateRequest(widget.request.requestId, request)
        .then((_) {
      requestController.clearFields();
      detailsController.refreshData();
      Get.back();
      Get.snackbar(
        'Success',
        'Request updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }).catchError((error) {
      Get.snackbar(
        'Error',
        'Failed to update request',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 50, bottom: 10),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 140, 170, 1),
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  height: 170,
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




