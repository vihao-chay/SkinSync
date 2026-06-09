import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/skin_chip.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final names = appState.user?.fullName.split(' ') ?? const <String>[];
    final firstName = names.isEmpty ? 'there' : names.first;
    final analysis = appState.latestAnalysis;
    final tracking = appState.trackingToday;
    final concerns = appState.profile?.concerns ?? const <String>[];

    return RefreshIndicator(
      onRefresh: appState.refreshHome,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Good morning, $firstName', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  analysis?.overview ?? 'Your personalized skincare dashboard updates after each AI scan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Skin Score', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Text('${analysis?.overallScore ?? 0}', style: Theme.of(context).textTheme.displayLarge),
                      const SizedBox(height: 8),
                      Text(analysis?.skinType ?? 'No analysis yet'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: concerns.map((concern) => SkinChip(label: concern)).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Analyze Skin',
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.quiz),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: 'View Routine',
                        icon: Icons.spa_rounded,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        title: 'Daily Log',
                        icon: Icons.edit_note_rounded,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.progress),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        title: 'Profile',
                        icon: Icons.person_rounded,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Today Routine', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        '${tracking?.completedSteps ?? 0} of ${tracking?.totalSteps ?? 0} steps completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: tracking == null || tracking.totalSteps == 0
                              ? 0
                              : tracking.completedSteps / tracking.totalSteps,
                          minHeight: 10,
                          backgroundColor: AppColors.secondary,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GradientPillButton(
                        label: 'Continue Routine',
                        expanded: true,
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.routine),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily Tip', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(appState.progress?.dailyTip ?? 'Complete a scan to receive your personalized daily tip.'),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.secondary,
              child: Icon(icon, color: AppColors.primaryDark),
            ),
            const Spacer(),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
