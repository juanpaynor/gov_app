import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Horizontal status stepper widget showing report progress
class StatusStepper extends StatelessWidget {
  final String currentStatus;

  const StatusStepper({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = ['pending', 'in_progress', 'resolved'];
    final currentIndex = statuses.indexOf(currentStatus);

    return Row(
      children: List.generate(statuses.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Line between dots
          final lineIndex = (index - 1) ~/ 2;
          final isCompleted = lineIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? AppColors.capizBlue : AppColors.gray300,
            ),
          );
        } else {
          // Dot
          final dotIndex = index ~/ 2;
          final isCompleted = dotIndex < currentIndex;
          final isCurrent = dotIndex == currentIndex;

          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted || isCurrent
                  ? AppColors.capizBlue
                  : AppColors.gray300,
              border: Border.all(
                color: isCurrent ? AppColors.capizBlue : AppColors.gray300,
                width: isCurrent ? 3 : 1,
              ),
            ),
          );
        }
      }),
    );
  }
}
