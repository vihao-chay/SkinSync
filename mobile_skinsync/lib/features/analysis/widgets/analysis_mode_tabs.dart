import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AnalysisMode { skin, product }

class AnalysisModeTabs extends StatelessWidget {
  const AnalysisModeTabs({
    super.key,
    required this.selectedMode,
    required this.onChanged,
  });

  final AnalysisMode selectedMode;
  final ValueChanged<AnalysisMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Skin',
              icon: Icons.face_retouching_natural_outlined,
              selected: selectedMode == AnalysisMode.skin,
              onTap: () => onChanged(AnalysisMode.skin),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Product',
              icon: Icons.science_outlined,
              selected: selectedMode == AnalysisMode.product,
              onTap: () => onChanged(AnalysisMode.product),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryDark : AppColors.foreground,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.primaryDark : AppColors.foreground,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
