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
import '../../core/widgets/stitch_top_bar.dart';
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
    final progress = appState.progress;
    final scanUsage = _findUsage(
      appState.subscription?.usage ?? const <SubscriptionUsage>[],
      'skin_analysis',
    );
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routineProgress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final routineSteps = [
      ...?regimen?.morning,
      ...?regimen?.evening,
    ].take(3).toList();
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
                  StitchTopBar(
                    avatarUrl: appState.user?.avatarUrl,
                    onLeadingTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.profile),
                    onTrailingTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.progress),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      4,
                      horizontalPadding,
                      Responsive.contentBottomSpacing(context, extra: 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Greeting(
                          name: _firstName(appState.profileDisplayName),
                          hasRoutine: regimen != null,
                          hasAnalysis: latestAnalysis != null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SkinHealthCard(
                          score:
                              latestAnalysis?.displaySkinHealthScore ??
                              latestAnalysis?.overallScore,
                          insight: progress?.progressInsight,
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

  String _firstName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'You') {
      return '';
    }
    return trimmed.split(' ').first.trim();
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

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.hasRoutine,
    required this.hasAnalysis,
  });

  final String name;
  final bool hasRoutine;
  final bool hasAnalysis;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final helloStr = name.isEmpty
        ? locale.tr('dashboard_hello')
        : '${locale.tr('dashboard_hello')}, $name';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helloStr,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hasRoutine
              ? locale.tr('dashboard_greeting_ready')
              : hasAnalysis
              ? locale.tr('dashboard_greeting_insights')
              : locale.tr('dashboard_greeting_start'),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.foreground),
        ),
      ],
    );
  }
}

class _SkinHealthCard extends StatelessWidget {
  const _SkinHealthCard({
    required this.score,
    required this.insight,
    required this.scanUsage,
    required this.onUpgrade,
  });

  final int? score;
  final String? insight;
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

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        children: [
          Text(
            locale.tr('dashboard_skin_health_title'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          CircularScore(
            score: resolvedScore,
            size: 136,
            label: score == null
                ? locale.tr('dashboard_no_scan')
                : locale.tr('dashboard_skin_balanced'),
            suffix: score == null ? '' : '%',
            progressColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              score == null
                  ? locale.tr('dashboard_scan_prompt')
                  : insight?.trim().isNotEmpty == true
                  ? insight!
                  : locale.tr('dashboard_baseline_saved'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (usageLabel != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    locale.tr('dashboard_usage'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.heading,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  usageLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: exhausted ? AppColors.error : AppColors.heading,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: usageProgress,
                minHeight: 5,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  exhausted ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            if (exhausted) ...[
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: onUpgrade,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: Text(locale.tr('dashboard_upgrade_unlimited_scans')),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(32),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
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
  final List<RegimenStep> steps;
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
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: steps.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _RoutineBubble(step: steps[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineBubble extends StatelessWidget {
  const _RoutineBubble({required this.step});

  final RegimenStep step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceStrong,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: Icon(
              _categoryIcon(step.category),
              color: AppColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            step.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
            ),
          ),
          Text(
            step.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
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
