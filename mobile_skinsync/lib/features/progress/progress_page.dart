import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/responsive.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/status_chip.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key, ProgressPageArgs? args})
    : args = args ?? const ProgressPageArgs();

  final ProgressPageArgs args;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final appState = context.read<AppState>();
      _refreshProgressData(showLoading: _hasNoProgressData(appState));
    });
  }

  @override
  void didUpdateWidget(covariant ProgressPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.args.cacheKey != widget.args.cacheKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _refreshProgressData(showLoading: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final progress = appState.progress;
    final latestAnalysis = appState.latestAnalysis;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routineProgress = _clampedProgress(completedSteps, totalSteps);
    final currentScore =
        progress?.currentScore ??
        latestAnalysis?.displaySkinHealthScore ??
        latestAnalysis?.overallScore;
    final insight =
        progress?.progressInsight ??
        progress?.dailyTip ??
        latestAnalysis?.overview;
    final hasProgressContent = !_hasNoProgressData(appState);
    final progressError =
        appState.progressLoadErrorMessage ??
        appState.analysisLoadErrorMessage ??
        appState.trackingLoadErrorMessage ??
        appState.todayLogLoadErrorMessage;
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);
    final showCheckupSavedState =
        widget.args.entryPoint == ProgressEntryPoint.checkupSaved;
    final showAnalysisState =
        widget.args.entryPoint == ProgressEntryPoint.analysisResult;

    return AppScaffold(
      title: locale.tr('progress_title'),
      subtitle: locale.tr('progress_history_at_glance'),
      compactHeader: true,
      onRefresh: _refreshProgressData,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.xs,
          horizontalPadding,
          Responsive.contentBottomSpacing(context, extra: 20),
        ),
        children: [
          if (showCheckupSavedState) ...[
            StatusChip(
              label: locale.tr('progress_checkup_saved'),
              icon: Icons.check_circle_outline_rounded,
              tone: StatusChipTone.success,
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (showAnalysisState) ...[
            StatusChip(
              label: locale.tr('progress_analysis_saved'),
              icon: Icons.analytics_outlined,
              tone: StatusChipTone.accent,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_isRefreshing && !hasProgressContent)
            const _ProgressLoadingCard()
          else if (!hasProgressContent && progressError != null)
            _ProgressErrorCard(
              message: progressError,
              onRetry: () => _refreshProgressData(showLoading: true),
            )
          else if (!hasProgressContent)
            _NoProgressCard(onStart: _openUpload)
          else ...[
            if (progressError != null) ...[
              _ProgressNoticeCard(message: progressError),
              const SizedBox(height: AppSpacing.sm),
            ],
            _ProgressHero(
              score: currentScore,
              insight: insight,
              improvementPercent: progress?.improvementPercent,
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricsGrid(
              currentScore: currentScore,
              currentStreak: progress?.currentStreak,
              improvementPercent: progress?.improvementPercent,
              routinePercent: (routineProgress * 100).round(),
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutineCompletionCard(
              completedSteps: completedSteps,
              totalSteps: totalSteps,
              progress: routineProgress,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProgressSectionTitle(locale.tr('progress_score_trend')),
            const SizedBox(height: AppSpacing.xs),
            const _ScoreTrendCard(),
            const SizedBox(height: AppSpacing.md),
            _ProgressSectionTitle(locale.tr('progress_visual_journey')),
            const SizedBox(height: AppSpacing.xs),
            _VisualJourneyCard(
              imageUrl: todayLog?.dailyImageUrl,
              onAddPhoto: _openProgressUpload,
            ),
            const SizedBox(height: AppSpacing.md),
            _ProgressSectionTitle(locale.tr('progress_recent_activity')),
            const SizedBox(height: AppSpacing.xs),
            _RecentActivityCard(
              latestAnalysis: latestAnalysis,
              completedSteps: completedSteps,
              totalSteps: totalSteps,
              hasPhoto: todayLog?.dailyImageUrl?.trim().isNotEmpty == true,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshProgressData({bool showLoading = false}) async {
    if (_isRefreshing) {
      return;
    }

    if (showLoading && mounted) {
      setState(() => _isRefreshing = true);
    }

    try {
      await context.read<AppState>().refreshHome();
    } catch (_) {
      // AppState stores user-facing load errors; keep this page renderable.
    } finally {
      if (mounted && _isRefreshing) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  bool _hasNoProgressData(AppState appState) {
    final todayLog = appState.todayLog;
    return appState.progress == null &&
        appState.latestAnalysis == null &&
        appState.trackingToday == null &&
        (todayLog == null ||
            (!todayLog.hasDiaryDetails &&
                !todayLog.morningCompleted &&
                !todayLog.eveningCompleted));
  }

  double _clampedProgress(int completed, int total) {
    if (total <= 0) {
      return 0.0;
    }
    return (completed / total).clamp(0.0, 1.0);
  }

  void _openUpload() {
    Navigator.pushNamed(context, AppRoutes.upload);
  }

  void _openProgressUpload() {
    Navigator.pushNamed(
      context,
      AppRoutes.upload,
      arguments: const SkinAnalysisFlowArgs(source: 'progress'),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.score,
    required this.insight,
    required this.improvementPercent,
  });

  final int? score;
  final String? insight;
  final double? improvementPercent;

  @override
  Widget build(BuildContext context) {
    final hasImprovement = improvementPercent != null;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 420;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight?.trim().isNotEmpty == true
                    ? insight!
                    : 'Progress updates after analysis, routine tracking, and daily logs are saved.',
                maxLines: stack ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.heading,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    hasImprovement
                        ? '${improvementPercent!.toStringAsFixed(1)}% improve'
                        : 'Not enough data',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          );
          return Flex(
            direction: stack ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircularScore(
                score: score ?? 0,
                size: 104,
                label: 'score',
                progressColor: AppColors.primary,
              ),
              SizedBox(
                width: stack ? 0 : AppSpacing.sm,
                height: stack ? AppSpacing.sm : 0,
              ),
              if (stack) details else Flexible(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.currentScore,
    required this.currentStreak,
    required this.improvementPercent,
    required this.routinePercent,
  });

  final int? currentScore;
  final int? currentStreak;
  final double? improvementPercent;
  final int routinePercent;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        label: 'Current Score',
        value: currentScore == null ? 'No data' : '$currentScore',
        icon: Icons.favorite_outline_rounded,
      ),
      _MetricData(
        label: 'Current Streak',
        value: currentStreak == null ? '0 days' : '$currentStreak days',
        icon: Icons.local_fire_department_outlined,
        alert: currentStreak == null || currentStreak == 0,
      ),
      _MetricData(
        label: 'Improvement',
        value: improvementPercent == null
            ? '0%'
            : '${improvementPercent!.toStringAsFixed(1)}%',
        icon: Icons.trending_up_rounded,
      ),
      _MetricData(
        label: 'Routine',
        value: '$routinePercent%',
        icon: Icons.checklist_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final tileWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                  columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(width: tileWidth, child: _MetricTile(item)),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool alert;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.data);

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 14, color: AppColors.primary),
              const Spacer(),
              if (data.alert)
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: AppColors.error,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.heading,
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCompletionCard extends StatelessWidget {
  const _RoutineCompletionCard({
    required this.completedSteps,
    required this.totalSteps,
    required this.progress,
  });

  final int completedSteps;
  final int totalSteps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final percent = (clampedProgress * 100).round();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Routine Completion',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  totalSteps == 0
                      ? 'No steps'
                      : '$completedSteps/$totalSteps steps',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            totalSteps == 0
                ? 'No routine steps tracked yet.'
                : '$percent% complete today.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ScoreTrendCard extends StatelessWidget {
  const _ScoreTrendCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not enough trend data yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLoadingCard extends StatelessWidget {
  const _ProgressLoadingCard();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 22),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.tr('progress_loading'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressErrorCard extends StatelessWidget {
  const _ProgressErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.tr('progress_load_failed'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: locale.tr('common_try_again'),
            expand: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _ProgressNoticeCard extends StatelessWidget {
  const _ProgressNoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.muted,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryDark,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualJourneyCard extends StatelessWidget {
  const _VisualJourneyCard({required this.imageUrl, required this.onAddPhoto});

  final String? imageUrl;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Container(
        height: 176,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        clipBehavior: Clip.antiAlias,
        child: resolvedUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No comparison photo yet.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onAddPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 12),
                    label: const Text('Take Progress Photo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.56),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ],
              )
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Photo preview unavailable.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _resolveImageUrl(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    return raw.startsWith('http') ? raw : '${AppConfig.apiBaseUrl}$raw';
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.latestAnalysis,
    required this.completedSteps,
    required this.totalSteps,
    required this.hasPhoto,
  });

  final AnalysisResult? latestAnalysis;
  final int completedSteps;
  final int totalSteps;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          _ActivityRow(
            icon: Icons.analytics_outlined,
            title: 'Latest analysis',
            value: latestAnalysis == null
                ? 'No analysis yet'
                : '${latestAnalysis!.overallScore}/100',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActivityRow(
            icon: Icons.fact_check_outlined,
            title: 'Routine tracking',
            value: '$completedSteps/$totalSteps steps',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActivityRow(
            icon: Icons.photo_camera_back_outlined,
            title: 'Latest photo',
            value: hasPhoto ? 'Photo saved' : 'No photo yet',
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
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
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

class _NoProgressCard extends StatelessWidget {
  const _NoProgressCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            color: AppColors.primary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.tr('progress_no_data'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            locale.tr('progress_no_data_desc'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: locale.tr('progress_analyze_skin_cta'),
            expand: false,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _ProgressSectionTitle extends StatelessWidget {
  const _ProgressSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.heading,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
