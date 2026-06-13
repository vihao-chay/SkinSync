import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class CategoryChipBar<T> extends StatelessWidget {
  const CategoryChipBar({
    super.key,
    required this.items,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
    this.iconBuilder,
  });

  final List<T> items;
  final T selected;
  final String Function(T item) labelBuilder;
  final IconData Function(T item)? iconBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isSelected = item == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              avatar: iconBuilder == null
                  ? null
                  : Icon(
                      iconBuilder!(item),
                      size: 16,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.mutedText,
                    ),
              label: Text(labelBuilder(item)),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: AppColors.secondary,
              backgroundColor: Colors.white.withValues(alpha: 0.7),
              side: const BorderSide(color: AppColors.border),
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppColors.primaryDark : AppColors.mutedText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
