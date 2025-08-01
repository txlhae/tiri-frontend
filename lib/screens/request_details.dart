import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/notification_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/controllers/request_details_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/models/request_model.dart';
import 'package:kind_clock/screens/profile_screen.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/intrested_dialog.dart';
import 'package:kind_clock/screens/widgets/request_widgets/details_card.dart';
import 'package:kind_clock/screens/widgets/request_widgets/details_row.dart';
import 'package:kind_clock/screens/widgets/request_widgets/status_row.dart';
import 'package:shimmer/shimmer.dart';

class RequestDetails extends StatefulWidget {
  const RequestDetails({super.key});

  @override
  State<RequestDetails> createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetails> {
  final RequestController requestController = Get.find<RequestController>();
  final AuthController authController = Get.find<AuthController>();
  final NotificationController notificationController =
      Get.put(NotificationController());
  // final FirebaseStorageService store = Get.find<FirebaseStorageService>(); // REMOVED: Migrating to Django
  late final RequestDetailsController detailsController;

  /// Convert RequestStatus enum to user-friendly display string
  /// 🎨 HELPER: Maps status enum to proper display names for UI
  /// - Handles "inprogress" as "IN PROGRESS" 
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
      case RequestStatus.expired:
        return 'EXPIRED';
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
      if (requestId != null && requestId.isNotEmpty && requestId.trim().isNotEmpty) {
        try {
          // Load request details after build completes with error handling
          await requestController.loadRequestDetails(requestId);
        } catch (e) {
          // Handle loading errors gracefully
          print('Error loading request details in initState: $e');
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
        print('Warning: No valid requestId provided to RequestDetails');
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
      body: DeferredPointerHandler(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 140, 170, 1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              height: 150,
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
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Request Details',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Obx(() {
                    if (requestController.isLoadingRequestDetails.value) {
                      return _buildLoadingContent();
                    }

                    return _buildLoadedContent();
                  }),
                ),
              ),
            ),
          ],
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
    
    // Check for invalid user data
    if (currentUserId.isEmpty) {
      return _buildErrorState(
        icon: Icons.warning_outlined,
        title: 'Invalid User Data',
        message: 'There seems to be an issue with your account. Please try logging in again.',
        buttonText: 'Refresh',
        onPressed: () => Get.back(),
      );
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
                      request.status != RequestStatus.expired &&
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
                    if (currentUserId != request.userId)
                             CircleAvatar(
                               backgroundColor:  Colors.grey[300],
                                 child: IconButton(
                                 icon: SvgPicture.asset('assets/icons/message.svg'),
                                 tooltip: "Chat with Poster",
                                 onPressed: () async {
                                   final roomId = requestController.getChatRoomId(
                                   currentUserId,
                                   request.userId,
                                   );
                                   Get.toNamed(
                                   Routes.chatPage,
                                   arguments: {
                                     'chatRoomId': roomId,
                                     'receiverId': request.userId,
                                     'receiverName': request.requester?.username ?? "User",
                                     'receiverProfilePic': " ",
                                   },
                             );
                           },
                       ),
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
                "${(request.requestedTime ?? request.timestamp).day}/${(request.requestedTime ?? request.timestamp).month}/${(request.requestedTime ?? request.timestamp).year} at ${(request.requestedTime ?? request.timestamp).hour}:${(request.requestedTime ?? request.timestamp).minute.toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
                const SizedBox(height: 12),
              DetailsRow(
                icon: Icons.person,
                label: "Posted by",
                value: request.requester?.referralCode ?? request.requester?.username ?? "Unknown User",
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
                value: "${request.timestamp.day}/${request.timestamp.month}/${request.timestamp.year} at ${request.timestamp.hour}:${request.timestamp.minute.toString().padLeft(2, '0')}",
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
                value: request.acceptedUser.length.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (requestController.isHelper.value)
          const DetailsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailsRow(
                  icon: Icons.feedback,
                  label: "Feedback",
                  value:
                      "You have been amazing in this program. I had lot of fun",
                ),
                SizedBox(height: 12),
                DetailsRow(
                  icon: Icons.timer,
                  label: "Hours helped",
                  value: "5 hours helped",
                ),
                SizedBox(height: 12),
                DetailsRow(
                  icon: Icons.star,
                  label: "Rating",
                  value: "4/5",
                ),
              ],
            ),
          ),
               if (request.acceptedUser.isNotEmpty &&
            (request.userId == currentUserId || request.acceptedUser.any((user) => user.userId == currentUserId)))
          Column(
            children: [
              DetailsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Accepted By:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                              ...request.acceptedUser.map((user) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: DetailsRow(
                                          icon: Icons.person,
                                          label: "Name",
                                          value: user.username,
                                        ),
                                      ),
                                      if (user.userId != currentUserId)
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.account_circle, color: Colors.blue),
                                              tooltip: "View Profile",
                                              onPressed: () {
                                                Get.to(() => ProfileScreen(user: user));
                                              },
                                            ),
                                         if (currentUserId == request.userId)
                                            IconButton(
                                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                              tooltip: "Chat",
                                              onPressed: () async {
                                                final roomId = requestController.getChatRoomId(
                                                  currentUserId,
                                                  user.userId,
                                                );
                                                Get.toNamed(
                                                  Routes.chatPage,
                                                  arguments: {
                                                    'chatRoomId': roomId,
                                                    'receiverId': user.userId,
                                                    'receiverName': user.username,
                                                    'receiverProfilePic':user.imageUrl ?? " ",
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DetailsRow(
                                    icon: Icons.email,
                                    label: "Email",
                                    value: user.email,
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(thickness: 1, color: Colors.grey),
                                  const SizedBox(height: 12),
                                ],
                              )),
                    const SizedBox(height: 15),
                    //completed and feedback button  
                    if ((request.status == RequestStatus.accepted || 
                         request.status == RequestStatus.inprogress || 
                         request.status == RequestStatus.incomplete) &&
                        authController.currentUserStore.value?.userId == request.userId &&
                        (request.requestedTime ?? request.timestamp).isBefore(DateTime.now()))
                      DeferPointer(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (request.feedbackList == null) {
                              Get.toNamed(
                                Routes.addfeedbackPage,
                                arguments: {'request': request},
                              )?.then((_) => detailsController.refreshData());
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: request.feedbackList == null
                                  ? const Color.fromRGBO(3, 80, 135, 1)
                                  : Colors.grey,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                request.feedbackList == null
                                    ? "Complete/Add feedback"
                                    : "Feedback added",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    //reminder notification button
                    if ((request.status == RequestStatus.accepted || 
                         request.status == RequestStatus.inprogress || 
                         request.status == RequestStatus.incomplete) &&
                        request.acceptedUser.any((user) =>
                            user.userId ==
                                authController.currentUserStore.value?.userId &&
                            (request.requestedTime ?? request.timestamp).isBefore(DateTime.now())))
                      DeferPointer(
                        child: GestureDetector(
                          onTap: () {
                            final newNotification = NotificationModel(
                              notificationId: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              status: "",
                              body: 'Please provide feedback for "${request.title}" accepted by ${authController.currentUserStore.value?.username}',
                              isUserWaiting: false,
                              userId: request.userId,
                              timestamp: DateTime.now(),
                            );
                            try {
                              notificationController
                                  .sendReminderNotification(newNotification);
                              //  debugPrint("Reminder notification sent");
                            } catch (e) {
                              debugPrint("Error: $e");
                            }

                            Get.snackbar(
                              'Reminder Sent',
                              'Notification sent to the requester!',
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
              ),
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

        //volunteer button with dynamic states
        Builder(
          builder: (context) {
            return _buildVolunteerButton(request);
          },
        ),
      ],
    );
  }

  /// Builds dynamic volunteer button based on user request status
  Widget _buildVolunteerButton(RequestModel request) {
    final currentUser = authController.currentUserStore.value;
    
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
    
    // 🎯 Determine display based on actual backend status
    String statusTitle;
    String statusSubtitle;
    Color statusColor;
    IconData statusIcon;
    
    switch (actualVolunteerStatus?.toLowerCase()) {
      case 'approved':
        statusTitle = "Request Approved ✅";
        statusSubtitle = "You have been approved as a volunteer!";
        statusColor = Colors.green.shade700;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusTitle = "Request Rejected ❌";
        statusSubtitle = "Your volunteer request was not accepted";
        statusColor = Colors.red.shade700;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusTitle = "Request Pending ⏳";
        statusSubtitle = "Waiting for requester approval";
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.pending_actions;
        break;
    }
    
    return Column(
      children: [
        // Status information card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: TextStyle(
                        color: statusColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.volunteerMessage != null && request.volunteerMessage!.trim().isNotEmpty
                          ? "Your message: \"${request.volunteerMessage}\""
                          : "Your message: \"No message provided\"",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Cancel Request button with loading state
        Obx(() => SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: requestController.isLoading.value ? null : () async {
              try {
                await requestController.cancelVolunteerRequest(request.requestId);
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
                Get.snackbar(
                  'Error',
                  'Failed to cancel volunteer request: $e',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
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
    // Check if request time has passed
    final bool timeHasPassed = (request.requestedTime ?? request.timestamp).isBefore(DateTime.now());
    
    return Column(
      children: [
        // Owner information card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 140, 170, 1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color.fromRGBO(0, 140, 170, 1).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Color.fromRGBO(0, 140, 170, 1), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Request",
                      style: TextStyle(
                        color: Color.fromRGBO(0, 140, 170, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You are the owner of this request",
                      style: TextStyle(
                        color: Color.fromRGBO(0, 140, 170, 1).withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // ✅ FIX: Only show delete button if request time hasn't passed
        if (!timeHasPassed) ...[
          // Delete Request button with loading state
          Obx(() => SizedBox(
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
        ] else ...[
          // Show message when delete is not available due to timing
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Request time has passed - deletion no longer available",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the approved request state UI
  Widget _buildApprovedRequestState(RequestModel request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
    final volunteerName = volunteerData['username'] ?? 'Unknown';
    final volunteerEmail = volunteerData['email'] ?? '';
    final volunteerMessage = volunteer['message'] ?? '';
    final appliedAt = volunteer['applied_at'] ?? '';
    final status = volunteer['status']?.toString().toLowerCase() ?? 'pending';
    
    // Get status display info
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade100;
        statusText = 'APPROVED';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade100;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade100;
        statusText = 'PENDING';
        statusIcon = Icons.schedule;
        break;
    }
    
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
          // Volunteer Info Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  volunteerName.isNotEmpty ? volunteerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volunteerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (volunteerEmail.isNotEmpty)
                      Text(
                        volunteerEmail,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
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
          
          // Action Buttons (only show for pending requests)
          if (status == 'pending') ...[
            const SizedBox(height: 16),
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
      return "Recently";
    }
  }

  // 🔍 Get current user's actual volunteer status from backend data
  String? _getCurrentUserVolunteerStatus(RequestModel request) {
    final currentUserId = authController.currentUserStore.value?.userId;
    if (currentUserId == null) return null;
    
    // 🎯 PRIMARY: Use the userRequestStatus from RequestModel extension (this is the authoritative source)
    final userStatus = request.userRequestStatus;
    print("🔍 DEBUG: _getCurrentUserVolunteerStatus - userStatus from backend: '$userStatus'"); // Debug log
    
    if (userStatus.isNotEmpty && userStatus != 'not_requested') {
      // The backend provides the actual status - use it directly!
      print("🔍 DEBUG: Using backend status: '$userStatus'"); // Debug log
      return userStatus;
    }
    
    print("🔍 DEBUG: Backend status was '$userStatus', trying fallbacks..."); // Debug log
    
    // 🔄 FALLBACK 1: Check volunteer requests data if available (for request owners)
    final volunteerRequests = requestController.pendingVolunteers;
    for (final volunteerRequest in volunteerRequests) {
      final volunteer = volunteerRequest['volunteer'];
      if (volunteer != null && volunteer['userId'] == currentUserId) {
        final status = volunteerRequest['status']?.toString();
        print("🔍 DEBUG: Found status in volunteer requests: '$status'"); // Debug log
        return status;
      }
    }
    
    // 🔄 FALLBACK 2: Check if user is in acceptedUser list (they're approved)
    final isAcceptedVolunteer = request.acceptedUser.any(
      (user) => user.userId == currentUserId
    );
    if (isAcceptedVolunteer) {
      print("🔍 DEBUG: Found user in acceptedUser list - status: 'approved'"); // Debug log
      return 'approved';
    }
    
    // 🔄 FALLBACK 3: If we have volunteer message or hasVolunteered flag, likely pending
    if (request.hasVolunteered || 
        (request.volunteerMessage != null && request.volunteerMessage!.isNotEmpty)) {
      print("🔍 DEBUG: hasVolunteered or volunteerMessage exists - status: 'pending'"); // Debug log
      return 'pending';
    }
    
    print("🔍 DEBUG: No status found, returning null"); // Debug log
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
}

