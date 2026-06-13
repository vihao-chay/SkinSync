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
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/linear_progress_stat.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/routine_checklist_item.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool _showMorning = true;
  bool _generating = false;
  bool _optimizing = false;
  String? _actionErrorMessage;

  Future<void> _generateRoutine(AppState appState) async {
    setState(() => _generating = true);
    try {
      await appState.generateRoutine(budgetMax: appState.profile?.monthlyBudget);
      if (mounted) {
        setState(() => _actionErrorMessage = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionErrorMessage =
              appState.errorMessage ?? 'Could not build your routine right now.';
        });
      }
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
      setState(() => _actionErrorMessage = null);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _ReminderSuggestionSheet(result: result),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionErrorMessage =
              appState.errorMessage ?? 'Could not optimize reminders right now.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _optimizing = false);
      }
    }
  }

  Future<void> _saveReminder(
    AppState appState,
    String routineType,
    String time,
  ) async {
    try {
      await appState.saveReminder(routineType, time, true);
      if (mounted) {
        setState(() => _actionErrorMessage = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionErrorMessage =
              appState.errorMessage ?? 'Could not save your reminder right now.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};
    final steps = _showMorning
        ? regimen?.morning ?? const <RegimenStep>[]
        : regimen?.evening ?? const <RegimenStep>[];
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

    return AppScaffold(
      title: 'My routine',
      subtitle: 'A calm, premium checklist for your skincare day, with reminders and AI guidance built in.',
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
          if (appState.routineDataErrorMessage != null ||
              _actionErrorMessage != null) ...[
            ErrorStateCard(
              title: 'Routine data needs attention',
              description:
                  _actionErrorMessage ?? appState.routineDataErrorMessage!,
              ctaLabel: 'Try again',
              onCta: appState.refreshHome,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusChip(
                  label: 'Consistency matters',
                  icon: Icons.spa_outlined,
                  tone: StatusChipTone.accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  regimen == null
                      ? 'Choose products first to build a calm routine that actually fits your shelf.'
                      : '$completedSteps of $totalSteps steps completed today.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressStat(
                  label: 'Today progress',
                  value: '$completedSteps/$totalSteps',
                  progress: progress,
                  caption: regimen == null
                      ? 'No active routine yet.'
                      : _showMorning
                          ? 'Morning steps are in focus.'
                          : 'Evening steps are in focus.',
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = [
                      AppButton(
                        label: regimen == null
                            ? 'Build from selected products'
                            : 'Refresh routine',
                        icon: const Icon(Icons.auto_awesome_outlined),
                        isLoading: _generating,
                        onPressed: () => _generateRoutine(appState),
                      ),
                      AppButton(
                        label: 'Open Today Check-up',
                        variant: AppButtonVariant.secondary,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.todayCheckup),
                      ),
                    ];
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [
                          actions[0],
                          const SizedBox(height: AppSpacing.sm),
                          actions[1],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: actions[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: actions[1]),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.wb_sunny_outlined,
            title: 'Routine Flow',
            subtitle: 'Switch between morning and evening without losing your progress context.',
          ),
          const SizedBox(height: AppSpacing.md),
          _RoutineSegmentedControl(
            showMorning: _showMorning,
            onChanged: (value) => setState(() => _showMorning = value),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (regimen == null || (regimen.morning.isEmpty && regimen.evening.isEmpty))
            EmptyStateCard(
              icon: Icons.checklist_rtl_outlined,
              title: 'Choose products first to build your routine',
              description: 'Routine steps only appear from your active regimen. Open Products and add items you want to use.',
              ctaLabel: 'Open Products',
              onCta: () => Navigator.pushNamed(context, AppRoutes.products),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  MetricCard(
                    label: 'Morning steps',
                    value: '${regimen.morning.length}',
                    icon: Icons.wb_sunny_outlined,
                  ),
                  MetricCard(
                    label: 'Evening steps',
                    value: '${regimen.evening.length}',
                    icon: Icons.nightlight_round,
                  ),
                  MetricCard(
                    label: 'Completed today',
                    value: '$completedSteps/$totalSteps',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ];
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: constraints.maxWidth < 360
                              ? constraints.maxWidth
                              : (constraints.maxWidth - AppSpacing.sm) / 2,
                          child: card,
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            SectionHeader(
              icon: _showMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              title: _showMorning ? 'Morning checklist' : 'Evening checklist',
              subtitle: _showMorning
                  ? 'Prep, treat, and protect before the day starts.'
                  : 'Cleanse, recover, and support overnight repair.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: RoutineChecklistItem(
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
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            variant: AppCardVariant.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Optimize this routine with AI',
                  subtitle: 'Review cadence, reminders, and fit before changing anything.',
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _ReminderTile(
                        title: 'Morning reminder',
                        item: _findReminder(reminders, 'morning'),
                        fallback: 'Not provided yet',
                      ),
                      _ReminderTile(
                        title: 'Evening reminder',
                        item: _findReminder(reminders, 'evening'),
                        fallback: 'Not provided yet',
                      ),
                    ];
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: card,
                              ),
                            )
                            .toList(),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Set 07:00',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _saveReminder(appState, 'Morning', '07:00'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Set 21:00',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _saveReminder(appState, 'Evening', '21:00'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Optimize reminders',
                  variant: AppButtonVariant.ai,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  isLoading: _optimizing,
                  onPressed: () => _optimizeReminders(appState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ReminderItem? _findReminder(List<ReminderItem> reminders, String type) {
    for (final item in reminders) {
      if (item.routineType.toLowerCase().contains(type)) {
        return item;
      }
    }
    return null;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
    final statusText = item == null
        ? fallback
        : '${item?.time ?? 'Not provided yet'} • ${item?.priority ?? 'normal'}';
    return AppCard(
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            statusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item?.reason?.trim().isNotEmpty == true
                ? item?.reason ?? fallback
                : 'SkinSync can adapt this reminder once it learns your routine pattern.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
                  variant: AppCardVariant.metric,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.routineType} • ${item.time}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.reason),
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
