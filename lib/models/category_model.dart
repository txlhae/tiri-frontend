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
      case 'social companionship':
        return Icons.people;
      case 'transportation':
        return Icons.directions_car;
      case 'leisure/game':
        return Icons.sports_esports;
      case 'elderly/care':
        return Icons.elderly;
      case 'medical/health help':
        return Icons.medical_services;
      case 'education/training':
        return Icons.school;
      case 'legal assistance':
        return Icons.gavel;
      case 'general':
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
      case 'social companionship':
        return const Color(0xFFFF7F50); // #FF7F50
      case 'transportation':
        return const Color(0xFF1E90FF); // #1E90FF
      case 'leisure/game':
        return const Color(0xFF8A2BE2); // #8A2BE2
      case 'elderly/care':
        return const Color(0xFFCD853F); // #CD853F
      case 'medical/health help':
        return const Color(0xFFDC143C); // #DC143C
      case 'education/training':
        return const Color(0xFF20B2AA); // #20B2AA
      case 'legal assistance':
        return const Color(0xFF2F4F4F); // #2F4F4F
      case 'general':
        return const Color(0xFF696969); // #696969
      default:
        return Colors.grey;
    }
  }

  /// Get display text with emoji
  String get displayText {
    switch (name.toLowerCase()) {
      case 'social companionship':
        return '👥 Social Companionship';
      case 'transportation':
        return '🚗 Transportation';
      case 'leisure/game':
        return '🎮 Leisure/Game';
      case 'elderly/care':
        return '👵 Elderly/Care';
      case 'medical/health help':
        return '🏥 Medical/Health Help';
      case 'education/training':
        return '📚 Education/Training';
      case 'legal assistance':
        return '⚖️ Legal Assistance';
      case 'general':
        return '📋 General';
      default:
        return name;
    }
  }

  /// Get all predefined categories (matching backend)
  static List<CategoryModel> getAllCategories() {
    return [
      const CategoryModel(id: 1, name: 'Social Companionship', description: 'Companionship visits, conversations, and social activities.', iconName: 'fa-users', colorHex: '#FF7F50'),
      const CategoryModel(id: 2, name: 'Transportation', description: 'Help with rides to appointments, errands, or events.', iconName: 'fa-car', colorHex: '#1E90FF'),
      const CategoryModel(id: 3, name: 'Leisure/Game', description: 'Board games, hobbies, and shared leisure activities.', iconName: 'fa-chess-knight', colorHex: '#8A2BE2'),
      const CategoryModel(id: 4, name: 'Elderly/Care', description: 'Non-medical assistance for elderly community members.', iconName: 'fa-hand-holding-heart', colorHex: '#CD853F'),
      const CategoryModel(id: 5, name: 'Medical/Health Help', description: 'Health-related support that does not require a professional license.', iconName: 'fa-heartbeat', colorHex: '#DC143C'),
      const CategoryModel(id: 6, name: 'Education/Training', description: 'Tutoring, workshops, and training sessions.', iconName: 'fa-graduation-cap', colorHex: '#20B2AA'),
      const CategoryModel(id: 7, name: 'Legal Assistance', description: 'Guidance and document support for basic legal needs.', iconName: 'fa-balance-scale', colorHex: '#2F4F4F'),
      const CategoryModel(id: 8, name: 'General', description: 'Requests that do not fit into other categories.', iconName: 'fa-ellipsis-h', colorHex: '#696969'),
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
