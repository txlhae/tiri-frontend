import 'package:flutter/material.dart';

class CustomCancel extends StatelessWidget {
  const CustomCancel({
    super.key,
    required this.buttonText,
    required this.onButtonPressed,
  });

  final String buttonText;
  final void Function() onButtonPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onButtonPressed,
      child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: const Color.fromRGBO(3, 80, 135, 1)),
              borderRadius: BorderRadius.circular(30)),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 15.0,
            ),
            child: Center(
              child: Text(
                buttonText,
                style: const TextStyle(
                    color: Color.fromRGBO(3, 80, 135, 1),
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )),
    );
  }
}
