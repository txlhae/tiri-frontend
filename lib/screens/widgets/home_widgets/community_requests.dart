import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';

class CommunityRequests extends StatefulWidget {
  const CommunityRequests({super.key});

  @override
  State<CommunityRequests> createState() => _CommunityRequestsState();
}

class _CommunityRequestsState extends State<CommunityRequests> {

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final requestController = Get.find<RequestController>();

    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (requestController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final currentUser = authController.currentUserStore.value;

            final allRequests = requestController.hasSearchedCommunity.value
                ? requestController.communityRequests
                : requestController.requestList;

            final filteredRequests = allRequests
                .where((request) =>
                    currentUser != null &&
                    request.userId != currentUser.userId && 
                    !request.acceptedUser
                        .any((user) => user.userId == currentUser.userId))
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                requestController.communityRequests.clear(); 
                await requestController.loadRequests(); 
              },
              child: filteredRequests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height - 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "No requests available.",
                                style: TextStyle(color: Colors.black, fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              if (allRequests.isNotEmpty)
                                Text(
                                  "Found ${allRequests.length} total requests but none match your filters",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () async {
                                  await requestController.loadRequests();
                                },
                                child: const Text("Refresh"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredRequests.length,
                      itemBuilder: (context, index) {
                        var request = filteredRequests[index];

                        return GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              Routes.requestDetailsPage,
                              arguments: {'requestId': request.requestId},
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Container(
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
                                        color: _getStatusColor(request.status),
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
                                        ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundImage: request.requester?.imageUrl !=
                                                    null
                                                ? NetworkImage(request.requester!.imageUrl!)
                                                : null,
                                            radius: 30,
                                            child: request.requester?.imageUrl == null
                                                ? const Icon(Icons.person)
                                                : null,
                                          ),
                                          title: Row(
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
                                              // Category badge aligned with title
                                              if (request.category != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: request.category!.color.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: request.category!.color.withValues(alpha: 0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        request.category!.icon,
                                                        size: 12,
                                                        color: request.category!.color,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        request.category!.name,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: request.category!.color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text("Required date: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black)),
                                              Flexible(
                                                child: Text(
                                                  DateFormat('dd MMM yyyy')
                                                      .format(
                                                          request.requestedTime ?? request.timestamp),
                                                  style: const TextStyle(
                                                    color: Color.fromRGBO(
                                                        22, 178, 217, 1),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text("Time: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black)),
                                              Flexible(
                                                child: Text(
                                                  DateFormat('h:mm a').format(
                                                      request.requestedTime ?? request.timestamp),
                                                  style: const TextStyle(
                                                    color: Color.fromRGBO(
                                                        22, 178, 217, 1),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Text("Location: ",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black)),
                                              Expanded(
                                                child: Text(
                                                  request.location ?? 'Not specified',
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        requestController
                                            .getRelativeTime(request.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
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
          }),
        ),
      ],
    );
  }

  /// Get status color based on request status
  /// Matches the color scheme from status_row.dart
  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return const Color(0xFF9E9E9E); // Gray - Material Gray 500
      case RequestStatus.accepted:
        return const Color(0xFF4CAF50); // Green - Material Green 500
      case RequestStatus.inprogress:
        return const Color(0xFF2196F3); // Blue - Material Blue 500
      case RequestStatus.complete:
        return const Color(0xFF4CAF50); // Green border for completed
      case RequestStatus.delayed:
        return const Color(0xFFFF9800); // Orange - Material Orange 500
      case RequestStatus.incomplete:
        return const Color(0xFFFF9800); // Orange - Material Orange 500
      case RequestStatus.cancelled:
        return const Color(0xFF9E9E9E); // Gray - same as pending
    }
  }
}
