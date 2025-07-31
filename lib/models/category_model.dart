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
      iconName: json['icon_name'],
      colorHex: json['color_hex'],
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
      case 'community events':
        return Icons.event;
      case 'elderly care':
        return Icons.elderly;
      case 'emergency help':
        return Icons.emergency;
      case 'garden & outdoor':
        return Icons.local_florist;
      case 'home help':
        return Icons.home_repair_service;
      case 'moving & delivery':
        return Icons.local_shipping;
      case 'pet care':
        return Icons.pets;
      case 'tech support':
        return Icons.computer;
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
      case 'community events':
        return Colors.purple;
      case 'elderly care':
        return Colors.orange;
      case 'emergency help':
        return Colors.red;
      case 'garden & outdoor':
        return Colors.green;
      case 'home help':
        return Colors.blue;
      case 'moving & delivery':
        return Colors.brown;
      case 'pet care':
        return Colors.pink;
      case 'tech support':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Get display text with emoji
  String get displayText {
    switch (name.toLowerCase()) {
      case 'community events':
        return '🎉 Community Events';
      case 'elderly care':
        return '👵 Elderly Care';
      case 'emergency help':
        return '🚨 Emergency Help';
      case 'garden & outdoor':
        return '🌻 Garden & Outdoor';
      case 'home help':
        return '🏠 Home Help';
      case 'moving & delivery':
        return '📦 Moving & Delivery';
      case 'pet care':
        return '🐕 Pet Care';
      case 'tech support':
        return '💻 Tech Support';
      default:
        return name;
    }
  }

  /// Get all predefined categories
  static List<CategoryModel> getAllCategories() {
    return [
      const CategoryModel(id: 34, name: 'Home Help', description: 'Household tasks and maintenance'),
      const CategoryModel(id: 35, name: 'Moving & Delivery', description: 'Moving and transportation help'),
      const CategoryModel(id: 36, name: 'Elderly Care', description: 'Support for elderly community members'),
      const CategoryModel(id: 37, name: 'Pet Care', description: 'Pet sitting and care'),
      const CategoryModel(id: 38, name: 'Tech Support', description: 'Technology assistance'),
      const CategoryModel(id: 39, name: 'Garden & Outdoor', description: 'Outdoor work and gardening'),
      const CategoryModel(id: 40, name: 'Emergency Help', description: 'Urgent assistance needed'),
      const CategoryModel(id: 41, name: 'Community Events', description: 'Events and gatherings'),
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
