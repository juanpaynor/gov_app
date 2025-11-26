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

class _StatsCardState extends State<StatsCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _iconBounceController;
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
    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animationController.forward();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _iconBounceController.dispose();
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
              colors: [AppColors.capizBlue, Color(0xFF1565C0)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.capizBlue.withOpacity(0.5),
                blurRadius: 32,
                spreadRadius: 4,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
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
                      child: SizedBox(
                        height: 140,
                        child: Stack(
                          key: const ValueKey('stats-row'),
                          children: [
                            // Diagonal layout with offset positioning
                            Positioned(
                              left: 0,
                              top: 0,
                              child: _StatItem(
                                icon: Icons.warning_amber_rounded,
                                count: _reportsCount,
                                label: 'Reports',
                                color: const Color(0xFFFFA726),
                                accentColor: const Color(0xFFFF9800),
                                iconBounceAnimation: _iconBounceController,
                                delay: 0,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 20,
                              child: Center(
                                child: _StatItem(
                                  icon: Icons.event_rounded,
                                  count: _appointmentsCount,
                                  label: 'Appointments',
                                  color: Colors.white,
                                  accentColor: const Color(0xFFE3F2FD),
                                  iconBounceAnimation: _iconBounceController,
                                  delay: 150,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: _StatItem(
                                icon: Icons.check_circle_rounded,
                                count: _resolvedCount,
                                label: 'Resolved',
                                color: const Color(0xFF66BB6A),
                                accentColor: const Color(0xFF4CAF50),
                                iconBounceAnimation: _iconBounceController,
                                delay: 300,
                              ),
                            ),
                          ],
                        ),
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

class _StatItem extends StatefulWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final Color accentColor;
  final AnimationController iconBounceAnimation;
  final int delay;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.accentColor,
    required this.iconBounceAnimation,
    required this.delay,
  });

  @override
  State<_StatItem> createState() => _StatItemState();
}

class _StatItemState extends State<_StatItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverScale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onTapUp: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      onTapCancel: () {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: ScaleTransition(
        scale: _hoverScale,
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withOpacity(0.15),
                widget.accentColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withOpacity(_isHovered ? 0.5 : 0.3),
              width: 1.5,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: widget.iconBounceAnimation,
                builder: (context, child) {
                  final delayedValue =
                      (widget.iconBounceAnimation.value - (widget.delay / 1000))
                          .clamp(0.0, 1.0);
                  final bounce = Curves.easeInOut.transform(delayedValue);
                  final offset = (bounce - 0.5) * 8;
                  return Transform.translate(
                    offset: Offset(0, -offset),
                    child: Transform.rotate(
                      angle: (bounce - 0.5) * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 24),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
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
                  '${widget.count}',
                  key: ValueKey<int>(widget.count),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                    shadows: [
                      Shadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.color.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
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
