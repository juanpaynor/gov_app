import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// MyRoxas - City Government Services for Roxas City
/// A modern civic app connecting Roxasnons with their local government
void main() {
  runApp(const MyRoxasApp());
}

class MyRoxasApp extends StatelessWidget {
  const MyRoxasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MyRoxas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
