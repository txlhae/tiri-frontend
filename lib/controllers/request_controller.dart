// lib/controllers/request_controller.dart
// 🚨 UPDATED: Removed automatic status updates - now handled by backend
// 
// 🔧 BACKEND STATUS MANAGEMENT:
// =============================
// CHANGE: Automatic request status updates removed from Flutter frontend
// REASON: Django backend now handles all status transitions automatically
// 
// REMOVED FEATURES:
// - Automatic status update logic (expired, incomplete, inprogress)
// - Session-based status update flags (_hasUpdatedStatusesThisSession, _isUpdatingStatuses)
// - updateRequestStatuses() method and related notification triggers
// - forceStatusUpdate() and resetStatusUpdateFlag() helper methods
// 
// CURRENT BEHAVIOR:
// - Frontend only handles manual status updates via user actions
// - Backend automatically manages time-based status transitions
// - Cleaner separation of concerns between frontend and backend
// - Updating request statuses skips further status checks to prevent loops

import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/models/user_model.dart';
import 'package:kind_clock/services/request_service.dart';

enum FilterOption { recentPosts, urgentRequired, location }

class RequestController extends GetxController {
  
  // =============================================================================
  // 🚨 DEBUG: Enhanced debugging properties
  // =============================================================================
  
  final RxBool debugMode = true.obs; // 🚨 Enable comprehensive debugging
  final RxString debugStatus = "Initializing...".obs;
  final RxInt totalRequestsFromApi = 0.obs;
  final RxInt totalMyRequestsFromApi = 0.obs;
  final RxInt filteredRequestsCount = 0.obs;
  
  // =============================================================================
  // =============================================================================
  // DJANGO ENTERPRISE INTEGRATION
  // =============================================================================
  
  final RequestService requestService = Get.find<RequestService>();
  final AuthController authController = Get.find<AuthController>();
  
  // =============================================================================
  // EXISTING STATE VARIABLES (Backward Compatible)
  // =============================================================================
  
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

  var reviewControllers = <TextEditingController>[].obs;
  var hourControllers = <TextEditingController>[].obs;
  var selectedRatings = <RxDouble>[].obs;
  var reviewErrors = <RxnString>[].obs;
  var hourErrors = <RxnString>[].obs;

  final RxBool isFeedbackLoading = true.obs;
  
  final RxList<RequestModel> communityRequests = <RequestModel>[].obs;
  final RxList<RequestModel> myPostRequests = <RequestModel>[].obs;

  final RxBool hasSearchedCommunity = false.obs;
  final RxBool hasSearchedMyPosts = false.obs;

  // =============================================================================
  // REQUEST DETAILS ON-DEMAND LOADING
  // =============================================================================
  
  final Rx<RequestModel?> currentRequestDetails = Rx<RequestModel?>(null);
  final RxBool isLoadingRequestDetails = false.obs;

  // =============================================================================
  // 🚨 DEBUG: Enhanced initialization with detailed logging
  // =============================================================================

  /// 🚨 CRITICAL FIX: Wait for AuthController to load tokens before fetching data
  Future<void> _waitForAuthThenLoadRequests() async {
    try {
      debugLog("⏳ RequestController: Waiting for AuthController to load tokens...");
      debugStatus.value = "Waiting for authentication...";
      
      // 🚨 SOLUTION: Wait for AuthController to finish loading tokens
      int attempts = 0;
      const maxAttempts = 30; // 3 seconds max wait (30 * 100ms)
      
      while (attempts < maxAttempts) {
        // Check if AuthController has finished initialization
        if (authController.isLoggedIn.value && authController.currentUserStore.value != null) {
          debugLog("✅ AuthController ready: User ${authController.currentUserStore.value?.email} logged in");
          break;
        }
        
        // If not logged in but also not loading, break (user needs to login)
        if (!authController.isLoggedIn.value && !authController.isLoading.value) {
          debugLog("ℹ️ No user session found - user needs to login first");
          isLoading.value = false;
          debugStatus.value = "No user session - login required";
          return;
        }
        
        // Wait a bit more for AuthController to finish
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
        
        if (attempts % 10 == 0) { // Log every second
          debugLog("⏳ Still waiting for AuthController... (${attempts/10}s)");
        }
      }
      
      if (attempts >= maxAttempts) {
        debugLog("⚠️ Timeout waiting for AuthController - proceeding anyway");
        debugStatus.value = "Authentication timeout - proceeding...";
      }
      
      // 🚨 Now check if we have a user before proceeding
      if (authController.currentUserStore.value != null) {
        debugLog("👤 User ready: ${authController.currentUserStore.value?.userId}");
        debugStatus.value = "Loading requests from Django...";
        
        // Load requests immediately
        await loadRequests();
        
        debugLog("🎯 RequestController: Initialization complete");
      } else {
        debugLog("❌ No valid user session - cannot load requests");
        isLoading.value = false;
        debugStatus.value = "Authentication required";
      }
        
    } catch (e, stackTrace) {
      debugLog("❌ RequestController: Error waiting for auth - $e");
      debugLog("Stack trace: $stackTrace");
      debugStatus.value = "Authentication wait failed: $e";
      isLoading.value = false;
    }
  }


  @override
  void onInit() {
    super.onInit(); // ✅ Call super.onInit() FIRST
    
    debugLog("🚀 RequestController: Starting initialization with ENHANCED DEBUG MODE");
    debugStatus.value = "Initializing RequestController...";
    
    // 🚨 KEY FIX: Set loading to true IMMEDIATELY
    isLoading.value = true;
    
    try {
      debugLog("📋 RequestController: Checking dependencies...");
      debugLog("   - RequestService: ✅ Available");
      debugLog("   - AuthController: ✅ Available");
      
      // 🚨 CRITICAL FIX: Initialize data loading immediately
      // Don't wait for perfect auth state - start loading process
      Future.microtask(() async {
        await _waitForAuthThenLoadRequests();
      });
      
    } catch (e) {
      debugLog("❌ RequestController: Initialization failed - $e");
      debugStatus.value = "Initialization failed: $e";
      isLoading.value = false;
    }
  }

  // =============================================================================
  // 🚨 DEBUG: Enhanced request loading with comprehensive logging
  // =============================================================================

  Future<void> loadRequests() async {
    try {
      isLoading.value = true;
      debugLog("🔄 RequestController: Starting loadRequests()");
      debugStatus.value = "Fetching requests from Django API...";

      // 🚨 Step 1: Fetch community requests
      debugLog("📡 Step 1: Fetching community requests from Django...");
      final communityRequestsFromApi = await requestService.fetchRequests();
      totalRequestsFromApi.value = communityRequestsFromApi.length;
      
      debugLog("   - Raw community requests from API: ${communityRequestsFromApi.length}");
      if (communityRequestsFromApi.isNotEmpty) {
        debugLog("   - First request sample: ${communityRequestsFromApi.first.title}");
        debugLog("   - First request status: ${communityRequestsFromApi.first.status}");
        debugLog("   - First request user: ${communityRequestsFromApi.first.userId}");
        debugLog("   - First request time: ${communityRequestsFromApi.first.requestedTime}");
      } else {
        debugLog("   - ⚠️ NO COMMUNITY REQUESTS RETURNED FROM API");
      }
      
      // 🚨 Step 2: Fetch user's own requests
      debugLog("📡 Step 2: Fetching user requests from Django...");
      final userRequestsFromApi = await requestService.fetchMyRequests();
      totalMyRequestsFromApi.value = userRequestsFromApi.length;
      
      debugLog("   - Raw user requests from API: ${userRequestsFromApi.length}");
      if (userRequestsFromApi.isNotEmpty) {
        debugLog("   - First user request: ${userRequestsFromApi.first.title}");
      } else {
        debugLog("   - ⚠️ NO USER REQUESTS RETURNED FROM API");
      }

      // 🚨 Step 3: Update request statuses (ONLY ONCE PER SESSION OR IF EXPLICITLY REQUESTED)
      // � REMOVED: Automatic status updates now handled by backend
      debugLog("🔄 Step 3: Automatic status updates removed (handled by backend)");

      // 🚨 Step 4: Apply filters (TEMPORARILY DISABLED FOR DEBUGGING)
      debugLog("🔍 Step 4: Applying filters...");
      debugStatus.value = "Applying filters...";
      
      // 🚨 DEBUGGING: Show all requests first, then apply filters
      final rawFilteredRequests = getFilteredRequests(communityRequestsFromApi);
      filteredRequestsCount.value = rawFilteredRequests.length;
      
      debugLog("   - Requests before filtering: ${communityRequestsFromApi.length}");
      debugLog("   - Requests after filtering: ${rawFilteredRequests.length}");
      
      if (communityRequestsFromApi.length > 0 && rawFilteredRequests.length == 0) {
        debugLog("   - 🚨 ALL REQUESTS FILTERED OUT! Using raw data for debugging...");
        // Temporarily show all requests to debug filtering issue
        requestList.assignAll(communityRequestsFromApi);
      } else {
        requestList.assignAll(rawFilteredRequests);
      }

      // 🚨 Step 5: Update state variables
      debugLog("📝 Step 5: Updating state variables...");
      myRequestList.assignAll(userRequestsFromApi);
      communityRequests.assignAll(communityRequestsFromApi);
      myPostRequests.assignAll(userRequestsFromApi);
      
      debugStatus.value = "Requests loaded successfully ✅";
      
      // 🚨 Final debugging summary
      debugLog("✅ RequestController: Load completed successfully");
      debugLog("   - Community API: ${communityRequestsFromApi.length} → UI: ${requestList.length}");
      debugLog("   - User API: ${userRequestsFromApi.length} → UI: ${myRequestList.length}");
      debugLog("   - Current user ID: ${authController.currentUserStore.value?.userId}");
      
      // 🚨 Detailed analysis if no requests showing
      if (requestList.isEmpty && communityRequestsFromApi.isNotEmpty) {
        debugLog("🚨 ISSUE DETECTED: API returned data but UI shows none");
        await debugFilteringLogic(communityRequestsFromApi);
      }
      
    } catch (e, stackTrace) {
      debugLog("❌ RequestController: ERROR in loadRequests() - $e");
      debugLog("Stack trace: $stackTrace");
      debugStatus.value = "Error loading requests: $e";
      
      // 🚨 Fallback: Set empty lists to prevent UI crashes
      requestList.clear();
      myRequestList.clear();
      communityRequests.clear();
      myPostRequests.clear();
      totalRequestsFromApi.value = 0;
      totalMyRequestsFromApi.value = 0;
      filteredRequestsCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // =============================================================================
  // 🚨 DEBUG: Detailed filtering analysis
  // =============================================================================

  Future<void> debugFilteringLogic(List<RequestModel> allRequests) async {
    try {
      debugLog("🔍 DEBUGGING FILTER LOGIC:");
      
      final currentUser = authController.currentUserStore.value;
      debugLog("   - Current user: ${currentUser?.userId ?? 'NULL'}");
      
      for (int i = 0; i < math.min(3, allRequests.length); i++) {
        final request = allRequests[i];
        debugLog("   - Request $i: ${request.title}");
        debugLog("     * Status: ${request.status}");
        debugLog("     * Is Pending: ${request.status == RequestStatus.pending}");
        debugLog("     * Is InProgress: ${request.status == RequestStatus.inprogress}");
        debugLog("     * Requested Time: ${request.requestedTime}");
        debugLog("     * Is Future Time: ${(request.requestedTime ?? request.timestamp).isAfter(DateTime.now())}");
        debugLog("     * Request User ID: ${request.userId}");
        debugLog("     * Current User ID: ${currentUser?.userId}");
        debugLog("     * Is Own Request: ${request.userId == currentUser?.userId}");
        debugLog("     * Accepted Users: ${request.acceptedUser.length}");
        debugLog("     * People Needed: ${request.numberOfPeople}");
        debugLog("     * Slots Available: ${request.acceptedUser.length < request.numberOfPeople}");
        
        // Check if current user already accepted
        final alreadyAccepted = request.acceptedUser.any((user) => user.userId == currentUser?.userId);
        debugLog("     * User Already Accepted: $alreadyAccepted");
        
        // Check overall eligibility
        final isEligible = currentUser != null && 
                          (request.status == RequestStatus.pending || request.status == RequestStatus.inprogress) &&
                          (request.requestedTime ?? request.timestamp).isAfter(DateTime.now()) &&
                          request.userId != currentUser.userId && 
                          request.acceptedUser.length < request.numberOfPeople &&
                          !alreadyAccepted;
        
        debugLog("     * 🎯 FINAL ELIGIBILITY: $isEligible");
        debugLog("");
      }
    } catch (e) {
      debugLog("❌ Error in debugFilteringLogic: $e");
    }
  }

  // =============================================================================
  // 🚨 DEBUG: Enhanced logging utility
  // =============================================================================

  void debugLog(String message) {
    if (debugMode.value) {
      log("🚨 [REQUEST_DEBUG] $message", name: 'RequestController');
    }
  }

  // =============================================================================
  // EXISTING METHODS (All preserved with debug logging added)
  // =============================================================================

  Future<void> searchRequests(String query, {String? location, bool isCommunityTab = true}) async {
    try {
      debugLog("🔍 searchRequests called: '$query', location: $location, communityTab: $isCommunityTab");
      
      if (query.trim().isEmpty) {
        if (isCommunityTab) {
          requestList.assignAll(getFilteredRequests(communityRequests));
          hasSearchedCommunity.value = false;
        } else {
          myRequestList.assignAll(myPostRequests);
          hasSearchedMyPosts.value = false;
        }
        return;
      }

      final searchResults = await requestService.searchRequests(query, location: location);
      debugLog("   - Search results: ${searchResults.length}");
      
      if (isCommunityTab) {
        requestList.assignAll(searchResults);
        hasSearchedCommunity.value = true;
      } else {
        final userSearchResults = myPostRequests.where((request) => 
          request.title.toLowerCase().contains(query.toLowerCase()) ||
          request.description.toLowerCase().contains(query.toLowerCase()) ||
          (request.location ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
        
        myRequestList.assignAll(userSearchResults);
        hasSearchedMyPosts.value = true;
      }
      
    } catch (e) {
      debugLog("❌ searchRequests error: $e");
    }
  }

  Future<bool> createRequest() async {
    try {
      if (!validateFields()) {
        debugLog("❌ createRequest: Validation failed");
        return false;
      }

      isLoading.value = true;
      debugLog("📝 createRequest: Creating request via Django API");

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

      final success = await requestService.createRequest(requestData);

      if (success) {
        debugLog("✅ createRequest: Request created successfully");
        clearForm();
        await loadRequests();
        return true;
      } else {
        debugLog("❌ createRequest: Failed to create request");
        return false;
      }
      
    } catch (e) {
      debugLog("❌ createRequest error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateRequestStatus(String requestId, String newStatus) async {
    try {
      debugLog("🔄 updateRequestStatus: $requestId → $newStatus");
      
      final updateData = {'status': newStatus};
      final success = await requestService.updateRequest(requestId, updateData);
      
      if (success) {
        debugLog("✅ updateRequestStatus: Status updated successfully");
        await loadRequests();
        return true;
      } else {
        debugLog("❌ updateRequestStatus: Failed to update status");
        return false;
      }
      
    } catch (e) {
      debugLog("❌ updateRequestStatus error: $e");
      return false;
    }
  }

  Future<UserModel?> getUserDetails(String userId) async {
    try {
      if (userCache.containsKey(userId) && userCache[userId]!.value != null) {
        return userCache[userId]!.value;
      }

      debugLog("👤 getUserDetails: Fetching user $userId from API");
      
      final user = await requestService.getUser(userId);
      
      if (user != null) {
        userCache[userId] = Rx<UserModel?>(user);
        return user;
      } else {
        debugLog("❌ getUserDetails: User $userId not found");
        return null;
      }
      
    } catch (e) {
      debugLog("❌ getUserDetails error: $e");
      return null;
    }
  }

  // =============================================================================
  // LOAD REQUEST DETAILS ON-DEMAND
  // =============================================================================
  
  /// Load complete request details by ID from the API
  /// ✅ ENHANCED: Now verifies UserRequestStatus data is properly loaded
  /// This ensures fresh data with enhanced volunteer status on every request details view
  Future<void> loadRequestDetails(String requestId) async {
    try {
      debugLog("🔄 LoadRequestDetails: Fetching request $requestId");
      isLoadingRequestDetails.value = true;
      currentRequestDetails.value = null;
      
      // Fetch the request from the API (uses RequestModelExtension.fromJsonWithRequester)
      final RequestModel? request = await requestService.getRequest(requestId);
      
      if (request != null) {
        currentRequestDetails.value = request;
        
        // ✅ ENHANCED: Debug logging to verify UserRequestStatus data
        debugLog("✅ LoadRequestDetails: Successfully loaded request $requestId");
        debugLog("📊 Enhanced Data Verification:");
        debugLog("   - User Request Status: ${request.userRequestStatus}");
        debugLog("   - Can Request: ${request.canRequest}");
        debugLog("   - Can Cancel Request: ${request.canCancelRequest}");
        debugLog("   - Has Volunteered: ${request.hasVolunteered}");
        debugLog("   - Volunteer Message: ${request.volunteerMessage ?? 'None'}");
        debugLog("   - Requested At: ${request.requestedAt?.toString() ?? 'Never'}");
        debugLog("   - Accepted At: ${request.acceptedAt?.toString() ?? 'Never'}");
        
        // Verify UserRequestStatus object is available
        final statusObject = request.userRequestStatusObject;
        if (statusObject != null) {
          debugLog("✅ UserRequestStatus object is properly loaded");
          debugLog("   - Full Status Data: ${statusObject.toJson()}");
        } else {
          debugLog("⚠️  UserRequestStatus object is null - may indicate backend data issue");
        }
        
        // Verify requester data is also available
        final requester = request.requester;
        if (requester != null) {
          debugLog("✅ Requester data available: ${requester.username}");
        } else {
          debugLog("⚠️  Requester data is null");
        }
        
      } else {
        debugLog("❌ LoadRequestDetails: Request $requestId not found");
        // Keep currentRequestDetails as null to show error state
      }
      
    } catch (e) {
      debugLog("💥 LoadRequestDetails error: $e");
      currentRequestDetails.value = null;
    } finally {
      isLoadingRequestDetails.value = false;
    }
  }

  // 🚨 REMOVED: updateRequestStatuses method - automatic status updates now handled by backend

  List<RequestModel> getFilteredRequests(List<RequestModel> allRequests) {
    return allRequests;
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
    
    titleError.value = null;
    descriptionError.value = null;
    locationError.value = null;
    dateTimeError.value = null;
  }

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

  Future<void> refreshRequests() async {
    debugLog("🔄 refreshRequests called - automatic status updates now handled by backend");
    await loadRequests();
  }

  void filterByLocation(String location) {
    debugLog("📍 filterByLocation: $location");
  }
  
  void sortRequests(String sortOption) {
    debugLog("🔀 sortRequests: $sortOption");
  }

  // =============================================================================
  // ALL REMAINING METHODS (Preserved exactly as they were)
  // =============================================================================

  void initializeFeedbackControllers(RequestModel request) {
    debugLog("📝 initializeFeedbackControllers called");
    
    reviewControllers.clear();
    hourControllers.clear();
    selectedRatings.clear();
    reviewErrors.clear();
    hourErrors.clear();
    
    for (int i = 0; i < request.acceptedUser.length; i++) {
      reviewControllers.add(TextEditingController());
      hourControllers.add(TextEditingController());
      selectedRatings.add(5.0.obs);
      reviewErrors.add(RxnString());
      hourErrors.add(RxnString());
    }
    
    isFeedbackReady.value = true;
  }

  void updateRating(int index, double rating) {
    if (index < selectedRatings.length) {
      selectedRatings[index].value = rating;
      debugLog("⭐ updateRating: index $index → $rating");
    }
  }

  Future<bool> handleFeedbackSubmission({RequestModel? request, BuildContext? context}) async {
    try {
      debugLog("📝 handleFeedbackSubmission called");
      
      if (request == null) {
        debugLog("❌ handleFeedbackSubmission: No request provided");
        return false;
      }
      
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
      
      for (int i = 0; i < request.acceptedUser.length; i++) {
        if (i < reviewControllers.length && i < hourControllers.length && i < selectedRatings.length) {
          final feedbackData = {
            'to_user_id': request.acceptedUser[i].userId,
            'request_id': request.requestId,
            'hours': int.tryParse(hourControllers[i].text) ?? 1,
            'rating': selectedRatings[i].value,
            'review': reviewControllers[i].text.trim(),
          };
          
          debugLog("📝 Submitting feedback: $feedbackData");
        }
      }
      
      return true;
    } catch (e) {
      debugLog("❌ handleFeedbackSubmission error: $e");
      return false;
    }
  }
  
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
      debugLog("❌ selectDate error: $e");
    }
  }

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
      debugLog("❌ selectTime error: $e");
    }
  }

  void validateIntegerInput({String? value, String? fieldName}) {
    value = value ?? '';
    fieldName = fieldName ?? '';
    
    if (fieldName.toLowerCase().contains('people')) {
      numberOfPeopleWarning.value = '';
    } else if (fieldName.toLowerCase().contains('hour')) {
      hoursNeededWarning.value = '';
    }
  }

  Future<bool> saveRequest() async {
    return await createRequest();
  }

  int validateIntField({TextEditingController? controller, int defaultValue = 1}) {
    if (controller == null) return defaultValue;
    return int.tryParse(controller.text) ?? defaultValue;
  }

  String determineRequestStatus(RequestModel request) {
    final now = DateTime.now();
    final acceptedCount = request.acceptedUser.length;
    final requiredCount = request.numberOfPeople;
    final timeUp = (request.requestedTime ?? request.timestamp).isBefore(now);
    
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

  Future<bool> controllerUpdateRequest(String requestId, dynamic data) async {
    try {
      if (data is RequestModel) {
        final statusData = {'status': data.status.toString().split('.').last};
        return await updateRequestStatus(requestId, statusData['status']!);
      } else if (data is Map<String, dynamic>) {
        return await updateRequestStatus(requestId, data['status'] ?? 'pending');
      } else {
        debugLog("❌ controllerUpdateRequest: Invalid data type");
        return false;
      }
    } catch (e) {
      debugLog("❌ controllerUpdateRequest error: $e");
      return false;
    }
  }

  void clearFields() {
    clearForm();
  }

  List<Map<String, dynamic>> get fullFeedbackList => profileFeedbackList;

  Future<void> fetchRequestsByLocation(String location) async {
    try {
      debugLog("📍 fetchRequestsByLocation: $location");
      final results = await requestService.searchRequests('', location: location);
      requestList.assignAll(results);
    } catch (e) {
      debugLog("❌ fetchRequestsByLocation error: $e");
    }
  }

  Future<void> fetchMyRequestsByLocation(String location) async {
    try {
      debugLog("📍 fetchMyRequestsByLocation: $location");
      final filtered = myPostRequests.where((request) => 
        (request.location ?? '').toLowerCase().contains(location.toLowerCase())
      ).toList();
      myRequestList.assignAll(filtered);
    } catch (e) {
      debugLog("❌ fetchMyRequestsByLocation error: $e");
    }
  }

  void showFilterDialog(BuildContext context) {
    debugLog("🔍 showFilterDialog called");
  }

  Future<void> fetchProfileFeedback(String userId) async {
    try {
      debugLog("👤 fetchProfileFeedback: $userId");
      profileFeedbackList.clear();
    } catch (e) {
      debugLog("❌ fetchProfileFeedback error: $e");
    }
  }

  String getChatRoomId(String requestId, String userId1, [String? userId2]) {
    if (userId2 == null) {
      userId2 = authController.currentUserStore.value?.userId ?? 'unknown';
    }
    
    final sortedIds = [userId1, userId2]..sort();
    return '${requestId}_${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<UserModel?> getRequestUser(RequestModel request) async {
    return await getUserDetails(request.userId);
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, HH:mm').format(dateTime);
  }

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

  // =============================================================================
  // VOLUNTEER REQUEST WORKFLOW METHODS
  // =============================================================================

  /// Request to volunteer for a specific request
  /// ✅ ENHANCED: Implements proper approval workflow via Django backend with UI integration
  Future<void> requestToVolunteer(String requestId, String message) async {
    try {
      isLoading.value = true;
      debugLog("🙋 RequestController: Requesting to volunteer for request $requestId");
      debugLog("   - Message: $message");
      debugLog("   - Message length: ${message.length} characters");
      
      // Validate input before API call
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      if (message.trim().isEmpty) {
        throw Exception('Volunteer message cannot be empty');
      }
      
      // Call the request service to send volunteer request
      final success = await requestService.requestToVolunteer(requestId, message);
      
      if (success) {
        debugLog("✅ RequestController: Successfully sent volunteer request for $requestId");
        
        // Clear the cache to ensure fresh data is loaded
        RequestModelExtension.clearUserStatusCache(requestId);
        debugLog("🗑️ RequestController: Cleared cache for request $requestId to ensure fresh data");
        
        // Refresh the specific request details to get updated UserRequestStatus
        await loadRequestDetails(requestId);
        debugLog("🔄 RequestController: Refreshed request details after volunteer request");
        
        // Also refresh general request lists for consistency
        await refreshRequests();
        debugLog("🔄 RequestController: Refreshed all requests after volunteer request");
        
      } else {
        debugLog("❌ RequestController: Failed to send volunteer request for $requestId");
        throw Exception('Failed to send volunteer request. Please try again.');
      }
    } catch (e) {
      debugLog("💥 RequestController: Error in requestToVolunteer for $requestId - $e");
      // Re-throw with more specific error message for UI
      if (e.toString().contains('Failed to send volunteer request')) {
        rethrow;
      } else {
        throw Exception('Network error: Unable to send volunteer request. Please check your connection and try again.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancel volunteer request for a specific request
  /// ✅ ENHANCED: Removes user from pending volunteer requests via Django backend with UI integration
  Future<void> cancelVolunteerRequest(String requestId) async {
    try {
      isLoading.value = true;
      debugLog("❌ RequestController: Canceling volunteer request for request $requestId");
      
      // Validate input before API call
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      // Get current request status for validation
      final currentRequest = currentRequestDetails.value;
      if (currentRequest != null) {
        debugLog("   - Current user status: ${currentRequest.userRequestStatus}");
        debugLog("   - Can cancel request: ${currentRequest.canCancelRequest}");
        
        // Validate that user can actually cancel
        if (!currentRequest.canCancelRequest) {
          throw Exception('You cannot cancel this volunteer request at this time');
        }
      }
      
      // Call the request service to cancel volunteer request
      final success = await requestService.cancelVolunteerRequest(requestId);
      
      if (success) {
        debugLog("✅ RequestController: Successfully canceled volunteer request for $requestId");
        
        // Refresh the specific request details to get updated UserRequestStatus
        await loadRequestDetails(requestId);
        debugLog("🔄 RequestController: Refreshed request details after canceling volunteer request");
        
        // Also refresh general request lists for consistency
        await refreshRequests();
        debugLog("🔄 RequestController: Refreshed all requests after canceling volunteer request");
        
      } else {
        debugLog("❌ RequestController: Failed to cancel volunteer request for $requestId");
        throw Exception('Failed to cancel volunteer request. Please try again.');
      }
    } catch (e) {
      debugLog("💥 RequestController: Error in cancelVolunteerRequest for $requestId - $e");
      // Re-throw with more specific error message for UI
      if (e.toString().contains('Failed to cancel volunteer request') || 
          e.toString().contains('You cannot cancel this volunteer request')) {
        rethrow;
      } else {
        throw Exception('Network error: Unable to cancel volunteer request. Please check your connection and try again.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Approve a volunteer request (for request owners)
  /// ✅ NEW: Allows request owners to approve pending volunteer requests
  Future<void> approveVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      isLoading.value = true;
      debugLog("✅ RequestController: Approving volunteer $volunteerUserId for request $requestId");
      
      // Validate inputs
      if (requestId.isEmpty || volunteerUserId.isEmpty) {
        throw Exception('Request ID and volunteer ID cannot be empty');
      }
      
      // Validate that current user owns the request
      final currentRequest = currentRequestDetails.value;
      final currentUserId = authController.currentUserStore.value?.userId;
      
      if (currentRequest == null || currentUserId == null) {
        throw Exception('Unable to verify request ownership');
      }
      
      if (currentRequest.userId != currentUserId) {
        throw Exception('Only request owners can approve volunteers');
      }
      
      // Call the request service to approve volunteer
      final success = await requestService.approveVolunteerRequest(requestId, volunteerUserId);
      
      if (success) {
        debugLog("✅ RequestController: Successfully approved volunteer $volunteerUserId for request $requestId");
        
        // Refresh request details to show updated volunteer list
        await loadRequestDetails(requestId);
        debugLog("🔄 RequestController: Refreshed request details after approving volunteer");
        
        // Refresh general requests
        await refreshRequests();
        
      } else {
        debugLog("❌ RequestController: Failed to approve volunteer $volunteerUserId for request $requestId");
        throw Exception('Failed to approve volunteer request. Please try again.');
      }
    } catch (e) {
      debugLog("💥 RequestController: Error in approveVolunteerRequest for $requestId - $e");
      if (e.toString().contains('Failed to approve volunteer request') || 
          e.toString().contains('Only request owners can approve')) {
        rethrow;
      } else {
        throw Exception('Network error: Unable to approve volunteer. Please check your connection and try again.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Get volunteer requests for a specific request (for request owners)
  /// ✅ NEW: Retrieves pending volunteer requests for approval workflow
  Future<List<Map<String, dynamic>>> getVolunteerRequests(String requestId) async {
    try {
      debugLog("📋 RequestController: Fetching volunteer requests for request $requestId");
      
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      // Call the request service to get volunteer requests
      final requests = await requestService.getVolunteerRequests(requestId);
      
      debugLog("✅ RequestController: Found ${requests.length} volunteer requests for request $requestId");
      return requests;
      
    } catch (e) {
      debugLog("💥 RequestController: Error fetching volunteer requests for $requestId - $e");
      throw Exception('Failed to load volunteer requests. Please try again.');
    }
  }

  @override
  void onClose() {
    titleController.value.dispose();
    descriptionController.value.dispose();
    locationController.value.dispose();
    numberOfPeopleController.value.dispose();
    hoursNeededController.value.dispose();
    selectedDateController.value.dispose();
    selectedTimeController.value.dispose();
    
    super.onClose();
  }
}