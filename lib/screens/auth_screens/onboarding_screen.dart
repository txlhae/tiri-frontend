import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/infrastructure/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _titles = [
    "Make Every Moment Count",
    "Earn Time by Helping Others!"
  ];

  final List<String> _descriptions = [
    "Time is your greatest investment! Connect with people, share your time, and make a real impact in your community.",
    "Help others and get rewarded! Exchange time for meaningful experiences and create a cycle of support and kindness."
  ];

  final List<String> _images = [
    "assets/images/onboard_first.svg",
    "assets/images/onboard_last.svg"
  ];

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    Get.offAllNamed(Routes.loginPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _titles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(_images[index],
                          height: 200, width: 200, fit: BoxFit.cover),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _titles[index],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(3, 80, 135, 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _descriptions[index],
                        textAlign: TextAlign.left,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex < _titles.length - 1)
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text("Skip",
                        style: TextStyle(fontSize: 15, color: Colors.grey)),
                  )
                else
                  const SizedBox(),
                TextButton(
                  onPressed: () {
                    if (_currentIndex == _titles.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(
                    _currentIndex == _titles.length - 1 ? "Finish" : "Next >",
                    style: const TextStyle(
                        fontSize: 15, color: Color.fromRGBO(3, 80, 135, 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
