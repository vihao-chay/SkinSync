import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'status_chip.dart';

class ProductRecommendationCard extends StatelessWidget {
  const ProductRecommendationCard({
    super.key,
    required this.item,
    required this.onViewDetails,
    required this.onAddToRoutine,
    required this.onCheckIngredients,
  });

  final AiRecommendedProduct item;
  final VoidCallback onViewDetails;
  final VoidCallback onAddToRoutine;
  final VoidCallback onCheckIngredients;

  @override
  Widget build(BuildContext context) {
    final reason = item.whyRecommended?.trim().isNotEmpty == true
        ? item.whyRecommended!
        : item.aiReason;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(item: item),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_friendly(item.brand)} • ${_friendly(item.category)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _MatchBadge(value: item.matchPercent ?? item.matchScore),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (item.alreadyInRoutine)
                          const StatusChip(
                            label: 'Already in routine',
                            icon: Icons.check_circle_outline_rounded,
                            tone: StatusChipTone.success,
                          ),
                        ...((item.cautions.isNotEmpty
                                ? item.cautions
                                : item.warnings)
                            .take(1)
                            .map(
                              (warning) => StatusChip(
                                label: warning,
                                icon: Icons.warning_amber_rounded,
                                tone: StatusChipTone.warning,
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.price.toStringAsFixed(0)} ${item.currency}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewDetails,
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Ingredients',
                  variant: AppButtonVariant.secondary,
                  onPressed: onCheckIngredients,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Add',
                  onPressed: onAddToRoutine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _friendly(String value) {
    return value.trim().isEmpty ? 'Not provided yet' : value;
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.item});

  final AiRecommendedProduct item;

  @override
  Widget build(BuildContext context) {
    final raw = item.imageUrl?.trim() ?? '';
    final url = raw.isEmpty
        ? ''
        : (raw.startsWith('http') ? raw : '${AppConfig.apiBaseUrl}$raw');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 76,
        height: 76,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryDark,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            '$value%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'match',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }
}
