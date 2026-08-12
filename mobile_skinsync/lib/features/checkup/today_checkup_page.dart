import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/routine_checklist_item.dart';
import '../../core/widgets/section_header.dart';

class TodayCheckupPage extends StatefulWidget {
  const TodayCheckupPage({super.key});

  @override
  State<TodayCheckupPage> createState() => _TodayCheckupPageState();
}

class _TodayCheckupPageState extends State<TodayCheckupPage> {
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _skinFeeling = 'good';
  bool _showMorning = true;
  bool _saving = false;
  bool _didSyncFromLog = false;
  bool _didSyncChecklist = false;
  File? _selectedImage;
  Set<String> _draftCompletedStepIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSyncFromLog) {
      return;
    }

    final log = context.read<AppState>().todayLog;
    _notesController.text = log?.notes ?? '';
    _skinFeeling = _resolveFeeling(log?.skinFeeling);
    _didSyncFromLog = true;
  }

  void _syncDraftChecklist(RoutineTrackingToday? tracking) {
    if (_didSyncChecklist) {
      return;
    }
    _draftCompletedStepIds = {...?tracking?.completedStepIds};
    _didSyncChecklist = true;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _saveCheckup(AppState appState) async {
    debugPrint('[SkinSync] check-up save');
    setState(() => _saving = true);
    try {
      await appState.saveDailyLog(
        skinFeeling: _skinFeeling,
        notes: _notesController.text.trim(),
        imageFile: _selectedImage,
        completedStepIds: _draftCompletedStepIds.toList(),
      );
      if (!mounted) {
        return;
      }
      final locale = AppLocale.of(context, listen: false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(locale.tr('checkup_submitted'))));
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.progress,
        (route) => false,
        arguments: const ProgressPageArgs(
          entryPoint: ProgressEntryPoint.checkupSaved,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      final locale = AppLocale.of(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ?? locale.tr('checkup_error_save'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    _syncDraftChecklist(tracking);
    final todayLog = appState.todayLog;
    final completedIds = _draftCompletedStepIds;
    final morningSteps = regimen?.morning ?? const <RegimenStep>[];
    final eveningSteps = regimen?.evening ?? const <RegimenStep>[];
    final activeSteps = _showMorning ? morningSteps : eveningSteps;
    final totalSteps =
        tracking?.totalSteps ?? (morningSteps.length + eveningSteps.length);
    final completedSteps = completedIds.length;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;
    final morningCompleted =
        morningSteps.isNotEmpty &&
        morningSteps.every((step) => completedIds.contains(step.stepId));
    final eveningCompleted =
        eveningSteps.isNotEmpty &&
        eveningSteps.every((step) => completedIds.contains(step.stepId));

    return AppScaffold(
      title: locale.tr('checkup_title'),
      compactHeader: true,
      showBackButton: true,
      backIcon: Icons.chevron_left_rounded,
      headerBottomSpacing: AppSpacing.sm,
      onRefresh: appState.refreshHome,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          Responsive.responsiveHorizontalPadding(context),
          0,
          Responsive.responsiveHorizontalPadding(context),
          Responsive.contentBottomSpacing(context, extra: 20),
        ),
        children: [
          if (appState.todayCheckupDataErrorMessage != null) ...[
            ErrorStateCard(
              title: locale.tr('checkup_needs_attention'),
              description: appState.todayCheckupDataErrorMessage!,
              ctaLabel: locale.tr('common_try_again'),
              onCta: appState.refreshHome,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
          ],
          _CheckupOverviewCard(
            completedSteps: completedSteps,
            totalSteps: totalSteps,
            progress: progress,
            morningCompleted: morningCompleted,
            eveningCompleted: eveningCompleted,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (regimen == null ||
              (morningSteps.isEmpty && eveningSteps.isEmpty) ||
              tracking == null)
            EmptyStateCard(
              icon: Icons.checklist_rtl_outlined,
              title: locale.tr('routine_no_regimen'),
              description: locale.tr('checkup_no_active_routine_desc'),
              ctaLabel: locale.tr('checkup_open_products'),
              onCta: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.products,
                (route) => false,
                arguments: const ProductsPageArgs(
                  entryPoint: ProductsEntryPoint.routineEmpty,
                ),
              ),
            )
          else ...[
            SectionHeader(
              icon: Icons.checklist_rounded,
              title: locale.tr('checkup_checklist_title'),
              subtitle: locale.tr('checkup_checklist_subtitle'),
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutineSegmentedControl(
              showMorning: _showMorning,
              onChanged: (value) => setState(() => _showMorning = value),
            ),
            const SizedBox(height: AppSpacing.md),
            if (activeSteps.isEmpty)
              EmptyStateCard(
                icon: Icons.spa_outlined,
                title: locale.tr('checkup_no_steps_in_block'),
                description: locale.tr('checkup_no_steps_in_block_desc'),
              )
            else
              ...activeSteps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: RoutineChecklistItem(
                    step: step,
                    completed: completedIds.contains(step.stepId),
                    onChanged: () => setState(() {
                      if (completedIds.contains(step.stepId)) {
                        completedIds.remove(step.stepId);
                      } else {
                        completedIds.add(step.stepId);
                      }
                    }),
                  ),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  icon: Icons.favorite_outline_rounded,
                  title: locale.tr('checkup_how_skin_feel'),
                  subtitle: locale.tr('checkup_skin_feel_subtitle'),
                ),
                const SizedBox(height: AppSpacing.md),
                Material(
                  color: Colors.transparent,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _skinFeelingOptions.map((option) {
                      final selected = _skinFeeling == option.value;
                      return ChoiceChip(
                        avatar: Icon(
                          option.icon,
                          size: 16,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.mutedText,
                        ),
                        label: Text(
                          AppLocale.of(
                            context,
                          ).tr('checkup_feeling_${option.value}'),
                        ),
                        selected: selected,
                        showCheckmark: false,
                        backgroundColor: AppColors.surfaceMuted,
                        selectedColor: AppColors.primaryFixed,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primaryDark
                              : Colors.white,
                        ),
                        shape: const StadiumBorder(),
                        onSelected: (_) =>
                            setState(() => _skinFeeling = option.value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: locale.tr('checkup_notes'),
                    hintText: locale.tr('checkup_notes_hint'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  icon: Icons.camera_alt_outlined,
                  title: locale.tr('checkup_photo_checkin'),
                  subtitle: locale.tr('checkup_photo_checkin_subtitle'),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 460) {
                      return Column(
                        children: [
                          _PhotoSlot(
                            label: locale.tr('checkup_front'),
                            imageFile: _selectedImage,
                            imageUrl: todayLog?.dailyImageUrl,
                            onTap: _pickImage,
                            enabled: true,
                            height: 184,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _PhotoSlot(
                                  label: locale.tr('checkup_left'),
                                  imageFile: null,
                                  imageUrl: null,
                                  enabled: false,
                                  height: 120,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _PhotoSlot(
                                  label: locale.tr('checkup_right'),
                                  imageFile: null,
                                  imageUrl: null,
                                  enabled: false,
                                  height: 120,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _PhotoSlot(
                            label: locale.tr('checkup_front'),
                            imageFile: _selectedImage,
                            imageUrl: todayLog?.dailyImageUrl,
                            onTap: _pickImage,
                            enabled: true,
                            height: 168,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _PhotoSlot(
                            label: locale.tr('checkup_left'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
                            height: 168,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _PhotoSlot(
                            label: locale.tr('checkup_right'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
                            height: 168,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppButton(
            label: locale.tr('checkup_save_today'),
            icon: const Icon(Icons.check_circle_outline_rounded),
            isLoading: _saving,
            onPressed: _saving ? null : () => _saveCheckup(appState),
          ),
        ],
      ),
    );
  }

  String _resolveFeeling(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    if (_skinFeelingOptions.any((option) => option.value == normalized)) {
      return normalized;
    }
    return 'good';
  }
}

class _CheckupOverviewCard extends StatelessWidget {
  const _CheckupOverviewCard({
    required this.completedSteps,
    required this.totalSteps,
    required this.progress,
    required this.morningCompleted,
    required this.eveningCompleted,
  });

  final int completedSteps;
  final int totalSteps;
  final double progress;
  final bool morningCompleted;
  final bool eveningCompleted;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    final percent = (safeProgress * 100).round();

    return AppCard(
      variant: AppCardVariant.accent,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primaryDark,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locale.tr('progress_routine_completion'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      locale.tr('routine_today_progress'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completedSteps/$totalSteps',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PeriodStatusTile(
                  icon: Icons.wb_sunny_outlined,
                  label: morningCompleted
                      ? locale.tr('checkup_morning_done')
                      : locale.tr('checkup_morning_pending'),
                  completed: morningCompleted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PeriodStatusTile(
                  icon: Icons.nightlight_round,
                  label: eveningCompleted
                      ? locale.tr('checkup_evening_done')
                      : locale.tr('checkup_evening_pending'),
                  completed: eveningCompleted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodStatusTile extends StatelessWidget {
  const _PeriodStatusTile({
    required this.icon,
    required this.label,
    required this.completed,
  });

  final IconData icon;
  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 17,
            color: completed ? AppColors.primaryDark : AppColors.mutedText,
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
    final locale = AppLocale.of(context);
    return AppCard(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: locale.tr('routine_morning'),
              selected: showMorning,
              onTap: () => onChanged(true),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
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

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.label,
    required this.imageFile,
    required this.imageUrl,
    this.onTap,
    this.enabled = false,
    this.height = 144,
    this.compact = false,
  });

  final String label;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool enabled;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fullUrl = (imageUrl ?? '').startsWith('http')
        ? imageUrl
        : ((imageUrl ?? '').isEmpty
              ? null
              : '${AppConfig.apiBaseUrl}$imageUrl');

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: height,
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: AppColors.secondary,
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : fullUrl != null
                      ? Image.network(fullUrl, fit: BoxFit.cover)
                      : Icon(
                          enabled
                              ? Icons.add_a_photo_outlined
                              : Icons.image_outlined,
                          color: AppColors.primaryDark,
                        ),
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              Text(
                enabled
                    ? AppLocale.of(context).tr('checkup_tap_to_capture')
                    : AppLocale.of(context).tr('checkup_placeholder'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkinFeelingOption {
  const _SkinFeelingOption(this.value, this.icon);

  final String value;
  final IconData icon;

  String get label => value; // the UI uses translated label anyway
}

const _skinFeelingOptions = [
  _SkinFeelingOption('good', Icons.sentiment_satisfied_alt_outlined),
  _SkinFeelingOption('dry', Icons.water_drop_outlined),
  _SkinFeelingOption('oily', Icons.opacity_outlined),
  _SkinFeelingOption('red', Icons.favorite_border_rounded),
  _SkinFeelingOption('irritated', Icons.warning_amber_rounded),
  _SkinFeelingOption('breakout', Icons.blur_on_outlined),
];
