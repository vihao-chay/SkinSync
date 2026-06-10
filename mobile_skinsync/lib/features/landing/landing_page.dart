import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/responsive_container.dart';
import '../../core/widgets/skin_chip.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nextRoute = context.watch<AppState>().isAuthenticated
        ? AppRoutes.dashboard
        : AppRoutes.login;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            28,
            AppSpacing.pagePadding,
            32,
          ),
          children: [
            const _TopBrand(),
            const SizedBox(height: 28),
            Text(
              'Skincare guidance that feels native to SkinSync.',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Create an account or sign in first, then complete the skin quiz, upload a clear selfie, review AI insights, and follow a routine built for daily use.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF4F1FF), Colors.white],
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
                                errorBuilder: (_, _, _) =>
                                    Container(color: AppColors.secondary),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryDark.withValues(
                                        alpha: 0.02,
                                      ),
                                      AppColors.primaryDark.withValues(
                                        alpha: 0.28,
                                      ),
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
                          SkinChip(
                            label: 'AI Analysis',
                            icon: Icons.auto_awesome_rounded,
                          ),
                          SkinChip(
                            label: 'Routine Builder',
                            icon: Icons.spa_outlined,
                          ),
                          SkinChip(
                            label: 'Daily Progress',
                            icon: Icons.insights_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            GradientPillButton(
              label: 'Start SkinSync',
              expanded: true,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => Navigator.pushNamed(context, nextRoute),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, nextRoute),
                child: const Text('Sign in to continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBrand extends StatelessWidget {
  const _TopBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _MiniBadge(label: 'SKINSYNC AI'),
        const BrandLogo(size: 38, radius: 14),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppColors.primaryDark,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.title, required this.value});

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
