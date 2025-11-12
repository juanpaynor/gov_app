import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Greeting header widget
/// Displays a warm, localized greeting based on time of day
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Maayong aga'; // Good morning
    } else if (hour < 18) {
      return 'Maayong hapon'; // Good afternoon
    } else {
      return 'Maayong gab-i'; // Good evening
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}, Roxasnon!',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(color: AppColors.capizBlue),
        ),
        const SizedBox(height: 8),
        Text(
          'How can we help you today?',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
