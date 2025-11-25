import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';

/// Greeting header widget
/// Displays a warm, localized greeting based on time of day
class GreetingHeader extends StatefulWidget {
  const GreetingHeader({super.key});

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
  String _firstName = 'Roxasnon';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _firstName = 'Roxasnon';
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to get from user_profiles table first
      final response = await supabase
          .from('user_profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        final fullName = response['full_name'] as String;
        setState(() {
          _firstName = fullName.split(' ').first;
          _isLoading = false;
        });
        return;
      }

      // Fallback to user metadata
      final fullName = user.userMetadata?['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        setState(() {
          _firstName = fullName.split(' ').first;
          _isLoading = false;
        });
        return;
      }

      // Last resort: use default
      setState(() {
        _firstName = 'Roxasnon';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _firstName = 'Roxasnon';
        _isLoading = false;
      });
    }
  }

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getGreeting()}, $_firstName!',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How can we help you today?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
