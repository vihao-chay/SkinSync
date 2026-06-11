import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    displayMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.04,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.08,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.08,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.12,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.18,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      height: 1.22,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.heading,
      fontFamily: 'CormorantGaramond',
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.55,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.mutedText,
      fontFamily: 'DMSans',
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: AppColors.foreground,
      fontFamily: 'DMSans',
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: AppColors.mutedText,
      fontFamily: 'DMSans',
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: AppColors.subtleText,
      fontFamily: 'DMSans',
    ),
  );
}
