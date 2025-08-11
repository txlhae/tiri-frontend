import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:intl/intl.dart';
import 'package:tiri/models/feedback_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';

class Feedback extends StatefulWidget {
  const Feedback({super.key});

  @override
  State<Feedback> createState() => _FeedbackState();
}

class _FeedbackState extends State<Feedback> {
  final requestController = Get.find<RequestController>();

  @override
  void initState() {
    super.initState();
    // Fetch feedback when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // For now, we'll fetch feedback for the current user
      // The userId parameter can be made dynamic based on requirements
      requestController.fetchProfileFeedback('current_user');
    });
  }

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
        // Stats section
        Obx(() {
          final stats = requestController.feedbackStats.value;
          if (stats.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${stats['total_feedback'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(0, 140, 170, 1),
                        ),
                      ),
                      const Text(
                        'Total Feedback',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${stats['total_hours'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(0, 140, 170, 1),
                        ),
                      ),
                      const Text(
                        'Total Hours',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(stats['average_rating'] ?? 0.0).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(0, 140, 170, 1),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Average Rating',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
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
                      final firstName = item['firstName'] ?? '';
                      final lastName = item['lastName'] ?? '';
                      final imageUrl = item['imageUrl'];
                      final title = item['title'] ?? 'Untitled Request';
                      final reputationDisplay = item['reputationDisplay'] ?? '';
                      final totalHoursHelped = item['totalHoursHelped'] ?? 0;
                      final averageRating = item['averageRating'] ?? 0.0;

                      // Enhanced TIRI Brief compliant feedback card
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row with name and date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: imageUrl != null
                                            ? NetworkImage(imageUrl)
                                            : null,
                                        backgroundColor: const Color.fromRGBO(0, 140, 170, 0.1),
                                        child: imageUrl == null
                                            ? const Icon(
                                                Icons.person,
                                                color: Color.fromRGBO(0, 140, 170, 1),
                                                size: 18,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (reputationDisplay.isNotEmpty)
                                            Text(
                                              reputationDisplay,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(feedback.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Star rating and hours row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Star rating display
                                  Row(
                                    children: List.generate(5, (index) => Icon(
                                      index < feedback.rating.round() ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    )),
                                  ),
                                  // Hours helped prominently displayed
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(0, 140, 170, 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Hours: ${feedback.hours}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color.fromRGBO(0, 140, 170, 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Request context
                              Text(
                                'Request: $title',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Review text
                              Text(
                                '"${feedback.review}"',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
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
