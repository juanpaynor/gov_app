import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/report.dart';
import '../../models/report_category.dart';
import '../../models/report_attachment.dart';
import '../../models/report_comment.dart';
import '../../models/report_status_history.dart';

/// Repository for managing reports with Supabase
class ReportsRepository {
  final SupabaseClient supabase;

  ReportsRepository(this.supabase);
  /// Fetch all active report categories
  Future<List<ReportCategory>> getCategories() async {
    try {
      final response = await supabase
          .from('report_categories')
          .select()
          .eq('is_active', true)
          .order('display_order');

      return (response as List)
          .map((json) => ReportCategory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Submit a new report
  Future<Report> submitReport({
    required String title,
    required String description,
    required String categoryId,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? address,
    String urgency = 'medium',
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Insert report
      final reportData = {
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'description': description,
        'location_lat': latitude,
        'location_lng': longitude,
        'location_address': address,
        'urgency': urgency,
        'status': 'pending',
      };

      final response = await supabase
          .from('reports')
          .insert(reportData)
          .select('*, category:report_categories(*)')
          .single();

      final report = Report.fromJson(response);

      // Upload photo if provided
      if (imagePath != null) {
        await uploadReportPhoto(report.id, imagePath);
      }

      return report;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Upload photo for a report
  Future<ReportAttachment> uploadReportPhoto(
    String reportId,
    String imagePath,
  ) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final file = File(imagePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$userId/$reportId/$fileName';

      // Upload to Supabase Storage
      await supabase.storage
          .from('report-attachments')
          .upload(filePath, file);

      // Get public URL
      final fileUrl = supabase.storage
          .from('report-attachments')
          .getPublicUrl(filePath);

      // Save attachment record
      final attachmentData = {
        'report_id': reportId,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_type': 'image/jpeg',
        'file_size': await file.length(),
        'uploaded_by': userId,
      };

      final response = await supabase
          .from('report_attachments')
          .insert(attachmentData)
          .select()
          .single();

      return ReportAttachment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Get user's reports
  Future<List<Report>> getUserReports() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('reports')
          .select('*, category:report_categories(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  /// Get report by ID with full details
  Future<Report> getReportById(String reportId) async {
    try {
      final response = await supabase
          .from('reports')
          .select('*, category:report_categories(*)')
          .eq('id', reportId)
          .single();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch report: $e');
    }
  }

  /// Get attachments for a report
  Future<List<ReportAttachment>> getReportAttachments(String reportId) async {
    try {
      final response = await supabase
          .from('report_attachments')
          .select()
          .eq('report_id', reportId)
          .order('created_at');

      return (response as List)
          .map((json) => ReportAttachment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attachments: $e');
    }
  }

  /// Get comments for a report
  Future<List<ReportComment>> getReportComments(String reportId) async {
    try {
      final response = await supabase
          .from('report_comments')
          .select()
          .eq('report_id', reportId)
          .order('created_at');

      return (response as List)
          .map((json) => ReportComment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Get status history for a report
  Future<List<ReportStatusHistory>> getReportStatusHistory(
      String reportId) async {
    try {
      final response = await supabase
          .from('report_status_history')
          .select()
          .eq('report_id', reportId)
          .order('created_at');

      return (response as List)
          .map((json) => ReportStatusHistory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch status history: $e');
    }
  }

  /// Add comment to a report
  Future<ReportComment> addComment(String reportId, String comment) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final commentData = {
        'report_id': reportId,
        'user_id': userId,
        'comment': comment,
        'is_admin': false,
      };

      final response = await supabase
          .from('report_comments')
          .insert(commentData)
          .select()
          .single();

      return ReportComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Stream real-time updates for user's reports
  Stream<List<Report>> watchUserReports() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Report.fromJson(json)).toList());
  }
}
