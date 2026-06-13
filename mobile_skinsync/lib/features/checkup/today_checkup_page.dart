import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
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
  File? _selectedImage;

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
    setState(() => _saving = true);
    try {
      await appState.saveDailyLog(
        skinFeeling: _skinFeeling,
        notes: _notesController.text.trim(),
        imageFile: _selectedImage,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Today Check-up saved successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appState.errorMessage ?? 'Could not save today check-up right now.',
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
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};
    final morningSteps = regimen?.morning ?? const <RegimenStep>[];
    final eveningSteps = regimen?.evening ?? const <RegimenStep>[];
    final activeSteps = _showMorning ? morningSteps : eveningSteps;
    final totalSteps = tracking?.totalSteps ?? 0;
    final completedSteps = tracking?.completedSteps ?? 0;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

    return AppScaffold(
      title: 'Today Check-up',
      subtitle: 'Check off your active routine and log how your skin feels today.',
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
          if (appState.todayCheckupDataErrorMessage != null) ...[
            ErrorStateCard(
              title: 'Today check-up needs attention',
              description: appState.todayCheckupDataErrorMessage!,
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
                  label: 'Routine completion',
                  icon: Icons.favorite_border_rounded,
                  tone: StatusChipTone.accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$completedSteps of $totalSteps routine steps completed today.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressStat(
                  label: 'Today progress',
                  value: '$completedSteps/$totalSteps',
                  progress: progress,
                  caption: 'Completion saves through routine tracking and your daily log.',
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    StatusChip(
                      label: tracking?.morningCompleted == true ? 'Morning done' : 'Morning pending',
                      icon: Icons.wb_sunny_outlined,
                      tone: tracking?.morningCompleted == true
                          ? StatusChipTone.success
                          : StatusChipTone.warning,
                    ),
                    StatusChip(
                      label: tracking?.eveningCompleted == true ? 'Evening done' : 'Evening pending',
                      icon: Icons.nightlight_round,
                      tone: tracking?.eveningCompleted == true
                          ? StatusChipTone.success
                          : StatusChipTone.warning,
                    ),
                    StatusChip(
                      label: _skinFeeling.replaceAll('_', ' '),
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
              title: 'No active routine yet',
              description: 'Today Check-up only uses products from your active routine. Build your routine first, then come back to track it here.',
              ctaLabel: 'Open routine',
              onCta: () => Navigator.pushNamed(context, AppRoutes.routine),
            )
          else ...[
            SectionHeader(
              icon: Icons.checklist_rounded,
              title: 'Checklist from active routine',
              subtitle: 'Morning and evening steps are pulled directly from your active regimen.',
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutineSegmentedControl(
              showMorning: _showMorning,
              onChanged: (value) => setState(() => _showMorning = value),
            ),
            const SizedBox(height: AppSpacing.md),
            if (activeSteps.isEmpty)
              const EmptyStateCard(
                icon: Icons.spa_outlined,
                title: 'No steps in this routine block',
                description: 'Your active routine does not have steps for this time of day yet.',
              )
            else
              ...activeSteps.map(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.favorite_outline_rounded,
                  title: 'How does your skin feel?',
                  subtitle: 'Save a quick signal alongside today’s checklist.',
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
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
                      label: Text(option.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _skinFeeling = option.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any dryness, redness, wins, or product reactions worth tracking today?',
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
                const SectionHeader(
                  icon: Icons.camera_alt_outlined,
                  title: 'Photo check-in',
                  subtitle: 'Use a real upload where available, with soft placeholders for the rest.',
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _PhotoSlot(
                        label: 'Front',
                        imageFile: _selectedImage,
                        imageUrl: todayLog?.dailyImageUrl,
                        onTap: _pickImage,
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: _PhotoSlot(
                        label: 'Left',
                        imageFile: null,
                        imageUrl: null,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: _PhotoSlot(
                        label: 'Right',
                        imageFile: null,
                        imageUrl: null,
                        enabled: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppButton(
            label: 'Save Today Check-up',
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
        : ((imageUrl ?? '').isEmpty ? null : '${AppConfig.apiBaseUrl}$imageUrl');

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 144,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
              enabled ? 'Tap to capture' : 'Placeholder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinFeelingOption {
  const _SkinFeelingOption(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

const _skinFeelingOptions = [
  _SkinFeelingOption('Good', 'good', Icons.sentiment_satisfied_alt_outlined),
  _SkinFeelingOption('Dry', 'dry', Icons.water_drop_outlined),
  _SkinFeelingOption('Oily', 'oily', Icons.opacity_outlined),
  _SkinFeelingOption('Red', 'red', Icons.favorite_border_rounded),
  _SkinFeelingOption('Irritated', 'irritated', Icons.warning_amber_rounded),
  _SkinFeelingOption('Breakout', 'breakout', Icons.blur_on_outlined),
];
