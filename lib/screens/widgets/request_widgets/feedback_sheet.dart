// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:get/get.dart';
// import 'package:kind_clock/controllers/request_controller.dart';
// import 'package:kind_clock/models/request_model.dart';
// import 'package:kind_clock/screens/widgets/custom_widgets/custom_button.dart';

// class FeedbackSheet extends StatelessWidget {
//   final RequestModel request;

//   const FeedbackSheet({super.key, required this.request});

//   @override
//   Widget build(BuildContext context) {
//     final RequestController controller = Get.find<RequestController>();

//     return Container(
//       height: 600,
//       width: 400,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 GestureDetector(
//                   onTap: () {
//                     controller.reviewController.clear();
//                     controller.hourController.clear();
//                     controller.selectedRating.value = 1;
//                     Get.back();
//                   },
//                   child: SvgPicture.asset('assets/icons/close_icon.svg'),
//                 ),
//                 const SizedBox(
//                   width: 15,
//                 ),
//                 const Text(
//                   "How was your day with the following users?",
//                   style: TextStyle(
//                       fontStyle: FontStyle.italic,
//                       fontSize: 18,
//                       color: Colors.black),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Column(
//               children: request.acceptedUser!.map((user) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 12),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         backgroundImage: NetworkImage(user.imageUrl ?? ""),
//                         child: user.imageUrl == null ? const Icon(Icons.person) : null,
//                       ),
//                       const SizedBox(width: 10),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             user.username,
//                             style: const TextStyle(color: Colors.black),
//                           ),
//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.star,
//                                 color: Color.fromRGBO(3, 80, 135, 1),
//                                 size: 15,
//                               ),
//                               Text(
//                                 '${user.rating ?? 0.0}',
//                                 style: const TextStyle(color: Colors.black),
//                               )
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 12),
//             TextField(
//               controller: controller.reviewController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 alignLabelWithHint: true,
//                 labelText: "Your Review",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: controller.hourController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 alignLabelWithHint: true,
//                 labelText: "Hours helped",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             const Text("Rate the service:", style: TextStyle(fontSize: 16)),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(5, (index) {
//                 return IconButton(
//                   onPressed: () {
//                     controller.updateRating(index + 1);
//                   },
//                   icon: Obx(() {
//                     return Icon(
//                       index < controller.selectedRating.value
//                           ? Icons.star
//                           : Icons.star_border,
//                       color: Colors.amber,
//                     );
//                   }),
//                 );
//               }),
//             ),
//             const SizedBox(height: 12),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 50.0),
//               child: CustomButton(
//                 buttonText: 'Submit',
//                 onButtonPressed: () {
//                   controller
//                       .submitFeedback(
//                           controller.reviewController.text,
//                           int.parse(controller.hourController.text),
//                           controller.selectedRating.value,
//                           request)
//                       .then(
//                     (value)async {
//                       await Get.find<RequestController>().markRequestAsComplete(request);
//                       Get.back();
//                     },
//                   ).onError(
//                     (error, stackTrace) {
//                       Get.snackbar(
//                           'Error', 'Error submitting feedback: $error');
//                       Get.back();
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
