import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
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
            children: MockSkinData.adminMetrics
                .map(
                  (metric) => PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          metric.value,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity'),
                SizedBox(height: 12),
                Text('- 238 new analyses generated today'),
                SizedBox(height: 8),
                Text('- 16 products updated in premium catalog'),
                SizedBox(height: 8),
                Text('- 5 prompt config drafts awaiting review'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
