import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../models/app_models.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class FloatingAiButton extends StatelessWidget {
  const FloatingAiButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.elevated,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'skinsync-ai-shell',
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.aiChatConversation,
            arguments: const AiChatLaunchArgs(entryPoint: 'shell_fab'),
          ),
          backgroundColor: AppColors.ai,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(AppLocale.of(context).tr('floating_ai_ask')),
        ),
      ),
    );
  }
}
