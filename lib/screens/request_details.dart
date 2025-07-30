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
                      request.requestedTime.isAfter(DateTime.now()))
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
                "${request.requestedTime.day}/${request.requestedTime.month}/${request.requestedTime.year} at ${request.requestedTime.hour}:${request.requestedTime.minute.toString().padLeft(2, '0')}",
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
                value: request.location,
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
                status: request.status.toString().split(".").last.toUpperCase(),
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
               if (((request.status == RequestStatus.accepted &&
                request.acceptedUser.isNotEmpty && 
                request.acceptedUser.isNotEmpty  ) ||
            request.status == RequestStatus.incomplete ||
            request.status == RequestStatus.inprogress || 
            request.status == RequestStatus.complete) &&
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
                    if ((request.status == RequestStatus.accepted || request.status == RequestStatus.incomplete ) &&
                        authController.currentUserStore.value?.userId ==
                            request.userId &&
                        request.requestedTime.isBefore(DateTime.now()))
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
                    if ((request.status == RequestStatus.accepted || request.status == RequestStatus.incomplete) &&
                        request.acceptedUser.any((user) =>
                            user.userId ==
                                authController.currentUserStore.value?.userId &&
                            request.requestedTime.isBefore(DateTime.now())))
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
        //volunteer button with dynamic states
        Builder(
          builder: (context) {
            print('Debug: About to call _buildVolunteerButton');
            return _buildVolunteerButton(request);
          },
        ),
      ],
    );
  }

  /// Builds dynamic volunteer button based on user request status
  Widget _buildVolunteerButton(RequestModel request) {
    final currentUser = authController.currentUserStore.value;
    
    // DEBUG PRINTS
    print('=== DEBUG _buildVolunteerButton ===');
    print('Debug: userId=${request.userId}, currentUserId=${currentUser?.userId}');
    print('Debug: acceptedUser.length=${request.acceptedUser.length}, numberOfPeople=${request.numberOfPeople}');
    print('Debug: userRequestStatus=${request.userRequestStatus}');
    print('Debug: canRequest=${request.canRequest}');
    print('Debug: Raw request data check...');
    // Try to access extension cache directly
    print('Debug: Extension cache check for ${request.requestId}');
    
    // Don't show button if user owns the request
    if (request.userId == currentUser?.userId) {
      print('Debug: User owns request - returning Container()');
      return Container();
    }
    
    // Don't show button if request is full (already has enough volunteers)
    if (request.acceptedUser.length >= request.numberOfPeople) {
      print('Debug: Request is full - returning Container()');
      return Container();
    }
    
    // Check if user is already an accepted volunteer
    final isAcceptedVolunteer = request.acceptedUser.any(
      (user) => user.userId == currentUser?.userId
    );
    if (isAcceptedVolunteer) {
      print('Debug: User is already accepted volunteer - returning Container()');
      return Container();
    }
    
    print('Debug: Proceeding to build button UI...');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Builder(
        builder: (context) {
          // Get user request status using extension (these are not reactive)
          final userRequestStatus = request.userRequestStatus;
          final canRequest = request.canRequest;
          
          print('Debug: Switch - userRequestStatus=$userRequestStatus, canRequest=$canRequest');
          
          switch (userRequestStatus) {
            case 'pending':
              print('Debug: Entering pending case');
              // Show pending status with cancel option
              return _buildPendingRequestState(request);
              
            case 'approved':
            case 'accepted':
              print('Debug: Entering approved/accepted case');
              // Show approved status
              return _buildApprovedRequestState(request);
              
            case 'not_requested':
            default:
              print('Debug: Entering default case (not_requested/null)');
              // Show appropriate button based on canRequest status
              return _buildInitialRequestState(request, canRequest);
          }
        },
      ),
    );
  }

  /// Builds the pending request state UI with status and cancel option
  Widget _buildPendingRequestState(RequestModel request) {
    return Column(
      children: [
        // Status information card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.pending_actions, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request Pending",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Waiting for requester approval",
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (request.volunteerMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Your message: \"${request.volunteerMessage}\"",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
    if (canRequest) {
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
                    request.acceptedUser.length >= request.numberOfPeople
                        ? "This request is already full"
                        : "You cannot volunteer for this request",
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
}

