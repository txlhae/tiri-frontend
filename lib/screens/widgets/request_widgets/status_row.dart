import 'package:flutter/material.dart';

class StatusRow extends StatelessWidget {
  final String label;
  final String status;
  const StatusRow({super.key, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: getStatusColor(status),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: getTextColor(status),
            ),
          ),
        ),
      ],
    );
  }
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const Color.fromRGBO(255, 242, 205, 1);
    case 'complete':
      return const Color.fromRGBO(204, 255, 204, 1);
    case 'incomplete':
      return const Color.fromRGBO(255, 224, 178, 1); 
    case 'accepted':
      return const Color.fromRGBO(233, 243, 255, 1);
    case 'expired':
      return const Color.fromRGBO(255, 204, 204, 1);  
    default:
      return const Color.fromRGBO(233, 243, 255, 1);
  }
}

Color getTextColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return const Color.fromRGBO(255, 193, 7, 1);
    case 'complete':
      return const Color.fromARGB(255, 76, 175, 80);
    case 'incomplete':
      return const Color.fromARGB(255, 255, 143, 0); 
    case 'accepted':
      return const Color.fromARGB(255, 33, 150, 243);
    case 'expired':
      return const Color.fromARGB(255, 244, 67, 54);    
    default:
      return const Color.fromARGB(255, 0, 0, 0);
  }
}
