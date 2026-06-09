import 'package:flutter/material.dart';

import '../mock/mock_skin_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'premium_card.dart';

class RoutineStepCard extends StatelessWidget {
  const RoutineStepCard({
    super.key,
    required this.step,
    required this.index,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onDetail,
    this.onEdit,
    this.onDelete,
  });

  final RoutineStep step;
  final int index;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onDetail;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggleComplete,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white)
                      : Text('${index + 1}'),
                ),
              ),
              const SizedBox(width: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.secondary,
                  child: step.imageUrl != null
                      ? Image.network(
                          step.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.spa_outlined),
                        )
                      : const Icon(Icons.spa_outlined, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.category, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(step.productName, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${step.brand} · ${step.price}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(step.instruction, style: Theme.of(context).textTheme.bodyMedium),
          if (step.warning != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(child: Text(step.warning!, style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onDetail,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Detail'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
