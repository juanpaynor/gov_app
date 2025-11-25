import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/report_status_history.dart';
import '../../../models/report_comment.dart';

/// Vertical timeline showing status changes and comments with smooth animations
class StatusTimeline extends StatelessWidget {
  final List<ReportStatusHistory> statusHistory;
  final List<ReportComment> comments;
  final String currentStatus;

  const StatusTimeline({
    super.key,
    required this.statusHistory,
    required this.comments,
    required this.currentStatus,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.capizBlue;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine status history with initial submission
    final allStatuses = <String>['pending', 'in_progress', 'resolved'];
    final completedStatuses = statusHistory.map((h) => h.newStatus).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInDown(
          duration: const Duration(milliseconds: 400),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.capizBlue.withOpacity(0.1),
                      AppColors.capizGold.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timeline,
                  color: AppColors.capizBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Status Timeline',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...allStatuses.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isCompleted = completedStatuses.contains(status) || status == 'pending';
          final isCurrent = status == currentStatus;
          final isLast = index == allStatuses.length - 1;

          // Find the history entry for this status
          final historyEntry = statusHistory.firstWhere(
            (h) => h.newStatus == status,
            orElse: () => ReportStatusHistory(
              id: '',
              reportId: '',
              newStatus: status,
              changedBy: '',
              createdAt: DateTime.now(),
            ),
          );

          // Find comments associated with this status
          final statusComments = comments.where((c) {
            // Match comments created around the time of this status change
            if (historyEntry.id.isEmpty) return false;
            final timeDiff = c.createdAt.difference(historyEntry.createdAt).abs();
            return timeDiff.inMinutes < 5; // Within 5 minutes of status change
          }).toList();

          return FadeInLeft(
            duration: Duration(milliseconds: 300 + (index * 100)),
            delay: Duration(milliseconds: 100 + (index * 50)),
            child: _TimelineItem(
              status: historyEntry.statusDisplayName,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              showLine: !isLast,
              color: _getStatusColor(status),
              timestamp: isCompleted ? historyEntry.createdAt : null,
              notes: historyEntry.notes,
              comments: statusComments,
              index: index,
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineItem extends StatefulWidget {
  final String status;
  final bool isCompleted;
  final bool isCurrent;
  final bool showLine;
  final Color color;
  final DateTime? timestamp;
  final String? notes;
  final List<ReportComment> comments;
  final int index;

  const _TimelineItem({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.showLine,
    required this.color,
    this.timestamp,
    this.notes,
    required this.comments,
    required this.index,
  });

  @override
  State<_TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<_TimelineItem> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) {
      _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    if (widget.isCurrent) {
      _pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isCompleted ? widget.color : AppColors.gray300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Dot and line
          SizedBox(
            width: 48,
            child: Column(
              children: [
                widget.isCurrent
                    ? ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                effectiveColor,
                                effectiveColor.withOpacity(0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: effectiveColor.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.radio_button_checked,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isCompleted
                              ? effectiveColor
                              : Colors.transparent,
                          border: Border.all(
                            color: effectiveColor,
                            width: widget.isCompleted ? 2.5 : 2,
                          ),
                          boxShadow: widget.isCompleted
                              ? [
                                  BoxShadow(
                                    color: effectiveColor.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.isCompleted
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                if (widget.showLine)
                  Expanded(
                    child: Container(
                      width: widget.isCompleted ? 3 : 2,
                      decoration: BoxDecoration(
                        gradient: widget.isCompleted
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  effectiveColor,
                                  effectiveColor.withOpacity(0.3),
                                ],
                              )
                            : null,
                        color: widget.isCompleted ? null : effectiveColor,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right side: Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: widget.isCurrent
                          ? LinearGradient(
                              colors: [
                                effectiveColor.withOpacity(0.1),
                                effectiveColor.withOpacity(0.05),
                              ],
                            )
                          : null,
                      color: widget.isCurrent ? null : (widget.isCompleted ? Colors.white : AppColors.gray50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isCurrent
                            ? effectiveColor.withOpacity(0.3)
                            : (widget.isCompleted ? effectiveColor.withOpacity(0.15) : AppColors.gray200),
                        width: widget.isCurrent ? 2 : 1,
                      ),
                      boxShadow: widget.isCurrent
                          ? [
                              BoxShadow(
                                color: effectiveColor.withOpacity(0.1),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : widget.isCompleted
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.status,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: widget.isCurrent ? FontWeight.bold : FontWeight.w600,
                                      color: widget.isCompleted
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                            ),
                            if (widget.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [effectiveColor, effectiveColor.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: effectiveColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timelapse,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Current',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (widget.timestamp != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd, yyyy • h:mm a').format(widget.timestamp!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gray200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.notes!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Show admin comments with fade in animation
                  ...widget.comments.where((c) => c.isAdmin).map((comment) {
                    return FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.capizBlue.withOpacity(0.08),
                                AppColors.capizBlue.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.capizBlue.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.capizBlue.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.capizBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Official Response',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.capizBlue,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment.comment,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (!widget.isCompleted && !widget.isCurrent) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Awaiting update',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
