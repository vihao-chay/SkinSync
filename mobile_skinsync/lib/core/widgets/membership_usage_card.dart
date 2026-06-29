import 'dart:ui';
import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../models/app_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'linear_progress_stat.dart';
import 'status_chip.dart';

class MembershipUsageCard extends StatelessWidget {
  const MembershipUsageCard({
    super.key,
    required this.planName,
    required this.planCode,
    required this.priceLabel,
    required this.usage,
    required this.onUpgrade,
    this.showUpgrade = false,
  });

  final String planName;
  final String planCode;
  final String priceLabel;
  final List<SubscriptionUsage> usage;
  final VoidCallback onUpgrade;
  final bool showUpgrade;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final visibleUsage = usage.take(4).toList();
    return AppCard(
      variant: AppCardVariant.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: locale.tr('dashboard_membership'),
                icon: Icons.workspace_premium_outlined,
                tone: StatusChipTone.accent,
              ),
              const Spacer(),
              StatusChip(
                label: planName,
                icon: _planIcon(planCode),
                tone: planCode.toLowerCase() == 'free'
                    ? StatusChipTone.neutral
                    : StatusChipTone.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (showUpgrade)
                AppButton(
                  label: locale.tr('dashboard_upgrade'),
                  expand: false,
                  onPressed: onUpgrade,
                ),
            ],
          ),
          if (visibleUsage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumn = constraints.maxWidth >= 340;
                final children = visibleUsage
                    .map((item) => _UsageTile(usage: item))
                    .toList();
                if (!twoColumn) {
                  return Column(
                    children: children
                        .map(
                          (child) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: child,
                          ),
                        )
                        .toList(),
                  );
                }

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: children
                      .map(
                        (child) => SizedBox(
                          width: (constraints.maxWidth - AppSpacing.sm) / 2,
                          child: child,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  static IconData _planIcon(String code) {
    switch (code.trim().toLowerCase()) {
      case 'premium':
        return Icons.diamond_outlined;
      case 'plus':
        return Icons.star_outline_rounded;
      default:
        return Icons.lock_open_outlined;
    }
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({required this.usage});

  final SubscriptionUsage usage;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final limit = usage.monthlyLimit;
    final progress = usage.isUnlimited || limit == null || limit <= 0
        ? 0.0
        : (usage.used / limit).clamp(0.0, 1.0);
    final value = usage.isUnlimited
        ? '${usage.used} ${locale.tr('membership_used')}'
        : '${usage.used}/${limit ?? 0}';

    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  usage.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              if (!usage.isEnabled)
                StatusChip(
                  label: locale.tr('membership_locked'),
                  icon: Icons.lock_outline_rounded,
                  tone: StatusChipTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressStat(
            label: usage.isUnlimited ? locale.tr('membership_flexible_usage') : locale.tr('membership_monthly_usage'),
            value: usage.isUnlimited
                ? locale.tr('membership_unlimited')
                : '${(progress * 100).round()}%',
            progress: usage.isUnlimited ? 0.35 : progress,
            caption: usage.remaining == null
                ? null
                : '${usage.remaining} ${locale.tr('membership_remaining_cycle')}',
            color: usage.isEnabled
                ? AppColors.primaryDark
                : AppColors.subtleText,
          ),
        ],
      ),
    );
  }
}
