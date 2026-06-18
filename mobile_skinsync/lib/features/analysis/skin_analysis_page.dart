import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/main_shell.dart';
import 'product_ingredient_analysis_page.dart';
import 'widgets/analysis_mode_tabs.dart';

class SkinAnalysisPage extends StatefulWidget {
  const SkinAnalysisPage({super.key});

  @override
  State<SkinAnalysisPage> createState() => _SkinAnalysisPageState();
}

class _SkinAnalysisPageState extends State<SkinAnalysisPage> {
  AnalysisMode _selectedMode = AnalysisMode.skin;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final result = appState.latestAnalysis;

    if (_selectedMode == AnalysisMode.product) {
      return ProductIngredientAnalysisPage(
        selectedMode: _selectedMode,
        onModeChanged: (mode) => setState(() => _selectedMode = mode),
      );
    }

    if (result == null) {
      return _EmptyAnalysis(
        selectedMode: _selectedMode,
        onModeChanged: (mode) => setState(() => _selectedMode = mode),
        onStart: () => Navigator.pushNamed(context, AppRoutes.quiz),
      );
    }

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                _AnalysisTopBar(
                  onBack: () =>
                      MainShell.navigateToTab(context, AppRoutes.dashboard),
                  onShare: () => Navigator.pushNamed(
                    context,
                    AppRoutes.aiChatConversation,
                    arguments: AiChatLaunchArgs(
                      entryPoint: 'analysis_result',
                      referenceId: result.progressEntryId ?? result.id,
                      prefillMessage:
                          'Can you explain this analysis and what I should do next?',
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryDark,
                    onRefresh: appState.refreshHome,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 82),
                      children: [
                        Text(
                          'Analysis Results',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          result.source?.trim().isNotEmpty == true
                              ? 'Saved from ${result.source}'
                              : 'Saved from your latest skin scan.',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.heading,
                                fontSize: 9,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        AnalysisModeTabs(
                          selectedMode: _selectedMode,
                          onChanged: (mode) =>
                              setState(() => _selectedMode = mode),
                        ),
                        const SizedBox(height: 10),
                        _ScoreHero(result: result),
                        const SizedBox(height: 10),
                        _OverviewCard(result: result),
                        const SizedBox(height: 10),
                        _DetectedAreas(issues: result.issues),
                        const SizedBox(height: 10),
                        _RecommendationList(
                          recommendations: result.recommendations,
                        ),
                        if (result.warnings.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _SafetyWarning(warnings: result.warnings),
                        ],
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.96),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _CompactActionButton(
                            label: 'Ask AI',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.aiChatConversation,
                              arguments: AiChatLaunchArgs(
                                entryPoint: 'analysis_result',
                                referenceId:
                                    result.progressEntryId ?? result.id,
                                prefillMessage:
                                    'Can you explain this analysis and what I should do next?',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactActionButton(
                            label: 'View Products',
                            secondary: true,
                            onPressed: () => MainShell.navigateToTab(
                              context,
                              AppRoutes.products,
                              arguments: ProductsPageArgs(
                                initialConcern: result.issues.isNotEmpty
                                    ? result.issues.first.issueType
                                    : 'any',
                                referenceId:
                                    result.progressEntryId ?? result.id,
                                entryPoint: ProductsEntryPoint.analysisResult,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  const _AnalysisTopBar({required this.onBack, this.onShare});

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
              tooltip: 'Back',
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
                tooltip: 'Share',
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
  const _EmptyAnalysis({
    required this.selectedMode,
    required this.onModeChanged,
    required this.onStart,
  });

  final AnalysisMode selectedMode;
  final ValueChanged<AnalysisMode> onModeChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            8,
            AppSpacing.pagePadding,
            AppSpacing.pageBottomPaddingWithActions,
          ),
          children: [
            _AnalysisTopBar(onBack: () => Navigator.maybePop(context)),
            const SizedBox(height: AppSpacing.md),
            AnalysisModeTabs(
              selectedMode: selectedMode,
              onChanged: onModeChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 42,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No analysis yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Complete the skin quiz and upload a clear photo to generate your first AI report.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: 'Start Quiz', onPressed: onStart),
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
  const _ScoreHero({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore ?? result.displaySkinHealthScore ?? 0;
    return AppCard(
      variant: AppCardVariant.metric,
      radius: AppRadius.small,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          _AnalysisScoreDial(score: score),
          const SizedBox(height: 6),
          Text(
            _balanceTitle(score),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.heading,
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          _TinyPill(
            label: '${result.confidenceScore}% confidence',
            icon: Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  String _balanceTitle(int score) {
    if (score >= 80) {
      return 'Excellent Balance';
    }
    if (score >= 60) {
      return 'Stable Balance';
    }
    return 'Needs Attention';
  }
}

class _AnalysisScoreDial extends StatelessWidget {
  const _AnalysisScoreDial({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100).toInt();
    return SizedBox.square(
      dimension: 104,
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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.heading,
                      fontSize: 9,
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
      ..color = AppColors.surfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
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
  const _OverviewCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('AI Overview'),
        const SizedBox(height: 6),
        AppCard(
          variant: AppCardVariant.metric,
          radius: AppRadius.small,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Text(
            result.overview?.trim().isNotEmpty == true
                ? result.overview!
                : 'Your latest analysis is ready. Keep tracking routine consistency and product fit over time.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              height: 1.38,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetectedAreas extends StatelessWidget {
  const _DetectedAreas({required this.issues});

  final List<AnalysisIssue> issues;

  @override
  Widget build(BuildContext context) {
    final visibleIssues = issues.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('Detected Areas'),
        const SizedBox(height: 6),
        if (issues.isEmpty)
          const _CompactEmptyCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'No detected concerns',
            body: 'Your latest scan did not return specific concern areas.',
          )
        else
          Row(
            children: List.generate(visibleIssues.length, (index) {
              final issue = visibleIssues[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == visibleIssues.length - 1 ? 0 : 8,
                  ),
                  child: _IssueCard(issue: issue),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final AnalysisIssue issue;

  @override
  Widget build(BuildContext context) {
    final high = issue.severityScore >= 70;
    final medium = issue.severityScore >= 40;
    return AppCard(
      variant: AppCardVariant.metric,
      radius: AppRadius.small,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IssueIcon(
                icon: high
                    ? Icons.priority_high_rounded
                    : medium
                    ? Icons.wb_sunny_outlined
                    : Icons.check_rounded,
                danger: high,
              ),
              const Spacer(),
              _SeverityPill(
                label: high
                    ? 'High'
                    : medium
                    ? 'Mild'
                    : 'Good',
                danger: high,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            issue.issueType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.heading,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            issue.description?.trim().isNotEmpty == true
                ? issue.description!
                : '${issue.severityScore}/100',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 9, height: 1.2),
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
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: danger
            ? AppColors.errorContainer.withValues(alpha: 0.66)
            : AppColors.primaryFixed.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 13,
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
  const _RecommendationList({required this.recommendations});

  final List<AnalysisRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('Recommendations'),
        const SizedBox(height: 6),
        if (recommendations.isEmpty)
          const _CompactEmptyCard(
            icon: Icons.spa_outlined,
            title: 'No recommendations yet',
            body:
                'Recommendations will appear when the analysis includes them.',
          )
        else
          ...recommendations
              .take(4)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: AppCard(
                    variant: AppCardVariant.metric,
                    radius: AppRadius.small,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco_outlined,
                            size: 13,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title.trim().isEmpty
                                    ? item.content
                                    : item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.heading,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (item.title.trim().isNotEmpty)
                                Text(
                                  item.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(fontSize: 9, height: 1.2),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.expand_more_rounded,
                          size: 16,
                          color: AppColors.mutedText,
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
      radius: AppRadius.small,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                  ).textTheme.labelSmall?.copyWith(fontSize: 9, height: 1.2),
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
  const _SafetyWarning({required this.warnings});

  final List<String> warnings;

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
                  'Sensitivity Warning',
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

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w900,
      fontSize: 10,
      height: 1,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );

    if (secondary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.62)),
          textStyle: textStyle,
          shape: shape,
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 13),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: textStyle,
        shape: shape,
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
