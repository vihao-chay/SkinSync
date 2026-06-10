import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiHubPage extends StatelessWidget {
  const AiHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final hasAnalysis = appState.latestAnalysis != null;
    final hasRoutine = appState.regimen != null;

    final options = [
      _HubOption(
        title: 'SkinSync AI',
        subtitle: 'Open saved sessions or start a new skincare conversation.',
        icon: Icons.chat_bubble_outline_rounded,
        status: 'Ready',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
      ),
      _HubOption(
        title: 'Skin Analysis',
        subtitle: hasAnalysis
            ? 'Review your latest scan result and recommendations.'
            : 'Upload a clear selfie to generate your first analysis.',
        icon: Icons.auto_awesome_rounded,
        status: hasAnalysis ? 'Latest scan available' : 'Scan required',
        onTap: () => Navigator.pushNamed(
          context,
          hasAnalysis ? AppRoutes.analysis : AppRoutes.upload,
        ),
      ),
      _HubOption(
        title: 'Generate Routine',
        subtitle: hasAnalysis
            ? 'Build or refresh a morning and evening routine from AI.'
            : 'Complete a scan first so routine generation has real data.',
        icon: Icons.spa_outlined,
        status: hasAnalysis ? 'Can generate now' : 'Needs analysis',
        onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
      ),
      _HubOption(
        title: 'Product Recommendation',
        subtitle:
            'Match products from your backend catalog by concern and budget.',
        icon: Icons.shopping_bag_outlined,
        status: 'Catalog search',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiProductRecommend),
      ),
      _HubOption(
        title: 'Ingredient Check',
        subtitle:
            'Paste ingredient lists and see beneficial, caution, and warning notes.',
        icon: Icons.biotech_outlined,
        status: 'Text input',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiIngredientCheck),
      ),
      _HubOption(
        title: 'Conflict Check',
        subtitle: hasRoutine
            ? 'Check your active routine for risky ingredient combinations.'
            : 'Generate a routine first, then scan it for conflicts.',
        icon: Icons.warning_amber_rounded,
        status: hasRoutine ? 'Routine ready' : 'Needs routine',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiConflictCheck),
      ),
      _HubOption(
        title: 'AI Reports',
        subtitle: 'Generate weekly, monthly, or post-analysis summary reports.',
        icon: Icons.insert_chart_outlined_rounded,
        status: 'History + generation',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiReports),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: AppRoutes.aiHub,
        title: 'AI Tools',
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: appState.refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeroCard(hasAnalysis: hasAnalysis, hasRoutine: hasRoutine),
              const SizedBox(height: 18),
              Text(
                'All AI Tools',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose one tool below. Each option opens a dedicated screen instead of leaving you on an empty placeholder.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HubListTile(option: option),
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7E0C8), Color(0xFFF2C29C), Color(0xFFE89A76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One place for every AI feature',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF45251C),
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Current status: ${hasAnalysis ? 'analysis ready' : 'no analysis yet'} - ${hasRoutine ? 'routine ready' : 'no routine yet'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF603127),
              height: 1.35,
            ),
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(option.icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            option.status,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(top: 12),
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
