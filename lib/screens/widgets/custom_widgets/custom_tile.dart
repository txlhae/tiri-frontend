import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/models/notification_model.dart';
import 'package:kind_clock/screens/widgets/dialog_widgets/verify_dialog.dart';
import 'package:kind_clock/screens/widgets/request_widgets/status_row.dart';

class CustomTile extends StatelessWidget {
  final NotificationModel notify;
  const CustomTile({super.key, required this.notify});

  @override
  Widget build(BuildContext context) {
    // final store = Get.find<FirebaseStorageService>(); // REMOVED: Migrating to Django
    final requestController = Get.find<RequestController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    notify.body,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible,
                    maxLines: null,
                  ),
                  const SizedBox(height: 20),
                  if (notify.isUserWaiting) const SizedBox(height: 5),
                  if (notify.isUserWaiting)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(3, 80, 135, 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                        minimumSize: const Size(30, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () async {
                        if (notify.isUserWaiting) {
                          log('In the verify');
                          // TODO: Implement Django API call to get user
                          final value = null; // Placeholder user data
                          if (value != null) {
                              log('The user is here: ${value!.toJson().toString()}');
                              Get.dialog(VerifyDialog(
                                acceptedUser: value,
                                notification: notify,
                              ));
                            }
                          // Removed misplaced comma and parenthesis
                        }
                      },
                      child: const Text(
                        "Verify",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: -10,
              left: 10,
              child: notify.status.isNotEmpty ?
               Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: getStatusColor(notify.status),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  notify.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: getTextColor(notify.status),
                  ),
                ),
              )
              :const SizedBox.shrink(),
            ),
            Positioned(
              bottom: 5,
              right: 12,
              child: Text(
                requestController.getRelativeTime(notify.timestamp),
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



