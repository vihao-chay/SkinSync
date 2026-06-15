import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/status_chip.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AiProductRecommendResponse? _latestRecommendation;
  bool _loadingRecommendations = true;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    _loadLatestRecommendation();
  }

  Future<void> _refreshAll() async {
    final appState = context.read<AppState>();
    await appState.refreshHome();
    await _loadLatestRecommendation();
  }

  Future<void> _loadLatestRecommendation() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      final result = await context.read<AppState>().getLatestRecommendations();
      if (!mounted) {
        return;
      }
      setState(() => _latestRecommendation = result);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _latestRecommendation = null;
        _recommendationError = context.read<AppState>().errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRecommendations = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final latestAnalysis = appState.latestAnalysis;
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final user = appState.user;

    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final routineProgress =
        totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final previewSteps = [...?regimen?.morning, ...?regimen?.evening].take(3).toList();
    final recommendedProducts = (_latestRecommendation?.products ?? const [])
        .where((item) => item.name.trim().isNotEmpty)
        .take(2)
        .toList();
    final score = latestAnalysis?.displaySkinHealthScore;

    return ColoredBox(
      color: const Color(0xFFF5F4EE),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: _refreshAll,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  12,
                  AppSpacing.pagePadding,
                  AppSpacing.pageBottomPaddingWithActions,
                ),
                children: [
                  _HomeHeader(
                    avatarUrl: user?.avatarUrl,
                    score: score,
                    onProfileTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.profile),
                    onProgressTap: () => MainShell.navigateToTab(
                      context,
                      AppRoutes.progress,
                    ),
                    onProductsTap: () => MainShell.navigateToTab(
                      context,
                      AppRoutes.products,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _GreetingSection(
                    firstName: _firstName(appState.profileDisplayName),
                    hasRoutine: regimen != null,
                    hasAnalysis: latestAnalysis != null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SkinHealthHeroCard(
                    score: score,
                    lastScanLabel: _lastScanLabel(latestAnalysis),
                    onOpenAnalysis: () =>
                        Navigator.pushNamed(context, AppRoutes.upload),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SkinConcernMetricsCard(
                    metrics: _buildConcernMetrics(latestAnalysis),
                    onScanWithAi: () =>
                        Navigator.pushNamed(context, AppRoutes.upload),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DailyRoutineCard(
                    completedSteps: completedSteps,
                    totalSteps: totalSteps,
                    progress: routineProgress,
                    hasRoutine: regimen != null,
                    onOpen: () {
                      if (regimen != null) {
                        Navigator.pushNamed(context, AppRoutes.todayCheckup);
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
                  if (previewSteps.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _SectionRow(
                      title: 'Today routine',
                      trailing: 'Open',
                      onTap: () =>
                          MainShell.navigateToTab(context, AppRoutes.routine),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...previewSteps.map(
                      (step) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RoutinePreviewTile(step: step),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _SectionRow(
                    title: 'For You',
                    trailing: recommendedProducts.isNotEmpty ? 'Open' : null,
                    onTap: recommendedProducts.isNotEmpty
                        ? () => MainShell.navigateToTab(
                              context,
                              AppRoutes.products,
                            )
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_loadingRecommendations)
                    const _HomeSkeletonLoading()
                  else if (recommendedProducts.isNotEmpty)
                    SizedBox(
                      height: 224,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendedProducts.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final product = recommendedProducts[index];
                          return SizedBox(
                            width: 168,
                            child: _ForYouProductPreview(
                              product: product,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.productDetail,
                                arguments: ProductDetailPageArgs(
                                  productId: product.productId,
                                  recommendationItem: product,
                                  sourceProductsEntryPoint:
                                      ProductsEntryPoint.bottomNav,
                                  alreadyInRoutine: product.alreadyInRoutine,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    _EmptyRecommendationCard(
                      message: _recommendationError?.trim().isNotEmpty == true
                          ? _recommendationError!
                          : 'Scan with AI first, then generate products manually.',
                      onOpenProducts: () => MainShell.navigateToTab(
                        context,
                        AppRoutes.products,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _QuickActionRow(
                    onScan: () => Navigator.pushNamed(context, AppRoutes.upload),
                    onCheckup: () {
                      if (regimen != null) {
                        Navigator.pushNamed(context, AppRoutes.todayCheckup);
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
                    onProgress: () =>
                        MainShell.navigateToTab(context, AppRoutes.progress),
                    onProducts: () =>
                        MainShell.navigateToTab(context, AppRoutes.products),
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

  String _lastScanLabel(AnalysisResult? result) {
    if (result == null) {
      return 'No scan yet';
    }
    return 'Latest scan';
  }

  List<_ConcernMetricSnapshot> _buildConcernMetrics(AnalysisResult? result) {
    final third = _resolveConcernMetric(
      result: result,
      primaryLabel: 'Oiliness',
      metricValue: result?.metrics.oiliness,
      issueMatchers: const ['oil', 'oily', 'shine', 'pore'],
      fallbackLabel: 'Moisture',
      fallbackMetricValue: result?.metrics.moisture,
      fallbackIssueMatchers: const ['dry', 'dehyd', 'moisture', 'hydrat'],
    );

    return [
      _ConcernMetricSnapshot(
        label: 'Acne',
        value: _resolveConcernMetricValue(
          result: result,
          metricValue: result?.metrics.acne,
          issueMatchers: const ['acne', 'breakout', 'pimple'],
        ),
      ),
      _ConcernMetricSnapshot(
        label: 'Redness',
        value: _resolveConcernMetricValue(
          result: result,
          metricValue: result?.metrics.redness,
          issueMatchers: const ['red', 'irrit', 'sensit'],
        ),
      ),
      third,
    ];
  }

  _ConcernMetricSnapshot _resolveConcernMetric({
    required AnalysisResult? result,
    required String primaryLabel,
    required int? metricValue,
    required List<String> issueMatchers,
    String? fallbackLabel,
    int? fallbackMetricValue,
    List<String> fallbackIssueMatchers = const [],
  }) {
    final primaryValue = _resolveConcernMetricValue(
      result: result,
      metricValue: metricValue,
      issueMatchers: issueMatchers,
    );
    if (primaryValue != null || fallbackLabel == null) {
      return _ConcernMetricSnapshot(label: primaryLabel, value: primaryValue);
    }

    return _ConcernMetricSnapshot(
      label: fallbackLabel,
      value: _resolveConcernMetricValue(
        result: result,
        metricValue: fallbackMetricValue,
        issueMatchers: fallbackIssueMatchers,
      ),
    );
  }

  int? _resolveConcernMetricValue({
    required AnalysisResult? result,
    required int? metricValue,
    required List<String> issueMatchers,
  }) {
    if (result == null) {
      return null;
    }

    final issueScore = _issueScore(result, issueMatchers);
    if (metricValue != null && metricValue > 0) {
      return metricValue.clamp(0, 100);
    }

    if (issueScore != null) {
      return issueScore;
    }

    if (metricValue == 0 && result.displayConcernSeverityScore == 0) {
      return 0;
    }

    return null;
  }

  int? _issueScore(AnalysisResult result, List<String> matchers) {
    for (final issue in result.issues) {
      final normalized = issue.issueType.toLowerCase();
      if (matchers.any(normalized.contains)) {
        return issue.severityScore.clamp(0, 100);
      }
    }
    return null;
  }
}

class _ConcernMetricSnapshot {
  const _ConcernMetricSnapshot({
    required this.label,
    required this.value,
  });

  final String label;
  final int? value;
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.avatarUrl,
    required this.score,
    required this.onProfileTap,
    required this.onProgressTap,
    required this.onProductsTap,
  });

  final String? avatarUrl;
  final int? score;
  final VoidCallback onProfileTap;
  final VoidCallback onProgressTap;
  final VoidCallback onProductsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.secondary,
            backgroundImage: _networkImage(avatarUrl),
            child: _networkImage(avatarUrl) == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (score != null) ...[
          Text(
            '$score%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Skin health',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
            ),
          ),
        ],
        const Spacer(),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onProgressTap,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.grid_view_rounded,
          onTap: onProductsTap,
        ),
      ],
    );
  }

  ImageProvider<Object>? _networkImage(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }
    return NetworkImage(url);
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.firstName,
    required this.hasRoutine,
    required this.hasAnalysis,
  });

  final String firstName;
  final bool hasRoutine;
  final bool hasAnalysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName.isEmpty ? 'Hello' : 'Hello $firstName',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.heading,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          hasRoutine
              ? 'Ready for your routine today?'
              : hasAnalysis
                  ? 'Latest scan is ready.'
                  : 'Start with a quick AI skin scan.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
      ],
    );
  }
}

class _SkinHealthHeroCard extends StatelessWidget {
  const _SkinHealthHeroCard({
    required this.score,
    required this.lastScanLabel,
    required this.onOpenAnalysis,
  });

  final int? score;
  final String lastScanLabel;
  final VoidCallback onOpenAnalysis;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.hero,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Skin Health',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  score == null ? '--' : '$score%',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        color: AppColors.heading,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastScanLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 108,
            height: 108,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: CircularProgressIndicator(
                    value: score == null ? 0 : score! / 100,
                    strokeWidth: 10,
                    backgroundColor: AppColors.border.withValues(alpha: 0.55),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFF1BD3D),
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8E8A6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    score == null
                        ? Icons.camera_alt_outlined
                        : Icons.spa_outlined,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinConcernMetricsCard extends StatelessWidget {
  const _SkinConcernMetricsCard({
    required this.metrics,
    required this.onScanWithAi,
  });

  final List<_ConcernMetricSnapshot> metrics;
  final VoidCallback onScanWithAi;

  @override
  Widget build(BuildContext context) {
    final hasAnyMetric = metrics.any((item) => item.value != null);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xs),
          if (hasAnyMetric)
            Row(
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  Expanded(
                    child: _CircularMetric(
                      label: metrics[index].label,
                      value: metrics[index].value,
                    ),
                  ),
                  if (index != metrics.length - 1)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                'No concern metrics yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _ScanWithAiPill(onTap: onScanWithAi),
        ],
      ),
    );
  }
}

class _CircularMetric extends StatelessWidget {
  const _CircularMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value == null ? 0 : value! / 100,
                strokeWidth: 7,
                backgroundColor: AppColors.secondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value == null ? AppColors.border : AppColors.primaryDark,
                ),
              ),
              Text(
                value == null ? '--' : '$value',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
      ],
    );
  }
}

class _ScanWithAiPill extends StatelessWidget {
  const _ScanWithAiPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFFF1BD3D),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scan with AI',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1BD3D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyRoutineCard extends StatelessWidget {
  const _DailyRoutineCard({
    required this.completedSteps,
    required this.totalSteps,
    required this.progress,
    required this.hasRoutine,
    required this.onOpen,
  });

  final int completedSteps;
  final int totalSteps;
  final double progress;
  final bool hasRoutine;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4CE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.mutedText,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Daily Routine',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Open',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasRoutine ? '$completedSteps/$totalSteps done' : 'No routine yet',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (hasRoutine) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.secondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutinePreviewTile extends StatelessWidget {
  const _RoutinePreviewTile({required this.step});

  final RegimenStep step;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
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
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTap,
            child: Text(trailing!),
          ),
      ],
    );
  }
}

class _ForYouProductPreview extends StatelessWidget {
  const _ForYouProductPreview({
    required this.product,
    required this.onTap,
  });

  final AiRecommendedProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceStrong,
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  radius: 18,
                  iconSize: 28,
                  placeholderTitle: product.brand.trim().isEmpty
                      ? product.name
                      : product.brand,
                  placeholderSubtitle: product.category,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.brand.trim().isEmpty ? 'Product' : product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${product.matchPercent ?? product.matchScore}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRecommendationCard extends StatelessWidget {
  const _EmptyRecommendationCard({
    required this.message,
    required this.onOpenProducts,
  });

  final String message;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: 'No recommendations yet',
            icon: Icons.auto_awesome_rounded,
            tone: StatusChipTone.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Open Products',
            variant: AppButtonVariant.secondary,
            onPressed: onOpenProducts,
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onScan,
    required this.onCheckup,
    required this.onProgress,
    required this.onProducts,
  });

  final VoidCallback onScan;
  final VoidCallback onCheckup;
  final VoidCallback onProgress;
  final VoidCallback onProducts;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final width = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.sm) / 2;
        final items = [
          _QuickActionItem(
            icon: Icons.auto_awesome_rounded,
            label: 'Scan with AI',
            onTap: onScan,
          ),
          _QuickActionItem(
            icon: Icons.check_circle_outline_rounded,
            label: 'Open Check-up',
            onTap: onCheckup,
          ),
          _QuickActionItem(
            icon: Icons.query_stats_rounded,
            label: 'View Progress',
            onTap: onProgress,
          ),
          _QuickActionItem(
            icon: Icons.shopping_bag_outlined,
            label: 'Products',
            onTap: onProducts,
          ),
        ];
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: item,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }
}

class _HomeSkeletonLoading extends StatelessWidget {
  const _HomeSkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonProductCard()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _SkeletonProductCard()),
      ],
    );
  }
}

class _SkeletonProductCard extends StatelessWidget {
  const _SkeletonProductCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 60,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
