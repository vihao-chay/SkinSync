import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class GradientPillButton extends StatelessWidget {
  const GradientPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return Opacity(
      opacity: disabled ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: disabled ? null : onPressed,
          child: Ink(
            height: 54,
            width: expanded ? double.infinity : null,
            decoration: BoxDecoration(
              gradient: disabled
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
              color: disabled ? AppColors.subtleText.withValues(alpha: 0.25) : null,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          icon!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
