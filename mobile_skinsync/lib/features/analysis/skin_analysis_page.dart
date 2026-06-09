import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/skin_chip.dart';

class SkinAnalysisPage extends StatelessWidget {
  const SkinAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final result = appState.latestAnalysis;

    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No analysis yet', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Complete the skin quiz and upload a photo to generate your first AI report.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              GradientPillButton(
                label: 'Start Quiz',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Skin Analysis', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(result.overview ?? 'Your latest AI-powered skin summary.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${result.overallScore}', style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 4),
                      Text('${result.skinType} skin'),
                      const SizedBox(height: 6),
                      Text('Confidence ${result.confidenceScore}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.issues.map((issue) => SkinChip(label: issue.issueType)).toList(),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    MetricTile(icon: Icons.face_rounded, label: 'Score', value: '${result.overallScore}/100'),
                    MetricTile(icon: Icons.shield_outlined, label: 'Confidence', value: '${result.confidenceScore}%'),
                    MetricTile(icon: Icons.bubble_chart_outlined, label: 'Concerns', value: '${result.issues.length}'),
                    MetricTile(icon: Icons.recommend_outlined, label: 'Tips', value: '${result.recommendations.length}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommendations', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...result.recommendations.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('• ${tip.content}'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Warnings', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        ...result.warnings.map((warning) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• $warning'),
                            )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientPillButton(
                  label: 'Open Routine',
                  expanded: true,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.routine),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
                  child: const Text('Analyze Again'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
