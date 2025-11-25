import 'package:flutter/material.dart';
import 'announcement_category.dart';

/// Announcement model
class Announcement {
  final String id;
  final String title;
  final String content;  // HTML content
  final String excerpt;
  final String categoryId;
  final String? featuredImageUrl;
  final String author;
  final DateTime publishedAt;
  final bool isPublished;
  final bool isFeatured;
  final int priority;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related data
  final AnnouncementCategory? category;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.categoryId,
    this.featuredImageUrl,
    required this.author,
    required this.publishedAt,
    this.isPublished = true,
    this.isFeatured = false,
    this.priority = 0,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      excerpt: json['excerpt'] as String,
      categoryId: json['category_id'] as String,
      featuredImageUrl: json['featured_image_url'] as String?,
      author: json['author'] as String? ?? 'Roxas City Government',
      publishedAt: DateTime.parse(json['published_at'] as String),
      isPublished: json['is_published'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] != null
          ? AnnouncementCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'excerpt': excerpt,
      'category_id': categoryId,
      'featured_image_url': featuredImageUrl,
      'author': author,
      'published_at': publishedAt.toIso8601String(),
      'is_published': isPublished,
      'is_featured': isFeatured,
      'priority': priority,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get category name (fallback if category not loaded)
  String get categoryName => category?.name ?? 'General';

  /// Get category color
  Color get categoryColor => category?.colorValue ?? const Color(0xFF3B82F6);

  /// Get category icon
  String get categoryIcon => category?.icon ?? '📋';

  /// Check if announcement is new (published within last 24 hours)
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inHours < 24;
  }

  /// Get formatted date string
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${publishedAt.month}/${publishedAt.day}/${publishedAt.year}';
    }
  }
}
