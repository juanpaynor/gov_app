/// Report attachment model
class ReportAttachment {
  final String id;
  final String reportId;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final int? fileSize;
  final String uploadedBy;
  final DateTime createdAt;

  ReportAttachment({
    required this.id,
    required this.reportId,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory ReportAttachment.fromJson(Map<String, dynamic> json) {
    return ReportAttachment(
      id: json['id'] as String,
      reportId: json['report_id'] as String,
      fileUrl: json['file_url'] as String,
      fileName: json['file_name'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
