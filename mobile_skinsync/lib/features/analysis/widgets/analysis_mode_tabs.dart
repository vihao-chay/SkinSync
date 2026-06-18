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
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Skin',
              selected: selectedMode == AnalysisMode.skin,
              onTap: () => onChanged(AnalysisMode.skin),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Products',
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: selected ? AppColors.primaryDark : AppColors.foreground,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 9,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
