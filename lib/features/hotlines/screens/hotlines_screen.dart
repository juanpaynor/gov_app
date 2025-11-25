import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

/// Hotlines screen - emergency and important contact numbers
class HotlinesScreen extends StatelessWidget {
  const HotlinesScreen({super.key});

  // Emergency hotlines data
  static final List<Map<String, dynamic>> _hotlines = [
    // Emergency Services
    {
      'name': 'National Emergency Services',
      'number': '911',
      'icon': 'emergency',
      'category': 'emergency',
    },
    {
      'name': 'Philippine Red Cross',
      'number': '143',
      'icon': 'health',
      'category': 'emergency',
    },
    {
      'name': 'Disaster Risk Reduction Office (CDRRMO)',
      'number': '(036) 522-7878',
      'icon': 'disaster',
      'category': 'emergency',
    },
    {
      'name': 'Fire Station (BFP)',
      'numbers': [
        '(036) 621-0221',
        '(036) 620-5618',
        '(036) 522-5211',
        '0950-608-5228',
      ],
      'icon': 'fire',
      'category': 'emergency',
    },
    {
      'name': 'Police Station (PNP)',
      'number': '0929-761-7482',
      'icon': 'police',
      'category': 'emergency',
    },
    {
      'name': 'Provincial Police Office (PNP)',
      'number': '0918-962-6477',
      'icon': 'police',
      'category': 'emergency',
    },
    {
      'name': 'Emergency Operations Center (EOC)',
      'number': '0912-472-2669',
      'icon': 'emergency',
      'category': 'emergency',
    },
    {
      'name': 'Red Cross - Mobile',
      'number': '0917-999-8888',
      'icon': 'health',
      'category': 'emergency',
    },

    // Government Offices
    {
      'name': "City Mayor's Office",
      'numbers': ['(036) 621-2049', '(036) 522-1987'],
      'icon': 'capitol',
      'category': 'government',
    },
    {
      'name': "City Administrator's Office",
      'number': '(036) 520-1520',
      'icon': 'capitol',
      'category': 'government',
    },
    {
      'name': 'City Health Office',
      'numbers': ['(036) 621-5686', '(036) 621-0578'],
      'icon': 'health',
      'category': 'government',
    },
    {
      'name': 'Social Welfare Office (CSWDO)',
      'number': '(036) 620-3190',
      'icon': 'social',
      'category': 'government',
    },
    {
      'name': "City Engineer's Office",
      'number': '(036) 620-5877',
      'icon': 'engineering',
      'category': 'government',
    },
    {
      'name': 'City Communications Group',
      'number': '(036) 522-1985',
      'icon': 'communication',
      'category': 'government',
    },
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
      case 'social':
        return Icons.people;
      case 'engineering':
        return Icons.engineering;
      case 'communication':
        return Icons.campaign;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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

          // Emergency Services Section
          Text(
            'Emergency Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.capizBlue,
            ),
          ),
          const SizedBox(height: 12),

          // Emergency hotlines
          ..._hotlines.where((h) => h['category'] == 'emergency').map((
            hotline,
          ) {
            return _buildHotlineCard(context, hotline);
          }),

          const SizedBox(height: 32),

          // Government Offices Section
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Government Offices (Mon-Fri, 8:00 AM - 5:00 PM)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: mutedTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Government office hotlines
          ..._hotlines.where((h) => h['category'] == 'government').map((
            hotline,
          ) {
            return _buildHotlineCard(context, hotline);
          }),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(BuildContext context, Map<String, dynamic> hotline) {
    final theme = Theme.of(context);
    // Handle multiple numbers
    final hasMultipleNumbers = hotline.containsKey('numbers');
    final displayNumber = hasMultipleNumbers
        ? '${hotline['numbers'].length} numbers'
        : hotline['number']!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        ),
        child: hasMultipleNumbers
            ? ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
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
                    displayNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.capizBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                children: (hotline['numbers'] as List<String>).map((number) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32),
                    title: Text(
                      number,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.capizBlue,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.phone,
                        color: AppColors.success,
                        size: 20,
                      ),
                      onPressed: () => _makePhoneCall(number),
                      tooltip: 'Call $number',
                    ),
                    onTap: () => _makePhoneCall(number),
                  );
                }).toList(),
              )
            : ListTile(
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
                    displayNumber,
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
  }
}
