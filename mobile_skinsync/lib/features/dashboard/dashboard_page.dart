import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/linear_progress_stat.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final latestAnalysis = appState.latestAnalysis;
    final tracking = appState.trackingToday;
    final regimen = appState.regimen;
    final todayLog = appState.todayLog;
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final previewSteps = [
      ...?regimen?.morning,
      ...?regimen?.evening,
    ].take(3).toList();

    return AppScaffold(
      title: 'Home',
      subtitle: 'Your latest analysis, routine, and check-up progress at a glance.',
      compactHeader: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircularScore(
                      score: latestAnalysis?.overallScore ?? 0,
                      size: 104,
                      label: 'score',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const StatusChip(
                            label: 'Today at a glance',
                            icon: Icons.wb_twilight_outlined,
                            tone: StatusChipTone.accent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            latestAnalysis != null
                                ? 'Latest skin score: ${latestAnalysis.overallScore}/100'
                                : 'Start with a skin analysis to unlock routine tracking and product recommendations.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          StatusChip(
                            label: regimen == null ? 'No active routine' : 'Routine active',
                            icon: regimen == null
                                ? Icons.spa_outlined
                                : Icons.checklist_rounded,
                            tone: regimen == null
                                ? StatusChipTone.warning
                                : StatusChipTone.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 360;
                    final children = [
                      MetricCard(
                        label: 'Routine',
                        value: regimen == null ? 'Not set' : 'Active',
                        icon: Icons.local_florist_outlined,
                      ),
                      MetricCard(
                        label: 'Today',
                        value: '$completedSteps/$totalSteps done',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      MetricCard(
                        label: 'Feeling',
                        value: _formatFeeling(todayLog?.skinFeeling),
                        icon: Icons.favorite_border_rounded,
                      ),
                    ];
                    if (!wide) {
                      return Column(
                        children: children
                            .map(
                              (child) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: child,
                              ),
                            )
                            .toList(),
                      );
                    }

                    return Row(
                      children: [
                        for (var i = 0; i < children.length; i++) ...[
                          Expanded(child: children[i]),
                          if (i != children.length - 1)
                            const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressStat(
                  label: 'Routine completion',
                  value: '$completedSteps/$totalSteps',
                  progress: progress,
                  caption: totalSteps == 0
                      ? 'Your checklist will appear once you have an active routine.'
                      : 'Keep today moving with your next active steps.',
                ),
                if (previewSteps.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(
                    icon: Icons.checklist_rounded,
                    title: 'Next steps',
                    subtitle: 'A quick preview from your active routine.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...previewSteps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${step.stepOrder}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              step.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(
                            label: step.category,
                            icon: Icons.water_drop_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: latestAnalysis != null
                      ? 'Open Today Check-up'
                      : 'Analyze Skin',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    latestAnalysis != null ? AppRoutes.todayCheckup : AppRoutes.upload,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Open Products',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.products),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.auto_graph_rounded,
            title: 'Quick Snapshot',
            subtitle: 'Small signals from your recent progress and habits.',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                MetricCard(
                  label: 'Current streak',
                  value: '${appState.progress?.currentStreak ?? 0} days',
                  icon: Icons.local_fire_department_outlined,
                  tone: AppColors.surface,
                ),
                MetricCard(
                  label: 'Completion',
                  value: '${(progress * 100).round()}%',
                  icon: Icons.donut_small_rounded,
                  tone: AppColors.surface,
                ),
                MetricCard(
                  label: 'Last analysis',
                  value: latestAnalysis == null ? 'Not yet' : 'Ready',
                  caption: latestAnalysis == null
                      ? 'Analyze skin to start tracking.'
                      : latestAnalysis.skinType,
                  icon: Icons.photo_camera_back_outlined,
                  tone: AppColors.surface,
                ),
              ];
              if (constraints.maxWidth < 360) {
                return Column(
                  children: tiles
                      .map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: tile,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: tiles
                    .map(
                      (tile) => SizedBox(
                        width: (constraints.maxWidth - AppSpacing.sm) / 2,
                        child: tile,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatFeeling(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return 'Not logged';
    }
    return normalized.replaceAll('_', ' ');
  }
}
