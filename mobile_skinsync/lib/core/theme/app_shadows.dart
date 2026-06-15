import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.055),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: 0.09),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
