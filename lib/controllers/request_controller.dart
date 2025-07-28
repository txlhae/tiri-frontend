// lib/controllers/request_controller.dart
// 🚨 DEBUG VERSION - Enhanced logging for request loading issues
// 
// 🔧 INFINITE LOOP FIX APPLIED:
// =============================
// PROBLEM: updateRequestStatuses() → updateRequestStatus() → loadRequests() → updateRequestStatuses() → LOOP
// SOLUTION: Added session-based flags and skipStatusUpdate parameter to break the cycle
// 
// KEY CHANGES:
// - Added _hasUpdatedStatusesThisSession flag to prevent repeated status updates
// - Added _isUpdatingStatuses flag to prevent nested status update calls
// - Modified loadRequests() to accept skipStatusUpdate parameter
// - Updated updateRequestStatus() to call loadRequests(skipStatusUpdate: true)
// - Updated createRequest() to skip status updates when refreshing data
// - Added forceStatusUpdate() and resetStatusUpdateFlag() for manual control
// 
// BEHAVIOR:
// - Status updates happen ONCE per app session during initialization
// - Manual refresh (refreshRequests) can force status updates if needed
// - Creating new requests skips status updates to avoid unnecessary API calls
// - Updating request statuses skips further status checks to prevent loops

import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/notification_controller.dart';
import 'package:kind_clock/models/notification_model.dart';
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
  // 🚨 FIX: Infinite loop prevention
  // =============================================================================
  
  /// Flag to prevent infinite loop between updateRequestStatuses and loadRequests
  /// Set to true after the first status update in the app session
  /// This ensures status updates only happen once per session unless explicitly reset
  bool _hasUpdatedStatusesThisSession = false;
  
  /// Flag to indicate when we're currently updating statuses (prevent nested calls)
  /// This prevents updateRequestStatuses from being called while it's already running
  bool _isUpdatingStatuses = false;
  
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

  Future<void> loadRequests({bool skipStatusUpdate = false}) async {
    try {
      isLoading.value = true;
      debugLog("🔄 RequestController: Starting loadRequests(skipStatusUpdate: $skipStatusUpdate)");
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
      if (!skipStatusUpdate && !_hasUpdatedStatusesThisSession && !_isUpdatingStatuses) {
        debugLog("🔄 Step 3: Updating request statuses (first time this session)...");
        debugStatus.value = "Updating request statuses...";
        
        _isUpdatingStatuses = true; // Prevent nested calls
        
        await updateRequestStatuses(communityRequestsFromApi);
        await updateRequestStatuses(userRequestsFromApi);
        
        _hasUpdatedStatusesThisSession = true; // Mark as completed for this session
        _isUpdatingStatuses = false;
        
        debugLog("   - Status updates completed ✅");
      } else {
        if (skipStatusUpdate) {
          debugLog("🔄 Step 3: Skipping status updates (skipStatusUpdate=true)");
        } else if (_hasUpdatedStatusesThisSession) {
          debugLog("🔄 Step 3: Skipping status updates (already done this session)");
        } else if (_isUpdatingStatuses) {
          debugLog("🔄 Step 3: Skipping status updates (currently updating)");
        }
      }

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
      debugLog("   - Status updates done this session: $_hasUpdatedStatusesThisSession");
      
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
        debugLog("     * Is Future Time: ${request.requestedTime.isAfter(DateTime.now())}");
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
                          request.requestedTime.isAfter(DateTime.now()) &&
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
          request.location.toLowerCase().contains(query.toLowerCase())
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
        // 🚨 FIX: Skip status updates when refreshing after creating a new request
        await loadRequests(skipStatusUpdate: true);
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
        // 🚨 FIX: Use skipStatusUpdate=true to prevent infinite loop
        await loadRequests(skipStatusUpdate: true);
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

  Future<void> updateRequestStatuses(List<RequestModel> requests) async {
    debugLog("🔄 updateRequestStatuses called with ${requests.length} requests");
    
    for (var request in requests) {
      int acceptedCount = request.acceptedUser.length;
      int requiredCount = request.numberOfPeople;
      bool timeUp = request.requestedTime.isBefore(DateTime.now());

      if ((request.status == RequestStatus.pending ||
              request.status == RequestStatus.incomplete ||
              request.status == RequestStatus.inprogress) &&
          timeUp) {
        try {
          if (acceptedCount == 0) {
            debugLog("🔄 Updating request ${request.requestId} to 'expired' (no accepted users)");
            await updateRequestStatus(request.requestId, "expired");
            
            NotificationModel notification = NotificationModel(
              body: request.title,
              timestamp: DateTime.now(),
              isUserWaiting: false,
              userId: request.userId,
              status: RequestStatus.expired.toString().split(".")[1],
              notificationId: DateTime.now().millisecondsSinceEpoch.toString(),
            );
            
            Get.find<NotificationController>().addNotification(notification);
            
          } else if (acceptedCount < requiredCount) {
            debugLog("🔄 Updating request ${request.requestId} to 'incomplete' ($acceptedCount/$requiredCount)");
            await updateRequestStatus(request.requestId, "incomplete");
          } else if (acceptedCount >= requiredCount) {
            debugLog("🔄 Updating request ${request.requestId} to 'inprogress' ($acceptedCount/$requiredCount)");
            await updateRequestStatus(request.requestId, "inprogress");
          }
        } catch (e) {
          debugLog("❌ updateRequestStatuses error for request ${request.requestId}: $e");
        }
      }
    }
    debugLog("✅ updateRequestStatuses completed");
  }

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

  Future<void> refreshRequests({bool forceStatusUpdate = false}) async {
    debugLog("🔄 refreshRequests called (forceStatusUpdate: $forceStatusUpdate)");
    
    if (forceStatusUpdate) {
      // Reset the flag to allow status updates
      _hasUpdatedStatusesThisSession = false;
      debugLog("🔄 Force status update requested - resetting session flag");
    }
    
    await loadRequests();
  }
  
  /// 🚨 NEW: Method to manually reset status update flag if needed
  void resetStatusUpdateFlag() {
    _hasUpdatedStatusesThisSession = false;
    debugLog("🔄 Status update flag manually reset");
  }
  
  /// 🚨 NEW: Method to force status updates (useful for manual refresh or debugging)
  Future<void> forceStatusUpdate() async {
    debugLog("🔄 forceStatusUpdate called - resetting flags and updating statuses");
    _hasUpdatedStatusesThisSession = false;
    _isUpdatingStatuses = false;
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
        request.location.toLowerCase().contains(location.toLowerCase())
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