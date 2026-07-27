import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/main_shell.dart';

class SkinAnalysisPage extends StatefulWidget {
  const SkinAnalysisPage({super.key});

  @override
  State<SkinAnalysisPage> createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final result = appState.latestAnalysis;

    if (result == null) {
      return _EmptyAnalysis(
        onStart: () => Navigator.pushNamed(context, AppRoutes.quiz),
      );
    }

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: double.infinity,
                tablet: 760,
                desktop: 960,
              ),
            ),
            child: Column(
              children: [
                _AnalysisTopBar(
                  locale: locale,
                  onBack: () =>
                      MainShell.navigateToTab(context, AppRoutes.dashboard),
                  onShare: () => Navigator.pushNamed(
                    context,
                    AppRoutes.aiChatConversation,
                    arguments: AiChatLaunchArgs(
                      entryPoint: 'analysis_result',
                      referenceId: result.progressEntryId ?? result.id,
                      prefillMessage: locale.tr('analysis_ai_prefill'),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryDark,
                    onRefresh: appState.refreshHome,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        Responsive.responsiveHorizontalPadding(context),
                        8,
                        Responsive.responsiveHorizontalPadding(context),
                        82,
                      ),
                      children: [
                        Text(
                          locale.tr('analysis_results_title'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontFamily: 'PlayfairDisplay',
                                color: AppColors.heading,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _savedFromLabel(result, locale),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.mutedText,
                                height: 1.35,
                              ),
                        ),
                        const SizedBox(height: 18),
                        _ScoreHero(result: result, locale: locale),
                        const SizedBox(height: 14),
                        _OverviewCard(result: result, locale: locale),
                        const SizedBox(height: 14),
                        _DetectedAreas(issues: result.issues, locale: locale),
                        const SizedBox(height: 14),
                        _RecommendationList(
                          recommendations: result.recommendations,
                          locale: locale,
                        ),
                        if (result.warnings.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _SafetyWarning(
                            warnings: result.warnings,
                            locale: locale,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: Responsive.responsivePadding(
                      context,
                      top: 10,
                      bottom: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final askAiButton = AppButton(
                          label: locale.tr('floating_ai_ask'),
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                          ),
                          variant: AppButtonVariant.ai,
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.aiChatConversation,
                            arguments: AiChatLaunchArgs(
                              entryPoint: 'analysis_result',
                              referenceId: result.progressEntryId ?? result.id,
                              prefillMessage: locale.tr('analysis_ai_prefill'),
                            ),
                          ),
                        );
                        final viewProductsButton = AppButton(
                          label: locale.tr('analysis_view_products'),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                          ),
                          variant: AppButtonVariant.secondary,
                          onPressed: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.products,
                            arguments: ProductsPageArgs(
                              initialConcern: result.issues.isNotEmpty
                                  ? result.issues.first.issueType
                                  : 'any',
                              referenceId: result.progressEntryId ?? result.id,
                              entryPoint: ProductsEntryPoint.analysisResult,
                            ),
                          ),
                        );

                        if (constraints.maxWidth < 360) {
                          return Column(
                            children: [
                              askAiButton,
                              const SizedBox(height: 8),
                              viewProductsButton,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: askAiButton),
                            const SizedBox(width: 10),
                            Expanded(child: viewProductsButton),
                          ],
                        );
                      },
                    ),
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

class _AnalysisTopBar extends StatelessWidget {
  const _AnalysisTopBar({
    required this.locale,
    required this.onBack,
    this.onShare,
  });

  final AppLocale locale;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            IconButton(
              tooltip: locale.tr('common_back'),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.heading,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              onPressed: onBack,
            ),
            const Spacer(),
            if (onShare != null)
              IconButton(
                tooltip: locale.tr('floating_ai_ask'),
                icon: const Icon(Icons.ios_share_rounded),
                color: AppColors.heading,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                onPressed: onShare,
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Responsive.responsiveHorizontalPadding(context),
            8,
            Responsive.responsiveHorizontalPadding(context),
            Responsive.contentBottomSpacing(context, extra: 20),
          ),
          children: [
            _AnalysisTopBar(
              locale: locale,
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              variant: AppCardVariant.metric,
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 42,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    locale.tr('analysis_empty_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    locale.tr('analysis_empty_desc'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: locale.tr('analysis_start_scan'),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    onPressed: onStart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.result, required this.locale});

  final AnalysisResult result;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore ?? result.displaySkinHealthScore ?? 0;
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          Row(
            children: [
              _TinyPill(
                label: result.skinType.trim().isEmpty
                    ? locale.tr('analysis_skin_type_unknown')
                    : result.skinType,
                icon: Icons.spa_outlined,
              ),
              const Spacer(),
              _TinyPill(
                label: locale
                    .tr('analysis_confidence_format')
                    .replaceAll(
                      '{percent}',
                      result.displayConfidencePercent.toString(),
                    ),
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AnalysisScoreDial(score: score),
          const SizedBox(height: 10),
          Text(
            _balanceTitle(score, locale),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.heading,
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _balanceTitle(int score, AppLocale locale) {
    if (score >= 80) {
      return locale.tr('analysis_score_excellent');
    }
    if (score >= 60) {
      return locale.tr('analysis_score_stable');
    }
    return locale.tr('analysis_score_attention');
  }
}

class _AnalysisScoreDial extends StatelessWidget {
  const _AnalysisScoreDial({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100).toInt();
    return SizedBox.square(
      dimension: 132,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped / 100),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _AnalysisScorePainter(
              progress: value,
              color: AppColors.primary,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$clamped',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      color: AppColors.heading,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnalysisScorePainter extends CustomPainter {
  const _AnalysisScorePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = AppColors.primaryFixed.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _AnalysisScorePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: AppColors.primary),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.result, required this.locale});

  final AnalysisResult result;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel(locale.tr('analysis_ai_overview')),
        const SizedBox(height: 8),
        AppCard(
          variant: AppCardVariant.metric,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SoftIcon(icon: Icons.auto_awesome_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.overview?.trim().isNotEmpty == true
                      ? result.overview!
                      : locale.tr('analysis_overview_fallback'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.heading,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetectedAreas extends StatelessWidget {
  const _DetectedAreas({required this.issues, required this.locale});

  final List<AnalysisIssue> issues;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = issues.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel(locale.tr('analysis_detected_areas')),
        const SizedBox(height: 8),
        if (issues.isEmpty)
          _CompactEmptyCard(
            icon: Icons.check_circle_outline_rounded,
            title: locale.tr('analysis_no_detected_concerns'),
            body: locale.tr('analysis_no_detected_concerns_desc'),
          )
        else
          Column(
            children: List.generate(visibleIssues.length, (index) {
              final issue = visibleIssues[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == visibleIssues.length - 1 ? 0 : 8,
                ),
                child: _IssueCard(issue: issue, locale: locale),
              );
            }),
          ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.locale});

  final AnalysisIssue issue;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    final high = issue.severityScore >= 70;
    final medium = issue.severityScore >= 40;
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IssueIcon(
            icon: high
                ? Icons.priority_high_rounded
                : medium
                ? Icons.wb_sunny_outlined
                : Icons.check_rounded,
            danger: high,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.issueType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue.description?.trim().isNotEmpty == true
                      ? issue.description!
                      : locale
                            .tr('analysis_score_out_of_100')
                            .replaceAll(
                              '{score}',
                              issue.severityScore.toString(),
                            ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _SeverityPill(
            label: high
                ? locale.tr('metric_severity_high')
                : medium
                ? locale.tr('metric_severity_mild')
                : locale.tr('analysis_status_good'),
            danger: high,
          ),
        ],
      ),
    );
  }
}

class _IssueIcon extends StatelessWidget {
  const _IssueIcon({required this.icon, required this.danger});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: danger
            ? AppColors.errorContainer.withValues(alpha: 0.66)
            : AppColors.primaryFixed.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 17,
        color: danger ? AppColors.error : AppColors.primary,
      ),
    );
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.label, required this.danger});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: danger
            ? AppColors.errorContainer.withValues(alpha: 0.5)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({
    required this.recommendations,
    required this.locale,
  });

  final List<AnalysisRecommendation> recommendations;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel(locale.tr('analysis_recommendations')),
        const SizedBox(height: 8),
        if (recommendations.isEmpty)
          _CompactEmptyCard(
            icon: Icons.spa_outlined,
            title: locale.tr('analysis_no_recommendations'),
            body: locale.tr('analysis_no_recommendations_desc'),
          )
        else
          ...recommendations
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    variant: AppCardVariant.metric,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SoftIcon(icon: Icons.eco_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.trim().isEmpty
                                    ? item.content
                                    : item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.heading,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (item.title.trim().isNotEmpty)
                                Text(
                                  item.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(height: 1.25),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _CompactEmptyCard extends StatelessWidget {
  const _CompactEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          _SoftIcon(icon: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyWarning extends StatelessWidget {
  const _SafetyWarning({required this.warnings, required this.locale});

  final List<String> warnings;
  final AppLocale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.tr('analysis_sensitivity_warning'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  warnings.take(2).join('\n'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontSize: 9,
                    height: 1.28,
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

class _SmallSectionLabel extends StatelessWidget {
  const _SmallSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.heading,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 17, color: AppColors.primaryDark),
    );
  }
}

String _savedFromLabel(AnalysisResult result, AppLocale locale) {
  final source = result.source?.trim();
  if (source != null &&
      source.isNotEmpty &&
      source.toLowerCase() != 'unknown') {
    return locale
        .tr('analysis_saved_from_source')
        .replaceAll('{source}', _friendlyAnalysisSource(source, locale));
  }

  return locale.tr('analysis_saved_latest_scan');
}

String _friendlyAnalysisSource(String source, AppLocale locale) {
  return switch (source.trim().toLowerCase()) {
    'manual' => locale.tr('analysis_source_manual'),
    'upload' || 'uploaded' => locale.tr('analysis_source_upload'),
    'camera' || 'photo' => locale.tr('analysis_source_camera'),
    'skin_scan' ||
    'skin-analysis' ||
    'skin_analysis' => locale.tr('analysis_source_skin_scan'),
    _ => source,
  };
}
