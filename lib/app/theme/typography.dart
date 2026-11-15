import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography definitions using Poppins font
class AppTypography {
  // Font family
  static const String fontFamily = 'Poppins';
  
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
    height: 1.22,
  );
  
  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );
  
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
  
  // Private constructor to prevent instantiation
  AppTypography._();
  
  /// Get the complete TextTheme for light mode
  static TextTheme get lightTextTheme {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: AppColors.textPrimaryLight),
      displayMedium: displayMedium.copyWith(color: AppColors.textPrimaryLight),
      displaySmall: displaySmall.copyWith(color: AppColors.textPrimaryLight),
      headlineLarge: headlineLarge.copyWith(color: AppColors.textPrimaryLight),
      headlineMedium: headlineMedium.copyWith(color: AppColors.textPrimaryLight),
      headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimaryLight),
      titleLarge: titleLarge.copyWith(color: AppColors.textPrimaryLight),
      titleMedium: titleMedium.copyWith(color: AppColors.textPrimaryLight),
      titleSmall: titleSmall.copyWith(color: AppColors.textPrimaryLight),
      bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimaryLight),
      bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimaryLight),
      bodySmall: bodySmall.copyWith(color: AppColors.textSecondaryLight),
      labelLarge: labelLarge.copyWith(color: AppColors.textPrimaryLight),
      labelMedium: labelMedium.copyWith(color: AppColors.textPrimaryLight),
      labelSmall: labelSmall.copyWith(color: AppColors.textSecondaryLight),
    );
  }
  
  /// Get the complete TextTheme for dark mode
  static TextTheme get darkTextTheme {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: AppColors.textPrimaryDark),
      displayMedium: displayMedium.copyWith(color: AppColors.textPrimaryDark),
      displaySmall: displaySmall.copyWith(color: AppColors.textPrimaryDark),
      headlineLarge: headlineLarge.copyWith(color: AppColors.textPrimaryDark),
      headlineMedium: headlineMedium.copyWith(color: AppColors.textPrimaryDark),
      headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimaryDark),
      titleLarge: titleLarge.copyWith(color: AppColors.textPrimaryDark),
      titleMedium: titleMedium.copyWith(color: AppColors.textPrimaryDark),
      titleSmall: titleSmall.copyWith(color: AppColors.textPrimaryDark),
      bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimaryDark),
      bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimaryDark),
      bodySmall: bodySmall.copyWith(color: AppColors.textSecondaryDark),
      labelLarge: labelLarge.copyWith(color: AppColors.textPrimaryDark),
      labelMedium: labelMedium.copyWith(color: AppColors.textPrimaryDark),
      labelSmall: labelSmall.copyWith(color: AppColors.textSecondaryDark),
    );
  }
}

