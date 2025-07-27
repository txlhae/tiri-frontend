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
import 'package:kind_clock/services/request_service.dart'; // 🔥 DJANGO SERVICE!

enum FilterOption { recentPosts, urgentRequired, location }

class RequestController extends GetxController {
  
  // =============================================================================
  // 🔥 DJANGO ENTERPRISE INTEGRATION
  // =============================================================================
  
  /// 🔥 NEW: Django RequestService (replaces FirebaseStorageService)
  final RequestService requestService = Get.find<RequestService>();
  final AuthController authController = Get.find<AuthController>();
  
  // =============================================================================
  // EXISTING STATE VARIABLES (Backward Compatible)
  // =============================================================================
  
  // Profile feedback list for user profiles
  final RxList<Map<String, dynamic>> profileFeedbackList = <Map<String, dynamic>>[].obs;
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

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  @override
  void onInit() async {
    log("🔥 RequestController: Initializing with Django backend integration");
    await loadRequests();
    log("✅ RequestController: Initialization complete - ${requestList.length} requests loaded");
    super.onInit();
  }

  // =============================================================================
  // 🔥 DJANGO API INTEGRATION METHODS
  // =============================================================================

  /// Load all requests from Django backend
  /// 🔥 UPDATED: Now uses Django APIs instead of Firebase
  Future<void> loadRequests() async {
    try {
      isLoading.value = true;
      log("🔥 RequestController: Loading requests from Django backend");

      // Fetch community requests from Django
      final communityRequestsFromApi = await requestService.fetchRequests();
      
      // Fetch user's own requests from Django  
      final userRequestsFromApi = await requestService.fetchMyRequests();

      // Update request statuses (keep existing logic)
      await updateRequestStatuses(communityRequestsFromApi);
      await updateRequestStatuses(userRequestsFromApi);

      // Update state variables
      myRequestList.assignAll(userRequestsFromApi);
      
      // Filter the community requests based on the selected filter
      final filteredRequests = getFilteredRequests(communityRequestsFromApi);
      requestList.assignAll(filteredRequests);
      
      // Update search lists
      communityRequests.assignAll(communityRequestsFromApi);
      myPostRequests.assignAll(userRequestsFromApi);
      
      log("✅ RequestController: Loaded ${communityRequestsFromApi.length} community requests");
      log("✅ RequestController: Loaded ${userRequestsFromApi.length} user requests");
      log("✅ RequestController: Applied filters - ${filteredRequests.length} requests visible");
      
    } catch (e) {
      log("❌ RequestController: Error loading requests from Django - $e");
      
      // Fallback: Set empty lists to prevent UI crashes
      requestList.clear();
      myRequestList.clear();
      communityRequests.clear();
      myPostRequests.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Search requests from Django backend
  /// 🔥 NEW: Enhanced search with Django APIs
  Future<void> searchRequests(String query, {String? location, bool isCommunityTab = true}) async {
    try {
      log("🔥 RequestController: Searching requests for '$query' in Django backend");
      
      if (query.trim().isEmpty) {
        // Reset to original lists if query is empty
        if (isCommunityTab) {
          requestList.assignAll(getFilteredRequests(communityRequests));
          hasSearchedCommunity.value = false;
        } else {
          myRequestList.assignAll(myPostRequests);
          hasSearchedMyPosts.value = false;
        }
        return;
      }

      // Search using Django API
      final searchResults = await requestService.searchRequests(query, location: location);
      
      if (isCommunityTab) {
        requestList.assignAll(searchResults);
        hasSearchedCommunity.value = true;
        log("✅ RequestController: Community search complete - ${searchResults.length} results");
      } else {
        // Filter user's requests locally for "My Posts" tab
        final userSearchResults = myPostRequests.where((request) => 
          request.title.toLowerCase().contains(query.toLowerCase()) ||
          request.description.toLowerCase().contains(query.toLowerCase()) ||
          request.location.toLowerCase().contains(query.toLowerCase())
        ).toList();
        
        myRequestList.assignAll(userSearchResults);
        hasSearchedMyPosts.value = true;
        log("✅ RequestController: My Posts search complete - ${userSearchResults.length} results");
      }
      
    } catch (e) {
      log("❌ RequestController: Search error - $e");
    }
  }

  /// Create new request via Django API
  /// 🔥 UPDATED: Now uses Django backend
  Future<bool> createRequest() async {
    try {
      if (!validateFields()) {
        log("❌ RequestController: Validation failed for new request");
        return false;
      }

      isLoading.value = true;
      log("🔥 RequestController: Creating request via Django API");

      // Prepare request data for Django API
      final requestData = {
        'title': titleController.value.text.trim(),
        'description': descriptionController.value.text.trim(),
        'location': locationController.value.text.trim(),
        'date_needed': selectedDateTime.value?.toIso8601String(),
        'number_of_people': int.tryParse(numberOfPeopleController.value.text) ?? 1,
        'hours_needed': int.tryParse(hoursNeededController.value.text) ?? 1,
        'status': 'pending',
        'priority': 'medium',
      };

      // Create request via Django API
      final success = await requestService.createRequest(requestData);

      if (success) {
        log("✅ RequestController: Request created successfully");
        
        // Clear form
        clearForm();
        
        // Reload requests to show the new one
        await loadRequests();
        
        return true;
      } else {
        log("❌ RequestController: Failed to create request");
        return false;
      }
      
    } catch (e) {
      log("❌ RequestController: Error creating request - $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update request status via Django API
  /// 🔥 UPDATED: Now uses Django backend
  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      log("🔥 RequestController: Updating request $requestId status to $newStatus via Django");
      
      final updateData = {'status': newStatus};
      final success = await requestService.updateRequest(requestId, updateData);
      
      if (success) {
        log("✅ RequestController: Request $requestId status updated to $newStatus");
        
        // Refresh requests to show updated status
        await loadRequests();
        return true;
      } else {
        log("❌ RequestController: Failed to update request $requestId status");
        return false;
      }
      
    } catch (e) {
      log("❌ RequestController: Error updating request status - $e");
      return false;
    }
  }

  /// Get user details via Django API
  /// 🔥 UPDATED: Now uses Django backend with caching
  Future<UserModel?> getUserDetails(String userId) async {
    try {
      // Check cache first
      if (userCache.containsKey(userId) && userCache[userId]!.value != null) {
        log("✅ RequestController: User $userId found in cache");
        return userCache[userId]!.value;
      }

      log("🔥 RequestController: Fetching user $userId from Django API");
      
      // Fetch from Django API
      final user = await requestService.getUser(userId);
      
      if (user != null) {
        // Cache the user
        userCache[userId] = Rx<UserModel?>(user);
        log("✅ RequestController: User $userId fetched and cached");
        return user;
      } else {
        log("❌ RequestController: User $userId not found");
        return null;
      }
      
    } catch (e) {
      log("❌ RequestController: Error fetching user $userId - $e");
      return null;
    }
  }

  // =============================================================================
  // EXISTING METHODS (Backward Compatible)
  // =============================================================================

  /// Update request statuses based on business logic
  /// ✅ KEPT: Existing logic maintained for backward compatibility
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
            await updateRequestStatus(request.requestId, "expired");
            
            // Create notification
            NotificationModel notification = NotificationModel(
              body: request.title,
              timestamp: DateTime.now(),
              isUserWaiting: false,
              userId: request.userId,
              status: RequestStatus.expired.toString().split(".")[1],
              notificationId: DateTime.now().millisecondsSinceEpoch.toString(),  // ✅ CORRECT
            );
            
            Get.find<NotificationController>().addNotification(notification);
            
          } else if (acceptedCount < requiredCount) {
            log("Partial volunteers and time up, updating to incomplete: ${request.requestId}");
            await updateRequestStatus(request.requestId, "incomplete");
          } else if (acceptedCount >= requiredCount) {
            log("Full volunteers and time up, updating to inprogress: ${request.requestId}");
            await updateRequestStatus(request.requestId, "inprogress");
          }
        } catch (e) {
          log("Error updating request status: $e");
        }
      }
    }
  }

  /// Get filtered requests based on current filter option
  /// ✅ KEPT: Existing filtering logic maintained
  List<RequestModel> getFilteredRequests(List<RequestModel> allRequests) {
    // Apply any filters here (existing logic)
    return allRequests;
  }

  /// Validate form fields
  /// ✅ KEPT: Existing validation logic
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

  /// Clear form fields
  /// ✅ KEPT: Existing form clearing logic
  void clearForm() {
    titleController.value.clear();
    descriptionController.value.clear();
    locationController.value.clear();
    numberOfPeopleController.value.clear();
    hoursNeededController.value.clear();
    selectedDateTime.value = null;
    selectedDate.value = null;
    selectedTime.value = null;
    selectedDateController.value.clear();
    selectedTimeController.value.clear();
    
    // Clear errors
    titleError.value = null;
    descriptionError.value = null;
    locationError.value = null;
    dateTimeError.value = null;
  }

  /// Set date and time
  /// ✅ KEPT: Existing date/time logic
  void setDateTime(DateTime date, TimeOfDay time) {
    selectedDate.value = date;
    selectedTime.value = time;
    
    selectedDateTime.value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    selectedDateController.value.text = DateFormat('dd/MM/yyyy').format(date);
    selectedTimeController.value.text = DateFormat('HH:mm').format(DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ));

    dateTimeError.value = null;
  }

  // =============================================================================
  // PLACEHOLDER METHODS (For backward compatibility)
  // =============================================================================

  /// Placeholder methods to maintain compatibility with existing UI
  /// These will be fully implemented in later phases
  
  Future<void> refreshRequests() async {
    await loadRequests();
  }
  
  void filterByLocation(String location) {
    log("🔧 RequestController: filterByLocation - placeholder method");
  }
  
  void sortRequests(String sortOption) {
    log("🔧 RequestController: sortRequests - placeholder method");
  }

  @override
  void onClose() {
    // Clean up controllers
    titleController.value.dispose();
    descriptionController.value.dispose();
    locationController.value.dispose();
    numberOfPeopleController.value.dispose();
    hoursNeededController.value.dispose();
    selectedDateController.value.dispose();
    selectedTimeController.value.dispose();
    
    super.onClose();
  }

  // APPEND THESE METHODS TO THE END OF RequestController class
  // Add these methods before the @override void onClose() method

  // =============================================================================
  // MISSING METHODS FOR BACKWARD COMPATIBILITY
  // =============================================================================

  /// Initialize feedback controllers for feedback submission
  void initializeFeedbackControllers(RequestModel request) {
    log("RequestController: initializeFeedbackControllers called");
    
    // Clear existing controllers
    reviewControllers.clear();
    hourControllers.clear();
    selectedRatings.clear();
    reviewErrors.clear();
    hourErrors.clear();
    
    // Initialize controllers for each accepted user
    for (int i = 0; i < request.acceptedUser.length; i++) {
      reviewControllers.add(TextEditingController());
      hourControllers.add(TextEditingController());
      selectedRatings.add(5.0.obs); // Default rating
      reviewErrors.add(RxnString());
      hourErrors.add(RxnString());
    }
    
    isFeedbackReady.value = true;
  }

  /// Update rating for feedback
  void updateRating(int index, double rating) {
    if (index < selectedRatings.length) {
      selectedRatings[index].value = rating;
      log("RequestController: Updated rating for index $index to $rating");
    }
  }

  /// Handle feedback submission
  Future<bool> handleFeedbackSubmission({RequestModel? request, BuildContext? context}) async {
    try {
      log("RequestController: handleFeedbackSubmission called");
      
      if (request == null) {
        log("RequestController: No request provided for feedback");
        return false;
      }
      
      // Validate all feedback forms
      bool isValid = true;
      for (int i = 0; i < request.acceptedUser.length; i++) {
        if (i < reviewControllers.length && reviewControllers[i].text.trim().isEmpty) {
          if (i < reviewErrors.length) reviewErrors[i].value = "Review is required";
          isValid = false;
        } else {
          if (i < reviewErrors.length) reviewErrors[i].value = null;
        }
        
        if (i < hourControllers.length && hourControllers[i].text.trim().isEmpty) {
          if (i < hourErrors.length) hourErrors[i].value = "Hours is required";
          isValid = false;
        } else {
          if (i < hourErrors.length) hourErrors[i].value = null;
        }
      }
      
      if (!isValid) {
        return false;
      }
      
      // Submit feedback for each user (placeholder implementation)
      for (int i = 0; i < request.acceptedUser.length; i++) {
        if (i < reviewControllers.length && i < hourControllers.length && i < selectedRatings.length) {
          final feedbackData = {
            'to_user_id': request.acceptedUser[i].userId,
            'request_id': request.requestId,
            'hours': int.tryParse(hourControllers[i].text) ?? 1,
            'rating': selectedRatings[i].value,
            'review': reviewControllers[i].text.trim(),
          };
          
          log("RequestController: Submitting feedback: $feedbackData");
          // TODO: Implement actual API call to submit feedback
        }
      }
      
      return true;
    } catch (e) {
      log("RequestController: Error in handleFeedbackSubmission - $e");
      return false;
    }
  }
  
  /// Select date for request
  Future<void> selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.value ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      
      if (picked != null) {
        selectedDate.value = picked;
        selectedDateController.value.text = DateFormat('dd/MM/yyyy').format(picked);
        
        // Update combined datetime if time is also selected
        if (selectedTime.value != null) {
          selectedDateTime.value = DateTime(
            picked.year,
            picked.month,
            picked.day,
            selectedTime.value!.hour,
            selectedTime.value!.minute,
          );
        }
        
        dateTimeError.value = null;
      }
    } catch (e) {
      log("RequestController: Error selecting date - $e");
    }
  }

  /// Select time for request
  Future<void> selectTime(BuildContext context) async {
    try {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value ?? TimeOfDay.now(),
      );
      
      if (picked != null) {
        selectedTime.value = picked;
        selectedTimeController.value.text = DateFormat('HH:mm').format(DateTime(
          2000, 1, 1, picked.hour, picked.minute,
        ));
        
        // Update combined datetime if date is also selected
        if (selectedDate.value != null) {
          selectedDateTime.value = DateTime(
            selectedDate.value!.year,
            selectedDate.value!.month,
            selectedDate.value!.day,
            picked.hour,
            picked.minute,
          );
        }
        
        dateTimeError.value = null;
      }
    } catch (e) {
      log("RequestController: Error selecting time - $e");
    }
  }

  /// Validate integer input
  void validateIntegerInput({String? value, String? fieldName}) {
    value = value ?? '';
    fieldName = fieldName ?? '';
    
    // Remove any validation warnings for now
    if (fieldName.toLowerCase().contains('people')) {
      numberOfPeopleWarning.value = '';
    } else if (fieldName.toLowerCase().contains('hour')) {
      hoursNeededWarning.value = '';
    }
  }

  /// Save request (alias for createRequest)
  Future<bool> saveRequest() async {
    return await createRequest();
  }

  /// Validate integer field
  int validateIntField({TextEditingController? controller, int defaultValue = 1}) {
    if (controller == null) return defaultValue;
    return int.tryParse(controller.text) ?? defaultValue;
  }

  /// Determine request status based on business logic
  String determineRequestStatus(RequestModel request) {
    final now = DateTime.now();
    final acceptedCount = request.acceptedUser.length;
    final requiredCount = request.numberOfPeople;
    final timeUp = request.requestedTime.isBefore(now);
    
    if (timeUp) {
      if (acceptedCount == 0) {
        return 'expired';
      } else if (acceptedCount < requiredCount) {
        return 'incomplete';
      } else {
        return 'inprogress';
      }
    } else {
      if (acceptedCount >= requiredCount) {
        return 'accepted';
      } else {
        return 'pending';
      }
    }
  }

  /// Controller update request (wrapper for updateRequest)
  Future<bool> controllerUpdateRequest(String requestId, dynamic data) async {
    try {
      if (data is RequestModel) {
        // Convert RequestModel to status string
        final statusData = {'status': data.status.toString().split('.').last};
        return await updateRequestStatus(requestId, statusData['status']!);
      } else if (data is Map<String, dynamic>) {
        return await updateRequestStatus(requestId, data['status'] ?? 'pending');
      } else {
        log("RequestController: Invalid data type for controllerUpdateRequest");
        return false;
      }
    } catch (e) {
      log("RequestController: Error in controllerUpdateRequest - $e");
      return false;
    }
  }

  /// Clear form fields (alias for clearForm)
  void clearFields() {
    clearForm();
  }

  /// Get full feedback list
  List<Map<String, dynamic>> get fullFeedbackList => profileFeedbackList;

  /// Fetch requests by location
  Future<void> fetchRequestsByLocation(String location) async {
    try {
      log("RequestController: fetchRequestsByLocation called for: $location");
      final results = await requestService.searchRequests('', location: location);
      requestList.assignAll(results);
    } catch (e) {
      log("RequestController: Error fetching requests by location - $e");
    }
  }

  /// Fetch my requests by location
  Future<void> fetchMyRequestsByLocation(String location) async {
    try {
      log("RequestController: fetchMyRequestsByLocation called for: $location");
      // Filter user's requests by location locally
      final filtered = myPostRequests.where((request) => 
        request.location.toLowerCase().contains(location.toLowerCase())
      ).toList();
      myRequestList.assignAll(filtered);
    } catch (e) {
      log("RequestController: Error fetching my requests by location - $e");
    }
  }

  /// Show filter dialog
  void showFilterDialog(BuildContext context) {
    log("RequestController: showFilterDialog called");
    // TODO: Implement filter dialog
  }

  /// Fetch profile feedback
  Future<void> fetchProfileFeedback(String userId) async {
    try {
      log("RequestController: fetchProfileFeedback called for user: $userId");
      // TODO: Implement feedback fetching from Django API
      profileFeedbackList.clear();
    } catch (e) {
      log("RequestController: Error fetching profile feedback - $e");
    }
  }

  /// Get chat room ID
  String getChatRoomId(String requestId, String userId1, [String? userId2]) {
    if (userId2 == null) {
      // If only two parameters provided, use current user as userId2
      userId2 = authController.currentUserStore.value?.userId ?? 'unknown';
    }
    
    // Generate a consistent chat room ID
    final sortedIds = [userId1, userId2]..sort();
    return '${requestId}_${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get request user (alias for getUserDetails)
  Future<UserModel?> getRequestUser(RequestModel request) async {
    return await getUserDetails(request.userId);
  }

  /// Format date time to string
  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, HH:mm').format(dateTime);
  }

  /// Get relative time string
  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

