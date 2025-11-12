import 'package:go_router/go_router.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/reports/screens/new_report_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/book_appointment_screen.dart';
import '../../features/hotlines/screens/hotlines_screen.dart';
import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../navigation/main_scaffold.dart';

/// MyCapiz app router configuration
/// Uses go_router for declarative navigation with bottom tab navigation
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Main shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          // Home
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),

          // Reports
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsScreen()),
          ),

          // Appointments
          GoRoute(
            path: '/appointments',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AppointmentsScreen()),
          ),

          // Hotlines
          GoRoute(
            path: '/hotlines',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HotlinesScreen()),
          ),

          // Announcements
          GoRoute(
            path: '/announcements',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnnouncementsScreen()),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside bottom nav)
      GoRoute(
        path: '/reports/new',
        builder: (context, state) => const NewReportScreen(),
      ),

      GoRoute(
        path: '/appointments/book',
        builder: (context, state) => const BookAppointmentScreen(),
      ),
    ],
  );
}
