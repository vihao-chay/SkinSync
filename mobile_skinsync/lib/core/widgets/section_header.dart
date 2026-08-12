import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBoxSize = Responsive.responsiveValue<double>(
      context,
      mobileSmall: 34,
      mobile: 38,
      tablet: 40,
      desktop: 42,
    );
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.fade,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            maxLines: 3,
            overflow: TextOverflow.fade,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 420;

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        icon,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(child: titleBlock),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(child: titleBlock),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        );
      },
    );
  }
}
