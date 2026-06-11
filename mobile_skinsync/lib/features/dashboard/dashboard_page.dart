import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final analysis = appState.latestAnalysis;
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final concerns = analysis?.issues.map((item) => item.issueType).toList() ?? [];
    final firstName = _firstName(appState.profileDisplayName);

    return AppScaffold(
      title: 'Good evening, $firstName',
      subtitle:
          'Your premium skincare dashboard keeps today\'s routine, scan insights, and gentle next steps in one calm place.',
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
          _HeroCard(
            analysis: analysis,
            completedSteps: tracking?.completedSteps ?? 0,
            totalSteps: tracking?.totalSteps ?? 0,
            onCheckIn: () => Navigator.pushNamed(context, AppRoutes.todayCheckup),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Today at a glance',
            subtitle: 'The most important signals from your latest scan and routine.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _InsightCard(
                  eyebrow: 'Skin score',
                  value: analysis == null ? 'Not scanned yet' : '${analysis.overallScore}/100',
                  description: analysis == null
                      ? 'Upload a photo to unlock your first AI analysis.'
                      : (analysis.overview?.trim().isNotEmpty == true
                            ? analysis.overview!
                            : 'Your current skin condition looks balanced overall.'),
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _InsightCard(
                  eyebrow: 'Skin type',
                  value: _friendlyText(analysis?.skinType),
                  description: concerns.isEmpty
                      ? 'No major concerns highlighted yet.'
                      : 'Top focus: ${concerns.take(2).join(', ')}',
                  icon: Icons.spa_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Routine rhythm',
            subtitle: 'Keep your morning and evening rituals consistent.',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.routine),
              child: const Text('Open routine'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (regimen == null)
            EmptyStateCard(
              icon: Icons.spa_outlined,
              title: 'No routine generated yet',
              description:
                  'Complete a skin scan and SkinSync will prepare a routine tailored to your skin goals.',
              ctaLabel: 'Start skin scan',
              onCta: () => Navigator.pushNamed(context, AppRoutes.upload),
            )
          else
            Column(
              children: [
                _RoutinePreviewCard(
                  title: 'Morning routine',
                  accent: const Color(0xFFE9D5BC),
                  steps: regimen.morning,
                  completed: tracking?.morningCompleted ?? false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _RoutinePreviewCard(
                  title: 'Evening routine',
                  accent: const Color(0xFFDCC5B4),
                  steps: regimen.evening,
                  completed: tracking?.eveningCompleted ?? false,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Quick actions',
            subtitle: 'Jump straight into the next best skincare task.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickActionChip(
                label: 'Today check-in',
                icon: Icons.check_circle_outline_rounded,
                onTap: () => Navigator.pushNamed(context, AppRoutes.todayCheckup),
              ),
              _QuickActionChip(
                label: 'Scan skin',
                icon: Icons.camera_alt_outlined,
                onTap: () => Navigator.pushNamed(context, AppRoutes.upload),
              ),
              _QuickActionChip(
                label: 'Ask SkinSync AI',
                icon: Icons.auto_awesome_rounded,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.aiChatConversation,
                  arguments: const AiChatLaunchArgs(entryPoint: 'home'),
                ),
              ),
              _QuickActionChip(
                label: 'Explore products',
                icon: Icons.shopping_bag_outlined,
                onTap: () => Navigator.pushNamed(context, AppRoutes.products),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'there';
    }
    return parts.first;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.analysis,
    required this.completedSteps,
    required this.totalSteps,
    required this.onCheckIn,
  });

  final AnalysisResult? analysis;
  final int completedSteps;
  final int totalSteps;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    return AppCard(
      backgroundColor: AppColors.surfaceStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s complexion story',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            analysis?.overview?.trim().isNotEmpty == true
                ? analysis!.overview!
                : 'Start with a quick check-in or fresh scan to build a more complete picture of your skin today.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Confidence',
                  value: analysis == null ? 'Not provided yet' : '${analysis!.confidenceScore}%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Routine progress',
                  value: totalSteps == 0 ? 'Not provided yet' : '$completedSteps/$totalSteps',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.65),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Check in now',
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: onCheckIn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.eyebrow,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String eyebrow;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RoutinePreviewCard extends StatelessWidget {
  const _RoutinePreviewCard({
    required this.title,
    required this.accent,
    required this.steps,
    required this.completed,
  });

  final String title;
  final Color accent;
  final List<RegimenStep> steps;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  title.contains('Morning')
                      ? Icons.wb_sunny_outlined
                      : Icons.bedtime_outlined,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: completed ? AppColors.secondary : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  completed ? 'Completed' : 'Pending',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            steps.isEmpty
                ? 'Not provided yet'
                : steps
                    .take(4)
                    .map((step) => '${step.stepOrder}. ${step.name}')
                    .join('\n'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}
