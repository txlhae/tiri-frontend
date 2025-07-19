import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/request_controller.dart';
import 'package:kind_clock/screens/widgets/custom_widgets/custom_back_button.dart';

class PrivacyAndSecurity extends StatelessWidget {
  const PrivacyAndSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
            decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 140, 170, 1),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20))),
            height: 200,
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
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Privacy and Security',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Privacy Policy for Community helping app.',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Privacy Policy for Community helping app. we value your privacy and are committed to protecting the personal information you share with us. This Privacy Policy outlines how we collect, use, and safeguard your data when you use our community helping app ("App"). By using our App, you agree to the terms of this Privacy Policy. Please read it carefully.',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
