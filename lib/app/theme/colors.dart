import 'package:flutter/material.dart';

/// Brand colors for the application - matching React design
class AppColors {
  // Primary brand color (blue-600)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Secondary brand color (yellow-400)
  static const Color secondary = Color(0xFFFACC15);
  static const Color secondaryDark = Color(0xFFEAB308);
  static const Color secondaryLight = Color(0xFFFDE047);

  // Background colors (slate-50 / slate-950)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF020617);

  // Additional semantic colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Text colors (slate-900 / slate-50)
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);

  // Surface colors (white / slate-900)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A);

  // Slate colors for borders and backgrounds
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Blue colors
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue900 = Color(0xFF1E3A8A);
  static const Color blue950 = Color(0xFF172554);

  // Yellow colors
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF9C3);
  static const Color yellow400 = Color(0xFFFACC15);
  static const Color yellow600 = Color(0xFFEAB308);
  static const Color yellow900 = Color(0xFF713F12);
  static const Color yellow950 = Color(0xFF422006);

  // Green colors
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green700 = Color(0xFF15803D);
  static const Color green900 = Color(0xFF14532D);
  static const Color green950 = Color(0xFF052E16);

  // Red colors
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color red900 = Color(0xFF7F1D1D);
  static const Color red950 = Color(0xFF450A0A);

  // 🎨 Blue + White Marketplace Theme Colors
  static const Color primaryBlue = Color(0xFF1E88E5);      // #1E88E5
  static const Color darkBlue = Color(0xFF1565C0);        // #1565C0
  static const Color lightBlue = Color(0xFF42A5F5);       // #42A5F5
  static const Color cardWhite = Color(0xFFFFFFFF);        // #FFFFFF
  static const Color textNavy = Color(0xFF0F172A);        // #0F172A
  static const Color borderGrey = Color(0xFFE2E8F0);       // #E2E8F0

  // Blue gradient colors for Blue+White theme
  static const Color blueGradientStart = Color(0xFF1E88E5);  // primaryBlue
  static const Color blueGradientEnd = Color(0xFF1565C0);     // darkBlue
  static const Color blueGradientLight = Color(0xFF42A5F5);  // lightBlue

  // 🧩 Aliases for backward compatibility (from previous code)
  static const Color blue500 = blue600;
  static const Color yellow500 = yellow400;
  static const Color yellow200 = yellow100;
  static const Color yellow300 = yellow400;
  static const Color yellow700 = yellow600;
  static const Color red500 = red600;

  // 🧱 Private constructor
  AppColors._();
}
