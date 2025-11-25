import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Main scaffold with bottom navigation bar
/// Wraps all main app screens for consistent navigation
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: _BottomNavBar());
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    // Determine current index based on route
    int currentIndex = 0;
    if (currentLocation.startsWith('/reports')) {
      currentIndex = 1;
    } else if (currentLocation.startsWith('/appointments')) {
      currentIndex = 2;
    } else if (currentLocation.startsWith('/announcements')) {
      currentIndex = 3;
    } else if (currentLocation.startsWith('/profile')) {
      currentIndex = 4;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.4)
        : AppColors.shadowMedium;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.report_problem_outlined,
                selectedIcon: Icons.report_problem,
                label: 'Reports',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/reports'),
              ),
              _NavItem(
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_today,
                label: 'Appointments',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/appointments'),
              ),
              _NavItem(
                icon: Icons.campaign_outlined,
                selectedIcon: Icons.campaign,
                label: 'News',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/announcements'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color selectedColor =
        theme.bottomNavigationBarTheme.selectedItemColor ??
        theme.colorScheme.primary;
    final Color unselectedColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ??
        (isDark
            ? theme.textTheme.bodySmall?.color?.withOpacity(0.7) ??
                  Colors.white70
            : AppColors.textSecondary);
    final color = isSelected ? selectedColor : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
