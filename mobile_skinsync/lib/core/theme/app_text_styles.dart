import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.1,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    displayMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.12,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    displaySmall: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.15,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.foreground,
      fontFamily: 'CormorantGaramond',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.mutedText,
      fontFamily: 'DMSans',
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: AppColors.mutedText,
      fontFamily: 'DMSans',
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: AppColors.subtleText,
      fontFamily: 'DMSans',
    ),
  );
}
