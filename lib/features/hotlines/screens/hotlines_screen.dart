import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

/// Hotlines screen - emergency and important contact numbers
class HotlinesScreen extends StatelessWidget {
  const HotlinesScreen({super.key});

  // Emergency hotlines data
  static final List<Map<String, String>> _hotlines = [
    {'name': 'City Emergency Response', 'number': '911', 'icon': 'emergency'},
    {
      'name': 'City Health Office',
      'number': '(036) 621-0379',
      'icon': 'health',
    },
    {'name': 'Police Station', 'number': '(036) 621-0356', 'icon': 'police'},
    {'name': 'Fire Department', 'number': '(036) 621-0245', 'icon': 'fire'},
    {
      'name': 'Disaster Risk Reduction',
      'number': '(036) 621-0123',
      'icon': 'disaster',
    },
    {'name': 'Roxas City Hall', 'number': '(036) 621-0340', 'icon': 'capitol'},
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  IconData _getIcon(String iconType) {
    switch (iconType) {
      case 'emergency':
        return Icons.emergency;
      case 'health':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fire':
        return Icons.local_fire_department;
      case 'disaster':
        return Icons.warning_amber;
      case 'capitol':
        return Icons.account_balance;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Emergency Hotlines')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any number to call immediately in case of emergency',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Hotlines list
          ..._hotlines.map((hotline) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.gray200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.capizBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIcon(hotline['icon']!),
                      color: AppColors.capizBlue,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    hotline['name']!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      hotline['number']!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.capizBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.success),
                    onPressed: () => _makePhoneCall(hotline['number']!),
                    tooltip: 'Call ${hotline['name']}',
                  ),
                  onTap: () => _makePhoneCall(hotline['number']!),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
