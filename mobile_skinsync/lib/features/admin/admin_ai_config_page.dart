import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/widgets/admin_shell.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';

class AdminAiConfigPage extends StatelessWidget {
  const AdminAiConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: AppRoutes.adminAiConfig,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin AI Config',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(label: 'Model', hint: 'gpt-4o / vision pipeline'),
                SizedBox(height: 12),
                AppTextField(label: 'Temperature', hint: '0.2'),
                SizedBox(height: 12),
                AppTextField(label: 'Max tokens', hint: '1200'),
                SizedBox(height: 12),
                AppTextField(
                  label: 'Prompt settings',
                  hint: 'Premium skincare analysis prompt',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientPillButton(label: 'Save Config', onPressed: null),
        ],
      ),
    );
  }
}
