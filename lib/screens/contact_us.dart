import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/request_widgets/details_card.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    final requestController = Get.find<RequestController>();

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // Add this to enable scrolling
          child: Stack(
            children: [
              // Background Container
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 50, bottom: 10),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 140, 170, 1),
                ),
                height: 170,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomBackButton(controller: requestController),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding:
                  EdgeInsets.only(top: 150, left: 20, right: 20, bottom: 20),
              child: DetailsCard(
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.phone,
                              color: Color.fromRGBO(22, 178, 217, 1)),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              Text('9999999999',
                                  style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Icon(Icons.email,
                              color: Color.fromRGBO(22, 178, 217, 1)),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              Text('thhhh@gmail.com',
                                  style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: Color.fromRGBO(22, 178, 217, 1)),
                          SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Address',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              Text(
                                'Lorem Ipsum, India',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Padding(
                      //   padding: EdgeInsets.only(left: 40, top: 5),
                      //   child: Text('Lorem Ipsum, India', style: TextStyle(color: Colors.black),),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
