import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.headerTrailing,
    this.onRefresh,
    this.headerBottomSpacing = AppSpacing.sectionGap,
  });

  final String title;
  final Widget body;
  final String? subtitle;
  final Widget? headerTrailing;
  final Future<void> Function()? onRefresh;
  final double headerBottomSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = onRefresh == null
        ? body
        : RefreshIndicator(
            color: AppColors.primaryDark,
            onRefresh: onRefresh!,
            child: body,
          );

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                18,
                AppSpacing.pagePadding,
                18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.heading,
                          ),
                        ),
                        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            subtitle!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerTrailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: headerTrailing!),
                  ],
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
