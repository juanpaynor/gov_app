import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/config/supabase_config.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/services/persistent_chat_service.dart';
import 'features/common/widgets/announcement_banner.dart';

/// MyRoxas - City Government Services for Roxas City
/// A modern civic app connecting Roxasnons with their local government
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (skip for web since .env doesn't work well there)
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  // Initialize notification service
  final notificationService = InAppNotificationService();

  // Initialize persistent chat service
  final persistentChatService = PersistentChatService();
  await persistentChatService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: notificationService),
        ChangeNotifierProvider.value(value: persistentChatService),
      ],
      child: const MyRoxasApp(),
    ),
  );
}

class MyRoxasApp extends StatelessWidget {
  const MyRoxasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'MyRoxas',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                // Notification banner overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Consumer<InAppNotificationService>(
                    builder: (context, service, _) {
                      if (service.currentNotification == null) {
                        return const SizedBox.shrink();
                      }
                      return AnnouncementBanner(
                        announcement: service.currentNotification!,
                        onDismiss: () {
                          service.dismissNotification(
                            service.currentNotification!.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
