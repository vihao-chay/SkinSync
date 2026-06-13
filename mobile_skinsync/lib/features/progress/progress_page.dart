import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final progress = appState.progress;
    final latestAnalysis = appState.latestAnalysis;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routinePercent = totalSteps == 0 ? 0 : ((completedSteps / totalSteps) * 100).round();

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
                            progress?.progressInsight ??
                                'Progress blends analysis score, checklist consistency, and diary activity.',
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.show_chart_rounded,
            title: 'Score Trend',
            subtitle: 'A lightweight view of how your routine and analysis are moving together.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            variant: AppCardVariant.standard,
            child: _MiniTrendChart(
              currentScore: progress?.currentScore ?? latestAnalysis?.overallScore ?? 0,
              improvementPercent: progress?.improvementPercent ?? 0,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.tips_and_updates_outlined,
            title: 'Insight Cards',
            subtitle: 'Short reads instead of long paragraphs.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InsightCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Daily tip',
                body: progress?.dailyTip ??
                    'Keep logging routine completion to help SkinSync personalize your next recommendations.',
              ),
              _InsightCard(
                icon: Icons.check_circle_outline_rounded,
                title: 'Routine signal',
                body: '$completedSteps of $totalSteps steps are completed today.',
              ),
              _InsightCard(
                icon: Icons.menu_book_outlined,
                title: 'Diary signal',
                body: todayLog?.hasDiaryDetails == true
                    ? 'Today already includes a saved skin feeling or note.'
                    : 'Add a quick skin feeling or note to strengthen your progress story.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
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
                  value: todayLog?.dailyImageUrl?.trim().isNotEmpty == true
                      ? 'Daily log photo saved'
                      : 'No daily log photo yet',
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
}

class _MiniTrendChart extends StatelessWidget {
  const _MiniTrendChart({
    required this.currentScore,
    required this.improvementPercent,
  });

  final int currentScore;
  final double improvementPercent;

  @override
  Widget build(BuildContext context) {
    final points = [
      (currentScore - 12).clamp(0, 100).toDouble(),
      (currentScore - 6).clamp(0, 100).toDouble(),
      currentScore.toDouble(),
      (currentScore + (improvementPercent / 3)).clamp(0, 100).toDouble(),
    ];

    return SizedBox(
      height: 164,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _TrendPainter(points),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 92,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                StatusChip(
                  label: 'Live trend',
                  icon: Icons.show_chart_rounded,
                  tone: StatusChipTone.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] / 100) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final stroke = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, stroke);

    final pointPaint = Paint()..color = AppColors.primaryDark;
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height - ((points[i] / 100) * size.height);
      canvas.drawCircle(Offset(x, y), 4.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) {
    return oldDelegate.points != points;
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
