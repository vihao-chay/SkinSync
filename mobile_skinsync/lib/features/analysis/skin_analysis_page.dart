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
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/stitch_top_bar.dart';
import '../../core/widgets/status_chip.dart';
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
                StitchTopBar(
                  leadingIcon: Icons.arrow_back_rounded,
                  trailingIcon: Icons.ios_share_rounded,
                  onLeadingTap: () => MainShell.navigateToTab(
                    context,
                    AppRoutes.dashboard,
                  ),
                  onTrailingTap: () => Navigator.pushNamed(
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        4,
                        AppSpacing.pagePadding,
                        18,
                      ),
                      children: [
                        Text(
                          'Analysis Results',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.source?.trim().isNotEmpty == true
                              ? 'Saved from ${result.source}'
                              : 'Saved from your latest skin scan.',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.foreground,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AnalysisModeTabs(
                          selectedMode: _selectedMode,
                          onChanged: (mode) => setState(() => _selectedMode = mode),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ScoreHero(result: result),
                        const SizedBox(height: AppSpacing.md),
                        _OverviewCard(result: result),
                        const SizedBox(height: AppSpacing.md),
                        _DetectedAreas(issues: result.issues),
                        const SizedBox(height: AppSpacing.md),
                        _RecommendationList(
                          recommendations: result.recommendations,
                        ),
                        if (result.warnings.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _SafetyWarning(warnings: result.warnings),
                        ],
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                          child: AppButton(
                            label: 'Ask SkinSync AI',
                            icon: const Icon(Icons.auto_awesome_rounded),
                            onPressed: () => Navigator.pushNamed(
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
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'View Products',
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
            const StitchTopBar(),
            const SizedBox(height: AppSpacing.md),
            AnalysisModeTabs(selectedMode: selectedMode, onChanged: onModeChanged),
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
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          CircularScore(
            score: result.overallScore,
            size: 132,
            label: '/100',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _balanceTitle(result.overallScore),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          StatusChip(
            label: '${result.confidenceScore}% confidence',
            icon: Icons.verified_outlined,
            tone: StatusChipTone.success,
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

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('AI Overview'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.overview?.trim().isNotEmpty == true
              ? result.overview!
              : 'Your latest analysis is ready. Keep tracking routine consistency and product fit over time.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.heading,
                height: 1.55,
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
    final visible = issues.isEmpty
        ? const <AnalysisIssue>[
            AnalysisIssue(issueType: 'Redness', severityScore: 20),
            AnalysisIssue(issueType: 'Texture', severityScore: 25),
          ]
        : issues.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('Detected Areas'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: visible
              .map(
                (issue) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _IssueCard(issue: issue),
                  ),
                ),
              )
              .toList(),
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
    final tone = high
        ? StatusChipTone.danger
        : medium
            ? StatusChipTone.warning
            : StatusChipTone.success;
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: high
                ? 'High'
                : medium
                    ? 'Mild'
                    : 'Good',
            tone: tone,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            issue.issueType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            issue.description?.trim().isNotEmpty == true
                ? issue.description!
                : '${issue.severityScore}/100',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({required this.recommendations});

  final List<AnalysisRecommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final items = recommendations.isEmpty
        ? const [
            AnalysisRecommendation(
              title: 'Increase ceramide intake',
              content: 'Keep your routine gentle and consistent while tracking changes.',
            ),
            AnalysisRecommendation(
              title: 'Adjust SPF application',
              content: 'Reapply sunscreen through the day when you are outside.',
            ),
          ]
        : recommendations.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmallSectionLabel('Recommendations'),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              variant: AppCardVariant.metric,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      size: 15,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (item.title.trim().isNotEmpty)
                          Text(
                            item.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
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

class _SafetyWarning extends StatelessWidget {
  const _SafetyWarning({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensitivity Warning',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  warnings.take(2).join('\n'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                        height: 1.45,
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
