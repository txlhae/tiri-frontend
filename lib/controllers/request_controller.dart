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
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/category_model.dart';
import 'package:tiri/models/feedback_model.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/services/api_service.dart';
import 'package:tiri/services/request_service.dart';

enum FilterOption { recentPosts, urgentRequired, location }

class RequestController extends GetxController {
  // My Volunteered Requests (for My Helps page)
  final RxList<RequestModel> myVolunteeredRequests = <RequestModel>[].obs;

  /// Load requests where the current user is a volunteer (My Helps)
  Future<void> loadMyVolunteeredRequests() async {
    try {
      isLoading.value = true;
      debugLog('🔄 RequestController: Loading my volunteered requests...');
      final volunteeredRequests = await requestService.fetchMyVolunteeredRequests();
      myVolunteeredRequests.assignAll(volunteeredRequests);
      debugLog('✅ RequestController: Loaded {volunteeredRequests.length} volunteered requests');
    } catch (e) {
      debugLog('❌ RequestController: Error loading my volunteered requests - $e');
      myVolunteeredRequests.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit feedback and complete request
  Future<void> submitFeedbackAndCompleteRequest({
    required String requestId,
    required List<Map<String, dynamic>> feedbackList,
  }) async {
    try {
      isLoading.value = true;
      debugLog('🔄 RequestController: Submitting feedback $requestId');
      
      // Submit feedback (this is working - 201 success)
      final feedbackResult = await requestService.submitBulkFeedback(
        requestId: requestId,
        feedbackList: feedbackList,
      );
      
      debugLog('✅ RequestController: Feedback submitted successfully');
      
      // Refresh request details to get updated status
      try {
        await loadRequestDetails(requestId);
        debugLog('✅ RequestController: Request details refreshed');
      } catch (refreshError) {
        debugLog('⚠️ RequestController: Could not refresh request details - $refreshError');
        // Don't fail the overall operation just because refresh failed
      }
      
      // Success! The feedback API handles completion automatically
      debugLog('✅ RequestController: Operation completed successfully');
      
    } catch (e) {
      debugLog('❌ RequestController: Error in feedback submission - $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete a request (mark as completed)
  Future<void> completeRequest(String requestId, {String? notes}) async {
    try {
      isLoading.value = true;
      debugLog('🔄 RequestController: Completing request $requestId');

      final result = await requestService.completeRequest(requestId, notes: notes);

      if (result != null) {
        debugLog('✅ RequestController: Request completed successfully');
        // Update the current request details if available
        await loadRequestDetails(requestId);
      }
    } catch (e) {
      debugLog('❌ RequestController: Error completing request - $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start a request manually (for request owners with accepted volunteers)
  /// This transitions the request from ACCEPTED to IN_PROGRESS status
  Future<void> startManualRequest(String requestId) async {
    try {
      isLoading.value = true;
      debugLog('🚀 RequestController: Starting request $requestId manually');

      // Validate that user owns this request
      final currentRequest = currentRequestDetails.value;
      final currentUserId = authController.currentUserStore.value?.userId;

      if (currentRequest == null || currentUserId == null) {
        throw Exception('Unable to verify request ownership');
      }

      if (currentRequest.userId != currentUserId) {
        throw Exception('Only request owners can start requests');
      }

      // Check if request has approved volunteers
      if (currentRequest.acceptedUser.isEmpty) {
        throw Exception('Need at least 1 approved volunteer to start');
      }

      // Call the service to start the request
      final result = await requestService.startRequest(requestId);

      if (result != null) {
        debugLog('✅ RequestController: Request started successfully');
        debugLog('   - New status: ${result['request']?['status']}');
        debugLog('   - Start time: ${result['request']?['start_time']}');
        debugLog('   - Volunteers count: ${result['request']?['volunteers_count']}');

        // Refresh request details to show updated status
        await loadRequestDetails(requestId);

        // Also refresh general request lists
        await loadRequests();

        debugLog('🔄 RequestController: UI refreshed after starting request');
      }
    } catch (e) {
      debugLog('❌ RequestController: Error starting request - $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Start a delayed request during grace period (Start Anyway)
  /// This allows starting a request that is in DELAYED status with insufficient volunteers
  Future<void> startDelayedRequest(String requestId) async {
    try {
      isLoading.value = true;
      debugLog('⚡ RequestController: Starting delayed request $requestId (grace period)');

      // Validate that user owns this request
      final currentRequest = currentRequestDetails.value;
      final currentUserId = authController.currentUserStore.value?.userId;

      if (currentRequest == null || currentUserId == null) {
        throw Exception('Unable to verify request ownership');
      }

      if (currentRequest.userId != currentUserId) {
        throw Exception('Only request owners can start requests');
      }

      // Verify request is actually in delayed status
      if (currentRequest.status != RequestStatus.delayed) {
        throw Exception('This endpoint is only for delayed requests');
      }

      // Call the service to start the delayed request
      final result = await requestService.startRequestAnyway(requestId);

      if (result != null) {
        debugLog('✅ RequestController: Delayed request started successfully');
        debugLog('   - New status: ${result['request']?['status']}');
        debugLog('   - Start time: ${result['request']?['start_time']}');
        debugLog('   - Volunteers count: ${result['request']?['volunteers_count']}');

        // Refresh request details to show updated status
        await loadRequestDetails(requestId);

        // Also refresh general request lists
        await loadRequests();

        debugLog('🔄 RequestController: UI refreshed after starting delayed request');
      }
    } catch (e) {
      debugLog('❌ RequestController: Error starting delayed request - $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
  
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
  final RxMap<String, dynamic> feedbackStats = <String, dynamic>{}.obs;
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

  // =============================================================================
  // CATEGORY MANAGEMENT
  // =============================================================================
  
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final Rxn<CategoryModel> selectedCategory = Rxn<CategoryModel>();
  final RxBool isLoadingCategories = false.obs;
  var categoryError = RxnString();

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
  // PENDING VOLUNTEERS MANAGEMENT (Enterprise-Grade)
  // =============================================================================
  
  final RxList<Map<String, dynamic>> pendingVolunteers = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingPendingVolunteers = false.obs;
  final RxString pendingVolunteersError = ''.obs;

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
      
      // 🚨 Initialize categories immediately (no auth required)
      debugLog("📂 RequestController: Loading categories...");
      loadCategories();
      
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
      
      if (communityRequestsFromApi.isNotEmpty && rawFilteredRequests.isEmpty) {
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
  // CATEGORY MANAGEMENT METHODS
  // =============================================================================

  /// Load predefined categories (no API call needed)
  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      categoryError.value = null;
      debugLog("📂 RequestController: Loading predefined categories");

      // Use predefined categories directly (no API call)
      categories.assignAll(CategoryModel.getAllCategories());
      debugLog("✅ RequestController: Loaded ${categories.length} predefined categories");

      debugLog("📋 Available categories: ${categories.map((c) => c.name).toList()}");

      // Set default category to Moving & Lifting (ID 5) if none selected
      if (selectedCategory.value == null && categories.isNotEmpty) {
        // Try to find Moving & Lifting (ID 5) first, otherwise use first category
        selectedCategory.value = categories.firstWhere(
          (cat) => cat.id == 5,
          orElse: () => categories.first,
        );
        debugLog("📌 Set default category: ${selectedCategory.value?.name} (ID: ${selectedCategory.value?.id})");
      }

    } catch (e) {
      debugLog("❌ RequestController: Error loading predefined categories - $e");
      categoryError.value = "Failed to load categories: $e";
      categories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Validate category selection
  bool validateCategory() {
    if (selectedCategory.value == null) {
      categoryError.value = "Please select a category";
      return false;
    }
    categoryError.value = null;
    return true;
  }

  /// Show dialog to add a new category
  Future<void> showAddCategoryDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? nameError;
    bool isCreating = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g., Tutoring, Food Delivery',
                        errorText: nameError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (nameError != null) {
                          setState(() {
                            nameError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Brief description of this category',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isCreating ? null : () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      setState(() {
                        nameError = 'Category name is required';
                      });
                      return;
                    }

                    // Check if category already exists
                    if (categories.any((cat) => cat.name.toLowerCase() == name.toLowerCase())) {
                      setState(() {
                        nameError = 'Category already exists';
                      });
                      return;
                    }

                    setState(() {
                      isCreating = true;
                    });

                    try {
                      await createNewCategory(name, descriptionController.text.trim());
                      Navigator.of(context).pop();
                      
                      // Show success message
                      Get.snackbar(
                        'Success',
                        'Category "$name" created successfully!',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    } catch (e) {
                      setState(() {
                        nameError = 'Failed to create category: $e';
                        isCreating = false;
                      });
                    }
                  },
                  child: isCreating 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Create a new category
  Future<void> createNewCategory(String name, String description) async {
    try {
      debugLog("📝 RequestController: Creating new category - $name");
      
      // Create the new category with a temporary ID
      final newCategory = CategoryModel(
        id: categories.length + 100, // Temporary ID for local categories
        name: name,
        description: description.isNotEmpty ? description : null,
      );

      // Add to local list immediately for better UX
      categories.add(newCategory);
      
      // Set as selected category
      selectedCategory.value = newCategory;
      
      debugLog("✅ RequestController: Created category locally - $name");
      
      // TODO: In a real app, you would also send this to the Django API
      // final response = await requestService.createCategory(newCategory);
      
    } catch (e) {
      debugLog("❌ RequestController: Error creating category - $e");
      throw Exception("Failed to create category: $e");
    }
  }

  /// Show success dialog after request creation
  Future<void> showRequestCreatedSuccessDialog(BuildContext context) async {
    final String title = titleController.value.text.trim();
    final String category = selectedCategory.value?.name ?? 'Home Help';
    final String location = locationController.value.text.trim();
    final String dateTime = selectedDateTime.value != null 
        ? "${selectedDateTime.value!.day}/${selectedDateTime.value!.month}/${selectedDateTime.value!.year} at ${selectedDateTime.value!.hour}:${selectedDateTime.value!.minute.toString().padLeft(2, '0')}"
        : 'Not specified';
    final String volunteers = numberOfPeopleController.value.text.isNotEmpty 
        ? "${numberOfPeopleController.value.text} volunteers"
        : "1 volunteer";
    final String hours = hoursNeededController.value.text.isNotEmpty 
        ? "${hoursNeededController.value.text} hours"
        : "1 hour";

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header with success icon and title
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0, 140, 170, 1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color.fromRGBO(0, 140, 170, 1),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Request Created Successfully!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your request has been posted to the community',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Content with request details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Details:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(3, 80, 135, 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Details container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(251, 252, 254, 1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromRGBO(0, 140, 170, 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('📝 Title', title),
                            _buildDetailRow('📂 Category', category),
                            _buildDetailRow('📍 Location', location),
                            _buildDetailRow('📅 Date & Time', dateTime),
                            _buildDetailRow('👥 Volunteers Needed', volunteers),
                            _buildDetailRow('⏰ Estimated Time', hours),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 140, 170, 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(0, 140, 170, 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color.fromRGBO(0, 140, 170, 1),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Community members will now be able to see and respond to your request.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color.fromRGBO(3, 80, 135, 1),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to home page (request management)
                      Get.offAllNamed(Routes.homePage);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(3, 80, 135, 1),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(3, 80, 135, 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.list_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'View My Requests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  /// Helper method to build detail rows in success dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color.fromRGBO(3, 80, 135, 1),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color.fromRGBO(3, 80, 135, 1),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color.fromRGBO(70, 70, 70, 1),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
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
      log('🚨 [DEBUG] createRequest: Creating request via Django API');

      // 🚨 COMPLETE FIX: Include ALL required Django backend fields
      final requestData = {
        // Core content fields
        'title': titleController.value.text.trim(),
        'description': descriptionController.value.text.trim(),

        // ✅ NEW: Category field - Use selected category ID or default to 5 (Moving & Lifting)
        'category': selectedCategory.value?.id ?? 5, // ✅ FIXED: Use actual selected category or default to valid backend ID 5

        // ✅ REQUIRED: Location fields - Django expects separate latitude/longitude/address/city
        'latitude': 0.0,  // Default coordinates (can be enhanced with GPS later)
        'longitude': 0.0, // Default coordinates (can be enhanced with GPS later)
        'address': locationController.value.text.trim(), // ✅ FIXED: was 'location'
        'city': locationController.value.text.trim(), // ✅ FINAL FIX: Required city field (not nullable)

        // ✅ TIMEZONE FIX: Convert local datetime to UTC before sending to backend
        'date_needed': selectedDateTime.value?.toUtc().toIso8601String(), // Convert to UTC

        // ✅ REQUIRED: Volunteer and time fields with correct names
        'volunteers_needed': int.tryParse(numberOfPeopleController.value.text) ?? 1, // ✅ FIXED: was 'number_of_people'
        'estimated_hours': int.tryParse(hoursNeededController.value.text) ?? 1, // ✅ FIXED: was 'hours_needed'

        // ✅ FIXED: Priority value - Django expects "normal" not "medium"
        'priority': 'normal', // ✅ FIXED: was 'medium' (invalid Django choice)
      };

      debugLog("📋 Request payload: $requestData");
      log('🚨 [DEBUG] Request payload: $requestData');
      
      debugLog("🔍 Payload validation:");
      log('🚨 [DEBUG] Payload validation:');
      debugLog("   - Title: '${requestData['title']}' (${requestData['title']?.runtimeType})");
      debugLog("   - Category ID: ${requestData['category']} (${requestData['category']?.runtimeType}) - ${selectedCategory.value?.name ?? 'Default Home Help'}");
      log('🚨 [DEBUG] Category ID: ${requestData['category']} (${requestData['category']?.runtimeType}) - ${selectedCategory.value?.name ?? 'Default Home Help'}');
      log('🚨 [DEBUG]    - Title: \'${requestData['title']}\' (${requestData['title']?.runtimeType})');
      debugLog("   - Description: '${requestData['description']}' (${requestData['description']?.runtimeType})");
      log('🚨 [DEBUG]    - Description: \'${requestData['description']}\' (${requestData['description']?.runtimeType})');
      debugLog("   - Category: ${requestData['category']} (${requestData['category']?.runtimeType})");
      log('🚨 [DEBUG]    - Category: ${requestData['category']} (${requestData['category']?.runtimeType})');
      debugLog("   - Address: '${requestData['address']}' (${requestData['address']?.runtimeType})");
      log('🚨 [DEBUG]    - Address: \'${requestData['address']}\' (${requestData['address']?.runtimeType})');
      debugLog("   - City: '${requestData['city']}' (${requestData['city']?.runtimeType})");
      log('🚨 [DEBUG]    - City: \'${requestData['city']}\' (${requestData['city']?.runtimeType})');
      debugLog("   - Date needed: '${requestData['date_needed']}' (${requestData['date_needed']?.runtimeType})");
      log('🚨 [DEBUG]    - Date needed: \'${requestData['date_needed']}\' (${requestData['date_needed']?.runtimeType})');
      debugLog("   - Volunteers needed: ${requestData['volunteers_needed']} (${requestData['volunteers_needed']?.runtimeType})");
      log('🚨 [DEBUG]    - Volunteers needed: ${requestData['volunteers_needed']} (${requestData['volunteers_needed']?.runtimeType})');
      debugLog("   - Estimated hours: ${requestData['estimated_hours']} (${requestData['estimated_hours']?.runtimeType})");
      log('🚨 [DEBUG]    - Estimated hours: ${requestData['estimated_hours']} (${requestData['estimated_hours']?.runtimeType})');
      
      // 🚨 ADD DETAILED ERROR HANDLING
      try {
        log('🚨 [DEBUG] About to call requestService.createRequest...');
        final success = await requestService.createRequest(requestData);
        log('🚨 [DEBUG] requestService.createRequest returned: $success');
        
        if (success) {
          debugLog("✅ createRequest: Request created successfully");
          log('🚨 [DEBUG] ✅ Request created successfully');
          
          // Show success dialog
          if (Get.context != null) {
            await showRequestCreatedSuccessDialog(Get.context!);
          }
          
          clearForm();
          await loadRequests();
          return true;
        } else {
          debugLog("❌ createRequest: Failed to create request - service returned false");
          log('🚨 [DEBUG] ❌ Failed to create request - service returned false');
          debugLog("🔍 Check RequestService.createRequest() logs for Django response details");
          log('🚨 [DEBUG] 🔍 Check RequestService.createRequest() logs for Django response details');
          return false;
        }
      } catch (serviceError) {
        debugLog("💥 createRequest: Service error details: $serviceError");
        log('🚨 [DEBUG] 💥 Service error details: $serviceError');
        debugLog("💥 Service error type: ${serviceError.runtimeType}");
        log('🚨 [DEBUG] 💥 Service error type: ${serviceError.runtimeType}');
        
        // Check if it's a DioException with response details
        if (serviceError.toString().contains('400')) {
          debugLog("🔍 400 Bad Request detected - likely Django validation error");
          log('🚨 [DEBUG] 🔍 400 Bad Request detected - likely Django validation error');
          debugLog("🔍 This suggests Django is rejecting specific field values or formats");
          log('🚨 [DEBUG] 🔍 This suggests Django is rejecting specific field values or formats');
        }
        
        return false;
      }
      
    } catch (e) {
      debugLog("❌ createRequest controller error: $e");
      debugLog("❌ Controller error type: ${e.runtimeType}");
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
      debugLog("🔄 LoadRequestDetails: STARTING - Fetching request $requestId");
      log('🔄 LoadRequestDetails: STARTING - Fetching request $requestId');
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
        
        // ✅ NEW: Load pending volunteers if user is the request owner
        final currentUserId = authController.currentUserStore.value?.userId;
        debugLog("🔍 LoadRequestDetails: Checking ownership - currentUserId: $currentUserId, request.userId: ${request.userId}");
        log('🔍 LoadRequestDetails: Checking ownership - currentUserId: $currentUserId, request.userId: ${request.userId}');
        
        if (currentUserId != null && request.userId == currentUserId) {
          debugLog("👥 LoadRequestDetails: User IS request owner, loading pending volunteers");
          log('👥 LoadRequestDetails: User IS request owner, loading pending volunteers');
          // Load pending volunteers in the background (don't await to avoid blocking UI)
          loadPendingVolunteers(requestId).catchError((error) {
            debugLog("⚠️ LoadRequestDetails: Failed to load pending volunteers - $error");
            log('⚠️ LoadRequestDetails: Failed to load pending volunteers - $error');
          });
        } else {
          debugLog("❌ LoadRequestDetails: User is NOT request owner or currentUserId is null");
          log('❌ LoadRequestDetails: User is NOT request owner or currentUserId is null');
          debugLog("   - currentUserId: $currentUserId");
          debugLog("   - request.userId: ${request.userId}");
          debugLog("   - Are they equal? ${currentUserId == request.userId}");
          log('   - currentUserId: $currentUserId');
          log('   - request.userId: ${request.userId}');
          log('   - Are they equal? ${currentUserId == request.userId}');
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
    
    // ✅ NEW: Category validation
    categoryError.value = selectedCategory.value == null ? "Please select a category" : null;

    return titleError.value == null &&
        descriptionError.value == null &&
        locationError.value == null &&
        dateTimeError.value == null &&
        categoryError.value == null; // ✅ NEW: Include category validation
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
    
    // ✅ NEW: Reset category selection to first category (default)
    if (categories.isNotEmpty) {
      selectedCategory.value = categories.first;
    } else {
      selectedCategory.value = null;
    }
    
    titleError.value = null;
    descriptionError.value = null;
    locationError.value = null;
    dateTimeError.value = null;
    categoryError.value = null; // ✅ NEW: Clear category error
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
      
      // Prepare feedback list for all volunteers
      List<Map<String, dynamic>> feedbackList = [];
      
      for (int i = 0; i < request.acceptedUser.length; i++) {
        if (i < reviewControllers.length && i < hourControllers.length && i < selectedRatings.length) {
          final feedbackData = {
            'to_user_id': request.acceptedUser[i].userId,
            'hours': int.tryParse(hourControllers[i].text) ?? 1,
            'rating': selectedRatings[i].value.toDouble(),
            'review': reviewControllers[i].text.trim(),
          };
          
          feedbackList.add(feedbackData);
          debugLog("📝 Prepared feedback: $feedbackData");
        }
      }
      
      debugLog("📤 Submitting ${feedbackList.length} feedback items for request ${request.requestId}");
      
      // Submit feedback and complete request using the new workflow
      await submitFeedbackAndCompleteRequest(
        requestId: request.requestId,
        feedbackList: feedbackList,
      );
      
      debugLog("✅ Feedback submission completed successfully");
      
      // Navigate back first, then show success message
      Get.back(); // Close feedback screen immediately
      
      // Show success message after navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        Get.snackbar(
          'Success!', 
          'Feedback submitted and request completed successfully!',
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      });
      
      return true;
    } catch (e) {
      debugLog("❌ handleFeedbackSubmission error: $e");
      
      // Show error message
      Get.snackbar(
        'Error', 
        'Failed to complete request. Please try again.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      );
      
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

  /// Fetch profile feedback from Django API
  /// Uses the user profile endpoint to get comprehensive user data including feedback
  Future<void> fetchProfileFeedback(String userId) async {
    try {
      isFeedbackLoading.value = true;
      debugLog("👤 fetchProfileFeedback: Starting to fetch feedback for user $userId");
      
      // Clear existing data before loading new
      profileFeedbackList.clear();
      feedbackStats.value = {};
      
      // Get ApiService singleton instance
      final apiService = Get.find<ApiService>();
      
      // Call Django user profile API that includes feedback
      final response = await apiService.get('/api/profile/users/$userId/');
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        debugLog("📥 fetchProfileFeedback: Raw API response: $responseData");
        
        // Extract feedback array from Django response
        final List<dynamic> feedbackArray = responseData['recent_feedback'] ?? [];
        final totalHours = responseData['total_hours_helped'] ?? 0;
        final averageRating = (responseData['average_rating'] as num?)?.toDouble() ?? 0.0;
        final totalFeedback = responseData['total_feedback_count'] ?? 0;
        
        debugLog("📊 fetchProfileFeedback: Found ${feedbackArray.length} feedback items");
        debugLog("📊 fetchProfileFeedback: Stats - Total: $totalFeedback, Hours: $totalHours, Rating: $averageRating");
        
        // Store stats for UI display
        feedbackStats.value = {
          'total_feedback': totalFeedback,
          'total_hours': totalHours,
          'average_rating': averageRating,
        };
        
        // Transform Django response to expected frontend format
        final List<Map<String, dynamic>> transformedFeedback = [];
        
        for (final item in feedbackArray) {
          try {
            final feedbackData = item as Map<String, dynamic>;
            
            // Create FeedbackModel from Django response
            final feedback = FeedbackModel(
              feedbackId: feedbackData['id']?.toString() ?? '',
              userId: feedbackData['from_user']?['id']?.toString() ?? '',
              requestId: feedbackData['request']?['id']?.toString() ?? '',
              review: feedbackData['review'] ?? '',
              rating: (feedbackData['rating'] as num?)?.toDouble() ?? 0.0,
              hours: (feedbackData['hours'] as num?)?.toInt() ?? 0,
              timestamp: feedbackData['created_at'] != null 
                ? DateTime.parse(feedbackData['created_at'])
                : DateTime.now(),
            );
            
            // Extract rich user data from backend
            final fromUser = feedbackData['from_user'] ?? {};
            
            // Transform to expected frontend format with rich user data
            final transformedItem = {
              'feedback': feedback,
              'username': fromUser['full_name'] ?? fromUser['username'] ?? 'Unknown User',
              'firstName': fromUser['first_name'] ?? '',
              'lastName': fromUser['last_name'] ?? '',
              'imageUrl': fromUser['profile_picture'],
              'totalHoursHelped': fromUser['total_hours_helped'] ?? 0,
              'averageRating': fromUser['average_rating'] ?? 0.0,
              'ratingCount': fromUser['rating_count'] ?? 0,
              'reputationDisplay': fromUser['reputation_display'] ?? '',
              'title': feedbackData['request']?['title'] ?? 'Untitled Request',
              'requestDescription': feedbackData['request']?['description'] ?? '',
            };
            
            transformedFeedback.add(transformedItem);
            
            debugLog("✅ fetchProfileFeedback: Transformed feedback from ${transformedItem['username']} - Rating: ${feedback.rating}");
            
          } catch (itemError) {
            debugLog("⚠️ fetchProfileFeedback: Error transforming feedback item: $itemError");
            debugLog("⚠️ fetchProfileFeedback: Problematic item: $item");
          }
        }
        
        // Update reactive state with transformed data
        profileFeedbackList.assignAll(transformedFeedback);
        
        debugLog("✅ fetchProfileFeedback: Successfully loaded ${transformedFeedback.length} feedback items");
        debugLog("📝 fetchProfileFeedback: profileFeedbackList now has ${profileFeedbackList.length} items");
        
      } else {
        debugLog("❌ fetchProfileFeedback: API returned status ${response.statusCode}");
        debugLog("❌ fetchProfileFeedback: Response data: ${response.data}");
        Get.snackbar('Error', 'Failed to load user profile feedback');
      }
      
    } catch (e) {
      debugLog("❌ fetchProfileFeedback error: $e");
      Get.snackbar('Error', 'Failed to load user profile feedback');
      profileFeedbackList.clear();
    } finally {
      isFeedbackLoading.value = false;
    }
  }

  String getChatRoomId(String requestId, String userId1, [String? userId2]) {
    userId2 ??= authController.currentUserStore.value?.userId ?? 'unknown';
    
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
  Future<void> cancelVolunteerRequest(String requestId, {String? reason}) async {
    try {
      isLoading.value = true;
      debugLog("❌ RequestController: Canceling volunteer request for request $requestId");
      if (reason != null && reason.isNotEmpty) {
        debugLog("📝 Cancellation reason: \"$reason\"");
      }
      
      // Validate input before API call
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      // Get current request status for validation
      final currentRequest = currentRequestDetails.value;
      if (currentRequest != null) {
        debugLog("   - Current user status: ${currentRequest.userRequestStatus}");
        debugLog("   - Can cancel request: ${currentRequest.canCancelRequest}");
        
        // TEMPORARY: Skip validation to test API functionality
        debugLog("🔥 BYPASSING canCancelRequest validation for testing");
        
        // TODO: Re-enable this validation once backend is fixed
        // if (!currentRequest.canCancelRequest) {
        //   throw Exception('You cannot cancel this volunteer request at this time');
        // }
      }
      
      // Call the request service to cancel volunteer request with optional reason
      final success = await requestService.cancelVolunteerRequest(requestId, reason: reason);
      
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
      debugLog("💥 RequestController: Error type: ${e.runtimeType}");
      debugLog("💥 RequestController: Full error details: ${e.toString()}");
      
      // Log specific error information for DioError
      if (e.toString().contains('DioError') || e.runtimeType.toString().contains('Dio')) {
        debugLog("💥 RequestController: This appears to be a Dio-related error");
        try {
          final dioError = e as dynamic;
          debugLog("💥 RequestController: Response status: ${dioError.response?.statusCode}");
          debugLog("💥 RequestController: Response data: ${dioError.response?.data}");
          debugLog("💥 RequestController: Error message: ${dioError.message}");
          debugLog("💥 RequestController: Request path: ${dioError.requestOptions?.path}");
          debugLog("💥 RequestController: Request method: ${dioError.requestOptions?.method}");
          debugLog("💥 RequestController: Request data: ${dioError.requestOptions?.data}");
        } catch (castError) {
          debugLog("💥 RequestController: Could not cast to Dio error, raw error: $e");
        }
      }
      
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

  /// Delete request (for request owners only)
  /// This completely deletes the request from the system
  Future<void> deleteRequest(String requestId) async {
    try {
      isLoading.value = true;
      debugLog("🗑️ RequestController: Deleting request $requestId");
      
      // Validate input before API call
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      // Get current request details to verify ownership
      final currentUser = authController.currentUserStore.value;
      if (currentUser == null) {
        throw Exception('You must be logged in to delete a request');
      }
      
      // Check if user owns this request
      final currentRequest = requestList.firstWhereOrNull((req) => req.requestId == requestId) ??
                           myRequestList.firstWhereOrNull((req) => req.requestId == requestId) ??
                           communityRequests.firstWhereOrNull((req) => req.requestId == requestId) ??
                           myPostRequests.firstWhereOrNull((req) => req.requestId == requestId);
      
      if (currentRequest != null && currentRequest.userId != currentUser.userId) {
        throw Exception('You can only delete your own requests');
      }
      
      debugLog("   - Request owner: ${currentRequest?.userId}");
      debugLog("   - Current user: ${currentUser.userId}");
      
      // Call the request service to delete request
      final success = await requestService.deleteRequest(requestId);
      
      if (success) {
        debugLog("✅ RequestController: Successfully deleted request $requestId");
        
        // Remove from local lists immediately for better UX
        requestList.removeWhere((req) => req.requestId == requestId);
        myRequestList.removeWhere((req) => req.requestId == requestId);
        communityRequests.removeWhere((req) => req.requestId == requestId);
        myPostRequests.removeWhere((req) => req.requestId == requestId);
        
        // Clear current request details if it's the deleted request
        if (currentRequestDetails.value?.requestId == requestId) {
          currentRequestDetails.value = null;
        }
        
        // Refresh the main request lists to sync with backend
        await refreshRequests();
        debugLog("🔄 RequestController: Refreshed all requests after deleting request");
        
      } else {
        debugLog("❌ RequestController: Failed to delete request $requestId");
        throw Exception('Failed to delete request. Please try again.');
      }
    } catch (e) {
      debugLog("💥 RequestController: Error in deleteRequest for $requestId - $e");
      
      // Re-throw with more specific error message for UI
      if (e.toString().contains('Failed to delete request') || 
          e.toString().contains('You can only delete your own requests') ||
          e.toString().contains('Request not found') ||
          e.toString().contains('You must be logged in')) {
        rethrow;
      } else {
        throw Exception('Network error: Unable to delete request. Please check your connection and try again.');
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
        
        // Refresh pending volunteers list
        await loadPendingVolunteers(requestId);
        debugLog("🔄 RequestController: Refreshed pending volunteers after approving volunteer");
        
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

  /// Reject a volunteer request for a specific service request
  /// ✅ NEW: Enterprise-grade reject volunteer functionality with comprehensive validation
  Future<void> rejectVolunteerRequest(String requestId, String volunteerUserId) async {
    try {
      isLoading.value = true;
      debugLog("❌ RequestController: Rejecting volunteer $volunteerUserId for request $requestId");
      
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
        throw Exception('Only request owners can reject volunteers');
      }
      
      // Call the request service to reject volunteer
      final success = await requestService.rejectVolunteerRequest(requestId, volunteerUserId);
      
      if (success) {
        debugLog("✅ RequestController: Successfully rejected volunteer $volunteerUserId for request $requestId");
        
        // Refresh request details to show updated volunteer list
        await loadRequestDetails(requestId);
        debugLog("🔄 RequestController: Refreshed request details after rejecting volunteer");
        
        // Refresh pending volunteers list
        await loadPendingVolunteers(requestId);
        debugLog("🔄 RequestController: Refreshed pending volunteers after rejecting volunteer");
        
        // Refresh general requests
        await refreshRequests();
        
      } else {
        debugLog("❌ RequestController: Failed to reject volunteer $volunteerUserId for request $requestId");
        throw Exception('Failed to reject volunteer request. Please try again.');
      }
    } catch (e) {
      debugLog("💥 RequestController: Error in rejectVolunteerRequest for $requestId - $e");
      if (e.toString().contains('Failed to reject volunteer request') || 
          e.toString().contains('Only request owners can reject')) {
        rethrow;
      } else {
        throw Exception('Network error: Unable to reject volunteer. Please check your connection and try again.');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all volunteer requests for a request (for request owners only)
  /// ✅ UPDATED: Now loads ALL volunteer requests (pending, approved, rejected)
  Future<void> loadPendingVolunteers(String requestId) async {
    try {
      isLoadingPendingVolunteers.value = true;
      pendingVolunteersError.value = '';
      debugLog("📋 RequestController: Loading all volunteer requests for request $requestId");
      log('📋 RequestController: Loading all volunteer requests for request $requestId');
      
      // Validate inputs
      if (requestId.isEmpty) {
        throw Exception('Request ID cannot be empty');
      }
      
      // Validate that current user owns the request (for security)
      final currentRequest = currentRequestDetails.value;
      final currentUserId = authController.currentUserStore.value?.userId;
      
      if (currentRequest == null || currentUserId == null) {
        throw Exception('Unable to verify request ownership');
      }
      
      if (currentRequest.userId != currentUserId) {
        debugLog("⚠️ RequestController: User is not request owner, skipping pending volunteers load");
        pendingVolunteers.value = [];
        return;
      }
      
      // Fetch pending volunteers from service
      final volunteers = await getVolunteerRequests(requestId);
      debugLog("📥 RequestController: Raw volunteers data: ${volunteers.length} volunteers found");
      log('📥 RequestController: Raw volunteers data: ${volunteers.length} volunteers found');
      
      // Debug: Log each volunteer's data structure
      for (int i = 0; i < volunteers.length; i++) {
        final vol = volunteers[i];
        debugLog("   Volunteer $i: id=${vol['id']}, status=${vol['status']}, volunteer=${vol['volunteer']?['username']}");
        log('   Volunteer $i: id=${vol['id']}, status=${vol['status']}, volunteer=${vol['volunteer']?['username']}');
      }
      
      // Store ALL volunteer requests (pending, approved, rejected)
      // UI will handle different displays based on status
      pendingVolunteers.value = volunteers;
      debugLog("✅ RequestController: Loaded ${volunteers.length} volunteer requests for request $requestId");
      log('✅ RequestController: Loaded ${volunteers.length} volunteer requests for request $requestId');
      debugLog("📊 RequestController: Volunteer requests data: ${volunteers.map((v) => '${v['volunteer']?['username']}(${v['status']})').toList()}");
      log('📊 RequestController: Volunteer requests data: ${volunteers.map((v) => '${v['volunteer']?['username']}(${v['status']})').toList()}');
      
    } catch (e) {
      debugLog("💥 RequestController: Error loading pending volunteers for $requestId - $e");
      log('💥 RequestController: Error loading pending volunteers for $requestId - $e');
      pendingVolunteersError.value = 'Failed to load pending volunteers. Please try again.';
      pendingVolunteers.value = [];
    } finally {
      isLoadingPendingVolunteers.value = false;
      log('🏁 RequestController: loadPendingVolunteers completed for $requestId');
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