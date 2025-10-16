import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/chat_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/controllers/request_details_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/models/user_model.dart';
import 'package:tiri/screens/profile_screen.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/dialog_widgets/intrested_dialog.dart';
import 'package:tiri/screens/widgets/request_widgets/details_card.dart';
import 'package:tiri/screens/widgets/request_widgets/details_row.dart';
import 'package:tiri/screens/widgets/request_widgets/status_row.dart';
import 'package:shimmer/shimmer.dart';

class RequestDetails extends StatefulWidget {
  const RequestDetails({super.key});

  @override
  State<RequestDetails> createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  final RequestController requestController = Get.find<RequestController>();
  final AuthController authController = Get.find<AuthController>();
  late final RequestDetailsController detailsController;

  /// Convert RequestStatus enum to user-friendly display string
  /// 🎨 HELPER: Maps status enum to proper display names for UI
  /// - Handles "inprogress" as "IN PROGRESS"
  /// - Handles "delayed" (formerly "expired") with proper warning color
  /// - Maintains proper capitalization
  /// - Works with StatusRow color scheme
  String getStatusDisplayName(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.inprogress:
        return 'IN PROGRESS';
      case RequestStatus.accepted:
        return 'ACCEPTED';
      case RequestStatus.complete:
        return 'COMPLETED';
      case RequestStatus.incomplete:
        return 'INCOMPLETE';
      case RequestStatus.delayed:
        return 'DELAYED';
      case RequestStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  void initState() {
    super.initState();
    detailsController = Get.put(RequestDetailsController());
    
    // Get requestId from navigation arguments with enhanced validation
    final arguments = Get.arguments;
    final String? requestId = arguments is Map<String, dynamic> 
        ? arguments['requestId']?.toString()
        : null;
    
    // ✅ FIX: Move reactive updates to post-frame to prevent setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      // ALWAYS refresh data, even if cached - for testing volunteer mapping
      if (requestId != null && requestId.isNotEmpty && requestId.trim().isNotEmpty) {
        try {
          // Load request details after build completes with error handling
          await requestController.loadRequestDetails(requestId);
        } catch (e) {
      // Error handled silently
          // Handle loading errors gracefully
          if (mounted) {
            Get.snackbar(
              'Loading Error',
              'Failed to load request details. Please try again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade600,
              colorText: Colors.white,
              margin: const EdgeInsets.all(16),
            );
          }
        }
      } else {
        // Handle error case where no valid requestId is provided
        requestController.currentRequestDetails.value = null;
        requestController.isLoadingRequestDetails.value = false;
        
        if (mounted) {
          Get.snackbar(
            'Navigation Error',
            'Invalid request. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade600,
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
          );
        }
      }
    });
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final request = detailsController.requestModel.value ?? widget.request;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: DeferredPointerHandler(
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
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CustomBackButton(
                        controller: requestController,
                      ),
                      const Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.only(right: 48),
                            child: Text(
                              'Request Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Get requestId from navigation arguments
                    final arguments = Get.arguments;
                    final String? requestId = arguments is Map<String, dynamic>
                        ? arguments['requestId']?.toString()
                        : null;

                    if (requestId != null && requestId.isNotEmpty) {
                      await requestController.loadRequestDetails(requestId);
                      // Also reload pending volunteers if user is the request owner
                      final request = requestController.currentRequestDetails.value;
                      if (request != null && request.userId == authController.currentUserStore.value?.userId) {
                        await requestController.loadPendingVolunteers(requestId);
                      }
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Obx(() {
                      if (requestController.isLoadingRequestDetails.value) {
                        return _buildLoadingContent();
                      }

                      return _buildLoadedContent();
                    }),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 10),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 20),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
              const SizedBox(height: 16),
              _buildShimmerPlaceholder(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadedContent() {
    final request = requestController.currentRequestDetails.value;
    final currentUser = authController.currentUserStore.value;
    
    
    // Enhanced error state handling with multiple scenarios
    if (request == null) {
      return _buildErrorState(
        icon: Icons.error_outline,
        title: 'Request not found',
        message: 'The request you are looking for does not exist or has been removed.',
        buttonText: 'Go Back',
        onPressed: () => Get.back(),
      );
    }

    // Check for authentication issues
    if (currentUser == null) {
      return _buildErrorState(
        icon: Icons.account_circle_outlined,
        title: 'Authentication Required',
        message: 'Please log in to view request details.',
        buttonText: 'Go to Login',
        onPressed: () => Get.offAllNamed('/login'),
      );
    }

    final currentUserId = currentUser.userId;
    
    // 🚨 FIXED: Enhanced user data validation with retry mechanism
    if (currentUserId.isEmpty) {
      // Instead of immediately showing error, try to refresh user data first
      return _buildUserDataRefreshState();
    }

    return Column(
      children: [
        DetailsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (request.userId ==
                          authController.currentUserStore.value?.userId &&
                      request.status != RequestStatus.complete &&
                      request.status != RequestStatus.delayed &&
                      (request.requestedTime ?? request.timestamp).isAfter(DateTime.now()))
                    IconButton(
                      onPressed: () {
                        Get.toNamed(
                          Routes.editAddRequestPage,
                          arguments: {'request': request},
                        );
                      },
                      icon:
                          SvgPicture.asset('assets/icons/edit_underscore.svg'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                "Description:",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                request.description,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
              const SizedBox(height: 10),
              const Text(
                "Date and Time",
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat('dd/MM/yyyy \'at\' h:mm a').format(request.requestedTime ?? request.timestamp),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
                const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.person,
                label: "Posted by",
                value: request.requester?.displayName ?? "Unknown User",
              ),
              const SizedBox(height: 16),
              DetailsRow(
                icon: Icons.person,
                label: "Referred by",
                value: request.requester?.referralUserId != null ? "Referred User" : "N/A",
              ),
              const SizedBox(height: 16),
              DetailsRow(
                icon: Icons.location_on,
                label: "Location",
                value: request.location ?? 'Location not specified',
              ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.access_time,
                label: "Posted on",
                value: DateFormat('dd/MM/yyyy \'at\' h:mm a').format(request.timestamp),
              ),
              const SizedBox(height: 12),
              StatusRow(
                label: "Status",
                status: getStatusDisplayName(request.status),
              ),
              const SizedBox(height: 16),   
                DetailsRow(
                  icon: Icons.timer,
                  label: "Hours Needed",
                  value: request.hoursNeeded.toString(),
                ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.group,
                label: "No. of People wanted ",
                value: request.numberOfPeople.toString(),
              ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.people_outline,
                label: "Accepted Users",
                value: (() {
                  return request.acceptedUser.length.toString();
                })(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Show feedback section if request is completed
        if (request.status == RequestStatus.complete && request.feedback != null)
          _buildFeedbackSection(request),
               // Volunteer Status Section - Show for all non-owners to enable chat
               // Show for all volunteers regardless of request status (even pending, rejected, etc.)
               if (request.userId != currentUserId)
          Column(
            children: [
              _buildVolunteerStatusSection(request),
              const SizedBox(height: 20),
            ],
          ),

        // 👥 VOLUNTEER REQUESTS SECTION (for request owners only)
        if (request.userId == currentUserId)
          Obx(() => Column(
            children: [
              DetailsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Volunteer Requests",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${requestController.pendingVolunteers.length}",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (requestController.isLoadingPendingVolunteers.value)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (requestController.pendingVolunteers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "No volunteer requests yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Volunteer requests will appear here when people apply",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...requestController.pendingVolunteers.map((volunteer) => 
                        _buildVolunteerRequestCard(volunteer, request.requestId)
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          )),



        //volunteer button with dynamic states - hide for completed requests
        if (request.status != RequestStatus.complete)
          Builder(
            builder: (context) {
              return _buildVolunteerButton(request);
            },
          ),

        // Start Request button for request owners (ACCEPTED status only)
        if (request.status == RequestStatus.accepted &&
            authController.currentUserStore.value?.userId == request.userId &&
            request.acceptedUser.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: requestController.isLoading.value ? null : () async {
                  try {
                    await requestController.startManualRequest(request.requestId);
                    Get.snackbar(
                      'Success',
                      'Request started successfully! Work can now begin.',
                      backgroundColor: Colors.green.shade600,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    );
                  } catch (e) {
      // Error handled silently
                    Get.snackbar(
                      'Error',
                      e.toString().replaceAll('Exception: ', ''),
                      backgroundColor: Colors.red.shade600,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    );
                  }
                },
                icon: requestController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow, size: 24),
                label: Text(
                  requestController.isLoading.value ? "Starting..." : "Start Request",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(34, 139, 34, 1), // Forest green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            )),
          ),

        // Start Anyway button for request owners (DELAYED status only)
        if (request.status == RequestStatus.delayed &&
            authController.currentUserStore.value?.userId == request.userId)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Column(
              children: [
                // Warning message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Request Delayed",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Not enough volunteers, but you can start anyway during grace period",
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Start Anyway button
                Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: requestController.isLoading.value ? null : () async {
                      // Show confirmation dialog
                      final confirmed = await Get.dialog<bool>(
                        AlertDialog(
                          title: const Text('Start Anyway?'),
                          content: const Text(
                            'This request does not have enough volunteers. Are you sure you want to start it anyway?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                              ),
                              child: const Text('Start Anyway'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        try {
                          await requestController.startDelayedRequest(request.requestId);
                          Get.snackbar(
                            'Success',
                            'Request started with available volunteers!',
                            backgroundColor: Colors.green.shade600,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 3),
                          );
                        } catch (e) {
      // Error handled silently
                          Get.snackbar(
                            'Error',
                            e.toString().replaceAll('Exception: ', ''),
                            backgroundColor: Colors.red.shade600,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 4),
                          );
                        }
                      }
                    },
                    icon: requestController.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.flash_on, size: 24),
                    label: Text(
                      requestController.isLoading.value ? "Starting..." : "Start Anyway",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                )),
              ],
            ),
          ),

        // Complete Request button for request owners at the bottom (IN_PROGRESS only)
        if (request.status == RequestStatus.inprogress &&
            authController.currentUserStore.value?.userId == request.userId)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToFeedbackScreen(request);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 140, 170, 1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Complete Request",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds dynamic volunteer button based on user request status
  Widget _buildVolunteerButton(RequestModel request) {
    final currentUser = authController.currentUserStore.value;
    
    // Don't show any buttons for completed requests
    if (request.status == RequestStatus.complete) {
      return Container();
    }
    
    // 1. Show delete button if user owns the request ✅
    if (request.userId == currentUser?.userId) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: _buildOwnerDeleteButton(request),
      );
    }
    
    // 2. Check if current user has already volunteered (pending/approved) ✅
    // Show user's volunteer status REGARDLESS of whether request is "full"
    final userRequestStatus = request.userRequestStatus;
    final canRequest = request.canRequest;
    final canCancelRequest = request.canCancelRequest;
    final hasVolunteered = request.hasVolunteered;
    final volunteerMessage = request.volunteerMessage;
    
    // Check if user is already an accepted volunteer (in acceptedUser list)
    final isAcceptedVolunteer = request.acceptedUser.any(
      (user) => user.userId == currentUser?.userId
    );
    
    if (isAcceptedVolunteer) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: _buildApprovedRequestState(request),
      );
    }
    
    // Check for pending volunteer status (user has volunteered but not yet accepted)
    if (userRequestStatus == 'pending' || 
        (hasVolunteered && canCancelRequest) ||
        (volunteerMessage != null && volunteerMessage.isNotEmpty)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: _buildPendingRequestState(request),
      );
    }
    
    // Check for approved/accepted status that might not be in acceptedUser list yet
    if (userRequestStatus == 'approved' || userRequestStatus == 'accepted') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: _buildApprovedRequestState(request),
      );
    }
    
    // 3. ONLY NOW check if request is full for NEW volunteers ✅
    if (request.acceptedUser.length >= request.numberOfPeople) {
      return Container();
    }
    
    // 4. Show "I'm Interested" button for new volunteers ✅
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: _buildInitialRequestState(request, canRequest),
    );
  }

  /// Builds the pending request state UI with status and cancel option
  Widget _buildPendingRequestState(RequestModel request) {
    // 🔍 NEW: Get the actual volunteer status from backend
    final actualVolunteerStatus = _getCurrentUserVolunteerStatus(request);

    // For approved status, don't show the status card - the "Accepted by" section will handle it
    if (actualVolunteerStatus?.toLowerCase() == 'approved') {
      // Return the cancel button for approved volunteers
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: requestController.isLoading.value ? null : () async {

              // Show cancel reason dialog
              final String? reason = await _showCancelReasonDialog();


              // If user didn't cancel the dialog
              if (reason != null) {
                try {
                  await requestController.cancelVolunteerRequest(request.requestId, reason: reason);

                  Get.snackbar(
                    'Success',
                    'Your volunteer request has been cancelled',
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade700,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  );
                } catch (e) {
      // Error handled silently
                  Get.snackbar(
                    'Error',
                    'Failed to cancel request. Please try again.',
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.red.shade700,
                  );
                }
              } else {
              }
            },
            icon: requestController.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(requestController.isLoading.value ? "Canceling..." : "Cancel Request"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      );
    }

    // Note: Status variables removed as they were unused after assignment

    return Column(
      children: [
        // Chat button for pending volunteers - NEW FEATURE
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          child: ElevatedButton.icon(
            onPressed: () async {
              final currentUserId = authController.currentUserStore.value?.userId;
              final requester = request.requester;

              if (currentUserId == null || requester == null) {
                Get.snackbar(
                  'Error',
                  'Unable to start chat. Please try again.',
                  backgroundColor: Colors.red.shade100,
                  colorText: Colors.red.shade700,
                );
                return;
              }

              try {
                final chatController = Get.put(ChatController());
                final roomId = await chatController.createOrGetChatRoom(
                  currentUserId,
                  request.userId,
                  serviceRequestId: request.requestId,
                );

                Get.toNamed(
                  Routes.chatPage,
                  arguments: {
                    'chatRoomId': roomId,
                    'receiverId': request.userId,
                    'receiverName': requester.displayName,
                    'receiverProfilePic': requester.imageUrl ?? " ",
                  },
                );
              } catch (e) {
      // Error handled silently
                Get.snackbar(
                  'Error',
                  'Failed to create chat room. Please try again.',
                  backgroundColor: Colors.red.shade100,
                  colorText: Colors.red.shade700,
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: const Text("Message Requester", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Cancel Request button with loading state
        Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: requestController.isLoading.value ? null : () async {

              // Show cancel reason dialog
              final String? reason = await _showCancelReasonDialog();


              // If user didn't cancel the dialog
              if (reason != null) {
                try {
                  await requestController.cancelVolunteerRequest(request.requestId, reason: reason);

                  Get.snackbar(
                    'Success',
                    'Volunteer request canceled successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                  // Reload request details to get updated status
                  await requestController.loadRequestDetails(request.requestId);
                } catch (e) {
      // Error handled silently
                  Get.snackbar(
                    'Error',
                    'Failed to cancel volunteer request: $e',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                }
              } else {
              }
            },
            icon: requestController.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(requestController.isLoading.value ? "Canceling..." : "Cancel Request"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// Builds the owner delete button for request owners
  /// ✅ FIX: Only shows delete button before request time passes
  Widget _buildOwnerDeleteButton(RequestModel request) {
    // Check if request is in progress or completed
    final bool isInProgress = request.status == RequestStatus.inprogress;
    final bool isComplete = request.status == RequestStatus.complete;

    // ✅ Show delete button for pending/accepted/delayed requests (not in progress or complete)
    if (!isInProgress && !isComplete) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0),
        child: Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
          onPressed: requestController.isLoading.value ? null : () async {
            // Show confirmation dialog
            final bool? confirmed = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Delete Request'),
                content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              try {
                await requestController.deleteRequest(request.requestId);
                Get.snackbar(
                  'Success',
                  'Request deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
                // Navigate back to the requests list
                Get.back();
              } catch (e) {
    // Error handled silently
                Get.snackbar(
                  'Error',
                  'Failed to delete request: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              }
            }
          },
          icon: requestController.isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: Text(requestController.isLoading.value ? "Deleting..." : "Delete Request"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      )),
      );
    }

    // Return empty container if conditions not met (no message shown)
    return Container();
  }

  /// Builds the approved request state UI
  Widget _buildApprovedRequestState(RequestModel request) {
    return Column(
      children: [
        // Success message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request Approved! 🎉",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You are confirmed as a volunteer for this request",
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (request.acceptedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Approved: ${_formatDateTime(request.acceptedAt!)}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cancel Request button for approved volunteers
        Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: requestController.isLoading.value ? null : () async {

              // Show cancel reason dialog
              final String? reason = await _showCancelReasonDialog();


              // If user didn't cancel the dialog
              if (reason != null) {
                try {
                  await requestController.cancelVolunteerRequest(request.requestId, reason: reason);

                  Get.snackbar(
                    'Success',
                    'Your volunteer request has been cancelled',
                    backgroundColor: Colors.green.shade100,
                    colorText: Colors.green.shade700,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  );
                } catch (e) {
      // Error handled silently
                  Get.snackbar(
                    'Error',
                    'Failed to cancel request. Please try again.',
                    backgroundColor: Colors.red.shade100,
                    colorText: Colors.red.shade700,
                  );
                }
              } else {
              }
            },
            icon: requestController.isLoading.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined),
            label: Text(requestController.isLoading.value ? "Canceling..." : "Cancel Request"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// Builds the initial request state UI based on availability
  Widget _buildInitialRequestState(RequestModel request, bool canRequest) {
    // ✅ FIX: Add timing constraint - only show before request time passes
    if (canRequest && (request.requestedTime ?? request.timestamp).isAfter(DateTime.now())) {
      // Show "Interested" button - user can volunteer
      return Column(
        children: [
          // Available slot information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${request.numberOfPeople - request.acceptedUser.length} volunteer spots available",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Interested button with loading state
          Obx(() => SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: requestController.isLoading.value ? null : () {
                Get.dialog(
                  IntrestedDialog(
                    questionText: "Are you interested in volunteering?",
                    submitText: "Yes, I'm Interested",
                    request: request,
                    acceptedUser: authController.currentUserStore.value!,
                  ),
                ).then((_) {
                  // Reload request details to get updated status
                  requestController.loadRequestDetails(request.requestId);
                });
              },
              icon: requestController.isLoading.value 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.volunteer_activism),
              label: Text(requestController.isLoading.value ? "Processing..." : "I'm Interested"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          )),
        ],
      );
    } else {
      // Show "Not Available" state with reason
      String unavailableReason;
      if (!canRequest) {
        unavailableReason = "Request is full or you're not eligible to volunteer";
      } else {
        unavailableReason = "Request time has passed";
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Not Available",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unavailableReason,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  /// Helper method to format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Show cancel request reason dialog
  Future<String?> _showCancelReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();
    
    return await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 24),
            const SizedBox(width: 8),
            const Text("Cancel Request"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to cancel your volunteer request?",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please provide a reason (optional):",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., No longer available, Plans changed, etc.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text("Keep Request"),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              Get.back(result: reason.isEmpty ? "No longer available" : reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Cancel Request"),
          ),
        ],
      ),
    );
  }

  /// Enhanced error state widget for better user experience
  /// ✅ NEW: Provides consistent error states with actionable feedback
  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(Icons.refresh),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👥 Build volunteer request card with status-based actions
  Widget _buildVolunteerRequestCard(Map<String, dynamic> volunteer, String requestId) {
    final volunteerData = volunteer['volunteer'] ?? {};
    final volunteerId = volunteerData['userId'] ?? '';
    final volunteerFullName = volunteerData['full_name'] ?? volunteerData['fullName'] ?? '';
    final volunteerFirstName = volunteerData['first_name'] ?? volunteerData['firstName'] ?? '';
    final volunteerName = volunteerFullName.isNotEmpty
        ? volunteerFullName
        : (volunteerFirstName.isNotEmpty ? volunteerFirstName : (volunteerData['username'] ?? 'Unknown'));
    final volunteerEmail = volunteerData['email'] ?? '';
    final volunteerMessage = volunteer['message'] ?? '';
    final appliedAt = volunteer['applied_at'] ?? '';
    final status = volunteer['status']?.toString().toLowerCase() ?? 'pending';
    
    // Get volunteer user data for profile navigation
    final volunteerRating = volunteerData['rating']?.toDouble() ?? 0.0;
    final volunteerImageUrl = volunteerData['imageUrl'] ?? volunteerData['image_url'];

    // Note: Status display variables removed as they were unused
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volunteer Info Header with Profile Icon
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Check if volunteer is current user - if so, don't pass stale data
                  final currentUserId = authController.currentUserStore.value?.userId;
                  if (volunteerId == currentUserId) {
                    // For current user, navigate without passing user data to force fresh fetch
                    Get.to(() => ProfileScreen());
                  } else {
                    // Navigate to profile screen and let it fetch fresh data from API
                    // Don't pass incomplete user data from request details
                    final volunteerUser = UserModel(
                      userId: volunteerId,
                      username: volunteerName,
                      email: volunteerEmail,
                      imageUrl: volunteerImageUrl,
                      // Don't pass incomplete rating/hours data - let profile screen fetch fresh data
                      isVerified: volunteerData['isVerified'] ?? false,
                      isApproved: volunteerData['isApproved'] ?? false,
                    );
                    Get.to(() => ProfileScreen(user: volunteerUser));
                  }
                },
                child: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: volunteerImageUrl != null && volunteerImageUrl.isNotEmpty
                      ? NetworkImage(volunteerImageUrl)
                      : null,
                  child: volunteerImageUrl == null || volunteerImageUrl.isEmpty
                      ? Text(
                          volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            volunteerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Rating display
                        if (volunteerRating > 0) ...[
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            volunteerRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Volunteer Message (if any)
          if (volunteerMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Message:",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    volunteerMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Applied At Info
          if (appliedAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  "Applied: ${_formatDateTimeString(appliedAt)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
          
          // Action Buttons - Chat button for all statuses, Approve/Reject only for pending
          const SizedBox(height: 16),
          
          // Chat Button (always available)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openChatWithVolunteer(volunteerId, volunteerName, requestId),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text("Chat with Volunteer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Approve/Reject Buttons (only for pending requests)
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Approve Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(volunteerId, volunteerName, requestId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Reject Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(volunteerId, volunteerName, requestId),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 📅 Format DateTime string for display (from API string)
  String _formatDateTimeString(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return "${difference.inDays}d ago";
      } else if (difference.inHours > 0) {
        return "${difference.inHours}h ago";
      } else if (difference.inMinutes > 0) {
        return "${difference.inMinutes}m ago";
      } else {
        return "Just now";
      }
    } catch (e) {
      // Error handled silently
      return "Recently";
    }
  }

  // 🔍 Get current user's actual volunteer status from backend data
  String? _getCurrentUserVolunteerStatus(RequestModel request) {
    final currentUserId = authController.currentUserStore.value?.userId;
    if (currentUserId == null) return null;
    
    // 🎯 PRIMARY: Use the userRequestStatus from RequestModel extension (this is the authoritative source)
    final userStatus = request.userRequestStatus;
    
    if (userStatus.isNotEmpty && userStatus != 'not_requested') {
      // The backend provides the actual status - use it directly!
      return userStatus;
    }
    
    
    // 🔄 FALLBACK 1: Check volunteer requests data if available (for request owners)
    final volunteerRequests = requestController.pendingVolunteers;
    for (final volunteerRequest in volunteerRequests) {
      final volunteer = volunteerRequest['volunteer'];
      if (volunteer != null && volunteer['userId'] == currentUserId) {
        final status = volunteerRequest['status']?.toString();
        return status;
      }
    }
    
    // 🔄 FALLBACK 2: Check if user is in acceptedUser list (they're approved)
    final isAcceptedVolunteer = request.acceptedUser.any(
      (user) => user.userId == currentUserId
    );
    if (isAcceptedVolunteer) {
      return 'approved';
    }
    
    // 🔄 FALLBACK 3: If we have volunteer message or hasVolunteered flag, likely pending
    if (request.hasVolunteered || 
        (request.volunteerMessage != null && request.volunteerMessage!.isNotEmpty)) {
      return 'pending';
    }
    
    return null;
  }

  // ✅ Show approve confirmation dialog
  void _showApproveDialog(String volunteerId, String volunteerName, String requestId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text("Approve Volunteer"),
          ],
        ),
        content: Text("Are you sure you want to approve $volunteerName as a volunteer for this request?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _approveVolunteer(volunteerId, requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Approve"),
          ),
        ],
      ),
    );
  }

  // ❌ Show reject confirmation dialog
  void _showRejectDialog(String volunteerId, String volunteerName, String requestId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text("Reject Volunteer"),
          ],
        ),
        content: Text("Are you sure you want to reject $volunteerName's volunteer request?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _rejectVolunteer(volunteerId, requestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  // ✅ Approve volunteer API call
  Future<void> _approveVolunteer(String volunteerId, String requestId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await requestController.approveVolunteerRequest(requestId, volunteerId);
      
      Get.back(); // Close loading dialog
      
      Get.snackbar(
        'Success',
        'Volunteer approved successfully!',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      
      // Refresh the page data
      await requestController.loadRequestDetails(requestId);
      await requestController.loadPendingVolunteers(requestId);
      
    } catch (e) {
      // Error handled silently
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to approve volunteer: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    }
  }

  // ❌ Reject volunteer API call
  Future<void> _rejectVolunteer(String volunteerId, String requestId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      await requestController.rejectVolunteerRequest(requestId, volunteerId);
      
      Get.back(); // Close loading dialog
      
      Get.snackbar(
        'Success',
        'Volunteer request rejected',
        backgroundColor: Colors.orange.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      
      // Refresh the page data
      await requestController.loadRequestDetails(requestId);
      await requestController.loadPendingVolunteers(requestId);
      
    } catch (e) {
      // Error handled silently
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Error',
        'Failed to reject volunteer: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    }
  }

  // 💬 Open chat with volunteer
  Future<void> _openChatWithVolunteer(String volunteerId, String volunteerName, String requestId) async {
    try {
      // Get current user ID
      final currentUserId = authController.currentUserStore.value?.userId;
      if (currentUserId == null) {
        Get.snackbar(
          'Error',
          'Unable to get current user information',
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
        );
        return;
      }


      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Create or get chat room using existing ChatController
      final chatController = Get.put(ChatController());
      
      final roomId = await chatController.createOrGetChatRoom(
        currentUserId,
        volunteerId,
        serviceRequestId: requestId,
      );


      // Close loading dialog
      Get.back();

      // Navigate to chat page
      
      Get.toNamed(
        Routes.chatPage,
        arguments: {
          'chatRoomId': roomId,
          'receiverId': volunteerId,
          'receiverName': volunteerName,
          'receiverProfilePic': " ",
        },
      );


    } catch (e) {
      // Error handled silently
      
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      Get.snackbar(
        'Error',
        'Failed to open chat. Please try again.',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Navigate to feedback screen with volunteer data
  void _navigateToFeedbackScreen(RequestModel request) {
    // Get volunteers from the request
    final volunteers = request.acceptedUser;

    // REMOVED: Frontend volunteer validation logic
    // If the request is in progress, the backend has already validated that volunteers exist
    // The frontend should not block completion based on volunteer count

    // Navigate to feedback page with request and volunteer data
    Get.toNamed(
      Routes.addfeedbackPage,
      arguments: {
        'request': request,
        'volunteers': volunteers,
        'isCompletion': true, // Flag to indicate this is for completion
      },
    )?.then((_) {
      // Refresh request details after returning from feedback
      requestController.loadRequestDetails(request.requestId);
    });
  }

  /// 🚨 FIXED: Smart user data refresh state with retry mechanism
  /// Shows loading state while attempting to refresh user data instead of immediate error
  Widget _buildUserDataRefreshState() {
    // Create a reactive variable to track refresh state
    final isRefreshing = true.obs;
    final refreshAttempted = false.obs;
    
    // Attempt to refresh user data automatically
    Future.microtask(() async {
      try {
        
        // Try to refresh user profile from the server
        await authController.refreshUserProfile();
        
        // Check if we now have valid user ID
        final refreshedUser = authController.currentUserStore.value;
        if (refreshedUser != null && refreshedUser.userId.isNotEmpty) {
          isRefreshing.value = false;
          refreshAttempted.value = true;
          // The Obx will automatically rebuild and show the proper content
        } else {
          // After failed refresh, still mark as attempted for error handling
          isRefreshing.value = false;
          refreshAttempted.value = true;
        }
      } catch (e) {
      // Error handled silently
        isRefreshing.value = false;
        refreshAttempted.value = true;
      }
    });

    return Obx(() {
      // If we're still refreshing, show loading
      if (isRefreshing.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading User Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We\'re refreshing your account information. Please wait...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // If refresh completed and user data is now valid, show the normal content
      final currentUser = authController.currentUserStore.value;
      if (refreshAttempted.value && currentUser != null && currentUser.userId.isNotEmpty) {
        // Recursively call _buildLoadedContent to show the normal view
        return _buildLoadedContent();
      }
      
      // If refresh failed, show the original error state
      return _buildErrorState(
        icon: Icons.warning_outlined,
        title: 'Invalid User Data',
        message: 'There seems to be an issue with your account. Please try logging in again.',
        buttonText: 'Refresh',
        onPressed: () {
          // Reset and try again
          isRefreshing.value = true;
          refreshAttempted.value = false;
        },
      );
    });
  }

  /// Build feedback section for completed requests
  Widget _buildFeedbackSection(RequestModel request) {
    final currentUserId = authController.currentUserStore.value?.userId;
    
    // Check if we have feedback data
    if (request.feedback == null) {
      return Container();
    }
    
    final feedbackData = request.feedback as Map<String, dynamic>;
    final receivedByMe = feedbackData['received_by_me'] as List<dynamic>?;
    final role = feedbackData['role'] as String?;
    
    // If current user is a volunteer and has received feedback, show it
    if (role == 'volunteer' && receivedByMe != null && receivedByMe.isNotEmpty) {
      // Show feedback received by volunteer
      final feedback = receivedByMe.first;
      final rating = feedback['rating']?.toDouble() ?? 0.0;
      final hours = feedback['hours'] ?? 0;
      final review = feedback['review'] ?? "";
      final fromUser = feedback['from_user'];
      
      return DetailsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Feedback Received",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Your work has been reviewed",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Feedback text section with proper spacing
            if (review.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Feedback:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      review,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                        wordSpacing: 1.0,
                      ),
                      textAlign: TextAlign.left,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            
            // Rating display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Rating: ${rating.toStringAsFixed(1)}/5",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Details row
            Row(
              children: [
                // Hours
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.timer, color: Colors.blue.shade700, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          "$hours hours",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          "contributed",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // From user
                if (fromUser != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person, color: Colors.purple.shade700, size: 20),
                          const SizedBox(height: 4),
                          Text(
                            fromUser['full_name'] ?? fromUser['first_name'] ?? fromUser['username'] ?? "Unknown",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "reviewed by",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    
    // If current user is the requester, show feedback given section
    if (request.userId == currentUserId) {
      return _buildFeedbackGivenSection(request);
    }
    
    // Default: no feedback to show
    return Container();
  }
  
  /// Build feedback given section for request owners
  Widget _buildFeedbackGivenSection(RequestModel request) {
    // Look for feedback in volunteers_assigned data
    final volunteers = request.acceptedUser;
    
    if (volunteers.isEmpty) {
      return Container();
    }
    
    return DetailsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Request Completed",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "This request has been successfully completed",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (request.completedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              "Completed on: ${_formatDateTime(request.completedAt!)}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            "Volunteers who helped:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ...volunteers.map((volunteer) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  volunteer.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// Build volunteer status section using the blue "Accepted By" design format
  Widget _buildVolunteerStatusSection(RequestModel request) {
    final currentUserId = authController.currentUserStore.value?.userId;
    final userStatus = request.userRequestStatus.toLowerCase();
    final requester = request.requester;
    
    // Determine the header title based on status
    String headerTitle;
    switch (userStatus) {
      case 'pending':
        headerTitle = "Request sent to:";
        break;
      case 'approved':
      case 'accepted':
        headerTitle = "Accepted by:";
        break;
      case 'rejected':
        headerTitle = "Rejected by:";
        break;
      default:
        // Check if user is in acceptedUser list (fallback)
        if (request.acceptedUser.any((user) => user.userId == currentUserId)) {
          headerTitle = "Accepted by:";
        } else {
          // For users who haven't sent a request yet
          headerTitle = "Request Details:";
        }
    }
    
    return DetailsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Requester Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    flex: 3,
                    child: DetailsRow(
                      icon: Icons.person,
                      label: "Name",
                      value: requester?.displayName ?? "Unknown User",
                    ),
                  ),
                  // Profile view icon for requester
                  if (requester != null)
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.account_circle, color: Colors.blue, size: 22),
                            tooltip: "View Profile",
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Check if requester is current user - if so, don't pass stale data
                              final currentUserId = authController.currentUserStore.value?.userId;
                              if (requester.userId == currentUserId) {
                                // For current user, navigate without passing user data to force fresh fetch
                                Get.to(() => ProfileScreen());
                              } else {
                                // For other users, pass the user data
                                Get.to(() => ProfileScreen(user: requester));
                              }
                            },
                          ),
                          // Chat button - only show if user has sent a volunteer request (pending, approved, or rejected)
                          if (userStatus == 'pending' || 
                              userStatus == 'approved' || 
                              userStatus == 'accepted' || 
                              userStatus == 'rejected' ||
                              request.hasVolunteered ||
                              request.acceptedUser.any((user) => user.userId == currentUserId))
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 22),
                              tooltip: "Chat",
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final chatController = Get.put(ChatController());
                                try {
                                  final roomId = await chatController.createOrGetChatRoom(
                                    currentUserId!,
                                    request.userId,
                                    serviceRequestId: request.requestId,
                                  );
                                  
                                  Get.toNamed(
                                    Routes.chatPage,
                                    arguments: {
                                      'chatRoomId': roomId,
                                      'receiverId': request.userId,
                                      'receiverName': requester.displayName,
                                      'receiverProfilePic': requester.imageUrl ?? " ",
                                    },
                                  );
                                } catch (e) {
      // Error handled silently
                                  Get.snackbar(
                                    'Error',
                                    'Failed to create chat room. Please try again.',
                                    backgroundColor: Colors.red.shade100,
                                    colorText: Colors.red.shade700,
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.email,
                label: "Email",
                value: requester?.email ?? "Not available",
              ),
              // Show volunteer message if status is pending
              if (userStatus == 'pending' && request.volunteerMessage != null && request.volunteerMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 140, 170, 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color.fromRGBO(0, 140, 170, 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.message_outlined, size: 16, color: Color.fromRGBO(0, 140, 170, 1)),
                          const SizedBox(width: 8),
                          const Text(
                            "Your message:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(0, 140, 170, 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.volunteerMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 12),
            ],
          ),
          
          // Reminder notification button (only for accepted volunteers after request time and NOT completed)
          if ((userStatus == 'approved' || userStatus == 'accepted' || 
               request.acceptedUser.any((user) => user.userId == currentUserId)) &&
              (request.requestedTime ?? request.timestamp).isBefore(DateTime.now()) &&
              request.status != RequestStatus.complete &&
              (request.status == RequestStatus.accepted || 
               request.status == RequestStatus.inprogress || 
               request.status == RequestStatus.incomplete))
            DeferPointer(
              child: GestureDetector(
                onTap: () {
                  Get.snackbar(
                    'Feature Coming Soon',
                    'Reminder functionality will be available soon!',
                    duration: const Duration(seconds: 3),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black87,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.orange,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    "Reminder for feedback",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

