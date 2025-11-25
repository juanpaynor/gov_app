import 'package:flutter/material.dart';
import 'report_category.dart';

/// Report model
class Report {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String description;
  final double? locationLat;
  final double? locationLng;
  final String? locationAddress;
  final String urgency;
  final String status;
  final String? assignedTo;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  
  // Related data
  final ReportCategory? category;

  Report({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.locationLat,
    this.locationLng,
    this.locationAddress,
    this.urgency = 'medium',
    this.status = 'pending',
    this.assignedTo,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.category,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      locationLat: json['location_lat'] != null 
          ? (json['location_lat'] as num).toDouble()
          : null,
      locationLng: json['location_lng'] != null
          ? (json['location_lng'] as num).toDouble()
          : null,
      locationAddress: json['location_address'] as String?,
      urgency: json['urgency'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      assignedTo: json['assigned_to'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      category: json['category'] != null
          ? ReportCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'location_address': locationAddress,
      'urgency': urgency,
      'status': status,
      'assigned_to': assignedTo,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  /// Get location as string (for display)
  String? get location => locationAddress;

  /// Get color for status badge
  Color get statusColor {
    switch (status) {
      case 'resolved':
        return const Color(0xFF10B981); // green
      case 'in_progress':
        return const Color(0xFF3B82F6); // blue
      case 'rejected':
        return const Color(0xFFEF4444); // red
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // orange
    }
  }

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get urgencyDisplayName {
    switch (urgency) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      default:
        return urgency;
    }
  }
}
