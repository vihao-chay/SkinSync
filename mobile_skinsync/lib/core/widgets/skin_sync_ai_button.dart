import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';

enum SkinSyncAiButtonMode { inline, compact }

class SkinSyncAiButton extends StatelessWidget {
  const SkinSyncAiButton({
    super.key,
    required this.title,
    required this.description,
    required this.label,
    required this.onPressed,
    this.mode = SkinSyncAiButtonMode.inline,
  });

  final String title;
  final String description;
  final String label;
  final VoidCallback onPressed;
  final SkinSyncAiButtonMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == SkinSyncAiButtonMode.compact) {
      return AppButton(
        label: label,
        icon: const Icon(Icons.auto_awesome_rounded),
        variant: AppButtonVariant.ai,
        onPressed: onPressed,
      );
    }

    return AppCard(
      backgroundColor: AppColors.aiSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.ai,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: label,
            icon: const Icon(Icons.auto_awesome_rounded),
            variant: AppButtonVariant.ai,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
