import 'package:flutter/material.dart';

class CustomSocialLogin extends StatelessWidget {
  final String socialMedia;
  final String imagePath;
  const CustomSocialLogin(
      {super.key, required this.socialMedia, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black)),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 15.0,
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    socialMedia,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Image.asset(imagePath)
                ],
              ),
            ),
          )),
    );
  }
}
