import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'AI Hub',
      subtitle: 'Open SkinSync AI tools from one place.',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Responsive.responsiveHorizontalPadding(context),
          0,
          Responsive.responsiveHorizontalPadding(context),
          Responsive.contentBottomSpacing(context, extra: 20),
        ),
        children: [
          _AiHubTile(
            title: 'Product Recommendations',
            subtitle: 'Review or generate saved recommendation sessions.',
            route: AppRoutes.aiProductRecommend,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AiHubTile(
            title: 'Ingredient Check',
            subtitle: 'Check whether a product ingredient list suits your skin.',
            route: AppRoutes.aiIngredientCheck,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AiHubTile(
            title: 'AI Reports',
            subtitle: 'Open your generated AI summaries and reports.',
            route: AppRoutes.aiReports,
          ),
        ],
      ),
    );
  }
}

class _AiHubTile extends StatelessWidget {
  const _AiHubTile({
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
