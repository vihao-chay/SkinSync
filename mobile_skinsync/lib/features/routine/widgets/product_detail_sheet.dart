import 'package:flutter/material.dart';

import '../../../core/mock/mock_skin_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/gradient_pill_button.dart';

class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({super.key, required this.step});

  final RoutineStep step;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            if (step.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: Image.network(
                    step.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AppColors.secondary),
                  ),
                ),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Icon(Icons.spa_rounded, size: 48, color: AppColors.primaryDark),
                ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(step.category, style: Theme.of(context).textTheme.labelMedium),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(step.productName, style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${step.brand} • ${step.price}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(step.instruction, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (step.warning != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6DE),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  step.warning!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            GradientPillButton(
              label: 'Use This Step',
              expanded: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
