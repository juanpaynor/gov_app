import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/gradient_button.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/reports_repository.dart';
import '../../../models/report.dart';
import '../../../models/report_attachment.dart';
import '../../../models/report_comment.dart';
import '../../../models/report_status_history.dart';
import '../widgets/status_timeline.dart';

/// Report details screen showing full report information with status timeline
class ReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late final ReportsRepository _repository;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = ReportsRepository(supabase);
    _loadReportDetails();
  }

  Report? _report;
  List<ReportAttachment> _attachments = [];
  List<ReportComment> _comments = [];
  List<ReportStatusHistory> _statusHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadReportDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repository.getReportById(widget.reportId),
        _repository.getReportAttachments(widget.reportId),
        _repository.getReportComments(widget.reportId),
        _repository.getReportStatusHistory(widget.reportId),
      ]);

      setState(() {
        _report = results[0] as Report;
        _attachments = results[1] as List<ReportAttachment>;
        _comments = results[2] as List<ReportComment>;
        _statusHistory = results[3] as List<ReportStatusHistory>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _repository.addComment(
        widget.reportId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadReportDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(title: const Text('Report Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load report',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: _loadReportDetails,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReportDetails,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Report Info
                  _buildReportInfo(),
                  const SizedBox(height: 20),

                  // Photos
                  if (_attachments.isNotEmpty) ...[
                    _buildPhotosSection(),
                    const SizedBox(height: 20),
                  ],

                  // Status Timeline
                  _buildTimelineSection(),
                  const SizedBox(height: 20),

                  // User Comments Section
                  if (_comments.where((c) => !c.isAdmin).isNotEmpty) ...[
                    _buildUserCommentsSection(),
                    const SizedBox(height: 20),
                  ],

                  // Add Comment
                  if (_report!.status != 'resolved' &&
                      _report!.status != 'rejected')
                    _buildAddCommentSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildReportInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge
            Row(
              children: [
                if (_report!.category?.icon != null)
                  Text(
                    _report!.category!.icon!,
                    style: const TextStyle(fontSize: 24),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _report!.category?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _report!.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Submitted ${DateFormat('MMM dd, yyyy • h:mm a').format(_report!.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _report!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // Location
            if (_report!.locationAddress != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _report!.locationAddress!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${_attachments.length})',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _attachments.length,
          itemBuilder: (context, index) {
            final attachment = _attachments[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                attachment.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.gray200,
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StatusTimeline(
          statusHistory: _statusHistory,
          comments: _comments,
          currentStatus: _report!.status,
        ),
      ),
    );
  }

  Widget _buildUserCommentsSection() {
    final userComments = _comments.where((c) => !c.isAdmin).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Comments',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...userComments.map((comment) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.gray200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • h:mm a',
                    ).format(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.comment,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddCommentSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Follow-up Comment',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add additional information or updates...',
              ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              onPressed: _addComment,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.send, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Send Comment'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
