import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/auth_controller.dart';
import 'package:tiri/controllers/notification_controller.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_tile.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final notifyController = Get.find<NotificationController>();
  final authController = Get.find<AuthController>();


  @override
  void initState() {
    notifyController.loadNotification();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(0, 140, 170, 1),
            ),
            height: 200,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomBackButton(
                      controller: notifyController,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Notification',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Obx(() {
            if (notifyController.isLoading.value) {
              return const Expanded(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final notification = notifyController.notifications.toList();

            if (notification.isEmpty) {
              return const Expanded(
                child: Center(
                  child: Text(
                    "No notifications",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              );
            }

            return Expanded(
              child: ListView.builder(
                itemCount: notification.length,
                itemBuilder: (context, index) {
                  var notify = notification[index];
                  if (notify.isUserWaiting) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: Future.value(null), // TODO: Replace with actual Django API call
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 20);
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      final userData = snapshot.data!;
                      if ((userData['isVerified'] != true) &&
                          (userData['referralUserId'] ==
                              authController
                                  // .currentUserStore.value!.userId
                              )) {
                        return CustomTile(notify: notify);
                      } else {
                        return const SizedBox.shrink();
                      }
                    }

                    return const SizedBox.shrink();
                  },
                );
              } else {
                // TODO: Replace the following condition with the correct userId check if needed
                // Example: if (notify.userId == authController.currentUserStore.value!.userId)
                return CustomTile(notify: notify);
              }
            },
          ),
        );
      }),
    ],
  ),
);
}
}




