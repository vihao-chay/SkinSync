import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/circular_score.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/stitch_top_bar.dart';
import '../../core/widgets/status_chip.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({
    super.key,
    RoutinePageArgs? args,
  }) : args = args ?? const RoutinePageArgs();

  final RoutinePageArgs args;

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool _showMorning = true;
  bool _optimizing = false;
  bool _didSeedDraft = false;
  bool _didHandleEntryPoint = false;
  String? _actionErrorMessage;
  Set<String> _draftCompletedStepIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHandleEntryPoint) {
      return;
    }
    _didHandleEntryPoint = true;
    if (widget.args.entryPoint == RoutineEntryPoint.productAdded) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await context.read<AppState>().refreshHome();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Routine reloaded from your saved backend regimen.'),
          ),
        );
      });
    }
  }

  void _seedDraftCompletedIds(RoutineTrackingToday? tracking) {
    if (_didSeedDraft) {
      return;
    }
    _draftCompletedStepIds = {...?tracking?.completedStepIds};
    _didSeedDraft = true;
  }

  Future<void> _toggleRoutineStepOptimistic(
    AppState appState,
    String stepId,
  ) async {
    final wasCompleted = _draftCompletedStepIds.contains(stepId);
    setState(() {
      if (wasCompleted) {
        _draftCompletedStepIds.remove(stepId);
      } else {
        _draftCompletedStepIds.add(stepId);
      }
      _actionErrorMessage = null;
    });

    try {
      await appState.toggleRoutineStep(stepId, wasCompleted);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (wasCompleted) {
          _draftCompletedStepIds.add(stepId);
        } else {
          _draftCompletedStepIds.remove(stepId);
        }
        _actionErrorMessage =
            appState.errorMessage ?? 'Could not update this routine step.';
      });
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    _seedDraftCompletedIds(tracking);

    final morningSteps = regimen?.morning ?? const <RegimenStep>[];
    final eveningSteps = regimen?.evening ?? const <RegimenStep>[];
    final activeSteps = _showMorning ? morningSteps : eveningSteps;
    final totalSteps = tracking?.totalSteps ?? (morningSteps.length + eveningSteps.length);
    final completedSteps = _draftCompletedStepIds.length;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: appState.refreshHome,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.pageBottomPaddingWithActions,
                ),
                children: [
                  StitchTopBar(
                    avatarUrl: appState.user?.avatarUrl,
                    onLeadingTap: () => MainShell.navigateToTab(
                      context,
                      AppRoutes.profile,
                    ),
                    onTrailingTap: () => MainShell.navigateToTab(
                      context,
                      AppRoutes.progress,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      4,
                      AppSpacing.pagePadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (appState.routineDataErrorMessage != null ||
                            _actionErrorMessage != null) ...[
                          ErrorStateCard(
                            title: 'Routine data needs attention',
                            description: _actionErrorMessage ??
                                appState.routineDataErrorMessage!,
                            ctaLabel: 'Try again',
                            onCta: appState.refreshHome,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _ProgressHeader(
                          percent: (progress * 100).round(),
                          completedSteps: completedSteps,
                          totalSteps: totalSteps,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RoutineSegmentedControl(
                          showMorning: _showMorning,
                          onChanged: (value) => setState(() => _showMorning = value),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ReminderRow(
                          morning: _findReminder(reminders, 'morning'),
                          evening: _findReminder(reminders, 'evening'),
                          onMorning: () => _saveReminder(
                            appState,
                            'Morning',
                            '07:00',
                          ),
                          onEvening: () => _saveReminder(
                            appState,
                            'Evening',
                            '21:00',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (regimen == null ||
                            (morningSteps.isEmpty && eveningSteps.isEmpty))
                          EmptyStateCard(
                            icon: Icons.checklist_rtl_outlined,
                            title: 'Choose products first',
                            description:
                                'Routine steps only appear from your active regimen. Open Shop and add products you want to use.',
                            ctaLabel: 'Open Shop',
                            onCta: () => MainShell.navigateToTab(
                              context,
                              AppRoutes.products,
                              arguments: const ProductsPageArgs(
                                entryPoint: ProductsEntryPoint.routineEmpty,
                              ),
                            ),
                          )
                        else if (activeSteps.isEmpty)
                          const EmptyStateCard(
                            icon: Icons.spa_outlined,
                            title: 'No steps here yet',
                            description:
                                'Your active routine does not have products for this time of day.',
                          )
                        else
                          ...activeSteps.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _RoutineStepTile(
                                step: step,
                                completed: _draftCompletedStepIds.contains(
                                  step.stepId,
                                ),
                                onChanged: () => _toggleRoutineStepOptimistic(
                                  appState,
                                  step.stepId,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: '+ Add Product',
                          onPressed: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.products,
                            arguments: const ProductsPageArgs(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Optimize Routine',
                          variant: AppButtonVariant.secondary,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          isLoading: _optimizing,
                          onPressed: _optimizing
                              ? null
                              : () => _optimizeReminders(appState),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.percent,
    required this.completedSteps,
    required this.totalSteps,
  });

  final int percent;
  final int completedSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularScore(score: percent, size: 132, label: 'Completed'),
        const SizedBox(height: 12),
        Text(
          'Today\'s Progress',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          totalSteps == 0
              ? 'No routine steps yet'
              : '$completedSteps of $totalSteps steps completed today',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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
      padding: const EdgeInsets.all(5),
      radius: AppRadius.pill,
      variant: AppCardVariant.muted,
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Morning',
              selected: showMorning,
              onTap: () => onChanged(true),
            ),
          ),
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.primaryDark : AppColors.foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.morning,
    required this.evening,
    required this.onMorning,
    required this.onEvening,
  });

  final ReminderItem? morning;
  final ReminderItem? evening;
  final VoidCallback onMorning;
  final VoidCallback onEvening;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReminderCard(
            label: 'Morning',
            time: morning?.time ?? '07:00',
            onTap: onMorning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ReminderCard(
            label: 'Evening',
            time: evening?.time ?? '21:00',
            onTap: onEvening,
          ),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      variant: AppCardVariant.metric,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_outlined,
            size: 15,
            color: AppColors.mutedText.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _RoutineStepTile extends StatelessWidget {
  const _RoutineStepTile({
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _StepImage(step: step),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.brand.trim().isEmpty ? step.category : step.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  step.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(step),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onChanged,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed ? AppColors.primaryDark : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed ? AppColors.primaryDark : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Icon(
                completed ? Icons.check_rounded : Icons.circle_outlined,
                size: completed ? 18 : 16,
                color: completed ? Colors.white : AppColors.subtleText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(RegimenStep step) {
    final instruction = step.instruction?.trim() ?? '';
    if (instruction.isNotEmpty) {
      return instruction;
    }
    final frequency = step.frequency?.trim() ?? '';
    if (frequency.isNotEmpty) {
      return frequency;
    }
    return step.purpose?.trim().isNotEmpty == true
        ? step.purpose!
        : 'Apply in your routine.';
  }
}

class _StepImage extends StatelessWidget {
  const _StepImage({required this.step});

  final RegimenStep step;

  @override
  Widget build(BuildContext context) {
    final raw = step.imageUrl?.trim() ?? '';
    final url = raw.isEmpty
        ? ''
        : raw.startsWith('http')
            ? raw
            : '${AppConfig.apiBaseUrl}$raw';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? Icon(
                _categoryIcon(step.category),
                color: AppColors.primaryDark,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  _categoryIcon(step.category),
                  color: AppColors.primaryDark,
                ),
              ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    return switch (category.trim().toLowerCase()) {
      'cleanser' => Icons.soap_outlined,
      'toner' => Icons.opacity_outlined,
      'serum' => Icons.science_outlined,
      'moisturizer' => Icons.spa_outlined,
      'sunscreen' => Icons.wb_sunny_outlined,
      _ => Icons.local_florist_outlined,
    };
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
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'SkinSync AI reminder plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
                      StatusChip(
                        label: '${item.routineType} - ${item.time}',
                        icon: Icons.schedule_rounded,
                        tone: StatusChipTone.accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
