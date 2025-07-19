import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/notification_controller.dart';
import 'package:kind_clock/models/feedback_model.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/services/firebase_storage.dart';

enum FilterOption { recentPosts, urgentRequired, location }

class RequestController extends GetxController {
  final FirebaseStorageService store = Get.find<FirebaseStorageService>();
  final AuthController authController = Get.find<AuthController>();
  // final HomeController homeController = Get.find<HomeController>();
  final isHelper = false.obs;
  final isViewer = false.obs;
  final isLoading = false.obs;
  final titleController = TextEditingController().obs;
  final descriptionController = TextEditingController().obs;
  final locationController = TextEditingController().obs;
  RxList<RequestModel> requestList = <RequestModel>[].obs;
  RxList<RequestModel> myRequestList = <RequestModel>[].obs;
  final Map<String, Rx<UserModel?>> userCache = {};
  
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();

  final selectedDateController = TextEditingController().obs;
  final selectedTimeController = TextEditingController().obs;

  final Rxn<DateTime> selectedDateTime = Rxn<DateTime>();
  final dateTimeError = RxnString(); 

  final numberOfPeopleController = TextEditingController().obs;
  final hoursNeededController = TextEditingController().obs;

  var titleError = RxnString();
  var descriptionError = RxnString();
  var locationError = RxnString();
  var numberOfPeopleWarning = ''.obs;
  final hoursNeededWarning = ''.obs;
  final isFeedbackReady = false.obs;



  // New fields for feedback
  var reviewControllers = <TextEditingController>[].obs;
  var hourControllers = <TextEditingController>[].obs;
  var selectedRatings = <RxDouble>[].obs;
  var reviewErrors = <RxnString>[].obs;
  var hourErrors = <RxnString>[].obs;

  final RxBool isFeedbackLoading = true.obs;
  //for search
  final RxList<RequestModel> communityRequests = <RequestModel>[].obs;
  final RxList<RequestModel> myPostRequests = <RequestModel>[].obs;

  final RxBool hasSearchedCommunity = false.obs;
  final RxBool hasSearchedMyPosts = false.obs;

  @override
  void onInit() async {
    await loadRequests();
    log("Requests length: ${requestList.length.toString()}");
    super.onInit();
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, hh:mm a').format(dateTime);
  }
Future<void> selectDate(BuildContext context) async {
  try {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );

    if (pickedDate != null) {
      selectedDate.value = pickedDate;
      selectedDateController.value.text =
          DateFormat('dd MMM yyyy').format(pickedDate);

      _updateCombinedDateTime();
    }
  } catch (e) {
    log("Error selecting date: $e");
  }
}

Future<void> selectTime(BuildContext context) async {
  try {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      selectedTime.value = pickedTime;
      selectedTimeController.value.text = pickedTime.format(context);

      _updateCombinedDateTime();
    }
  } catch (e) {
    log("Error selecting time: $e");
  }
}

void _updateCombinedDateTime() {
  if (selectedDate.value != null && selectedTime.value != null) {
    selectedDateTime.value = DateTime(
      selectedDate.value!.year,
      selectedDate.value!.month,
      selectedDate.value!.day,
      selectedTime.value!.hour,
      selectedTime.value!.minute,
    ); 
    log("Combined selected DateTime: ${formatDateTime(selectedDateTime.value!)}");

    dateTimeError.value = null;
  }
}



  bool validateFields() {
    titleError.value =
        titleController.value.text.isEmpty ? "Title is required" : null;
    descriptionError.value = descriptionController.value.text.isEmpty
        ? "Description is required"
        : null;
    locationError.value =
        locationController.value.text.isEmpty ? "Location is required" : null;
    dateTimeError.value =
        selectedDateTime.value == null ? "Please select a date and time" : null;
   

    return titleError.value == null &&
        descriptionError.value == null &&
        locationError.value == null &&
        dateTimeError.value == null;
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    try {
      await store.fetchRequests().then(
        (requests) {
          updateRequestStatuses(requests).then(
            (value) {
              myRequestList.assignAll(requests);
            },
          );

          // Filter the requests based on the selected filter
          final filteredRequests = getFilteredRequests(requests);
          requestList.assignAll(filteredRequests);
          log("Requests fetched successfully");
          log("Requests after filtering: ${filteredRequests.length}");
        },
      );
    } catch (e) {
      log("Error fetching requests: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Function to update Firestore based on request status
 Future<void> updateRequestStatuses(List<RequestModel> requests) async {
    for (var request in requests) {
      log("Checking request: ${request.requestId} with status: ${request.status} and time: ${request.requestedTime}");

      int acceptedCount = request.acceptedUser.length;
      int requiredCount = request.numberOfPeople;
      bool timeUp = request.requestedTime.isBefore(DateTime.now());

      if ((request.status == RequestStatus.pending ||
              request.status == RequestStatus.incomplete ||
              request.status == RequestStatus.inprogress) &&
          timeUp) {
        try {
          if (acceptedCount == 0) {
            log("No accepted users and time up, updating to expired: ${request.requestId}");
            await store.updateRequest(
                request.requestId, {"status": "expired"}).then((_) async {
              NotificationModel notification = NotificationModel(
                body: request.title,
                timestamp: DateTime.now(),
                isUserWaiting: false,
                userId: request.userId,
                status: RequestStatus.expired.toString().split(".").last,
                notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
              );
              await store.updateNotification(notification);
            });
            log("Updated request ${request.requestId} to expired");
          } else if (acceptedCount >= 1 && acceptedCount < requiredCount) {
            log("Accepted users less than required and time up, updating to incomplete: ${request.requestId}");
            await store.updateRequest(
                request.requestId, {"status": "incomplete"}).then((_) async {
              NotificationModel notification = NotificationModel(
                body: request.title,
                timestamp: DateTime.now(),
                isUserWaiting: false,
                userId: request.userId,
                status: RequestStatus.incomplete.toString().split(".").last,
                notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
              );
              await store.updateNotification(notification);
            });
            log("Updated request ${request.requestId} to incomplete");
          } else {
            log("Request ${request.requestId} does not meet criteria for status update");
          }
        } catch (e) {
          log("Error updating request ${request.requestId}: $e");
        }
      } else {
        log("This request is STILL VALID, not updating: ${request.requestId}");
      }
    }
  }


//feedback and statuscomplete
  Future<void> markRequestAsComplete(RequestModel request) async {
    try {
      await store.updateRequest(
          request.requestId, {"status": RequestStatus.complete.name});
      NotificationModel notification = NotificationModel(
        body: request.title,
        timestamp: DateTime.now(),
        isUserWaiting: false,
        userId: request.userId,
        status: RequestStatus.complete.name,
        notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await store.updateNotification(notification);
      log("Manually updated request ${request.requestId} to 'complete'");
    } catch (e) {
      log("Error marking request as complete: $e");
    }
  }

  Future<void> saveRequest() async {
    if (!validateFields()) return;

    log("Title: ${titleController.value.text}");
    log("Description: ${descriptionController.value.text}");
    log("Location: ${locationController.value.text}");
    log("Selected DateTime: ${selectedDateTime.value}");
    log("Number of people: ${numberOfPeopleController.value.text}");

    isLoading.value = true;
    
     final number = validateIntField(
    controller: numberOfPeopleController,
    warning: numberOfPeopleWarning,
    label: 'Number of People',
    );
    if (number == null) return;
 //helping hour
    final hours = validateIntField(
      controller: hoursNeededController,
      warning: hoursNeededWarning,
      label: 'Hours Needed',
    );
    if (hours == null) return;


    try {
      final user = authController.currentUserStore.value!;
      final request = RequestModel(
        requestId: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.userId,
        title: titleController.value.text,
        description: descriptionController.value.text,
        location: locationController.value.text.toLowerCase().trim(),
        timestamp: DateTime.now(),
        requestedTime: selectedDateTime.value!,
        numberOfPeople: number,
        hoursNeeded: hours, 
        status: RequestStatus.pending,
        acceptedUser: [],
      );
      log("Saving new request with requestedTime: ${selectedDateTime.value}");

      final notify = NotificationModel(
        notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
        status: RequestStatus.pending.toString().split(".").last,
        body: request.title,
        isUserWaiting: false,
        userId: user.userId,
        timestamp: DateTime.now(),
      );

      await store.saveRequestToStorage(request);
      await store.saveNotification(notify);
      await loadRequests();

      clearFields();
      Get.back();
    } catch (e) {
      log("Error saving request: $e");
      Get.snackbar("Error", "Failed to save request. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void validateIntegerInput({
  required String value,
  required RxString warningText,
  int min = 1,
  int max = 999,
  String fieldName = 'Value',
}) {
  final number = int.tryParse(value);
  if (number == null) {
    warningText.value = 'Only numbers are allowed';
    return;
  }

  if (value.length > 1 && value.startsWith('0')) {
    warningText.value = 'Leading zero is not allowed';
    return;
  }

  if (number < min || number > max) {
    warningText.value = 'Enter a number between $min and $max';
    return;
  }

  warningText.value = '';
}

//validation in edit request before save
int? validateIntField({
  required Rx<TextEditingController> controller,
  required RxString warning,
  required String label,
  int min = 1,
  int max = 100,
}) {
  final value = controller.value.text.trim();
  final number = int.tryParse(value);

 if (value.isEmpty) {
    controller.value.text = '1'; 
    warning.value = '';
    return 1;
  }
  if (number == null) {
    warning.value = '$label must be a number';
    return null;
  }

  if (value.length > 1 && value.startsWith('0')) {
    warning.value = 'Leading zero is not allowed';
    return null;
  }

  if (number < min || number > max) {
    warning.value = '$label must be between $min and $max';
    return null;
  }

  warning.value = '';
  return number;
}

  // Feedback methods
 void initializeFeedbackControllers(RequestModel request) {
  final count = request.acceptedUser?.length ?? 0;
  reviewControllers.clear();
  hourControllers.clear();
  selectedRatings.clear();
  reviewErrors.clear();
  hourErrors.clear();

 if (count == 0) {
    isFeedbackReady.value = true; 
    return;
  }
  for (int i = 0; i < count; i++) {
    reviewControllers.add(TextEditingController());

    // Pre-fill hours with request.hoursNeeded
    hourControllers.add(TextEditingController(
      text: request.hoursNeeded.toString(),
    ));

    selectedRatings.add(1.0.obs);
    reviewErrors.add(RxnString());
    hourErrors.add(RxnString());
  }
  isFeedbackReady.value = true;

}

bool validateFeedbackFields() {
  bool isValid = true;

  for (int i = 0; i < reviewControllers.length; i++) {
    final review = reviewControllers[i].text.trim();
    final hour = hourControllers[i].text.trim();

    reviewErrors[i].value = review.isEmpty ? "Review is required" : null;
    hourErrors[i].value = hour.isEmpty ? "Hours helped is required" : null;

    if (review.isEmpty || hour.isEmpty) {
      isValid = false;
    }
  }

  return isValid;
}
void updateRating(int index, double rating) {
  if (index >= 0 && index < selectedRatings.length) {
    selectedRatings[index].value = rating;
  }
}

Future<bool> handleFeedbackSubmission({
  required RequestModel request,
  required BuildContext context,
}) async {
  if (!validateFeedbackFields()) {
    return false;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    List<Future> feedbackFutures = [];

    for (int i = 0; i < request.acceptedUser!.length; i++) {
      final review = reviewControllers[i].text;
      final hours = int.tryParse(hourControllers[i].text) ?? 0;
      final rating = selectedRatings[i].value;

      feedbackFutures.add(submitSingleFeedback(
        userId: request.acceptedUser![i].userId,
        review: review,
        hours: hours,
        rating: rating.toDouble(),
        request: request,
      ));
    }

    await Future.wait(feedbackFutures);

    await markRequestAsComplete(request);

    List<Future> notificationFutures = [];

    for (var user in request.acceptedUser ?? []) {
      final notification = NotificationModel(
        body: "The work '${request.title}' is completed and feedback has been added.",
        timestamp: DateTime.now(),
        isUserWaiting: false,
        userId: user.userId,
        status: RequestStatus.complete.toString().split(".").last,
        notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      notificationFutures.add(store.saveNotification(notification));
    }

    await Future.wait(notificationFutures);

    Navigator.of(context).pop(); 
    return true;
  } catch (e) {
    Navigator.of(context).pop();
    print('Feedback submission error: $e');
    Get.snackbar('Error', 'Error submitting feedback: ${e.toString()}');
    return false;
  }
}


  Future<void> submitSingleFeedback({
    required String userId,
    required String review,
    required int hours,
    required double rating,
    required RequestModel request,
  }) async {
    try {
      // Get the latest version of the request from Firebase
      final latestRequest = await store.getRequest(request.requestId);

      final feedback = FeedbackModel(
        feedbackId: userId,
        userId: request.userId,
        requestId: request.requestId,
        review: review,
        rating: rating,
        hours: hours,
        timestamp: DateTime.now(),
      );

      //   Add the feedback to the latest list
      final List<FeedbackModel> updatedFeedbackList = [
        ...(latestRequest?.feedbackList ?? []),
        feedback
      ];

      final updatedRequest =
          latestRequest!.copyWith(feedbackList: updatedFeedbackList);
      await controllerUpdateRequest(request.requestId, updatedRequest);

      final userData = await store.getUser(userId);
      if (userData != null) {
        int previousHours = userData.hours ?? 0;
        int totalHours = previousHours + hours;

        double previousRating = userData.rating ?? 0;
        double newRating = (previousRating + rating) / 2;
        newRating = newRating.clamp(0, 5);
        newRating =
            double.parse(newRating.toStringAsFixed(1)); // round to 1 decimal

        await store.updateUser({
          'rating': newRating,
          'hours': totalHours,
        }, userId);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback for user $userId: $e');
    }
  }

  final RxList<Map<String, dynamic>> fullFeedbackList =
      <Map<String, dynamic>>[].obs;

  Future<void> fetchProfileFeedback(String userId) async {
    try {
      isFeedbackLoading.value = true;

      final feedbacks = await store.getFeedbackForUser(userId);
      final currentUserId = authController.currentUserStore.value?.userId;
      final filteredFeedbacks =
          currentUserId == userId ? feedbacks : feedbacks.take(4).toList();

      final List<Map<String, dynamic>> tempList = [];

      for (var feedback in filteredFeedbacks) {
        final displayData = await getFeedbackDisplayData(feedback);
        tempList.add({
          'feedback': feedback,
          'username': displayData['username'],
          'imageUrl': displayData['imageUrl'],
          'title': displayData['title'],
        });
      }

      fullFeedbackList.value = tempList;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load feedback');
    } finally {
      isFeedbackLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> getFeedbackDisplayData(
      FeedbackModel feedback) async {
    final user = await store.getUser(feedback.userId);

    final request = await store.getRequest(feedback.requestId);

    return {
      "username": user?.username ?? "Unknown User",
      "imageUrl": user?.imageUrl,
      "title": request?.title ?? "Untitled Request",
    };
  }

  void clearFields() {
    titleController.value.clear();
    descriptionController.value.clear();
    locationController.value.clear();
    selectedDateTime.value = null;
    reviewControllers.clear();
    hourControllers.clear();
    selectedRatings.clear();
    selectedDateController.value.clear();
    selectedTimeController.value.clear();
    numberOfPeopleController.value.clear();
    hoursNeededController.value.clear();
    reviewErrors.clear();
    hourErrors.clear();
    titleError.value = null;
    descriptionError.value = null;
    locationError.value = null;
    dateTimeError.value = null;
  }

  @override
  void onClose() {
    numberOfPeopleController.value.dispose();
    hoursNeededController.value.dispose();
    titleController.value.dispose();
    descriptionController.value.dispose();
    locationController.value.dispose();
     for (var c in reviewControllers) {
    c.dispose();
    }
    for (var c in hourControllers) {
      c.dispose();
    }
    selectedDateTime.update(
      (val) {
        selectedDateTime.value = null;
      },
    );
    clearFields();
    update();
    super.onClose();
  }
  

    Future<void> controllerUpdateRequest(
    String requestId,
    RequestModel updatedFields,
  ) async {
  try {
    isLoading.value = true;

    final oldRequest = await store.getRequest(requestId);

    // Notify requester if request status changed to "accepted"
    if (oldRequest?.status != RequestStatus.accepted &&
        updatedFields.status == RequestStatus.accepted) {
      var notifyToRequester = NotificationModel(
        notificationId: "${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(100000)}",
        status: RequestStatus.accepted.toString().split('.').last,
        body: "${updatedFields.title} is accepted",
        isUserWaiting: false,
        userId: updatedFields.userId,
        timestamp: DateTime.now(),
      );

      await store.saveNotification(notifyToRequester);
      // await Get.find<NotificationController>().loadNotification();
    }
  //  Check if actual request details were edited
    bool isEdited = (oldRequest?.title != updatedFields.title) ||
        (oldRequest?.description != updatedFields.description) ||
        (oldRequest?.location != updatedFields.location) ||
        (oldRequest?.requestedTime != updatedFields.requestedTime) ||
        (oldRequest?.numberOfPeople != updatedFields.numberOfPeople);

    //  Only if edited, notify accepted users
    if (isEdited &&
        updatedFields.acceptedUser != null &&
        updatedFields.acceptedUser!.isNotEmpty) {
      for (var acceptedUser in updatedFields.acceptedUser!) {
        if (acceptedUser.userId != updatedFields.userId) {
          var notifyToAcceptedUser = NotificationModel(
            notificationId: "${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(100000)}",
            status: "Edited",
            body: "${updatedFields.title} is edited",
            isUserWaiting: false,
            userId: acceptedUser.userId,
            timestamp: DateTime.now(),
          );
          await store.saveNotification(notifyToAcceptedUser);
           await Get.find<NotificationController>().loadNotification();
        }
      }
    }
   //  Update the request
    await store.updateRequest(requestId, updatedFields.toJson());

    await loadRequests();
    isLoading.value = false;
  } catch (e) {
    isLoading.value = false;
    log('Error updating request: $e');
  }
}


  // Update filter
  // Mapping of enums to display text
  final Map<FilterOption, String> filterLabels = {
    FilterOption.recentPosts: "Recent Posts",
    FilterOption.urgentRequired: "Urgent Required",
    FilterOption.location: "Location",
  };

  // Observable for selected filter
  Rx<FilterOption> selectedFilter = FilterOption.recentPosts.obs;

  // Update filter function
  void updateFilter(FilterOption? filter) {
    if (filter != null) {
      selectedFilter.value = filter;
      log("Selected filter: ${filterLabels[filter]}");
      loadRequests();
    }
    Get.back();
  }

  void clearFilters() {
    selectedFilter.value = FilterOption.recentPosts;
    Get.back();
  }

  List<RequestModel> getFilteredRequests(List<RequestModel> requests) {
    List<RequestModel> filteredList = requests.where((request) {
      switch (selectedFilter.value) {
        case FilterOption.recentPosts:
          return request.timestamp
              .isAfter(DateTime.now().subtract(const Duration(days: 50)));
        case FilterOption.urgentRequired:
          return request.requestedTime
              .isBefore(DateTime.now().add(const Duration(days: 15)));
        // case FilterOption.location:
        //   return request.location.toLowerCase() ==
        //       authController.currentUserStore.value!.location?.toLowerCase();
        default:
          return true;
      }
    }).toList();

    // Sort only if "urgentRequired" filter is selected
    if (selectedFilter.value == FilterOption.urgentRequired) {
      filteredList.sort((a, b) => a.requestedTime.compareTo(b.requestedTime));
    }

    return filteredList;
  }

  // filter dialogue
  void showFilterDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => Column(
                  children: FilterOption.values.map((FilterOption filter) {
                    return RadioListTile<FilterOption>(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      value: filter,
                      groupValue: selectedFilter.value,
                      onChanged: updateFilter,
                      title: Text(filterLabels[filter]!,
                          style: const TextStyle(color: Colors.black)),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                )),
          ],
        ),
      ),
    );
  }

  Future<UserModel?> getRequestUser(RequestModel request) async {
    var userMod = await store.getUser(request.userId);
    return userMod!;
  }

  String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (difference <= 5) {
      return difference == 1 ? "Yesterday" : "$difference days ago";
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

//status control for community post
  RequestStatus determineRequestStatus(
      RequestModel request, List<UserModel> acceptedUsers) {
    int required = request.numberOfPeople;
    int accepted = acceptedUsers.length;
    bool timeUp = request.requestedTime.isBefore(DateTime.now());

    if (timeUp && accepted == 0) {
      return RequestStatus.expired;
    } else if (timeUp && accepted >= 1 && accepted < required) {
      return RequestStatus.incomplete;
    } else if (accepted == 0) {
      return RequestStatus.pending;
    } else if (accepted < required) {
      return RequestStatus.inprogress;
    } else if (accepted >= required) {
      return RequestStatus.accepted;
    } else {
      return RequestStatus.pending;
    }
  }

//search method
  Future<void> fetchRequestsByLocation(String location) async {
    try {
      hasSearchedCommunity.value = true;
      final results = await store.searchRequestsByLocation(location);
      communityRequests.value = results;
    } catch (e) {
      Get.snackbar('Error', 'Could not fetch location-based requests');
    }
  }

  Future<void> fetchMyRequestsByLocation(String location) async {
    try {
      hasSearchedMyPosts.value = true;
      final results = await store.searchRequestsByLocation(location);
      myPostRequests.value = results;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load your requests');
    }
  }
  //chat room 
  String getChatRoomId(String uid1, String uid2) {
  // Sort to ensure same ID for both combinations
  final ids = [uid1, uid2]..sort();
  return ids.join("_");
}

}
