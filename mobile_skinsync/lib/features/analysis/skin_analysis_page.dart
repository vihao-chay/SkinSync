import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
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
    final result = MockSkinData.analysis;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Skin Analysis', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Your latest AI-powered skin summary.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _HeaderCircleButton(icon: Icons.ios_share_rounded, onTap: () {}),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            result.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(color: AppColors.secondary),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${result.score}', style: Theme.of(context).textTheme.headlineMedium),
                                Text('Skin Score', style: Theme.of(context).textTheme.labelMedium),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.skinType, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence ${result.confidence}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.concerns.map((concern) => SkinChip(label: concern)).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: result.metrics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final item = result.metrics[index];
                    return MetricTile(
                      icon: [
                        Icons.water_drop_rounded,
                        Icons.tune_rounded,
                        Icons.blur_on_rounded,
                        Icons.grain_rounded,
                      ][index],
                      label: item.label,
                      value: '${item.value}%',
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommendations', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...const [
                        'Keep your routine gentle and barrier-friendly.',
                        'Prioritize hydration before stronger actives.',
                        'Introduce exfoliants slowly if irritation appears.',
                        'Track weekly changes with short daily logs.',
                      ].map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Icon(Icons.circle, size: 6, color: AppColors.primaryDark),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6DE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${result.recommendation} This AI report is informational only and not a medical diagnosis.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientPillButton(
                  label: 'Build My Routine',
                  expanded: true,
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.routine),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
                  child: const Text('Retake Quiz'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
    );
  }
}
