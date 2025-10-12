import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/models/request_model.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_button.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_form_field.dart';

class AddFeedbackPage extends StatefulWidget {
  final RequestModel request;

  const AddFeedbackPage({super.key, required this.request});

  @override
  State<AddFeedbackPage> createState() => _AddFeedbackPageState();
}

class _AddFeedbackPageState extends State<AddFeedbackPage> {
  final RequestController controller = Get.find<RequestController>();
  bool applyFirstToAll = false;

  @override
  void initState() {
    super.initState();
  controller.initializeFeedbackControllers(widget.request);
  }

  void applyFirstUserDataToAll() {
    if (widget.request.acceptedUser.length <= 1) return;
    for (int i = 1; i < widget.request.acceptedUser.length; i++) {
     controller.reviewControllers[i].text = controller.reviewControllers[0].text;
     controller.hourControllers[i].text = controller.hourControllers[0].text;
     controller.selectedRatings[i].value = controller.selectedRatings[0].value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  padding:
                      const EdgeInsets.only(left: 10, right: 10, top: 50, bottom: 10),
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(0, 140, 170, 1),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      )),
                  height: 170,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomBackButton(
                          controller: controller,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Feedback',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Obx(() {
  final count = widget.request.acceptedUser.length;

  if (!controller.isFeedbackReady.value ||
      controller.reviewControllers.length < count ||
      controller.hourControllers.length < count ||
      controller.reviewErrors.length < count ||
      controller.hourErrors.length < count ||
      controller.selectedRatings.length < count) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  return Column(
    children: [
      const SizedBox(height: 12),
        if (widget.request.acceptedUser.length > 1)
            CheckboxListTile(
              title: const Text("Apply first user's feedback to all"),
              value: applyFirstToAll,
              onChanged: (value) {
                setState(() {
                  applyFirstToAll = value!;
                  if (applyFirstToAll) applyFirstUserDataToAll();
                });
              },
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(16),
            child:  ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.request.acceptedUser.length,
                  itemBuilder: (context, index) {
                    final user = widget.request.acceptedUser[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(user.imageUrl ?? ""),
                                child: user.imageUrl == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 15,
                                          color: Colors.amber,),
                                      Text(
                                        '${user.rating ?? 0.0}',
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomFormField(
                                hintText: "Your Review",
                                haveObscure: false,
                                textController: controller.reviewControllers[index],
                              ),
                              if (controller.reviewErrors[index].value != null)
                                Text(controller.reviewErrors[index].value!,
                                    style: const TextStyle(color: Colors.red)),
                
                              const SizedBox(height: 8),
                
                              CustomFormField(
                                hintText: "Hours helped",
                                haveObscure: false,
                                keyboardType: TextInputType.number,
                                textController: controller.hourControllers[index],
                              ),
                              if (controller.hourErrors[index].value != null)
                                Text(controller.hourErrors[index].value!,
                                    style: const TextStyle(color: Colors.red)),
                
                              const SizedBox(height: 8),
                
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Obx(() => IconButton(
                                        icon: Icon(
                                          starIndex < controller.selectedRatings[index].value
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                        ),
                                         onPressed: () {
                                              controller.updateRating(index, starIndex + 1);}, 
                                      ));
                                }),
                              ),
                              const Divider(),
                            ],
                          )
                            ],
                      ),
                    );
              })
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: CustomButton(
                buttonText: 'Submit',
                onButtonPressed: () async {
                  final success = await controller.handleFeedbackSubmission(
                    request: widget.request,
                  );
                  if (success) {
                    Get.back(); 
                  }
                }

              ),
            ),
          ],
        );
            }),
          ]
        ),
        ),
      ),
    );
  }
}
