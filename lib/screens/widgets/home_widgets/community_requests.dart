import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:kind_clock/controllers/auth_controller.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:kind_clock/models/request_model.dart';

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
                    currentUser != null && (request.status == RequestStatus.pending ||request.status == RequestStatus.inprogress   ) &&
                    request.requestedTime.isAfter(DateTime.now()) &&
                    request.userId != currentUser.userId && 
                    request.acceptedUser.length < request.numberOfPeople &&
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
                              arguments: {'request': request},
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
                                    color: Colors.black.withOpacity(0.1),
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
                                    ListTile(
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
                                      title: Text(
                                        request.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
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
                                              Text(
                                                DateFormat('dd MMM yyyy')
                                                    .format(
                                                        request.requestedTime),
                                                style: const TextStyle(
                                                  color: Color.fromRGBO(
                                                      22, 178, 217, 1),
                                                  fontWeight: FontWeight.bold,
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
                                              Text(
                                                DateFormat('h:mm a').format(
                                                    request.requestedTime),
                                                style: const TextStyle(
                                                  color: Color.fromRGBO(
                                                      22, 178, 217, 1),
                                                  fontWeight: FontWeight.bold,
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
                                              Text(
                                                request.location,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
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
}
