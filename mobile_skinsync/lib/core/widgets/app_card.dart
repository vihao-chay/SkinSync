import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

enum AppCardVariant { standard, hero, accent, muted, metric }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.backgroundColor,
    this.variant = AppCardVariant.standard,
    this.radius,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final AppCardVariant variant;
  final double? radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground =
        backgroundColor ?? _backgroundForVariant(variant);
    final resolvedRadius = radius ?? _radiusForVariant(variant);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(resolvedRadius),
      side: BorderSide(color: borderColor ?? _borderForVariant(variant)),
    );
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: Border.all(
          color: borderColor ?? _borderForVariant(variant),
          width: 1,
        ),
        boxShadow: variant == AppCardVariant.muted
            ? const []
            : variant == AppCardVariant.metric
            ? AppShadows.soft.sublist(0, 1)
            : AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(resolvedRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }

  Color _backgroundForVariant(AppCardVariant variant) {
    return switch (variant) {
      AppCardVariant.standard => AppColors.surface,
      AppCardVariant.hero => AppColors.surface,
      AppCardVariant.accent => AppColors.primaryFixed.withValues(alpha: 0.34),
      AppCardVariant.muted => AppColors.surfaceMuted,
      AppCardVariant.metric => AppColors.surface.withValues(alpha: 0.94),
    };
  }

  Color _borderForVariant(AppCardVariant variant) {
    return switch (variant) {
      AppCardVariant.standard => AppColors.border.withValues(alpha: 0.62),
      AppCardVariant.hero => Colors.white.withValues(alpha: 0.7),
      AppCardVariant.accent => AppColors.primaryContainer.withValues(
        alpha: 0.38,
      ),
      AppCardVariant.muted => AppColors.border.withValues(alpha: 0.56),
      AppCardVariant.metric => Colors.white.withValues(alpha: 0.76),
    };
  }

  double _radiusForVariant(AppCardVariant variant) {
    return switch (variant) {
      AppCardVariant.metric => AppRadius.medium,
      AppCardVariant.hero => AppRadius.card,
      AppCardVariant.accent => AppRadius.card,
      AppCardVariant.muted => AppRadius.card,
      AppCardVariant.standard => AppRadius.card,
    };
  }
}
