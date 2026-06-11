import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 36,
    this.radius = 12,
    this.showShadow = true,
  });

  final double size;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'logo.jpg',
        fit: BoxFit.cover,
        semanticLabel: 'SkinSync logo',
        errorBuilder: (_, _, _) =>
            const Icon(Icons.spa_rounded, color: AppColors.primaryDark),
      ),
    );
  }
}
