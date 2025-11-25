/// Report comment model
class ReportComment {
  final String id;
  final String reportId;
  final String userId;
  final String comment;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportComment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.comment,
    required this.isAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportComment.fromJson(Map<String, dynamic> json) {
    return ReportComment(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'user_id': userId,
      'comment': comment,
      'is_admin': isAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
