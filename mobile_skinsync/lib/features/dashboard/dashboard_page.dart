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
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/skin_sync_header.dart';
import '../../core/widgets/status_chip.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AiProductRecommendResponse? _latestRecommendation;
  String? _recommendationError;
  bool _loadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecommendations());
  }

  Future<void> _refreshAll() async {
    await context.read<AppState>().refreshHome();
    await _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      final result = await context.read<AppState>().getLatestRecommendations();
      if (mounted) {
        setState(() => _latestRecommendation = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latestRecommendation = null;
          _recommendationError = context.read<AppState>().errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final latestAnalysis = appState.latestAnalysis;
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final scanUsage = _findUsage(
      appState.subscription?.usage ?? const <SubscriptionUsage>[],
      'skin_analysis',
    );
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routineProgress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final routineSteps = _routinePreviewItems(regimen, locale);
    final products =
        (_latestRecommendation?.products ?? const <AiRecommendedProduct>[])
            .where((item) => item.name.trim().isNotEmpty)
            .take(2)
            .toList();
    final contentMaxWidth = Responsive.maxContentWidth(
      context,
      mobile: double.infinity,
      tablet: 760,
      desktop: 1040,
    );
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 0),
                children: [
                  SkinSyncHeader(
                    name: appState.profileDisplayName,
                    avatarUrl: appState.user?.avatarUrl,
                    onAvatarTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.profile),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      Responsive.floatingNavigationBottomSpacing(
                        context,
                        extra: 20,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkinHealthCard(
                          score:
                              latestAnalysis?.displaySkinHealthScore ??
                              latestAnalysis?.overallScore,
                          lastScanAt: latestAnalysis?.lastScanAt,
                          scanUsage: scanUsage,
                          onUpgrade: () => Navigator.pushNamed(
                            context,
                            AppRoutes.membershipPlans,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionTitle(
                          title: locale.tr('dashboard_key_metrics'),
                          actionLabel: locale.tr('dashboard_details'),
                          onAction: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.progress,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _MetricGrid(
                          acne: _issueScore(latestAnalysis, 'acne'),
                          redness: _issueScore(latestAnalysis, 'redness'),
                          hydration: _hydrationLabel(appState.todayLog, locale),
                          routinePercent: routineProgress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RoutinePreviewCard(
                          completedSteps: completedSteps,
                          totalSteps: totalSteps,
                          progress: routineProgress,
                          steps: routineSteps,
                          onOpen: () {
                            if (regimen != null) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.todayCheckup,
                              );
                              return;
                            }
                            MainShell.navigateToTab(
                              context,
                              AppRoutes.products,
                              arguments: const ProductsPageArgs(
                                entryPoint: ProductsEntryPoint.routineEmpty,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ForYouSection(
                          loading: _loadingRecommendations,
                          errorMessage: _recommendationError,
                          products: products,
                          onOpenProducts: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.products,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PrimaryScanAction(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.upload),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _QuickActionGrid(
                          onChat: () =>
                              Navigator.pushNamed(context, AppRoutes.aiChat),
                          onProgress: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.progress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int? _issueScore(AnalysisResult? result, String contains) {
    if (result == null) {
      return null;
    }
    final needle = contains.toLowerCase();
    for (final issue in result.issues) {
      if (issue.issueType.toLowerCase().contains(needle)) {
        return issue.severityScore.clamp(0, 100);
      }
    }
    return null;
  }

  String _hydrationLabel(DailyLog? log, AppLocale locale) {
    final hydration = log?.hydrationLevel;
    if (hydration == null) {
      return locale.tr('hydration_optimal');
    }
    if (hydration >= 7) {
      return locale.tr('hydration_optimal');
    }
    if (hydration >= 4) {
      return locale.tr('hydration_balanced');
    }
    return locale.tr('hydration_low');
  }
}

class _SkinHealthCard extends StatelessWidget {
  const _SkinHealthCard({
    required this.score,
    required this.lastScanAt,
    required this.scanUsage,
    required this.onUpgrade,
  });

  final int? score;
  final DateTime? lastScanAt;
  final SubscriptionUsage? scanUsage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final resolvedScore = score ?? 0;
    final limit = scanUsage?.monthlyLimit;
    final used = scanUsage?.used ?? 0;
    final unlimited = scanUsage?.isUnlimited ?? false;
    final exhausted = !unlimited && limit != null && limit > 0 && used >= limit;
    final usageProgress = unlimited
        ? 1.0
        : limit == null || limit <= 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);

    final usageLabel = scanUsage == null
        ? null
        : unlimited
        ? locale.tr('dashboard_unlimited_scans')
        : limit == null
        ? '$used ${locale.tr('plan_scans')}'
        : '$used/$limit ${locale.tr('plan_scans')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardHeight = (cardWidth * (exhausted ? 0.9 : 0.82))
            .clamp(exhausted ? 324.0 : 294.0, exhausted ? 354.0 : 326.0)
            .toDouble();
        final scoreSize = (cardWidth * 0.34).clamp(118.0, 132.0).toDouble();
        final usageRailWidth = (cardWidth * 0.64)
            .clamp(218.0, 252.0)
            .toDouble();
        const pairedGap = 12.0;

        return SizedBox(
          height: cardHeight,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: Colors.white),
              image: const DecorationImage(
                image: AssetImage('img/logo_home_perfect.png'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.foreground.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.08),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  children: [
                    Text(
                      locale.tr('dashboard_skin_health_title'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'PlayfairDisplay',
                        color: AppColors.heading,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: pairedGap),
                    CircularScore(
                      score: resolvedScore,
                      size: scoreSize,
                      label: score == null
                          ? locale.tr('dashboard_no_scan')
                          : locale.tr('dashboard_skin_balanced'),
                      suffix: score == null ? '' : '%',
                      progressColor: AppColors.primaryDark,
                      scoreFontSize: 30,
                      labelFontSize: 10,
                      scoreColor: AppColors.heading,
                      labelColor: AppColors.heading,
                    ),
                    const SizedBox(height: 22),
                    if (lastScanAt != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                locale
                                    .tr('dashboard_last_scan_format')
                                    .replaceAll(
                                      '{time}',
                                      _relativeScanTime(lastScanAt!, locale),
                                    ),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.heading,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (usageLabel != null) ...[
                      const SizedBox(height: pairedGap),
                      SizedBox(
                        width: usageRailWidth,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    locale.tr('dashboard_usage'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.heading,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                Text(
                                  usageLabel,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AppColors.heading,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: LinearProgressIndicator(
                                value: usageProgress,
                                minHeight: 5,
                                backgroundColor: AppColors.surface.withValues(
                                  alpha: 0.82,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  exhausted
                                      ? AppColors.error
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (exhausted) ...[
                        const SizedBox(height: 5),
                        TextButton.icon(
                          onPressed: onUpgrade,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                          ),
                          label: Text(
                            locale.tr('dashboard_upgrade_unlimited_scans'),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            textStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                            minimumSize: const Size.fromHeight(26),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _relativeScanTime(DateTime value, AppLocale locale) {
  final localValue = value.toLocal();
  var difference = DateTime.now().difference(localValue);
  if (difference.isNegative) {
    difference = Duration.zero;
  }

  if (difference.inMinutes < 1) {
    return locale.tr('dashboard_scan_just_now');
  }
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    final key = minutes == 1
        ? 'dashboard_scan_minute_ago'
        : 'dashboard_scan_minutes_ago';
    return locale.tr(key).replaceAll('{count}', '$minutes');
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    final key = hours == 1
        ? 'dashboard_scan_hour_ago'
        : 'dashboard_scan_hours_ago';
    return locale.tr(key).replaceAll('{count}', '$hours');
  }
  if (difference.inDays < 30) {
    final days = difference.inDays;
    final key = days == 1
        ? 'dashboard_scan_day_ago'
        : 'dashboard_scan_days_ago';
    return locale.tr(key).replaceAll('{count}', '$days');
  }

  final day = localValue.day.toString().padLeft(2, '0');
  final month = localValue.month.toString().padLeft(2, '0');
  return '$day/$month/${localValue.year}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.acne,
    required this.redness,
    required this.hydration,
    required this.routinePercent,
  });

  final int? acne;
  final int? redness;
  final String hydration;
  final double routinePercent;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          final itemWidth = (constraints.maxWidth - (AppSpacing.sm * 3)) / 4;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: itemWidth,
                child: _MetricMiniCard(
                  label: locale.tr('metric_acne'),
                  value: _scoreLabel(acne, locale),
                  tone: _scoreTone(acne),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _MetricMiniCard(
                  label: locale.tr('metric_redness'),
                  value: _scoreLabel(redness, locale),
                  tone: _scoreTone(redness),
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _MetricMiniCard(
                  label: locale.tr('metric_hydration'),
                  value: hydration,
                  tone: StatusChipTone.success,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _MetricMiniCard(
                  label: locale.tr('metric_routine'),
                  value: '${(routinePercent * 100).round()}%',
                  tone: StatusChipTone.accent,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricMiniCard(
                    label: locale.tr('metric_acne'),
                    value: _scoreLabel(acne, locale),
                    tone: _scoreTone(acne),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetricMiniCard(
                    label: locale.tr('metric_redness'),
                    value: _scoreLabel(redness, locale),
                    tone: _scoreTone(redness),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetricMiniCard(
              label: locale.tr('metric_hydration'),
              value: hydration,
              trailing: '${(routinePercent * 100).round()}%',
              tone: StatusChipTone.success,
            ),
          ],
        );
      },
    );
  }

  String _scoreLabel(int? value, AppLocale locale) {
    if (value == null) {
      return locale.tr('metric_severity_low');
    }
    if (value >= 70) {
      return locale.tr('metric_severity_high');
    }
    if (value >= 40) {
      return locale.tr('metric_severity_mild');
    }
    return locale.tr('metric_severity_low');
  }

  StatusChipTone _scoreTone(int? value) {
    if (value == null || value < 40) {
      return StatusChipTone.success;
    }
    if (value < 70) {
      return StatusChipTone.warning;
    }
    return StatusChipTone.danger;
  }
}

class _MetricMiniCard extends StatelessWidget {
  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.tone,
    this.trailing,
  });

  final String label;
  final String value;
  final String? trailing;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusChipTone.success => AppColors.success,
      StatusChipTone.warning => AppColors.warning,
      StatusChipTone.danger => AppColors.error,
      _ => AppColors.primaryDark,
    };
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryDark, width: 3),
              ),
              child: Text(
                trailing!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutinePreviewCard extends StatelessWidget {
  const _RoutinePreviewCard({
    required this.completedSteps,
    required this.totalSteps,
    required this.progress,
    required this.steps,
    required this.onOpen,
  });

  final int completedSteps;
  final int totalSteps;
  final double progress;
  final List<_RoutinePreviewItem> steps;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locale.tr('dashboard_today_routine'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              StatusChip(
                label: totalSteps == 0
                    ? locale.tr('routine_not_set')
                    : '$completedSteps/$totalSteps ${locale.tr('dashboard_steps')}',
                tone: StatusChipTone.accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (steps.isEmpty)
            Text(
              locale.tr('routine_empty_prompt'),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: steps.length,
                separatorBuilder: (_, index) {
                  final changesPeriod =
                      steps[index].periodLabel != steps[index + 1].periodLabel;
                  if (!changesPeriod) {
                    return const SizedBox(width: 12);
                  }
                  return SizedBox(
                    width: 24,
                    child: Center(
                      child: Container(
                        width: 1.5,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.outline.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  );
                },
                itemBuilder: (context, index) =>
                    _RoutineBubble(item: steps[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineBubble extends StatelessWidget {
  const _RoutineBubble({required this.item});

  final _RoutinePreviewItem item;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final step = item.step;
    final category = step.category.trim().isEmpty
        ? locale.tr('product_default_brand')
        : step.category.trim();
    final stepLabel = locale
        .tr('dashboard_step_number')
        .replaceAll('{number}', '${item.sequence}');
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          _RoutineProductImage(step: step),
          const SizedBox(height: 7),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.periodLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stepLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineProductImage extends StatelessWidget {
  const _RoutineProductImage({required this.step});

  final RegimenStep step;

  @override
  Widget build(BuildContext context) {
    final raw = step.imageUrl?.trim() ?? '';
    final url = raw.isEmpty
        ? ''
        : raw.startsWith('http')
        ? raw
        : '${AppConfig.apiBaseUrl}$raw';

    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? _RoutineImageFallback(category: step.category)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _RoutineImageFallback(category: step.category),
              ),
      ),
    );
  }
}

class _RoutineImageFallback extends StatelessWidget {
  const _RoutineImageFallback({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceStrong,
      child: Icon(
        _categoryIcon(category),
        color: AppColors.primaryDark,
        size: 22,
      ),
    );
  }
}

class _RoutinePreviewItem {
  const _RoutinePreviewItem({
    required this.step,
    required this.periodLabel,
    required this.sequence,
  });

  final RegimenStep step;
  final String periodLabel;
  final int sequence;
}

List<_RoutinePreviewItem> _routinePreviewItems(
  CurrentRegimen? regimen,
  AppLocale locale,
) {
  if (regimen == null) {
    return const [];
  }

  _RoutinePreviewItem buildItem(
    RegimenStep step,
    int index,
    String periodLabel,
  ) {
    return _RoutinePreviewItem(
      step: step,
      periodLabel: periodLabel,
      sequence: step.stepOrder > 0 ? step.stepOrder : index + 1,
    );
  }

  return [
    for (var i = 0; i < regimen.morning.length; i++)
      buildItem(regimen.morning[i], i, locale.tr('dashboard_morning')),
    for (var i = 0; i < regimen.evening.length; i++)
      buildItem(regimen.evening[i], i, locale.tr('dashboard_evening')),
  ];
}

IconData _categoryIcon(String category) {
  return switch (category.trim().toLowerCase()) {
    'cleanser' => Icons.soap_outlined,
    'toner' => Icons.opacity_outlined,
    'serum' => Icons.science_outlined,
    'moisturizer' => Icons.spa_outlined,
    'sunscreen' => Icons.wb_sunny_outlined,
    _ => Icons.local_florist_outlined,
  };
}

class _ForYouSection extends StatelessWidget {
  const _ForYouSection({
    required this.loading,
    required this.products,
    required this.onOpenProducts,
    this.errorMessage,
  });

  final bool loading;
  final List<AiRecommendedProduct> products;
  final VoidCallback onOpenProducts;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    if (loading) {
      return const _ForYouLoading();
    }
    if (products.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: locale.tr('recommendation_empty_title'),
              icon: Icons.auto_awesome_rounded,
              tone: StatusChipTone.accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage?.trim().isNotEmpty == true
                  ? errorMessage!
                  : locale.tr('recommendation_empty_prompt'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: locale.tr('recommendation_open_shop'),
              variant: AppButtonVariant.secondary,
              onPressed: onOpenProducts,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: locale.tr('recommendation_for_you'),
          actionLabel: locale.tr('recommendation_shop'),
          onAction: onOpenProducts,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 208,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) => SizedBox(
              width: 164,
              child: _ProductPreview(product: products[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ForYouLoading extends StatelessWidget {
  const _ForYouLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _LoadingBlock()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _LoadingBlock()),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.metric,
      child: SizedBox(
        height: 128,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryDark.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.product});

  final AiRecommendedProduct product;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _ProductImage(product: product)),
          const SizedBox(height: 8),
          Text(
            product.brand.trim().isEmpty
                ? locale.tr('product_default_brand')
                : product.brand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${product.matchPercent ?? product.matchScore}% ${locale.tr('product_match_percent')}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final AiRecommendedProduct product;

  @override
  Widget build(BuildContext context) {
    final raw = product.imageUrl?.trim() ?? '';
    final url = raw.isEmpty
        ? ''
        : raw.startsWith('http')
        ? raw
        : '${AppConfig.apiBaseUrl}$raw';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        width: double.infinity,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? const Icon(Icons.spa_outlined, color: AppColors.primaryDark)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.onChat, required this.onProgress});

  final VoidCallback onChat;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 700;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - AppSpacing.sm) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: itemWidth,
              child: _SecondaryActionCard(
                onPressed: onChat,
                icon: Icons.chat_bubble_outline_rounded,
                label: locale.tr('dashboard_ai_chat'),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _SecondaryActionCard(
                onPressed: onProgress,
                icon: Icons.trending_up_rounded,
                label: locale.tr('dashboard_view_progress'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrimaryScanAction extends StatelessWidget {
  const _PrimaryScanAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 86,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.document_scanner_outlined,
                color: AppColors.onPrimary,
                size: 26,
              ),
              const SizedBox(height: 7),
              Text(
                locale.tr('dashboard_scan_with_ai'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.onPrimary,
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  const _SecondaryActionCard({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: const BorderSide(color: Colors.white),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 78,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.heading,
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SubscriptionUsage? _findUsage(
  List<SubscriptionUsage> usage,
  String featureKey,
) {
  final normalizedKey = featureKey.trim().toLowerCase();
  for (final item in usage) {
    if (item.featureKey.trim().toLowerCase() == normalizedKey) {
      return item;
    }
  }
  return null;
}
