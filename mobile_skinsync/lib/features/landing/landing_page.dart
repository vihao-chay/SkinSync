import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_badge.dart';
import '../../core/widgets/skin_chip.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = Responsive.isDesktop(context);
    final mobile = Responsive.isMobile(context);
    return Scaffold(
      appBar: const GlassHeader(currentRoute: AppRoutes.landing),
      body: ListView(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.pageBackground, AppColors.cream, AppColors.pageBackground],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ResponsiveContainer(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: mobile ? 18 : 40),
                child: desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(child: _HeroCopy()),
                          SizedBox(width: 32),
                          Expanded(child: _HeroVisual()),
                        ],
                      )
                    : mobile
                        ? const _MobileHero()
                        : const Column(
                            children: [
                              _HeroCopy(),
                              SizedBox(height: 24),
                              _HeroVisual(),
                            ],
                          ),
              ),
            ),
          ),
          ResponsiveContainer(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: mobile ? 18 : 24),
              child: mobile
                  ? SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: MockSkinData.landingStats.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = MockSkinData.landingStats[index];
                          return SizedBox(
                            width: 170,
                            child: MetricTile(
                              icon: [
                                Icons.people_alt_outlined,
                                Icons.analytics_outlined,
                                Icons.auto_awesome_motion_outlined,
                                Icons.favorite_border_rounded,
                              ][index],
                              label: item.label,
                              value: item.value,
                              trend: item.trend,
                            ),
                          );
                        },
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.gridColumns(context, desktop: 4, tablet: 2, mobile: 2),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: MockSkinData.landingStats.length,
                      itemBuilder: (context, index) {
                        final item = MockSkinData.landingStats[index];
                        return MetricTile(
                          icon: [
                            Icons.people_alt_outlined,
                            Icons.analytics_outlined,
                            Icons.auto_awesome_motion_outlined,
                            Icons.favorite_border_rounded,
                          ][index],
                          label: item.label,
                          value: item.value,
                          trend: item.trend,
                        );
                      },
                    ),
            ),
          ),
          ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionBadge(label: 'Signature Features', icon: Icons.auto_awesome_rounded),
                  const SizedBox(height: 14),
                  Text('Premium skincare, translated into product flow.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'The mobile experience keeps the cream-and-gold visual language from the web app while adapting layouts for touch and smaller screens.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (mobile)
                    const Column(
                      children: [
                        _FeatureCard(
                          icon: Icons.psychology_alt_outlined,
                          title: 'AI Skin Analysis',
                          description: 'Computer vision insights with premium reporting surfaces.',
                        ),
                        SizedBox(height: 14),
                        _FeatureCard(
                          icon: Icons.spa_outlined,
                          title: 'Personalized Routine',
                          description: 'Morning and evening rituals built around skin profile and concerns.',
                        ),
                        SizedBox(height: 14),
                        _FeatureCard(
                          icon: Icons.insights_outlined,
                          title: 'Progress Tracking',
                          description: 'Logs, completion history, and routine consistency over time.',
                        ),
                        SizedBox(height: 14),
                        _FeatureCard(
                          icon: Icons.shield_outlined,
                          title: 'Ingredient Warnings',
                          description: 'Conflict messaging and softer fallback guidance before API wiring.',
                        ),
                      ],
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: Responsive.gridColumns(context, desktop: 4, tablet: 2, mobile: 1),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.05,
                      children: const [
                        _FeatureCard(
                          icon: Icons.psychology_alt_outlined,
                          title: 'AI Skin Analysis',
                          description: 'Computer vision insights with premium reporting surfaces.',
                        ),
                        _FeatureCard(
                          icon: Icons.spa_outlined,
                          title: 'Personalized Routine',
                          description: 'Morning and evening rituals built around skin profile and concerns.',
                        ),
                        _FeatureCard(
                          icon: Icons.insights_outlined,
                          title: 'Progress Tracking',
                          description: 'Logs, completion history, and routine consistency over time.',
                        ),
                        _FeatureCard(
                          icon: Icons.shield_outlined,
                          title: 'Ingredient Warnings',
                          description: 'Conflict messaging and softer fallback guidance before API wiring.',
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: const [
                  SkinChip(label: 'Oily', icon: Icons.water_drop_outlined),
                  SkinChip(label: 'Dry', icon: Icons.opacity_outlined),
                  SkinChip(label: 'Combination', icon: Icons.blur_circular_outlined),
                  SkinChip(label: 'Sensitive', icon: Icons.favorite_outline_rounded),
                ],
              ),
            ),
          ),
          Container(
            color: AppColors.darkPanel,
            child: ResponsiveContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 42),
                child: Column(
                  children: [
                    Text(
                      'Ready to turn your skin data into a daily ritual?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontSize: mobile ? 28 : 40,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start with the quiz, upload a clear photo, and let SkinSync build your first premium routine.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.accent),
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: GradientPillButton(
                        label: 'Start Skin Quiz',
                        expanded: true,
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionBadge(label: 'AI-Powered Skincare', icon: Icons.auto_awesome_rounded),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Luxury-feel skincare guidance, now built for Flutter.',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: Responsive.isMobile(context) ? 44 : 56,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Quiz your skin profile, upload your photo, review AI insights, and follow a personalized routine in one responsive experience.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            GradientPillButton(
              label: 'Start Skin Quiz',
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.quiz),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.analysis),
              child: const Text('View Demo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroCopy(),
        const SizedBox(height: 18),
        PremiumCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: AspectRatio(
                  aspectRatio: 0.95,
                  child: Image.network(
                    MockSkinData.analysis.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AppColors.secondary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _FloatingInsight(title: 'Skin Score', value: '87/100')),
                  SizedBox(width: 10),
                  Expanded(child: _FloatingInsight(title: 'AI Analysis', value: 'Ready in 30s')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PremiumCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 520,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    MockSkinData.analysis.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: AppColors.secondary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.05),
                          AppColors.primaryDark.withValues(alpha: 0.34),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 18,
          top: 24,
          child: _FloatingInsight(title: 'Skin Score', value: '87/100'),
        ),
        const Positioned(
          right: 18,
          bottom: 26,
          child: _FloatingInsight(title: 'Routine Ready', value: 'Morning + Night'),
        ),
      ],
    );
  }
}

class _FloatingInsight extends StatelessWidget {
  const _FloatingInsight({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary,
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          SizedBox(height: mobile ? 14 : 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
