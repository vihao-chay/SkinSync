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
    this.contentMaxWidth = 460,
    this.headerBottomSpacing = AppSpacing.sectionGap,
    this.compactHeader = false,
  });

  final String title;
  final Widget body;
  final String? subtitle;
  final Widget? headerTrailing;
  final Future<void> Function()? onRefresh;
  final double contentMaxWidth;
  final double headerBottomSpacing;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final topPadding = compactHeader ? 10.0 : 16.0;
    final bottomPadding = compactHeader ? 10.0 : 16.0;
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
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    topPadding,
                    AppSpacing.pagePadding,
                    bottomPadding,
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
                                fontSize: compactHeader ? 26 : null,
                                height: compactHeader ? 1.08 : null,
                              ),
                            ),
                            if (subtitle != null &&
                                subtitle!.trim().isNotEmpty) ...[
                              SizedBox(height: compactHeader ? 6 : AppSpacing.sm),
                              Text(
                                subtitle!,
                                maxLines: compactHeader ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.mutedText,
                                  height: compactHeader ? 1.45 : 1.55,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (headerTrailing != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: compactHeader ? 56 : 64,
                          child: headerTrailing!,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: headerBottomSpacing > AppSpacing.sm
                      ? headerBottomSpacing - AppSpacing.sm
                      : 0,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: safeBottom),
                    child: content,
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
