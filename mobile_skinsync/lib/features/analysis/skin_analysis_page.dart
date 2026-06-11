import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand_logo.dart';
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientTop, AppColors.gradientBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: appState.refreshHome,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  6,
                  AppSpacing.pagePadding,
                  18,
                ),
                children: [
                  const _MiniTopBar(),
                  const SizedBox(height: 14),
                  AnalysisModeTabs(
                    selectedMode: _selectedMode,
                    onChanged: (mode) => setState(() => _selectedMode = mode),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Skin Analysis',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.overview ??
                        'Skin score ${result.overallScore}/100 with balanced overall condition.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ScoreCard(result: result),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.42,
                    children: [
                      _MetricCard(
                        icon: Icons.face_retouching_natural_outlined,
                        label: 'Skin score',
                        value: '${result.overallScore}/100',
                      ),
                      _MetricCard(
                        icon: Icons.verified_user_outlined,
                        label: 'Confidence',
                        value: '${result.confidenceScore}%',
                      ),
                      _MetricCard(
                        icon: Icons.troubleshoot_rounded,
                        label: 'Concerns found',
                        value: '${result.issues.length}',
                      ),
                      _MetricCard(
                        icon: Icons.tips_and_updates_outlined,
                        label: 'Action tips',
                        value: '${result.recommendations.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _RecommendationsCard(
                    recommendations: result.recommendations,
                    warnings: result.warnings,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.cream.withValues(alpha: 0.94),
                border: Border(
                  top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.routine),
                      child: const Text('Generate Routine'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.progress),
                          child: const Text('View Progress'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
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
                          child: const Text('Ask AI'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.aiProductRecommend,
                        arguments: ProductsPageArgs(
                          initialConcern: result.issues.isNotEmpty
                              ? result.issues.first.issueType
                              : 'any',
                          referenceId: result.progressEntryId ?? result.id,
                        ),
                      ),
                      child: const Text('View Products'),
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.upload),
                    child: const Text('Analyze Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 106),
      children: [
        const _MiniTopBar(),
        const SizedBox(height: 14),
        AnalysisModeTabs(selectedMode: selectedMode, onChanged: onModeChanged),
        const SizedBox(height: 28),
        _SoftCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No analysis yet',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                'Complete the skin quiz and upload a photo to generate your first AI report.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onStart,
                  child: const Text('Start Quiz'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniTopBar extends StatelessWidget {
  const _MiniTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const BrandLogo(size: 24, radius: 8, showShadow: false),
          const Spacer(),
          Text(
            'SkinSync',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_none_rounded,
            size: 17,
            color: AppColors.foreground,
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current reading',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${result.overallScore}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/100',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _friendlySkinType(result.skinType),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Confidence ${result.confidenceScore}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 20),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({
    required this.recommendations,
    required this.warnings,
  });

  final List<AnalysisRecommendation> recommendations;
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final items = recommendations.isEmpty
        ? const [
            'Keep your routine gentle and consistent while tracking changes.',
          ]
        : recommendations.map((item) => item.content).toList();

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommendations',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.foreground,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.foreground,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 4),
            Divider(color: AppColors.border.withValues(alpha: 0.34)),
            const SizedBox(height: 8),
            ...warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  warning,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _friendlySkinType(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') {
    return 'Skin type updating';
  }
  return trimmed;
}
