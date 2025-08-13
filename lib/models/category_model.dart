import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? iconName;
  final String? colorHex;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.colorHex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      iconName: json['icon'] ?? json['icon_name'], // Handle both 'icon' and 'icon_name'
      colorHex: json['color'] ?? json['color_hex'], // Handle both 'color' and 'color_hex'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
    };
  }

  /// Get icon for the category
  IconData get icon {
    switch (name.toLowerCase()) {
      case 'elderly care':
        return Icons.elderly;
      case 'grocery shopping':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'technology help':
        return Icons.computer;
      case 'moving & lifting':
        return Icons.local_shipping;
      case 'home repair':
        return Icons.home_repair_service;
      case 'yard work':
        return Icons.local_florist;
      case 'pet care':
        return Icons.pets;
      case 'childcare':
        return Icons.child_care;
      case 'education & tutoring':
        return Icons.school;
      case 'medical assistance':
        return Icons.medical_services;
      case 'emergency help':
        return Icons.emergency;
      case 'language translation':
        return Icons.translate;
      case 'legal assistance':
        return Icons.gavel;
      case 'social companionship':
        return Icons.people;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.help_outline;
    }
  }

  /// Get color for the category
  Color get color {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to default color
      }
    }

    // Fallback colors based on category name
    switch (name.toLowerCase()) {
      case 'elderly care':
        return const Color(0xFFFF6B6B);
      case 'grocery shopping':
        return const Color(0xFF4ECDC4);
      case 'transportation':
        return const Color(0xFF45B7D1);
      case 'technology help':
        return const Color(0xFF96CEB4);
      case 'moving & lifting':
        return const Color(0xFFFFEAA7);
      case 'home repair':
        return const Color(0xFFDDA0DD);
      case 'yard work':
        return const Color(0xFF98D8C8);
      case 'pet care':
        return const Color(0xFFF7DC6F);
      case 'childcare':
        return const Color(0xFF85C1E2);
      case 'education & tutoring':
        return const Color(0xFFBB8FCE);
      case 'medical assistance':
        return const Color(0xFFEC7063);
      case 'emergency help':
        return const Color(0xFFE74C3C);
      case 'language translation':
        return const Color(0xFF5DADE2);
      case 'legal assistance':
        return const Color(0xFF76448A);
      case 'social companionship':
        return const Color(0xFFF39C12);
      case 'other':
        return const Color(0xFF95A5A6);
      default:
        return Colors.grey;
    }
  }

  /// Get display text with emoji
  String get displayText {
    switch (name.toLowerCase()) {
      case 'elderly care':
        return '👵 Elderly Care';
      case 'grocery shopping':
        return '🛒 Grocery Shopping';
      case 'transportation':
        return '🚗 Transportation';
      case 'technology help':
        return '💻 Technology Help';
      case 'moving & lifting':
        return '📦 Moving & Lifting';
      case 'home repair':
        return '🔧 Home Repair';
      case 'yard work':
        return '🌻 Yard Work';
      case 'pet care':
        return '🐕 Pet Care';
      case 'childcare':
        return '👶 Childcare';
      case 'education & tutoring':
        return '📚 Education & Tutoring';
      case 'medical assistance':
        return '🏥 Medical Assistance';
      case 'emergency help':
        return '🚨 Emergency Help';
      case 'language translation':
        return '🗣️ Language Translation';
      case 'legal assistance':
        return '⚖️ Legal Assistance';
      case 'social companionship':
        return '👥 Social Companionship';
      case 'other':
        return '❓ Other';
      default:
        return name;
    }
  }

  /// Get all predefined categories (matching backend CSV data)
  static List<CategoryModel> getAllCategories() {
    return [
      const CategoryModel(id: 1, name: 'Elderly Care', description: 'Assistance for elderly community members with daily tasks', iconName: 'fa-hands-helping', colorHex: '#FF6B6B'),
      const CategoryModel(id: 2, name: 'Grocery Shopping', description: 'Help with grocery shopping and delivery', iconName: 'fa-shopping-cart', colorHex: '#4ECDC4'),
      const CategoryModel(id: 3, name: 'Transportation', description: 'Rides to appointments, stores, or other destinations', iconName: 'fa-car', colorHex: '#45B7D1'),
      const CategoryModel(id: 4, name: 'Technology Help', description: 'Computer, phone, and internet assistance', iconName: 'fa-laptop', colorHex: '#96CEB4'),
      const CategoryModel(id: 5, name: 'Moving & Lifting', description: 'Help with moving furniture or heavy items', iconName: 'fa-truck', colorHex: '#FFEAA7'),
      const CategoryModel(id: 6, name: 'Home Repair', description: 'Basic home maintenance and repair tasks', iconName: 'fa-tools', colorHex: '#DDA0DD'),
      const CategoryModel(id: 7, name: 'Yard Work', description: 'Gardening, lawn care, and outdoor maintenance', iconName: 'fa-leaf', colorHex: '#98D8C8'),
      const CategoryModel(id: 8, name: 'Pet Care', description: 'Pet sitting, walking, and basic care', iconName: 'fa-paw', colorHex: '#F7DC6F'),
      const CategoryModel(id: 9, name: 'Childcare', description: 'Babysitting and child supervision', iconName: 'fa-baby', colorHex: '#85C1E2'),
      const CategoryModel(id: 10, name: 'Education & Tutoring', description: 'Teaching, tutoring, and homework help', iconName: 'fa-graduation-cap', colorHex: '#BB8FCE'),
      const CategoryModel(id: 11, name: 'Medical Assistance', description: 'Non-emergency medical help and accompaniment', iconName: 'fa-heartbeat', colorHex: '#EC7063'),
      const CategoryModel(id: 12, name: 'Emergency Help', description: 'Urgent assistance needed immediately', iconName: 'fa-exclamation-triangle', colorHex: '#E74C3C'),
      const CategoryModel(id: 13, name: 'Language Translation', description: 'Help with translation and interpretation', iconName: 'fa-language', colorHex: '#5DADE2'),
      const CategoryModel(id: 14, name: 'Legal Assistance', description: 'Basic legal document help and guidance', iconName: 'fa-balance-scale', colorHex: '#76448A'),
      const CategoryModel(id: 15, name: 'Social Companionship', description: 'Companionship for isolated or lonely individuals', iconName: 'fa-users', colorHex: '#F39C12'),
      const CategoryModel(id: 16, name: 'Other', description: 'Other types of community assistance', iconName: 'fa-ellipsis-h', colorHex: '#95A5A6'),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
