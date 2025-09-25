import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/dialog_widgets/cancel_dialog.dart';

class MyRequests extends StatelessWidget {
  const MyRequests({super.key});

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
        return const Center(
          child: Text(
            "No requests found.",
            style: TextStyle(color: Colors.black),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: myRequests.length,
        itemBuilder: (context, index) {
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: request.status == RequestStatus.accepted ||  request.status == RequestStatus.incomplete 
                      ? Colors.blue[50]
                      : [
                          'pending',
                          'inprogress',
                          'completed',
                        ].contains(request.status.toString().split('.').last)
                          ? Colors.grey[200]
                          : request.status == RequestStatus.delayed
                          ? Colors.orange[50]
                          : const Color(0xFFF6F8F9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
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
                              (request.requestedTime ?? request.timestamp).isAfter(DateTime.now()))
                            _buildCancelButton(request),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
        log("Cancel it");
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
}
