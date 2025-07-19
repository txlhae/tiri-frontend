import 'package:flutter/material.dart';

class NavigateRow extends StatelessWidget {
  const NavigateRow({
    super.key,
    required this.textData,
    required this.buttonTextData,
    required this.onButtonPressed,
  });

  final VoidCallback onButtonPressed;
  final String textData;
  final String buttonTextData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          textData,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        TextButton(
            onPressed: onButtonPressed,
            child: Text(
              buttonTextData,
              style: const TextStyle(
                  color: Color.fromRGBO(0, 140, 170, 1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            )),
      ],
    );
  }
}
