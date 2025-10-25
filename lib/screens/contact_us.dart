import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiri/controllers/request_controller.dart';
import 'package:tiri/screens/widgets/custom_widgets/custom_back_button.dart';
import 'package:tiri/screens/widgets/request_widgets/details_card.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  Future<void> _launchUri(Uri uri) async {
    final canHandle = await canLaunchUrl(uri);
    if (!canHandle) {
      debugPrint('Cannot handle $uri');
      return;
    }
    final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!didLaunch) {
      debugPrint('Unable to launch $uri');
    }
  }

  Future<void> _openPhone() async {
    await _launchUri(Uri(scheme: 'tel', path: '+917356636563'));
  }

  Future<void> _openEmail() async {
    await _launchUri(
      Uri(
        scheme: 'mailto',
        path: 'tiritechconsulting@gmail.com',
      ),
    );
  }

  Future<void> _openAddress() async {
    await _launchUri(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=Cochin%2C%20Infopark',
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    required Future<void> Function() onPressed,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await onPressed();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color.fromRGBO(22, 178, 217, 1),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: MediaQuery.of(context).size.height < 700 ? 30 : 50,
                  bottom: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0, 140, 170, 1),
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
                          'Contact Us',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 150, left: 20, right: 20),
                child: DetailsCard(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15.0,
                      right: 15.0,
                      top: 15.0,
                      bottom: 20.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactItem(
                          icon: Icons.phone,
                          title: 'Phone',
                          value: '+91 7356636563',
                          onPressed: _openPhone,
                        ),
                        const SizedBox(height: 20),
                        _buildContactItem(
                          icon: Icons.email,
                          title: 'Email',
                          value: 'tiritechconsulting@gmail.com',
                          onPressed: _openEmail,
                        ),
                        const SizedBox(height: 20),
                        _buildContactItem(
                          icon: Icons.location_on,
                          title: 'Address',
                          value: 'Cochin, Infopark',
                          onPressed: _openAddress,
                        ),
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
