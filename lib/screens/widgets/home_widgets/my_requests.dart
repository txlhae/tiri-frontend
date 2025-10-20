import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/dialog_widgets/cancel_dialog.dart';
import 'package:tiri/screens/widgets/request_widgets/status_row.dart';

class MyRequests extends StatefulWidget {
  const MyRequests({super.key});

  @override
  State<MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends State<MyRequests> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final requestController = Get.find<RequestController>();

    // Load more when scrolled to 80% of the list
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (requestController.hasMyRequestsMore.value &&
          !requestController.isLoadingMore.value) {
        requestController.loadMoreMyRequests();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final requestController = Get.find<RequestController>();

    return Obx(() {
      if (requestController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final currentUser = authController.currentUserStore.value;
      if (currentUser == null) {
        return const Center(child: Text("User not found."));
      }
      final allRequests = requestController.hasSearchedMyPosts.value
          ? requestController.myPostRequests
          : requestController.myRequestList;

      final myRequests = allRequests
          .where((request) => request.userId == currentUser.userId)
          .where((request) => request.status != RequestStatus.cancelled)
          .toList();

      if (myRequests.isEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            await requestController.loadRequests();
          },
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(
                child: Text(
                  "No requests found.",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await requestController.loadRequests();
        },
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 60),
          itemCount: myRequests.length + (requestController.hasMyRequestsMore.value || requestController.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
          // Show loading indicator at the end when loading more
          if (index == myRequests.length) {
            return Obx(() => requestController.isLoadingMore.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink(),
            );
          }

          final request = myRequests[index];

          return GestureDetector(
            onTap: () => Get.toNamed(
              Routes.requestDetailsPage,
              arguments: {'requestId': request.requestId},
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromRGBO(246, 248, 249, 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Status indicator on the left border
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: _getStatusBorderColor(request.status),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(request.status),
                            ],
                          ),
                          const SizedBox(height: 5),
                          _buildRequestDetail(
                              "Required date: ",
                              DateFormat('dd MMM yyyy', 'en_US')
                                  .format(request.requestedTime ?? request.timestamp)),
                          _buildRequestDetail(
                              "Time: ",
                              requestController
                                  .formatDateTime(request.requestedTime ?? request.timestamp)
                                  .split(", ")
                                  .last),
                          _buildRequestDetail("Location: ", request.location ?? 'Not specified'),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                requestController
                                    .getRelativeTime(request.timestamp),
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 10),
                              ),
                              const Spacer(),
                              if (!_isRequestCompleted(request.status) &&
                                  request.status != RequestStatus.inprogress)
                                _buildCancelButton(request),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        ),
      );
    });
  }

  Widget _buildRequestDetail(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color.fromRGBO(22, 178, 217, 1),
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  bool _isRequestCompleted(RequestStatus status) {
    return status == RequestStatus.delayed ||
        status == RequestStatus.cancelled ||
        status == RequestStatus.complete;
  }

  Widget _buildCancelButton(RequestModel request) {
    return GestureDetector(
      onTap: () {
        if (request.status != RequestStatus.complete) {
          Get.dialog(
            CancelDialog(
              questionText: "Are you sure you want to cancel?",
              submitText: "Proceed to cancel",
              request: request,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(233, 246, 255, 0.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(color: Color.fromRGBO(3, 80, 135, 1)),
        ),
      ),
    );
  }

  /// Get border color based on request status
  Color _getStatusBorderColor(RequestStatus status) {
    final statusString = status.toString().split('.').last;
    // For completed status, use green border instead of white
    if (statusString.toLowerCase() == 'complete' || statusString.toLowerCase() == 'completed') {
      return const Color(0xFF4CAF50); // Material Green 500
    }
    return getStatusColor(statusString);
  }

  /// Build status badge widget
  Widget _buildStatusBadge(RequestStatus status) {
    final statusString = status.toString().split('.').last;
    final backgroundColor = getStatusColor(statusString);
    final textColor = getTextColor(statusString);
    final borderColor = getStatusBorderColor(statusString);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Text(
        _formatStatusText(statusString),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// Format status text for display
  String _formatStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'inprogress':
        return 'In Progress';
      case 'accepted':
        return 'Accepted';
      case 'complete':
        return 'Completed';
      case 'delayed':
        return 'Delayed';
      case 'incomplete':
        return 'Incomplete';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
