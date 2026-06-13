import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/linear_progress_stat.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    ProgressPageArgs? args,
  }) : args = args ?? const ProgressPageArgs();

  final ProgressPageArgs args;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _didHandleEntryPoint = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHandleEntryPoint) {
      return;
    }
    _didHandleEntryPoint = true;
    if (widget.args.entryPoint == ProgressEntryPoint.checkupSaved ||
        widget.args.entryPoint == ProgressEntryPoint.analysisResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.read<AppState>().refreshHome();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final progress = appState.progress;
    final latestAnalysis = appState.latestAnalysis;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final latestPhotoUrl = _resolveImageUrl(
      todayLog?.dailyImageUrl?.trim().isNotEmpty == true
          ? todayLog!.dailyImageUrl
          : latestAnalysis?.imageUrl,
    );
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routinePercent = totalSteps == 0 ? 0 : ((completedSteps / totalSteps) * 100).round();
    final hasRealInsight = (progress?.dailyTip?.trim().isNotEmpty ?? false) ||
        (progress?.progressInsight?.trim().isNotEmpty ?? false);
    final hasVisualJourney = latestPhotoUrl.isNotEmpty;

    final showCheckupSavedState =
        widget.args.entryPoint == ProgressEntryPoint.checkupSaved;
    final showAnalysisState =
        widget.args.entryPoint == ProgressEntryPoint.analysisResult;

    if (progress == null && latestAnalysis == null) {
      return AppScaffold(
        title: 'Progress',
        subtitle: 'Analysis history, routine completion, and daily logs stay in sync here.',
        compactHeader: true,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            0,
            AppSpacing.pagePadding,
            AppSpacing.pageBottomPaddingWithActions,
          ),
          children: [
            EmptyStateCard(
              icon: Icons.insights_outlined,
              title: 'No progress data yet',
              description: 'Analyze your skin and start completing your routine to unlock a clearer progress story.',
              ctaLabel: 'Analyze skin',
              onCta: () => Navigator.pushNamed(context, AppRoutes.upload),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Progress',
      subtitle: 'Analysis history, routine completion, and daily logs stay in sync here.',
      compactHeader: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          if (showCheckupSavedState) ...[
            const StatusChip(
              label: 'Check-up saved',
              icon: Icons.check_circle_outline_rounded,
              tone: StatusChipTone.success,
            ),
            const SizedBox(height: AppSpacing.md),
          ] else if (showAnalysisState) ...[
            const StatusChip(
              label: 'Analysis saved',
              icon: Icons.analytics_outlined,
              tone: StatusChipTone.accent,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircularScore(
                      score: progress?.currentScore ?? latestAnalysis?.overallScore ?? 0,
                      size: 112,
                      label: 'current',
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const StatusChip(
                            label: 'Current Progress Snapshot',
                            icon: Icons.query_stats_rounded,
                            tone: StatusChipTone.accent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            progress?.progressInsight?.trim().isNotEmpty == true
                                ? progress!.progressInsight!
                                : 'Progress updates when analysis, routine tracking, and daily logs are saved.',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = [
                      MetricCard(
                        label: 'Current score',
                        value: '${progress?.currentScore ?? latestAnalysis?.overallScore ?? 0}',
                        icon: Icons.favorite_outline_rounded,
                      ),
                      MetricCard(
                        label: 'Current streak',
                        value: '${progress?.currentStreak ?? 0} days',
                        icon: Icons.local_fire_department_outlined,
                      ),
                      MetricCard(
                        label: 'Improvement',
                        value: _formatPercent(progress?.improvementPercent),
                        icon: Icons.trending_up_rounded,
                      ),
                      MetricCard(
                        label: 'Routine completion',
                        value: '$routinePercent%',
                        icon: Icons.checklist_rounded,
                      ),
                    ];
                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: metrics
                          .map(
                            (metric) => SizedBox(
                              width: constraints.maxWidth < 360
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - AppSpacing.sm) / 2,
                              child: metric,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressStat(
                  label: 'Routine completion',
                  value: '$routinePercent%',
                  progress: totalSteps == 0 ? 0 : completedSteps / totalSteps,
                  caption: totalSteps == 0
                      ? 'No routine steps tracked yet.'
                      : '$completedSteps of $totalSteps steps completed today.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Score Trend',
            subtitle: 'Only show a trend when there is enough real data to support it.',
          ),
          const SizedBox(height: AppSpacing.md),
          const EmptyStateCard(
            icon: Icons.show_chart_rounded,
            title: 'Not enough trend data yet',
            description:
                'Complete more analyses and check-ups to unlock a clearer score trend.',
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.photo_camera_back_outlined,
            title: 'Visual Journey',
            subtitle: 'Your latest analysis or daily log photo appears here when backend data is available.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasVisualJourney)
            AppCard(
              child: _VisualJourneyCard(
                imageUrl: latestPhotoUrl,
                title: todayLog?.dailyImageUrl?.trim().isNotEmpty == true
                    ? 'Latest daily log photo'
                    : 'Latest analysis photo',
                value: latestAnalysis != null
                    ? 'Skin score ${latestAnalysis.overallScore}/100 from your most recent scan.'
                    : 'A real saved photo is available for future comparison.',
              ),
            )
          else
            const EmptyStateCard(
              icon: Icons.photo_library_outlined,
              title: 'No comparison photos yet',
              description:
                  'Save daily or analysis photos over time to unlock a clearer visual journey.',
            ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (hasRealInsight) ...[
            SectionHeader(
              icon: Icons.tips_and_updates_outlined,
              title: 'Insight Cards',
              subtitle: 'Short reads grounded in your saved backend data.',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (progress?.dailyTip?.trim().isNotEmpty == true)
                  _InsightCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Daily tip',
                    body: progress!.dailyTip!,
                  ),
                if (progress?.progressInsight?.trim().isNotEmpty == true)
                  _InsightCard(
                    icon: Icons.query_stats_rounded,
                    title: 'Progress signal',
                    body: progress!.progressInsight!,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          SectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Recent Timeline',
            subtitle: 'The latest moments feeding your progress.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _TimelineRow(
                  icon: Icons.analytics_outlined,
                  title: 'Latest analysis',
                  value: latestAnalysis == null
                      ? 'No analysis yet'
                      : '${latestAnalysis.overallScore}/100 • ${latestAnalysis.skinType}',
                ),
                const SizedBox(height: AppSpacing.md),
                _TimelineRow(
                  icon: Icons.checklist_rounded,
                  title: 'Latest check-up',
                  value: '$completedSteps/$totalSteps routine steps completed today',
                ),
                const SizedBox(height: AppSpacing.md),
                _TimelineRow(
                  icon: Icons.photo_camera_back_outlined,
                  title: 'Latest photo',
                  value: latestPhotoUrl.isNotEmpty
                      ? (todayLog?.dailyImageUrl?.trim().isNotEmpty == true
                          ? 'Daily log photo saved'
                          : 'Analysis photo saved')
                      : 'No saved photo yet',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPercent(double? value) {
    final safe = value ?? 0;
    return '${safe.toStringAsFixed(1)}%';
  }

  String _resolveImageUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }
    return value.startsWith('http') ? value : '${AppConfig.apiBaseUrl}$value';
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width > 380 ? 170 : double.infinity,
      child: AppCard(
        variant: AppCardVariant.metric,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primaryDark),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisualJourneyCard extends StatelessWidget {
  const _VisualJourneyCard({
    required this.imageUrl,
    required this.title,
    required this.value,
  });

  final String imageUrl;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 88,
            height: 112,
            color: AppColors.secondary,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.primaryDark,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TimelineRow(
            icon: Icons.photo_camera_back_outlined,
            title: title,
            value: value,
          ),
        ),
      ],
    );
  }
}
