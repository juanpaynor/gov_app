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
    return Row(
      children: [
        // Logo
        Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.capizGold.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              'https://hmozgkvakanhxddmficm.supabase.co/storage/v1/object/public/Images_random/HDlogo-pbb5bel39vn69zemn9s1ntn15vgtrbn30kqu8la0rg.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, Roxasnon!',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(
                      color: AppColors.capizBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'How can we help you today?',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
