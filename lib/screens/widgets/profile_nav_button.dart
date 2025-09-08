
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ProfileNavButton extends StatelessWidget {
  final String icon;
  final String buttonText;
  final String navDestination;
  final bool haveDialog;
  final Widget? dialog;
  const ProfileNavButton(
      {super.key,
      required this.buttonText,
      required this.navDestination,
      required this.icon,
      required this.haveDialog,
      this.dialog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (haveDialog&&dialog!=null) {
          Get.dialog(dialog!); // show custom dialog
        } else {
          Get.toNamed(navDestination);
        }
      },
      child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          width: double.infinity,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 25.0),
            child: Row(
              children: [
                SvgPicture.asset(icon, height: 20, width: 20),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 15,
                  color: Colors.black,
                )
              ],
            ),
          )),
    );
  }
}
