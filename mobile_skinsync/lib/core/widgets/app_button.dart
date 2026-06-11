import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

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
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Text(label);

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.secondary => OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.ai => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ai,
          foregroundColor: Colors.white,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
      AppButtonVariant.danger => FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
        ),
        onPressed: isLoading ? null : onPressed,
        icon: icon ?? const SizedBox.shrink(),
        label: child,
      ),
    };

    final effective = icon == null
        ? switch (variant) {
            AppButtonVariant.primary => FilledButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.secondary => OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.ai => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ai,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
            AppButtonVariant.danger => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : onPressed,
              child: child,
            ),
          }
        : button;

    final themed = Theme(
      data: Theme.of(context).copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            minimumSize: const Size(0, 52),
          ),
        ),
      ),
      child: effective,
    );

    if (!expand) {
      return themed;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite) {
          return SizedBox(width: double.infinity, child: themed);
        }
        return themed;
      },
    );
  }
}
