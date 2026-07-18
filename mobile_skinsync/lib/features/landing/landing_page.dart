import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive/responsive.dart';
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
    final appState = context.watch<AppState>();
    final nextRoute = !appState.isAuthenticated
        ? AppRoutes.login
        : appState.shouldShowOnboarding
        ? AppRoutes.onboardingIntro
        : AppRoutes.dashboard;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        topPadding: 28,
        bottomPadding: 32,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _TopBrand(),
            const SizedBox(height: 28),
            Text(
              'Skincare guidance grounded in your real routine and real skin data.',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in, complete onboarding, upload a clear photo, and let SkinSync build analysis, routine, diary, and progress around your actual account.',
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
                    colors: [Color(0xFFF9F3EC), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceStrong,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: AspectRatio(
                          aspectRatio: Responsive.isTablet(context)
                              ? 1.9
                              : 1.35,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned(
                                top: 28,
                                right: 24,
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 24,
                                bottom: 24,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Live data only',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: AppColors.primaryDark,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'No fake scores.\nNo sample routine.\nJust your own journey.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.heading,
                                            fontWeight: FontWeight.w800,
                                            height: 1.05,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'SkinSync starts showing analysis, routine, and progress after you actually sign in and add data.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.mutedText,
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
                            label: 'Daily Check-up',
                            icon: Icons.favorite_border_rounded,
                          ),
                          SkinChip(
                            label: 'Progress Tracking',
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
