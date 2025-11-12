import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Announcements screen - city news and advisories
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  // Sample announcements data (will be from backend later)
  static final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'City Health Advisory',
      'content':
          'Free vaccination program continues at all city health centers. Bring valid ID and vaccination card.',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'health',
    },
    {
      'title': 'Road Construction Update',
      'content':
          'Main highway repairs ongoing. Expect minor delays. Alternative routes available via Barangay Roads.',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'infrastructure',
    },
    {
      'title': 'Weather Advisory',
      'content':
          'Moderate to heavy rainfall expected this week. Stay alert for possible flooding in low-lying areas.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'type': 'weather',
    },
  ];

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'health':
        return Icons.local_hospital;
      case 'infrastructure':
        return Icons.construction;
      case 'weather':
        return Icons.cloud;
      default:
        return Icons.announcement;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'health':
        return AppColors.success;
      case 'infrastructure':
        return AppColors.warning;
      case 'weather':
        return AppColors.info;
      default:
        return AppColors.capizBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Announcements')),
      body: _announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for updates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                final color = _getTypeColor(announcement['type']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.gray200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and date row
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getTypeIcon(announcement['type']),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'MMM dd, yyyy • h:mm a',
                                  ).format(announcement['date']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Title
                          Text(
                            announcement['title'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),

                          const SizedBox(height: 8),

                          // Content
                          Text(
                            announcement['content'],
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
