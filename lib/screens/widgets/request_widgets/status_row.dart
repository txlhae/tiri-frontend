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
            border: getStatusBorderColor(status) != null 
                ? Border.all(color: getStatusBorderColor(status)!, width: 2)
                : null,
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

/// Get background color for status badge according to design requirements
/// 🎨 DESIGN SPEC:
/// - PENDING: Gray (#9E9E9E)
/// - INPROGRESS: Blue (#2196F3)
/// - ACCEPTED: Green (#4CAF50)
/// - COMPLETED: White (#FFFFFF) with green border
/// - DELAYED: Orange (#FF9800) (formerly EXPIRED)
/// - INCOMPLETE: Orange (#FF9800)
Color getStatusColor(String status) {
  switch (status.toLowerCase().replaceAll(' ', '')) {
    case 'pending':
      return const Color(0xFF9E9E9E); // Material Gray 500
    case 'inprogress':
      return const Color(0xFF2196F3); // Material Blue 500
    case 'accepted':
      return const Color(0xFF4CAF50); // Material Green 500
    case 'complete':
    case 'completed':
      return const Color(0xFFFFFFFF); // White background
    case 'delayed':
    case 'expired':
      return const Color(0xFFFF9800); // Material Orange 500 (warning color)
    case 'incomplete':
      return const Color(0xFFFF9800); // Material Orange 500
    default:
      return const Color(0xFF9E9E9E); // Default to gray for unknown status
  }
}

/// Get text color for status badge with proper contrast
/// 🎨 DESIGN SPEC: White text for colored backgrounds, dark text for white background
Color getTextColor(String status) {
  switch (status.toLowerCase().replaceAll(' ', '')) {
    case 'pending':
      return const Color(0xFFFFFFFF); // White text on gray background
    case 'inprogress':
      return const Color(0xFFFFFFFF); // White text on blue background
    case 'accepted':
      return const Color(0xFFFFFFFF); // White text on green background
    case 'complete':
    case 'completed':
      return const Color(0xFF2E7D32); // Dark green text on white background
    case 'delayed':
    case 'expired':
      return const Color(0xFFFFFFFF); // White text on orange background
    case 'incomplete':
      return const Color(0xFFFFFFFF); // White text on orange background
    default:
      return const Color(0xFFFFFFFF); // Default to white text
  }
}

/// Get border color for status badge (special case for completed status)
/// 🎨 DESIGN SPEC: Green border for completed status, transparent for others
Color? getStatusBorderColor(String status) {
  switch (status.toLowerCase().replaceAll(' ', '')) {
    case 'complete':
    case 'completed':
      return const Color(0xFF4CAF50); // Green border for white background
    default:
      return null; // No border for other statuses
  }
}
