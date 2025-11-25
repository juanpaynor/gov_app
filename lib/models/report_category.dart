import 'package:flutter/material.dart';

/// Report category model
class ReportCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String color;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.color,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportCategory.fromJson(Map<String, dynamic> json) {
    return ReportCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#3B82F6',
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get IconData from icon string
  IconData get iconData {
    switch (icon) {
      case 'construction':
        return Icons.construction;
      case 'warning':
        return Icons.warning;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'delete':
        return Icons.delete;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.report_problem;
    }
  }

  /// Get Color from color hex string
  Color get colorValue {
    try {
      // Remove # if present
      final hexColor = color.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return const Color(0xFF3B82F6); // default blue
    }
  }
}
