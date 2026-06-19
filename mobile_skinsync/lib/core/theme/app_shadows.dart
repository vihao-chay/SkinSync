import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.foreground.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.foreground.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get sageGlow => [
    BoxShadow(
      color: AppColors.primaryContainer.withValues(alpha: 0.22),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: AppColors.accent.withValues(alpha: 0.18),
      blurRadius: 26,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    ),
  ];
}
