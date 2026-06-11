import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Padding(padding: padding, child: child),
              )
            : InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Padding(padding: padding, child: child),
                ),
              ),
      ),
    );

    return card;
  }
}
