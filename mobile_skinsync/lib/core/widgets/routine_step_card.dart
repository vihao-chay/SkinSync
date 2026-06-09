import 'package:flutter/material.dart';

import '../mock/mock_skin_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'premium_card.dart';

class RoutineStepCard extends StatelessWidget {
  const RoutineStepCard({
    super.key,
    required this.step,
    required this.index,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onDetail,
    this.editMode = false,
  });

  final RoutineStep step;
  final int index;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onDetail;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isCompleted ? 0.78 : 1,
      child: PremiumCard(
        onTap: onDetail,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onToggleComplete,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                    : Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryDark,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                width: 56,
                height: 56,
                color: AppColors.secondary,
                child: step.imageUrl != null
                    ? Image.network(
                        step.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.spa_rounded),
                      )
                    : const Icon(Icons.spa_rounded, color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.category, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(step.productName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    step.instruction,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        step.brand,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      Text(step.price, style: Theme.of(context).textTheme.labelSmall),
                      if (step.warning != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                if (editMode)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.smallGap),
                    child: Icon(Icons.drag_handle_rounded, color: AppColors.subtleText),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onDetail,
                  child: Ink(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      editMode ? Icons.delete_outline_rounded : Icons.more_horiz_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
