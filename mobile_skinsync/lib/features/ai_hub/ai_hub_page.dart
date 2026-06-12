import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasAnalysis = appState.latestAnalysis != null;
    final hasRoutine = appState.regimen != null;

    final options = [
      _HubOption(
        title: 'AI chat',
        subtitle: 'Open a quick SkinSync AI conversation for daily skincare guidance.',
        icon: Icons.chat_bubble_outline_rounded,
        status: 'Quick help',
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.aiChatConversation,
          arguments: const AiChatLaunchArgs(entryPoint: 'ai_hub'),
        ),
      ),
      _HubOption(
        title: 'Skin analysis',
        subtitle: hasAnalysis
            ? 'Review your latest scan result and personalized recommendations.'
            : 'Upload a clear skin photo to generate your first AI analysis.',
        icon: Icons.auto_awesome_rounded,
        status: hasAnalysis ? 'Latest scan ready' : 'Photo needed',
        onTap: () => Navigator.pushNamed(
          context,
          hasAnalysis ? AppRoutes.analysis : AppRoutes.upload,
        ),
      ),
      _HubOption(
        title: 'Ingredient check',
        subtitle: 'Paste ingredient lists and let SkinSync explain benefits, cautions, and warnings.',
        icon: Icons.biotech_outlined,
        status: 'Text input',
        onTap: () =>
            Navigator.pushNamed(context, AppRoutes.aiIngredientCheck),
      ),
      _HubOption(
        title: 'Conflict check',
        subtitle: hasRoutine
            ? 'Scan your current routine for risky combinations before irritation starts.'
            : 'Generate or save a routine first, then run a conflict check.',
        icon: Icons.warning_amber_rounded,
        status: hasRoutine ? 'Routine ready' : 'Needs routine',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiConflictCheck),
      ),
      _HubOption(
        title: 'Routine generator',
        subtitle: 'Create or refresh an AI routine matched to your skin profile and budget.',
        icon: Icons.spa_outlined,
        status: 'Routine builder',
        onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
      ),
      _HubOption(
        title: 'Progress report',
        subtitle: 'Generate weekly or monthly AI summaries based on your skincare progress.',
        icon: Icons.insert_chart_outlined_rounded,
        status: 'Reports',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiReports),
      ),
      _HubOption(
        title: 'Today diary',
        subtitle: 'Log how your skin feels today and feed that signal back into progress tracking.',
        icon: Icons.edit_note_rounded,
        status: 'Daily check-in',
        onTap: () => Navigator.pushNamed(context, AppRoutes.todayCheckup),
      ),
      _HubOption(
        title: 'Product recommendations',
        subtitle: 'Match products from the catalog by concern, category, and budget.',
        icon: Icons.shopping_bag_outlined,
        status: 'Catalog AI',
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.aiProductRecommend,
        ),
      ),
    ];

    return AppScaffold(
      title: 'AI Hub',
      subtitle:
          'Every SkinSync AI tool in one premium workspace, from chat and scans to routine generation and progress insights.',
      onRefresh: appState.refreshHome,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.bottomNavHeight + 64,
        ),
        children: [
          _HeroCard(hasAnalysis: hasAnalysis, hasRoutine: hasRoutine),
          const SizedBox(height: AppSpacing.sectionGap),
          const SectionHeader(
            title: 'AI toolkit',
            subtitle: 'Pick the right tool for the task you want to complete today.',
          ),
          const SizedBox(height: AppSpacing.md),
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _HubListTile(option: option),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hasAnalysis, required this.hasRoutine});

  final bool hasAnalysis;
  final bool hasRoutine;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI skincare command center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.heading,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasAnalysis
                ? 'Your latest analysis is ready, so you can move straight into recommendations, reports, and routine refinement.'
                : 'Start with a skin scan or chat, then let SkinSync connect every insight back to your routine and progress.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(
                label: hasAnalysis ? 'Analysis ready' : 'No scan yet',
              ),
              _StatusChip(
                label: hasRoutine ? 'Routine available' : 'No routine yet',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubListTile extends StatelessWidget {
  const _HubListTile({required this.option});

  final _HubOption option;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option.onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.32)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(option.icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatusChip(label: option.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      option.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HubOption {
  const _HubOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String status;
  final VoidCallback onTap;
}
