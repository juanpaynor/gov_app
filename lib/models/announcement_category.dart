import 'package:flutter/material.dart';

/// Announcement category model
class AnnouncementCategory {
  final String id;
  final String name;
  final String slug;
  final String? icon;  // Emoji or icon identifier
  final String color;  // Hex color code
  final String? description;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnouncementCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.color,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnnouncementCategory.fromJson(Map<String, dynamic> json) {
    return AnnouncementCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#3B82F6',
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'color': color,
      'description': description,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get color as Flutter Color object
  Color get colorValue {
    try {
      final hexColor = color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6); // Default blue
    }
  }
}
