import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/brand_logo.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool morning = true;
  bool _generating = false;
  bool _optimizingReminders = false;

  Future<void> _generateRoutine(AppState appState) async {
    setState(() => _generating = true);
    try {
      await appState.generateRoutine(
        budgetMax: appState.profile?.monthlyBudget,
      );
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  Future<void> _optimizeReminders(AppState appState) async {
    setState(() => _optimizingReminders = true);
    try {
      final result = await appState.optimizeAiReminders();
      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _ReminderSuggestionSheet(result: result),
      );
    } finally {
      if (mounted) {
        setState(() => _optimizingReminders = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    final steps = morning
        ? regimen?.morning ?? const <RegimenStep>[]
        : regimen?.evening ?? const <RegimenStep>[];
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: appState.refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          6,
          AppSpacing.pagePadding,
          106,
        ),
        children: [
          const _MiniTopBar(),
          const SizedBox(height: 20),
          Text(
            'My Routine',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${tracking?.completedSteps ?? 0} of ${tracking?.totalSteps ?? 0} steps completed today',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.foreground),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _generating
                    ? null
                    : () => _generateRoutine(appState),
                child: Text(
                  _generating ? 'Generating...' : 'Regenerate Routine',
                ),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.aiConflictCheck),
                child: const Text('Check Conflicts'),
              ),
              OutlinedButton(
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
                child: const Text('Ask SkinSync AI'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SegmentedControl(
            morning: morning,
            onChanged: (value) => setState(() => morning = value),
          ),
          const SizedBox(height: 16),
          _RemindersCard(
            reminders: reminders,
            onMorning: () => appState.saveReminder('Morning', '07:00', true),
            onEvening: () => appState.saveReminder('Evening', '21:00', true),
            optimizing: _optimizingReminders,
            onOptimize: () => _optimizeReminders(appState),
          ),
          const SizedBox(height: 16),
          if (regimen == null || steps.isEmpty)
            const _EmptyRoutineCard()
          else
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
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

class _MiniTopBar extends StatelessWidget {
  const _MiniTopBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          const BrandLogo(size: 24, radius: 8, showShadow: false),
          const Spacer(),
          Text(
            'SkinSync',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_none_rounded,
            size: 17,
            color: AppColors.foreground,
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.morning, required this.onChanged});

  final bool morning;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Morning',
              selected: morning,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Evening',
              selected: !morning,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.foreground,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RemindersCard extends StatelessWidget {
  const _RemindersCard({
    required this.reminders,
    required this.onMorning,
    required this.onEvening,
    required this.optimizing,
    required this.onOptimize,
  });

  final List<ReminderItem> reminders;
  final VoidCallback onMorning;
  final VoidCallback onEvening;
  final bool optimizing;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context) {
    final morningReminder =
        _findReminder('morning') ??
        const ReminderItem(
          reminderId: 'm',
          time: '07:00',
          routineType: 'Morning',
          frequency: 'daily',
          isEnabled: true,
        );
    final eveningReminder =
        _findReminder('evening') ??
        const ReminderItem(
          reminderId: 'e',
          time: '21:00',
          routineType: 'Evening',
          frequency: 'daily',
          isEnabled: true,
        );

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminders',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Manual reminders still work. AI can optimize the timing based on your routine consistency.',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 12),
          _ReminderRow(item: morningReminder),
          const SizedBox(height: 8),
          _ReminderRow(item: eveningReminder),
          const SizedBox(height: 12),
          _ReminderButton(
            label: 'Set Morning Reminder 07:00',
            onPressed: onMorning,
          ),
          const SizedBox(height: 8),
          _ReminderButton(
            label: 'Set Evening Reminder 21:00',
            onPressed: onEvening,
          ),
          const SizedBox(height: 8),
          _ReminderButton(
            label: optimizing ? 'Optimizing with AI...' : 'Optimize with SkinSync AI',
            onPressed: optimizing ? () {} : onOptimize,
            filled: true,
            backgroundColor: const Color(0xFFD1EA8B),
            foregroundColor: AppColors.foreground,
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

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.item});

  final ReminderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          item.isEnabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          size: 16,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.routineType}: ${item.time}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((item.reason ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  item.reason!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.isEnabled ? 'On' : 'Off',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.foreground),
            ),
            if (item.isAdaptive) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1EA8B),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.priority.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ReminderButton extends StatelessWidget {
  const _ReminderButton({
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.backgroundColor = const Color(0xFF4B5568),
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onPressed,
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }
}

class _ReminderSuggestionSheet extends StatelessWidget {
  const _ReminderSuggestionSheet({required this.result});

  final AiReminderSuggestResponse result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SkinSync AI Reminder Plan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              result.overallAdvice,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 16),
            ...result.suggestions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.routineType} - ${item.time}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1EA8B),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.priority.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.foreground,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.foreground,
                          height: 1.4,
                        ),
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
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.78,
            child: Checkbox(
              value: completed,
              activeColor: const Color(0xFF4D7BFF),
              side: BorderSide(color: AppColors.border.withValues(alpha: 0.9)),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.stepOrder}. ${_titleCase(step.category)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${step.brand} ${step.name}'.trim(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((step.purpose ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    step.purpose!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.foreground,
                      height: 1.35,
                    ),
                  ),
                ],
                if ((step.instruction ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    step.instruction!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.35,
                    ),
                  ),
                ],
                if ((step.caution ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Caution: ${step.caution!}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class _EmptyRoutineCard extends StatelessWidget {
  const _EmptyRoutineCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(
            Icons.spa_outlined,
            color: AppColors.primaryDark.withValues(alpha: 0.65),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            'No routine yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete a skin analysis to generate your morning and evening steps.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}
