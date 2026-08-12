import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'status_chip.dart';

class ProductRecommendationCard extends StatelessWidget {
  const ProductRecommendationCard({
    super.key,
    required this.item,
    required this.onAddToRoutine,
  });

  final AiRecommendedProduct item;
  final VoidCallback onAddToRoutine;

  @override
  Widget build(BuildContext context) {
    final reason = item.whyRecommended?.trim().isNotEmpty == true
        ? item.whyRecommended!
        : item.aiReason;
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _ProductThumb(item: item),
              Positioned(
                left: 10,
                top: 10,
                child: _ConfidenceBadge(
                  value: item.matchPercent ?? item.matchScore,
                ),
              ),
              if (item.alreadyInRoutine)
                const Positioned(
                  right: 10,
                  top: 10,
                  child: StatusChip(
                    label: 'In routine',
                    icon: Icons.check_circle_outline_rounded,
                    tone: StatusChipTone.success,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _friendly(item.brand).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _priceLabel(item),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_alt_outlined,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    reason,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.heading,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.cautions.isNotEmpty || item.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children:
                  (item.cautions.isNotEmpty ? item.cautions : item.warnings)
                      .take(2)
                      .map(
                        (warning) => StatusChip(
                          label: warning,
                          icon: Icons.warning_amber_rounded,
                          tone: StatusChipTone.warning,
                        ),
                      )
                      .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _RoutineActionButton(
            label: item.alreadyInRoutine ? 'View in Routine' : 'Add to Routine',
            inRoutine: item.alreadyInRoutine,
            onPressed: onAddToRoutine,
          ),
        ],
      ),
    );
  }

  String _friendly(String value) {
    return value.trim().isEmpty ? 'Not provided yet' : value;
  }

  String _priceLabel(AiRecommendedProduct item) {
    final value = item.price <= 0 ? '0' : item.price.toStringAsFixed(0);
    if (item.currency.toUpperCase() == 'VND') {
      return '$value VND';
    }
    return '${item.currency} $value';
  }
}

class _RoutineActionButton extends StatefulWidget {
  const _RoutineActionButton({
    required this.label,
    required this.inRoutine,
    required this.onPressed,
  });

  final String label;
  final bool inRoutine;
  final VoidCallback onPressed;

  @override
  State<_RoutineActionButton> createState() => _RoutineActionButtonState();
}

class _RoutineActionButtonState extends State<_RoutineActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.inRoutine
        ? AppColors.heading
        : AppColors.primaryDark;
    final highlighted = widget.inRoutine && _hovered;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        mouseCursor: SystemMouseCursors.click,
        onHover: (value) => setState(() => _hovered = value),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: highlighted ? 1.015 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: widget.inRoutine
                  ? highlighted
                        ? const Color(0xFFE1DED8)
                        : const Color(0xFFE8E6E1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: widget.inRoutine
                  ? null
                  : Border.all(color: AppColors.primaryDark, width: 1.4),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: AppColors.foreground.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.inRoutine) ...[
                  Icon(
                    Icons.calendar_month_outlined,
                    color: foreground,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        width: double.infinity,
        height: 190,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primaryDark,
                size: 34,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
              ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 4),
          Text(
            '$value% match',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
