import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/responsive.dart';
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
import '../../core/widgets/status_chip.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key, RoutinePageArgs? args})
    : args = args ?? const RoutinePageArgs();

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
        final locale = AppLocale.of(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(locale.tr('routine_reloaded'))));
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
    final locale = AppLocale.of(context);
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
            appState.errorMessage ?? locale.tr('routine_error_update_step');
      });
    }
  }

  Future<void> _saveReminder(
    AppState appState,
    String routineType,
    String time,
  ) async {
    final locale = AppLocale.of(context);
    try {
      await appState.saveReminder(routineType, time, true);
      if (mounted) {
        setState(() => _actionErrorMessage = null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionErrorMessage =
              appState.errorMessage ?? locale.tr('routine_error_save_reminder');
        });
      }
    }
  }

  Future<void> _optimizeReminders(AppState appState) async {
    final locale = AppLocale.of(context);
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
              appState.errorMessage ?? locale.tr('routine_error_optimize');
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
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final reminders = appState.reminders;
    _seedDraftCompletedIds(tracking);

    final morningSteps = regimen?.morning ?? const <RegimenStep>[];
    final eveningSteps = regimen?.evening ?? const <RegimenStep>[];
    final activeSteps = _showMorning ? morningSteps : eveningSteps;
    final totalSteps =
        tracking?.totalSteps ?? (morningSteps.length + eveningSteps.length);
    final completedSteps = _draftCompletedStepIds.length;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: double.infinity,
                tablet: 760,
                desktop: 960,
              ),
            ),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: appState.refreshHome,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 0),
                children: [
                  _RoutineHeroHeader(
                    avatarUrl: appState.user?.avatarUrl,
                    onLeadingTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.profile),
                    onTrailingTap: () =>
                        MainShell.navigateToTab(context, AppRoutes.progress),
                    percent: (progress * 100).round(),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.responsiveHorizontalPadding(context),
                      AppSpacing.md,
                      Responsive.responsiveHorizontalPadding(context),
                      Responsive.contentBottomSpacing(context, extra: 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (appState.routineDataErrorMessage != null ||
                            _actionErrorMessage != null) ...[
                          ErrorStateCard(
                            title: locale.tr('routine_error_data_attention'),
                            description:
                                _actionErrorMessage ??
                                appState.routineDataErrorMessage!,
                            ctaLabel: locale.tr('common_retry'),
                            onCta: appState.refreshHome,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _RoutineSegmentedControl(
                          showMorning: _showMorning,
                          onChanged: (value) =>
                              setState(() => _showMorning = value),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _ReminderRow(
                          morning: _findReminder(reminders, 'morning'),
                          evening: _findReminder(reminders, 'evening'),
                          onMorning: () =>
                              _saveReminder(appState, 'Morning', '07:00'),
                          onEvening: () =>
                              _saveReminder(appState, 'Evening', '21:00'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (regimen == null ||
                            (morningSteps.isEmpty && eveningSteps.isEmpty))
                          EmptyStateCard(
                            icon: Icons.checklist_rtl_outlined,
                            title: locale.tr('routine_empty_title'),
                            description: locale.tr('routine_empty_desc'),
                            ctaLabel: locale.tr('recommendation_open_shop'),
                            onCta: () => MainShell.navigateToTab(
                              context,
                              AppRoutes.products,
                              arguments: const ProductsPageArgs(
                                entryPoint: ProductsEntryPoint.routineEmpty,
                              ),
                            ),
                          )
                        else if (activeSteps.isEmpty)
                          EmptyStateCard(
                            icon: Icons.spa_outlined,
                            title: locale.tr('routine_no_steps_title'),
                            description: locale.tr('routine_no_steps_desc'),
                          )
                        else
                          ...activeSteps.map(
                            (step) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
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
                          label: locale.tr('routine_add_product'),
                          onPressed: () => MainShell.navigateToTab(
                            context,
                            AppRoutes.products,
                            arguments: const ProductsPageArgs(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: locale.tr('routine_optimize'),
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

class _RoutineHeroHeader extends StatelessWidget {
  const _RoutineHeroHeader({
    required this.avatarUrl,
    required this.onLeadingTap,
    required this.onTrailingTap,
    required this.percent,
  });

  final String? avatarUrl;
  final VoidCallback onLeadingTap;
  final VoidCallback onTrailingTap;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final topBarHeight = isWide ? 64.0 : 56.0;
    final progressSize = isWide ? 150.0 : 124.0;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.pageBackground),
      child: Column(
        children: [
          SizedBox(
            height: topBarHeight,
            child: _RoutineTopBar(
              avatarUrl: avatarUrl,
              onLeadingTap: onLeadingTap,
              onTrailingTap: onTrailingTap,
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outline.withValues(alpha: 0.28),
          ),
          SizedBox(height: isWide ? 28 : 18),
          CircularScore(
            score: percent,
            size: progressSize,
            label: locale.tr('routine_completed'),
            scoreFontSize: isWide ? 34 : 28,
            labelFontSize: isWide ? 11 : 9,
          ),
          const SizedBox(height: 12),
          Text(
            locale.tr('routine_today_progress'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.w800,
              color: AppColors.heading,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineTopBar extends StatelessWidget {
  const _RoutineTopBar({
    required this.avatarUrl,
    required this.onLeadingTap,
    required this.onTrailingTap,
  });

  final String? avatarUrl;
  final VoidCallback onLeadingTap;
  final VoidCallback onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RoutineAvatarButton(
                avatarUrl: avatarUrl,
                size: 28,
                onTap: onLeadingTap,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'SkinSync',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  height: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _RoutineIconButton(
                size: 32,
                onTap: onTrailingTap,
                icon: Icons.notifications_none_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineAvatarButton extends StatelessWidget {
  const _RoutineAvatarButton({
    required this.avatarUrl,
    required this.size,
    required this.onTap,
  });

  final String? avatarUrl;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarUrl?.trim() ?? '';

    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: size,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _RoutineAvatarFallback(),
                )
              : const _RoutineAvatarFallback(),
        ),
      ),
    );
  }
}

class _RoutineAvatarFallback extends StatelessWidget {
  const _RoutineAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.person_outline_rounded, color: AppColors.primary),
    );
  }
}

class _RoutineIconButton extends StatelessWidget {
  const _RoutineIconButton({
    required this.size,
    required this.onTap,
    required this.icon,
  });

  final double size;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: size * 0.58, color: AppColors.primary),
        ),
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
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.all(5),
      radius: AppRadius.pill,
      variant: AppCardVariant.muted,
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: locale.tr('routine_morning'),
              selected: showMorning,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: locale.tr('routine_evening'),
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
    final locale = AppLocale.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              _ReminderCard(
                label: locale.tr('routine_morning'),
                time: morning?.time ?? '07:00',
                onTap: onMorning,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReminderCard(
                label: locale.tr('routine_evening'),
                time: evening?.time ?? '21:00',
                onTap: onEvening,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _ReminderCard(
                label: locale.tr('routine_morning'),
                time: morning?.time ?? '07:00',
                onTap: onMorning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ReminderCard(
                label: locale.tr('routine_evening'),
                time: evening?.time ?? '21:00',
                onTap: onEvening,
              ),
            ),
          ],
        );
      },
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
                    fontFamily: 'PlusJakartaSans',
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(step, context),
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
                  color: completed ? AppColors.primaryDark : Colors.white,
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

  String _subtitle(RegimenStep step, BuildContext context) {
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
        : AppLocale.of(context).tr('routine_step_apply_default');
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
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        width: 72,
        height: 72,
        color: AppColors.surfaceStrong,
        child: url.isEmpty
            ? Icon(_categoryIcon(step.category), color: AppColors.primaryDark)
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
    final locale = AppLocale.of(context);
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
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              locale.tr('routine_ai_plan_title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.overallAdvice.isEmpty
                  ? locale.tr('routine_ai_no_summary')
                  : result.overallAdvice,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
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
