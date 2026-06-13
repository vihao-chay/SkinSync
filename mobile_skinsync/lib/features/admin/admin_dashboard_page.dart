import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/section_badge.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.admin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionBadge(
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: 14),
          Text(
            'Admin Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'This dashboard no longer shows sample metrics. Connect live admin reporting endpoints before surfacing totals here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Responsive.gridColumns(
              context,
              desktop: 4,
              tablet: 2,
              mobile: 1,
            ),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: Responsive.isMobile(context) ? 2.2 : 1.25,
            children: const [
              _AdminPlaceholderCard(
                title: 'User metrics',
                body: 'No live admin metrics connected yet.',
              ),
              _AdminPlaceholderCard(
                title: 'Catalog metrics',
                body: 'Connect product reporting to show real counts.',
              ),
              _AdminPlaceholderCard(
                title: 'AI usage',
                body: 'Show real quota and request volume after wiring analytics.',
              ),
              _AdminPlaceholderCard(
                title: 'Operations',
                body: 'Recent admin activity will appear from real logs only.',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity'),
                SizedBox(height: 12),
                Text(
                  'No live admin activity feed is connected yet. This area should stay empty until real backend reporting is available.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPlaceholderCard extends StatelessWidget {
  const _AdminPlaceholderCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
