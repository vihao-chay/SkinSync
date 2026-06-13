import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'status_chip.dart';

class RoutineChecklistItem extends StatelessWidget {
  const RoutineChecklistItem({
    super.key,
    required this.step,
    required this.completed,
    required this.onChanged,
  });

  final RegimenStep step;
  final bool completed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.standard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onChanged,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? AppColors.primaryDark : Colors.white,
                border: Border.all(
                  color: completed ? AppColors.primaryDark : AppColors.border,
                  width: 1.4,
                ),
              ),
              child: Icon(
                completed ? Icons.check_rounded : Icons.circle_outlined,
                size: completed ? 16 : 14,
                color: completed ? Colors.white : AppColors.subtleText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StepBubble(number: step.stepOrder),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: _friendly(step.category),
                      icon: _categoryIcon(step.category),
                    ),
                    if ((step.frequency ?? '').trim().isNotEmpty)
                      StatusChip(
                        label: _friendly(step.frequency ?? ''),
                        icon: Icons.schedule_rounded,
                        tone: StatusChipTone.accent,
                      ),
                    if ((step.brand).trim().isNotEmpty)
                      StatusChip(
                        label: step.brand,
                        icon: Icons.water_drop_outlined,
                      ),
                  ],
                ),
                if ((step.instruction ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    step.instruction!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
                if ((step.caution ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  StatusChip(
                    label: step.caution!,
                    icon: Icons.warning_amber_rounded,
                    tone: StatusChipTone.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String rawCategory) {
    switch (rawCategory.trim().toLowerCase()) {
      case 'cleanser':
        return Icons.soap_outlined;
      case 'toner':
        return Icons.opacity_outlined;
      case 'serum':
      case 'treatment':
        return Icons.auto_awesome_outlined;
      case 'moisturizer':
        return Icons.spa_outlined;
      case 'sunscreen':
        return Icons.wb_sunny_outlined;
      default:
        return Icons.local_florist_outlined;
    }
  }

  String _friendly(String value) {
    if (value.trim().isEmpty) {
      return 'Not set';
    }
    return value.replaceAll('_', ' ');
  }
}

class _StepBubble extends StatelessWidget {
  const _StepBubble({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
