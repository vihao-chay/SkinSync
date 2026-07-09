import 'package:flutter/material.dart';

import '../config/app_config.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumbnail(step: step),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    step.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onChanged,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: completed ? AppColors.primaryDark : Colors.white,
                    border: Border.all(
                      color: completed
                          ? AppColors.primaryDark
                          : AppColors.outline,
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    size: completed ? 19 : 16,
                    color: completed ? Colors.white : AppColors.subtleText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StepBubble(number: step.stepOrder),
              StatusChip(
                label: _friendly(step.category),
                icon: _productCategoryIcon(step.category),
              ),
              if ((step.frequency ?? '').trim().isNotEmpty)
                StatusChip(
                  label: _friendly(step.frequency ?? ''),
                  icon: Icons.schedule_rounded,
                  tone: StatusChipTone.accent,
                ),
              if ((step.brand).trim().isNotEmpty)
                StatusChip(label: step.brand, icon: Icons.water_drop_outlined),
            ],
          ),
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
    );
  }

  String _friendly(String value) {
    if (value.trim().isEmpty) {
      return 'Not set';
    }
    return value.replaceAll('_', ' ');
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.step});

  final RegimenStep step;

  @override
  Widget build(BuildContext context) {
    final rawUrl = step.imageUrl?.trim() ?? '';
    final imageUrl = rawUrl.isEmpty
        ? null
        : rawUrl.startsWith('http')
        ? rawUrl
        : '${AppConfig.apiBaseUrl}$rawUrl';

    return Container(
      width: 76,
      height: 84,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: imageUrl == null
            ? _ProductImageFallback(category: step.category)
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    _ProductImageFallback(category: step.category),
              ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.secondary,
      child: Icon(
        _productCategoryIcon(category),
        color: AppColors.primaryDark,
        size: 24,
      ),
    );
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
        border: Border.all(color: Colors.white),
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

IconData _productCategoryIcon(String rawCategory) {
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
