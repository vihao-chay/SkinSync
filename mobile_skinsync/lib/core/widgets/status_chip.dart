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
        AppColors.surfaceMuted,
        AppColors.border,
        AppColors.primaryDark,
      ),
      StatusChipTone.success => _ChipColors(
        const Color(0xFFE4F1E4),
        const Color(0xFFBFD8BF),
        AppColors.success,
      ),
      StatusChipTone.warning => _ChipColors(
        const Color(0xFFF9ECDA),
        const Color(0xFFE7CDA8),
        AppColors.warning,
      ),
      StatusChipTone.danger => _ChipColors(
        const Color(0xFFF7E6E0),
        const Color(0xFFE7C1B6),
        AppColors.error,
      ),
      StatusChipTone.accent => _ChipColors(
        AppColors.secondary,
        AppColors.border,
        AppColors.primaryDark,
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
