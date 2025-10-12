
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tiri/controllers/auth_controller.dart';
// import 'package:tiri/controllers/home_controller.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/infrastructure/routes.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/dialog_widgets/cancel_dialog.dart';

class MyHelps extends StatefulWidget {
  const MyHelps({super.key});

  @override
  State<MyHelps> createState() => _MyHelpsState();
}

class _MyHelpsState extends State<MyHelps> with SingleTickerProviderStateMixin {
  final authController = Get.find<AuthController>();
  final requestController = Get.find<RequestController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Defer loading until after first frame to avoid Obx setState error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestController.loadMyVolunteeredRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            //  Top Header
            Container(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: MediaQuery.of(context).size.height < 700 ? 30 : 50,
                bottom: 10,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomBackButton(controller: requestController),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'My Helps',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TabBar(
                  controller: _tabController,
                  indicator: const BoxDecoration(),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(text: "Accepted"),
                    Tab(text: "Completed"),
                  ],
                ),
              ],
            ),
          ),

          //  Tab Content
          Expanded(
            child: Obx(() {
              if (requestController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildHelpsList([RequestStatus.accepted, RequestStatus.inprogress, RequestStatus.incomplete]),
                  _buildHelpsList([RequestStatus.complete]),
                ],
              );
            }),
          ),
          ],
        ),
      ),
    );
  }

  ///  Builds Help List UI by status filter
  Widget _buildHelpsList(List<RequestStatus> statusFilter) {
    final myHelpRequests = requestController.myVolunteeredRequests
        .where((request) => statusFilter.contains(request.status))
        .toList();

    if (myHelpRequests.isEmpty) {
      return const Center(child: Text("No requests available.", style: TextStyle(color: Colors.black)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: myHelpRequests.length,
      itemBuilder: (context, index) {
        final request = myHelpRequests[index];
        final user = requestController.userCache[request.userId]?.value;
        return GestureDetector(
          onTap: () => Get.toNamed(Routes.requestDetailsPage, arguments: {'requestId': request.requestId}),
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
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
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: user?.imageUrl != null ? NetworkImage(user!.imageUrl!) : null,
                      radius: 25,
                      child: user?.imageUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(request.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text("Required date: ", style: TextStyle(fontSize: 12, color: Colors.black)),
                              Flexible(
                                child: Text(DateFormat('dd MMM yyyy', 'en_US').format(request.requestedTime ?? request.timestamp),
                                    style: const TextStyle(color: Color.fromRGBO(22, 178, 217, 1), fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text("Time: ", style: TextStyle(fontSize: 12, color: Colors.black)),
                              Expanded(
                                child: Text(
                                  (requestController.formatDateTime(request.requestedTime ?? request.timestamp).split(", ").last).length > 15 
                                    ? '${(requestController.formatDateTime(request.requestedTime ?? request.timestamp).split(", ").last).substring(0, 15)}...'
                                    : requestController.formatDateTime(request.requestedTime ?? request.timestamp).split(", ").last,
                                  style: const TextStyle(color: Color.fromRGBO(22, 178, 217, 1), fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("Location: ", style: TextStyle(fontSize: 12, color: Colors.black)),
                              Expanded(
                                child: Text(
                                  (request.location ?? 'Not specified').length > 15
                                    ? '${(request.location ?? 'Not specified').substring(0, 15)}...'
                                    : request.location ?? 'Not specified',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: request.status != RequestStatus.complete &&
                                request.status != RequestStatus.delayed &&
                                (request.requestedTime ?? request.timestamp).isAfter(DateTime.now())
                            ? const Color.fromRGBO(3, 80, 135, 1)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        minimumSize: const Size(30, 35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      ),
                      onPressed: () {
                        if (request.status != RequestStatus.complete &&
                            request.status != RequestStatus.delayed &&
                            (request.requestedTime ?? request.timestamp).isAfter(DateTime.now())) {
                          Get.dialog(
                            CancelDialog(
                              questionText: "Are you sure you want to cancel?",
                              submitText: "Proceed to cancel",
                              request: request,
                            ),
                          );
                        }
                      },
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}