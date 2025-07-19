import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/models/feedback_model.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';

class Feedback extends StatelessWidget {
  Feedback({super.key});

  final requestController = Get.find<RequestController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: DeferredPointerHandler(
      child: Column(children: [
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
                    'Feedbacks',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Obx(() {
                  if (requestController.isFeedbackLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final feedbackList = requestController.fullFeedbackList;

                  if (feedbackList.isEmpty) {
                    return const Center(
                        child: Text(
                      "No feedback available",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ));
                  }

                  return ListView.builder(
                    itemCount: feedbackList.length,
                    itemBuilder: (context, index) {
                      final item = feedbackList[index];
                      final feedback = item['feedback'] as FeedbackModel;
                      final username = item['username'] ?? 'Unknown User';
                      final imageUrl = item['imageUrl'];
                      final title = item['title'] ?? 'Untitled Request';

                      return Card(
                        elevation: 3,
                        color: Colors.grey[200],
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundImage: imageUrl != null
                                            ? NetworkImage(imageUrl)
                                            : null,
                                        backgroundColor: Colors.grey[300],
                                        child: imageUrl == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                       Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Request : ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Review : ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
                                                text: feedback.review ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.normal,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              "Rating: ${feedback.rating ?? 'N/A'} ⭐",
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "Hours: ${feedback.hours ?? 'N/A'}",
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${feedback.timestamp?.day ?? '-'}"
                                    "/${feedback.timestamp?.month ?? '-'}"
                                    "/${feedback.timestamp?.year ?? '-'}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                })))
      ]),
    ));
  }
}
