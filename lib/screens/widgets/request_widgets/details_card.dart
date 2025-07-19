import 'package:flutter/material.dart';

class DetailsCard extends StatelessWidget {
  final Widget child;
  const DetailsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(251, 252, 254, 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(1.0, 1.0), //(x,y)
            blurRadius: 6.0,
          ),
        ],
      ),
      child: child,
    );
  }
}
