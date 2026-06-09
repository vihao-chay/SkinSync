import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/skin_chip.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = MockSkinData.user.name.split(' ').first;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning, $firstName 👋',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'How is your skin today?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedText,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const _TopIcon(icon: Icons.notifications_none_rounded),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.softPink,
                    child: Icon(Icons.person_rounded, color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Skin Score', style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(height: 8),
                                Text(
                                  '${MockSkinData.analysis.score}',
                                  style: Theme.of(context).textTheme.displayLarge,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              MockSkinData.analysis.skinType,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primaryDark,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Main concerns',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MockSkinData.user.concerns
                            .map((concern) => SkinChip(label: concern))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 160,
                        child: GradientPillButton(
                          label: 'View Analysis',
                          expanded: true,
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.analysis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionTitle(
                title: 'Quick Actions',
                subtitle: 'Shortcuts for the tasks you use most.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _QuickActionCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'Analyze Skin',
                      route: AppRoutes.quiz,
                    ),
                    SizedBox(width: 12),
                    _QuickActionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Add Log',
                      route: AppRoutes.progress,
                    ),
                    SizedBox(width: 12),
                    _QuickActionCard(
                      icon: Icons.spa_rounded,
                      title: 'View Routine',
                      route: AppRoutes.routine,
                    ),
                    SizedBox(width: 12),
                    _QuickActionCard(
                      icon: Icons.search_rounded,
                      title: 'Check Product',
                      route: AppRoutes.routine,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              _SectionTitle(
                title: 'Today Routine',
                subtitle: 'Stay consistent with your morning and evening plan.',
              ),
              const SizedBox(height: 12),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RoutineProgressRow(label: 'Morning', completed: 3, total: 4),
                    const SizedBox(height: 12),
                    const _RoutineProgressRow(label: 'Evening', completed: 1, total: 3),
                    const SizedBox(height: 16),
                    GradientPillButton(
                      label: 'Continue Routine',
                      expanded: true,
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.routine,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              PremiumCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Daily Tip', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Keep tonight gentle and focus on hydration before introducing stronger actives.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: AppColors.primaryDark),
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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => Navigator.pushNamed(context, route),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: SizedBox(
        width: 126,
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

class _RoutineProgressRow extends StatelessWidget {
  const _RoutineProgressRow({
    required this.label,
    required this.completed,
    required this.total,
  });

  final String label;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = completed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('$completed/$total', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.secondary,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
