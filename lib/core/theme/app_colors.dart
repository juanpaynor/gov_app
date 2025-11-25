import 'package:flutter/material.dart';

/// Modern color system for MyRoxas
/// Sleek, vibrant, and accessible colors for light and dark themes
class AppColors {
  // ============ LIGHT THEME COLORS ============

  // Primary - Modern Blue/Purple gradient base
  static const Color primaryLight = Color(0xFF064CA4); // Deep Blue
  static const Color primaryVariantLight = Color(0xFF074AA5); // Light Blue
  static const Color accentLight = Color(0xFFFAC505); // Yellow accent

  // Backgrounds - Clean and airy
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Text - High contrast for readability
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textHintLight = Color(0xFF999999);

  // ============ DARK THEME COLORS ============

  // Primary - Vibrant blues and purples
  static const Color primaryDark = Color(0xFF074AA5);
  static const Color primaryVariantDark = Color(0xFF064CA4);
  static const Color accentDark = Color(0xFFFAC505);

  // Backgrounds - Rich dark surfaces
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF151B2E);
  static const Color cardDark = Color(0xFF1A2236);

  // Text - Soft on dark
  static const Color textPrimaryDark = Color(0xFFE8EAED);
  static const Color textSecondaryDark = Color(0xFFB8BABD);
  static const Color textHintDark = Color(0xFF6B6D70);

  // ============ SHARED COLORS ============

  // Legacy Capiz colors (kept for compatibility)
  static const Color capizBlue = Color(0xFF1B4B7F);
  static const Color capizGold = Color(0xFFD4A13D);

  // Status colors - Work in both themes
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Glassmorphism overlays
  static const Color glassLight = Color(0xCCFFFFFF); // 80% white
  static const Color glassDark = Color(0x80151B2E); // 50% dark surface

  // Shadows and overlays
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowHeavy = Color(0x29000000);
  static const Color overlay = Color(0x80000000);

  // Compatibility aliases (for gradual migration)
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
}
