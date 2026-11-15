import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'colors.dart';
import 'typography.dart';
import '../utils/app_animations.dart';

/// Light theme configuration
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
        },
      ),
      
      // Color scheme - Blue + White Theme
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.lightBlue,
        background: AppColors.backgroundLight,
        surface: AppColors.cardWhite,
        error: AppColors.error,
        onPrimary: AppColors.cardWhite,
        onSecondary: AppColors.textNavy,
        onBackground: AppColors.textNavy,
        onSurface: AppColors.textNavy,
        onError: AppColors.cardWhite,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.textNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textNavy,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // rounded-2xl
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // rounded-2xl
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // rounded-2xl
          borderSide: BorderSide(color: AppColors.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // rounded-2xl
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // rounded-2xl
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), // rounded-2xl
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
      
      // Text theme
      textTheme: AppTypography.lightTextTheme,
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textNavy,
        size: 24,
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.borderGrey,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Dark theme configuration (Aligned with crisp clean bright theme to prevent black boxes)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
        },
      ),
      
      // Color scheme - Blue + Pure Light
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.lightBlue,
        background: AppColors.backgroundLight,
        surface: AppColors.cardWhite,
        error: AppColors.error,
        onPrimary: AppColors.cardWhite,
        onSecondary: AppColors.textNavy,
        onBackground: AppColors.textNavy,
        onSurface: AppColors.textNavy,
        onError: AppColors.cardWhite,
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardWhite,
        foregroundColor: AppColors.textNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.textNavy,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // rounded-2xl
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.cardWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // rounded-2xl/3xl
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Input decoration theme - Clean White with crisp subtle border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.slate200.withOpacity(0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.slate200.withOpacity(0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
      
      // Text theme
      textTheme: AppTypography.darkTextTheme,
      
      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimaryDark,
        size: 24,
      ),
      
      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.textSecondaryDark.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

