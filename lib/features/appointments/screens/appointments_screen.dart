import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/appointments_repository.dart';
import '../../../models/appointment.dart';

/// Appointments screen - view scheduled appointments
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final _repository = AppointmentsRepository();
  late TabController _tabController;

  List<Appointment> _upcomingAppointments = [];
  List<Appointment> _ongoingAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);

    try {
      final upcoming = await _repository.getUpcomingAppointments();
      final ongoing = await _repository.getOngoingAppointments();

      setState(() {
        _upcomingAppointments = upcoming;
        _ongoingAppointments = ongoing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildOngoingTab(), _buildUpcomingTab()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/appointments/book');
          if (result == true) {
            _loadAppointments();
          }
        },
        backgroundColor: AppColors.capizGold,
        icon: const Icon(Icons.add),
        label: const Text('Book Appointment'),
      ),
    );
  }

  Widget _buildOngoingTab() {
    if (_ongoingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_outlined,
        title: 'No ongoing appointments',
        subtitle: 'Appointments for today will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ongoingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _ongoingAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule_outlined,
        title: 'No upcoming appointments',
        subtitle: 'Book an appointment with a provincial office',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final hintColor = theme.textTheme.bodySmall?.color?.withOpacity(0.6);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: hintColor),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final theme = Theme.of(context);
    final mutedTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);
    final statusColor = _getStatusColor(appointment.status);
    final statusIcon = _getStatusIcon(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: InkWell(
        onTap: () async {
          final result = await context.push('/appointments/${appointment.id}');
          if (result == true) {
            _loadAppointments(); // Refresh if cancelled
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Ticket number and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.capizBlue,
                          AppColors.capizBlue.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.ticketNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          appointment.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Department
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.capizGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(appointment.departmentIcon ?? 'business'),
                      size: 20,
                      color: AppColors.capizGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.departmentName ?? 'Department',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appointment.fullName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: mutedTextColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      appointment.formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: mutedTextColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      appointment.formattedTimeSlot,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Purpose
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(
                    theme.brightness == Brightness.dark ? 0.6 : 0.9,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: mutedTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.purpose,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.checkedIn:
        return AppColors.success;
      case AppointmentStatus.inProgress:
        return AppColors.capizBlue;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.missed:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.pending_outlined;
      case AppointmentStatus.checkedIn:
        return Icons.check_circle_outline;
      case AppointmentStatus.inProgress:
        return Icons.play_circle_outline;
      case AppointmentStatus.completed:
        return Icons.check_circle;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.missed:
        return Icons.event_busy;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'business':
        return Icons.business;
      case 'construction':
        return Icons.construction;
      case 'description':
        return Icons.description;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'gavel':
        return Icons.gavel;
      default:
        return Icons.business;
    }
  }
}
