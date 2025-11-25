import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/appointments_repository.dart';
import '../../../core/theme/gradient_button.dart';
import 'package:go_router/go_router.dart';

/// Hero stats card showing user activity summary
/// Glassmorphism design with blur effect
class StatsCard extends StatefulWidget {
  const StatsCard({super.key});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final _appointmentsRepository = AppointmentsRepository();
  int _reportsCount = 0;
  int _appointmentsCount = 0;
  int _resolvedCount = 0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final reportsResponse = await supabase
            .from('reports')
            .select()
            .eq('user_id', userId);

        // Keep appointment count logic in sync with appointments screen
        final upcomingAppointments = await _appointmentsRepository
            .getUpcomingAppointments();

        final resolvedResponse = await supabase
            .from('reports')
            .select()
            .eq('user_id', userId)
            .eq('status', 'resolved');

        if (mounted) {
          setState(() {
            _reportsCount = (reportsResponse as List).length;
            _appointmentsCount = upcomingAppointments.length;
            _resolvedCount = (resolvedResponse as List).length;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stats card data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.capizBlue, Color(0xFF2196F3)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.capizBlue.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.capizBlue.withOpacity(0.8),
                          const Color(0xFF2196F3).withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.dashboard_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Activity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                          ),
                        ),
                        Text(
                          'Track your submissions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.yellow.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isRefreshing ? null : _loadData,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          RotationTransition(
                            turns: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.yellow,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.yellow,
                              size: 22,
                            ),
                    ),
                    tooltip: 'Refresh activity',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.yellow,
                          ),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: Row(
                        key: const ValueKey('stats-row'),
                        children: [
                          Expanded(
                            child: _StatItem(
                              icon: Icons.report_problem_outlined,
                              count: _reportsCount,
                              label: 'Reports',
                              color: Colors.yellow,
                              labelColor: Colors.yellow.withOpacity(0.8),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.yellow.withOpacity(0.3),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.calendar_today_outlined,
                              count: _appointmentsCount,
                              label: 'Appointments',
                              color: Colors.yellow,
                              labelColor: Colors.yellow.withOpacity(0.8),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.yellow.withOpacity(0.3),
                          ),
                          Expanded(
                            child: _StatItem(
                              icon: Icons.check_circle_outline,
                              count: _resolvedCount,
                              label: 'Resolved',
                              color: Colors.yellow,
                              labelColor: Colors.yellow.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  onPressed: () => context.push('/reports'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.trending_up, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'View activity insights',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final Color labelColor;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
          child: Text(
            '$count',
            key: ValueKey<int>(count),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
