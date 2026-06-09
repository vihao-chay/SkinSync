import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/section_badge.dart';
import '../../core/widgets/user_shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserShell(
      currentRoute: AppRoutes.dashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionBadge(label: 'Daily Overview', icon: Icons.sunny),
          const SizedBox(height: 14),
          Text(
            'Good morning, ${MockSkinData.user.name.split(' ').first}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('Here is your skin journey today.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Responsive.gridColumns(context, desktop: 4, tablet: 2, mobile: 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: Responsive.isMobile(context) ? 2.4 : 1.2,
            children: const [
              MetricTile(icon: Icons.auto_awesome_rounded, label: 'Skin Score', value: '82', trend: '+4 this week'),
              MetricTile(icon: Icons.check_circle_outline_rounded, label: 'Routine Completion', value: '86%', trend: '5 of 7 days'),
              MetricTile(icon: Icons.local_fire_department_outlined, label: 'Streak', value: '12 days', trend: 'Strong consistency'),
              MetricTile(icon: Icons.notifications_active_outlined, label: 'Next Reminder', value: '07:00 AM', trend: 'Morning routine'),
            ],
          ),
          const SizedBox(height: 20),
          Responsive.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 2, child: _DashboardPrimaryColumn()),
                    SizedBox(width: 16),
                    Expanded(child: _DashboardSecondaryColumn()),
                  ],
                )
              : const Column(
                  children: [
                    _DashboardPrimaryColumn(),
                    SizedBox(height: 16),
                    _DashboardSecondaryColumn(),
                  ],
                ),
        ],
      ),
    );
  }
}

class _DashboardPrimaryColumn extends StatelessWidget {
  const _DashboardPrimaryColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Skin Status', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text('Skin type: ${MockSkinData.user.skinType}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text('Main concerns: ${MockSkinData.user.concerns.join(', ')}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text('Current goal: ${MockSkinData.user.goal}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today\'s Suggestions', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const _Bullet(text: 'Keep the morning routine simple and barrier-friendly.'),
              const _Bullet(text: 'Prioritize hydration before introducing stronger actives tonight.'),
              const _Bullet(text: 'Reapply sunscreen if you are outdoors for more than 2 hours.'),
              const SizedBox(height: 16),
              GradientPillButton(
                label: 'Open Analysis',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.analysis),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSecondaryColumn extends StatelessWidget {
  const _DashboardSecondaryColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Skin Profile', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(MockSkinData.user.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(MockSkinData.user.goal, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Routine', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...MockSkinData.morningRoutine.take(3).map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('- ${step.productName}', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- '),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
