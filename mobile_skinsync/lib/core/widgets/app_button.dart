import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ai, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final baseShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    ButtonStyle filledStyle(Color? backgroundColor, Color? foregroundColor) =>
        FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: 14,
          ),
          shape: baseShape,
        );
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 54),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: 14,
      ),
      shape: baseShape,
    );
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(label);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        style: filledStyle(null, null),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.secondary => OutlinedButton.icon(
        style: outlinedStyle,
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.ai => FilledButton.icon(
        style: filledStyle(AppColors.ai, Colors.white),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.danger => FilledButton.icon(
        style: filledStyle(AppColors.error, Colors.white),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
    };

    final effective = icon == null
        ? switch (variant) {
            AppButtonVariant.primary => FilledButton(
              style: filledStyle(null, null),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.secondary => OutlinedButton(
              style: outlinedStyle,
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.ai => FilledButton(
              style: filledStyle(AppColors.ai, Colors.white),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.danger => FilledButton(
              style: filledStyle(AppColors.error, Colors.white),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
          }
        : button;

    if (!expand) {
      return effective;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          return SizedBox(width: double.infinity, child: effective);
        }
        return effective;
      },
    );
  }
}
