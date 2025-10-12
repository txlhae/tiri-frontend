import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/chat_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final AuthController authController = Get.find<AuthController>();
  final RequestController requestController = Get.find<RequestController>();
  final RxList<Map<String, dynamic>> myApplications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadMyApplications();
  }

  /// Load all requests where current user has volunteered
  Future<void> _loadMyApplications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final currentUserId = authController.currentUserStore.value?.userId;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Get all requests from the controller
      final allRequests = requestController.requestList;
      
      // Filter requests where current user has volunteered
      final applications = <Map<String, dynamic>>[];
      
      for (final request in allRequests) {
        // Check if user is in accepted volunteers
        final isAccepted = request.acceptedUser.any((user) => user.userId == currentUserId);
        
        if (isAccepted) {
          applications.add({
            'request': request,
            'status': 'accepted',
            'appliedAt': null, // We don't have this data in the current model
          });
          continue;
        }
        
        // Check if user has volunteered (pending status)
        if (request.hasVolunteered || request.userRequestStatus == 'pending') {
          applications.add({
            'request': request,
            'status': request.userRequestStatus,
            'appliedAt': null,
          });
        }
      }

      myApplications.value = applications;
      
    } catch (e) {
      // Error handled silently
      errorMessage.value = 'Failed to load applications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Open chat with requester
  Future<void> _openChatWithRequester(RequestModel request) async {
    try {
      final currentUserId = authController.currentUserStore.value?.userId;
      if (currentUserId == null) {
        Get.snackbar('Error', 'Unable to get current user information');
        return;
      }

      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Create chat room
      final chatController = Get.put(ChatController());
      final roomId = await chatController.createOrGetChatRoom(
        currentUserId,
        request.userId,
        serviceRequestId: request.requestId,
      );

      Get.back(); // Close loading

      // Navigate to chat
      Get.toNamed(
        Routes.chatPage,
        arguments: {
          'chatRoomId': roomId,
          'receiverId': request.userId,
          'receiverName': request.requester?.username ?? "Requester",
          'receiverProfilePic': request.requester?.imageUrl ?? " ",
        },
      );

    } catch (e) {
      // Error handled silently
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Failed to open chat: $e',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: AppBar(
          backgroundColor: const Color.fromRGBO(3, 80, 135, 1),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: CustomBackButton(controller: authController),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'My Applications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          centerTitle: true,
          ),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your applications...'),
              ],
            ),
          );
        }

        if (errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage.value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadMyApplications,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (myApplications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.volunteer_activism_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Applications Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applications to volunteer for requests will appear here',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(3, 80, 135, 1),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Browse Requests',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadMyApplications,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myApplications.length,
            itemBuilder: (context, index) {
              final application = myApplications[index];
              final request = application['request'] as RequestModel;
              final status = application['status'] as String;
              
              return _buildApplicationCard(request, status);
            },
          ),
        );
      }),
    );
  }

  Widget _buildApplicationCard(RequestModel request, String status) {
    // Status styling
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'approved':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade100;
        statusText = 'ACCEPTED';
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
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
            
            const SizedBox(height: 12),
            
            // Request details
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Date and location info
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(request.requestedTime ?? request.timestamp),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location ?? 'Location not specified',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                // View Details Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(
                      Routes.requestDetailsPage,
                      arguments: {'requestId': request.requestId},
                    ),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromRGBO(3, 80, 135, 1),
                      side: const BorderSide(color: Color.fromRGBO(3, 80, 135, 1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Chat Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openChatWithRequester(request),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(3, 80, 135, 1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
