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

class _GreetingHeaderState extends State<GreetingHeader>
    with SingleTickerProviderStateMixin {
  String _firstName = 'Roxasnon';
  bool _isLoading = true;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _loadUserName();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
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

  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return Icons.wb_sunny_rounded; // Morning sun
    } else if (hour < 18) {
      return Icons.wb_sunny_outlined; // Afternoon sun
    } else {
      return Icons.nightlight_round; // Evening moon
    }
  }

  Color _getIconColor() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return const Color(0xFFFFA726); // Orange for morning
    } else if (hour < 18) {
      return const Color(0xFFFFB74D); // Light orange for afternoon
    } else {
      return const Color(0xFF5C6BC0); // Purple-blue for evening
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Animated time-appropriate icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Transform.rotate(
                    angle: value * 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getIconColor().withOpacity(0.2),
                            _getIconColor().withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getTimeIcon(),
                        color: _getIconColor(),
                        size: 28,
                        shadows: [
                          Shadow(
                            color: _getIconColor().withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Greeting text with wave animation
            Expanded(
              child: AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _waveAnimation.value),
                    child: child,
                  );
                },
                child: Text(
                  '${_getGreeting()}, $_firstName!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD4A13D),
                    letterSpacing: 0.5,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Text(
            'How can we help you today?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
