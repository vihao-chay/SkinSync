import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool morning = true;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    final steps = morning ? regimen?.morning ?? const <RegimenStep>[] : regimen?.evening ?? const <RegimenStep>[];
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};

    if (regimen == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Text('No routine available yet. Complete an analysis to generate one.'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Routine', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            '${tracking?.completedSteps ?? 0} of ${tracking?.totalSteps ?? 0} steps completed today',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(child: _Segment(label: 'Morning', selected: morning, onTap: () => setState(() => morning = true))),
                Expanded(child: _Segment(label: 'Evening', selected: !morning, onTap: () => setState(() => morning = false))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (reminders.isNotEmpty)
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: reminders
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${item.routineType}: ${item.time} ${item.isEnabled ? "On" : "Off"}'),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),
          ...steps.map(
            (step) {
              final completed = completedIds.contains(step.stepId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: completed,
                        onChanged: (_) => appState.toggleRoutineStep(step.stepId, completed),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${step.stepOrder}. ${step.category}', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text('${step.brand} ${step.name}', style: Theme.of(context).textTheme.bodyMedium),
                            if (step.purpose != null) ...[
                              const SizedBox(height: 8),
                              Text(step.purpose!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                            if (step.instruction != null) ...[
                              const SizedBox(height: 8),
                              Text(step.instruction!, style: Theme.of(context).textTheme.bodySmall),
                            ],
                            if (step.caution != null) ...[
                              const SizedBox(height: 8),
                              Text('Caution: ${step.caution!}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          GradientPillButton(
            label: 'Set Morning Reminder 07:00',
            expanded: true,
            onPressed: () => appState.saveReminder('Morning', '07:00', true),
          ),
          const SizedBox(height: 12),
          GradientPillButton(
            label: 'Set Evening Reminder 21:00',
            expanded: true,
            onPressed: () => appState.saveReminder('Evening', '21:00', true),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(label),
      ),
    );
  }
}
