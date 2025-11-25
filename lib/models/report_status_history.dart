/// Report status history model for tracking status changes
class ReportStatusHistory {
  final String id;
  final String reportId;
  final String? oldStatus;
  final String newStatus;
  final String changedBy;
  final String? notes;
  final DateTime createdAt;

  ReportStatusHistory({
    required this.id,
    required this.reportId,
    this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    this.notes,
    required this.createdAt,
  });

  factory ReportStatusHistory.fromJson(Map<String, dynamic> json) {
    return ReportStatusHistory(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String,
      changedBy: json['changed_by'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusDisplayName {
    switch (newStatus) {
      case 'pending':
        return 'Submitted';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected';
      default:
        return newStatus;
    }
  }
}
