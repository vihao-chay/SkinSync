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
import '../../core/widgets/linear_progress_stat.dart';
import '../../core/widgets/routine_checklist_item.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

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
      subtitle: locale.tr('checkup_subtitle'),
      onRefresh: appState.refreshHome,
      headerTrailing: _HeaderHomeButton(
        onTap: () => Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        ),
      ),
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
          AppCard(
            variant: AppCardVariant.hero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(
                  label: locale.tr('progress_routine_completion'),
                  icon: Icons.favorite_border_rounded,
                  tone: StatusChipTone.accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale
                      .tr('checkup_routine_completion_desc')
                      .replaceAll('{completed}', '$completedSteps')
                      .replaceAll('{total}', '$totalSteps'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressStat(
                  label: locale.tr('routine_today_progress'),
                  value: '$completedSteps/$totalSteps',
                  progress: progress,
                  caption: locale.tr('checkup_completion_saves_desc'),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusChip(
                      label: morningCompleted
                          ? locale.tr('checkup_morning_done')
                          : locale.tr('checkup_morning_pending'),
                      icon: Icons.wb_sunny_outlined,
                      tone: morningCompleted
                          ? StatusChipTone.success
                          : StatusChipTone.warning,
                    ),
                    StatusChip(
                      label: eveningCompleted
                          ? locale.tr('checkup_evening_done')
                          : locale.tr('checkup_evening_pending'),
                      icon: Icons.nightlight_round,
                      tone: eveningCompleted
                          ? StatusChipTone.success
                          : StatusChipTone.warning,
                    ),
                    StatusChip(
                      label: locale.tr('checkup_feeling_$_skinFeeling'),
                      icon: Icons.mood_outlined,
                    ),
                  ],
                ),
              ],
            ),
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
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _PhotoSlot(
                            label: locale.tr('checkup_left'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _PhotoSlot(
                            label: locale.tr('checkup_right'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
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
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _PhotoSlot(
                            label: locale.tr('checkup_left'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _PhotoSlot(
                            label: locale.tr('checkup_right'),
                            imageFile: null,
                            imageUrl: null,
                            enabled: false,
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
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: locale.tr('checkup_back_to_home'),
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
            ),
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

class _HeaderHomeButton extends StatelessWidget {
  const _HeaderHomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
          ),
          child: const Icon(Icons.home_rounded, color: AppColors.primaryDark),
        ),
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
  });

  final String label;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool enabled;

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
        height: 144,
        padding: const EdgeInsets.all(12),
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
