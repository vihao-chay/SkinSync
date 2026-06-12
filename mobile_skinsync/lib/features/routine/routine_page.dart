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
import '../../core/widgets/skin_sync_ai_button.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool _showMorning = true;
  bool _generating = false;
  bool _optimizing = false;

  Future<void> _generateRoutine(AppState appState) async {
    setState(() => _generating = true);
    try {
      await appState.generateRoutine(budgetMax: appState.profile?.monthlyBudget);
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _optimizeReminders(AppState appState) async {
    setState(() => _optimizing = true);
    try {
      final result = await appState.optimizeAiReminders();
      if (!mounted) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ReminderSuggestionSheet(result: result),
      );
    } finally {
      if (mounted) {
        setState(() => _optimizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    final steps = _showMorning
        ? regimen?.morning ?? const <RegimenStep>[]
        : regimen?.evening ?? const <RegimenStep>[];
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};

    return AppScaffold(
      title: 'My routine',
      subtitle:
          'A calm, premium checklist for your skincare day, with reminders and AI guidance built in.',
      onRefresh: appState.refreshHome,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          AppCard(
            backgroundColor: AppColors.surfaceStrong,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistency matters more than intensity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${tracking?.completedSteps ?? 0} of ${tracking?.totalSteps ?? 0} steps completed today.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Regenerate',
                        icon: const Icon(Icons.auto_awesome_outlined),
                        isLoading: _generating,
                        onPressed: () => _generateRoutine(appState),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Open Today Check-up',
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.todayCheckup),
                ),
                const SizedBox(height: AppSpacing.sm),
                SkinSyncAiButton(
                  mode: SkinSyncAiButtonMode.inline,
                  title: 'Optimize this routine with AI',
                  description:
                      'Ask SkinSync AI to review your current steps, cadence, and product fit before changing anything.',
                  label: 'Optimize with SkinSync AI',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.aiChatConversation,
                    arguments: AiChatLaunchArgs(
                      entryPoint: 'routine',
                      referenceId: regimen?.regimenId,
                      prefillMessage:
                          'Can you review my routine and tell me what to improve?',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Routine timeline',
            subtitle: 'Switch between morning and evening steps without losing context.',
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutineSegmentedControl(
            showMorning: _showMorning,
            onChanged: (value) => setState(() => _showMorning = value),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Reminders',
            subtitle: 'Manual reminders still work, and AI can fine-tune them for you.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ReminderCard(
            reminders: reminders,
            optimizing: _optimizing,
            onOptimize: () => _optimizeReminders(appState),
            onMorning: () => appState.saveReminder('Morning', '07:00', true),
            onEvening: () => appState.saveReminder('Evening', '21:00', true),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: _showMorning ? 'Morning steps' : 'Evening steps',
            subtitle: _showMorning
                ? 'Prep, treat, and protect before the day starts.'
                : 'Cleanse, recover, and support overnight repair.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (regimen == null || steps.isEmpty)
            EmptyStateCard(
              icon: Icons.spa_outlined,
              title: 'No routine steps yet',
              description:
                  'Complete a skin analysis first, then SkinSync can build a personalized routine for you.',
              ctaLabel: 'Start skin scan',
              onCta: () => Navigator.pushNamed(context, AppRoutes.upload),
            )
          else
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RoutineStepCard(
                  step: step,
                  completed: completedIds.contains(step.stepId),
                  onChanged: () => appState.toggleRoutineStep(
                    step.stepId,
                    completedIds.contains(step.stepId),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineSegmentedControl extends StatelessWidget {
  const _RoutineSegmentedControl({
    required this.showMorning,
    required this.onChanged,
  });

  final bool showMorning;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Morning',
              selected: showMorning,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _SegmentButton(
              label: 'Evening',
              selected: !showMorning,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppColors.primaryDark : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminders,
    required this.optimizing,
    required this.onOptimize,
    required this.onMorning,
    required this.onEvening,
  });

  final List<ReminderItem> reminders;
  final bool optimizing;
  final VoidCallback onOptimize;
  final VoidCallback onMorning;
  final VoidCallback onEvening;

  @override
  Widget build(BuildContext context) {
    final morning = _findReminder('morning');
    final evening = _findReminder('evening');

    return AppCard(
      child: Column(
        children: [
          _ReminderTile(
            title: 'Morning reminder',
            item: morning,
            fallback: 'Not provided yet',
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReminderTile(
            title: 'Evening reminder',
            item: evening,
            fallback: 'Not provided yet',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Set morning 07:00',
                  variant: AppButtonVariant.secondary,
                  onPressed: onMorning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'Set evening 21:00',
                  variant: AppButtonVariant.secondary,
                  onPressed: onEvening,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Optimize with SkinSync AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            variant: AppButtonVariant.ai,
            isLoading: optimizing,
            onPressed: onOptimize,
          ),
        ],
      ),
    );
  }

  ReminderItem? _findReminder(String type) {
    for (final item in reminders) {
      if (item.routineType.toLowerCase().contains(type)) {
        return item;
      }
    }
    return null;
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.title,
    required this.item,
    required this.fallback,
  });

  final String title;
  final ReminderItem? item;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item == null ? fallback : '${item!.time} • ${item!.priority}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item?.reason?.trim().isNotEmpty == true
                ? item!.reason!
                : 'SkinSync can adapt this reminder once it learns your routine pattern.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RoutineStepCard extends StatelessWidget {
  const _RoutineStepCard({
    required this.step,
    required this.completed,
    required this.onChanged,
  });

  final RegimenStep step;
  final bool completed;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: completed,
            activeColor: AppColors.primaryDark,
            side: const BorderSide(color: AppColors.border),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.stepOrder}. ${step.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _productLine(step),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoText(label: 'Category', value: _friendlyText(step.category)),
                _InfoText(label: 'Purpose', value: _friendlyText(step.purpose)),
                _InfoText(
                  label: 'How to use',
                  value: _friendlyText(step.instruction),
                ),
                if ((step.caution ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Caution: ${step.caution!}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _productLine(RegimenStep step) {
    final brand = step.brand.trim();
    final name = step.name.trim();
    final joined = [brand, name].where((item) => item.isNotEmpty).join(' • ');
    return joined.isEmpty ? 'Not provided yet' : joined;
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ReminderSuggestionSheet extends StatelessWidget {
  const _ReminderSuggestionSheet({required this.result});

  final AiReminderSuggestResponse result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SkinSync AI reminder plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.overallAdvice.isEmpty
                  ? 'SkinSync did not return a summary yet.'
                  : result.overallAdvice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...result.suggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  backgroundColor: AppColors.surfaceMuted,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.routineType} • ${item.time}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.reason.isEmpty ? 'Not provided yet' : item.reason,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}
