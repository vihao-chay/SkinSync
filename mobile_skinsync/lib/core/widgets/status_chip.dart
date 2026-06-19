import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum StatusChipTone { neutral, success, warning, danger, accent }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusChipTone.neutral,
  });

  final String label;
  final IconData? icon;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ChipColors _colorsForTone(StatusChipTone tone) {
    return switch (tone) {
      StatusChipTone.neutral => _ChipColors(
        AppColors.surfaceContainerLow,
        AppColors.outlineVariant,
        AppColors.onSurfaceVariant,
      ),
      StatusChipTone.success => _ChipColors(
        AppColors.primaryFixed.withValues(alpha: 0.64),
        AppColors.primaryContainer.withValues(alpha: 0.42),
        AppColors.primary,
      ),
      StatusChipTone.warning => _ChipColors(
        AppColors.tertiaryFixed.withValues(alpha: 0.72),
        AppColors.tertiaryFixedDim.withValues(alpha: 0.58),
        AppColors.tertiary,
      ),
      StatusChipTone.danger => _ChipColors(
        AppColors.errorContainer,
        AppColors.error.withValues(alpha: 0.18),
        AppColors.error,
      ),
      StatusChipTone.accent => _ChipColors(
        AppColors.secondaryFixed,
        AppColors.secondaryFixedDim.withValues(alpha: 0.58),
        AppColors.secondaryAction,
      ),
    };
  }
}

class _ChipColors {
  const _ChipColors(this.background, this.border, this.foreground);

  final Color background;
  final Color border;
  final Color foreground;
}
