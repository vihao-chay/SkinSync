import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_badge.dart';
import '../../core/widgets/skin_chip.dart';

class SkinAnalysisPage extends StatelessWidget {
  const SkinAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final result = MockSkinData.analysis;
    return Scaffold(
      appBar: const GlassHeader(currentRoute: AppRoutes.analysis),
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionBadge(label: 'AI Analysis', icon: Icons.auto_awesome_rounded),
                const SizedBox(height: 16),
                Text('Your AI skin report', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'This mock UI is ready for API integration later. The layout already matches the premium web direction for mobile, tablet, and desktop.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Responsive.isDesktop(context)
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _AnalysisImage(result: result)),
                          const SizedBox(width: 24),
                          Expanded(child: _AnalysisPanel(result: result)),
                        ],
                      )
                    : Column(
                        children: [
                          _AnalysisImage(result: result),
                          const SizedBox(height: 20),
                          _AnalysisPanel(result: result),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisImage extends StatelessWidget {
  const _AnalysisImage({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 520,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                result.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: Colors.black12),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.02), Colors.black.withValues(alpha: 0.48)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              child: PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skin Score'),
                    Text('${result.score}', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
            ),
            const Positioned(
              right: 20,
              bottom: 20,
              child: Icon(Icons.document_scanner_outlined, color: Colors.white, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.skinType, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Confidence ${result.confidence}%', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: result.concerns.map((item) => SkinChip(label: item)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Responsive.gridColumns(context, desktop: 2, tablet: 2, mobile: 2),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemCount: result.metrics.length,
          itemBuilder: (context, index) {
            final item = result.metrics[index];
            return MetricTile(
              icon: [
                Icons.water_drop_outlined,
                Icons.wb_sunny_outlined,
                Icons.texture_outlined,
                Icons.blur_on_outlined,
              ][index],
              label: item.label,
              value: '${item.value}%',
            );
          },
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommendation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(result.recommendation, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
              Text(
                'This analysis is AI-generated and not a medical diagnosis.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GradientPillButton(
                label: 'Build My Routine',
                expanded: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.routine),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
                child: const Text('Retake Quiz'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
