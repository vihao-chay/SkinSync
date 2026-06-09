import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/glass_header.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/section_badge.dart';
import '../../core/widgets/skin_chip.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nextRoute = context.watch<AppState>().isAuthenticated ? AppRoutes.quiz : AppRoutes.login;

    return Scaffold(
      appBar: const GlassHeader(currentRoute: AppRoutes.landing),
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            32,
          ),
          children: [
            _HeroSection(nextRoute: nextRoute),
            const SizedBox(height: AppSpacing.sectionGap),
            const _StatsStrip(),
            const SizedBox(height: AppSpacing.sectionGap),
            const _FeatureSection(),
            const SizedBox(height: AppSpacing.sectionGap),
            const _JourneySection(),
            const SizedBox(height: AppSpacing.sectionGap),
            _BottomCta(nextRoute: nextRoute),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.nextRoute});

  final String nextRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionBadge(
          label: 'AI-Powered Skincare',
          icon: Icons.auto_awesome_rounded,
        ),
        const SizedBox(height: 16),
        Text(
          'Skincare guidance that feels native to the app.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Quiz your skin profile, upload a clear selfie, review AI insights, and follow a routine built for daily use.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
        const SizedBox(height: 20),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 1,
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
                                  AppColors.primaryDark.withValues(alpha: 0.02),
                                  AppColors.primaryDark.withValues(alpha: 0.28),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Row(
                              children: const [
                                Expanded(
                                  child: _HeroMetric(
                                    title: 'Skin Score',
                                    value: '87/100',
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: _HeroMetric(
                                    title: 'Routine',
                                    value: 'AM + PM',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      SkinChip(label: 'AI Analysis', icon: Icons.psychology_alt_outlined),
                      SkinChip(label: 'Routine Builder', icon: Icons.spa_outlined),
                      SkinChip(label: 'Daily Progress', icon: Icons.insights_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GradientPillButton(
          label: 'Start Skin Quiz',
          expanded: true,
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pushNamed(context, nextRoute),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, nextRoute),
            child: const Text('Sign In To Continue'),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final items = MockSkinData.landingStats.take(3).toList();

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return PremiumCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(item.label, style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  Text(
                    item.trend,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
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

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(
          title: 'What You Can Do',
          subtitle: 'Everything here is shaped for quick mobile use, not a desktop landing page.',
        ),
        SizedBox(height: 14),
        _FeatureCard(
          icon: Icons.auto_awesome_rounded,
          title: 'Analyze Your Skin',
          description: 'Upload a clear selfie and get a structured AI summary with score, concerns, and recommendations.',
        ),
        SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.spa_rounded,
          title: 'Build A Practical Routine',
          description: 'Turn skin type, concerns, and budget into a morning and evening skincare plan.',
        ),
        SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.edit_note_rounded,
          title: 'Track Daily Progress',
          description: 'Check off steps, save daily logs, and review streaks and skincare insights over time.',
        ),
      ],
    );
  }
}

class _JourneySection extends StatelessWidget {
  const _JourneySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionTitle(
          title: 'How It Flows',
          subtitle: 'The same flow used by the mobile app experience.',
        ),
        SizedBox(height: 14),
        _JourneyStep(
          step: '01',
          title: 'Create account or sign in',
          description: 'Start with your SkinSync account so your profile and routine stay synced.',
        ),
        SizedBox(height: 12),
        _JourneyStep(
          step: '02',
          title: 'Complete the skin quiz',
          description: 'Choose skin type, concerns, and budget before analysis.',
        ),
        SizedBox(height: 12),
        _JourneyStep(
          step: '03',
          title: 'Upload a clear skin photo',
          description: 'The AI scan uses your selfie and quiz profile together.',
        ),
        SizedBox(height: 12),
        _JourneyStep(
          step: '04',
          title: 'Follow the generated routine',
          description: 'Move into dashboard, routine tracking, and progress review.',
        ),
      ],
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.nextRoute});

  final String nextRoute;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to turn your skin data into a daily ritual?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Start with the quiz, upload a clear photo, and let SkinSync create your first usable routine.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                ),
          ),
          const SizedBox(height: 16),
          GradientPillButton(
            label: 'Begin Now',
            expanded: true,
            onPressed: () => Navigator.pushNamed(context, nextRoute),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
        ),
      ],
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
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondary,
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
