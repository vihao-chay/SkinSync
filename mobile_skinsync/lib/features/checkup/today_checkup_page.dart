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
import '../../core/widgets/glass_header.dart';

class TodayCheckupPage extends StatefulWidget {
  const TodayCheckupPage({super.key});

  @override
  State<TodayCheckupPage> createState() => _TodayCheckupPageState();
}

class _TodayCheckupPageState extends State<TodayCheckupPage> {
  final _notesController = TextEditingController();
  final _acneController = TextEditingController();
  final _drynessController = TextEditingController();
  final _rednessController = TextEditingController();
  final _hydrationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _skinFeeling = 'normal';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _seedFromTodayLog(context.read<AppState>().todayLog);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _acneController.dispose();
    _drynessController.dispose();
    _rednessController.dispose();
    _hydrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/today-checkup',
        title: 'Today Check-up',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            12,
            AppSpacing.pagePadding,
            AppSpacing.pageBottomPaddingWithActions,
          ),
          children: [
            _TodayOverviewCard(
              tracking: tracking,
              todayLog: todayLog,
              onOpenRoutine: () => Navigator.pushNamed(context, AppRoutes.routine),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SectionTitle(
              title: 'Routine today',
              subtitle:
                  'Confirm the steps you actually completed today. This keeps routine tracking and check-up in sync.',
            ),
            const SizedBox(height: AppSpacing.md),
            _RoutineBlock(
              title: 'Morning routine',
              icon: Icons.wb_sunny_outlined,
              completed: tracking?.morningCompleted ?? todayLog?.morningCompleted ?? false,
              steps: regimen?.morning ?? const <RegimenStep>[],
              completedIds: completedIds,
              onMarkAll: () => _markAll(
                appState,
                regimen?.morning ?? const <RegimenStep>[],
                completedIds,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoutineBlock(
              title: 'Evening routine',
              icon: Icons.bedtime_outlined,
              completed: tracking?.eveningCompleted ?? todayLog?.eveningCompleted ?? false,
              steps: regimen?.evening ?? const <RegimenStep>[],
              completedIds: completedIds,
              onMarkAll: () => _markAll(
                appState,
                regimen?.evening ?? const <RegimenStep>[],
                completedIds,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SectionTitle(
              title: 'Skin diary today',
              subtitle:
                  'Log today\'s skin response in a quick 30 to 60 second check-in.',
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How does your skin feel today?',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _skinFeelingOptions)
                        _FeelingChip(
                          label: option.label,
                          selected: _skinFeeling == option.value,
                          onTap: () => setState(() => _skinFeeling = option.value),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Daily symptom inputs',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreField(
                          controller: _acneController,
                          label: 'Acne',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ScoreField(
                          controller: _rednessController,
                          label: 'Redness',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreField(
                          controller: _drynessController,
                          label: 'Dryness',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ScoreField(
                          controller: _hydrationController,
                          label: 'Hydration',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      hintText:
                          'Optional. Example: skin felt calm this morning, but a new serum caused mild redness.',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SectionTitle(
              title: 'Today photo',
              subtitle:
                  'Optional diary photo for today only. This does not go into the progress timeline.',
            ),
            const SizedBox(height: AppSpacing.md),
            _PhotoCard(
              title: 'Diary photo',
              subtitle: 'Saved only with today\'s check-up',
              imageFile: _selectedImage,
              imageUrl: todayLog?.dailyImageUrl,
              onTap: _pickImage,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AppButton(
              label: appState.isBusy ? 'Saving...' : 'Save Today Check-up',
              icon: const Icon(Icons.favorite_border_rounded),
              isLoading: appState.isBusy,
              onPressed: () => _save(appState),
            ),
          ],
        ),
      ),
    );
  }

  void _seedFromTodayLog(DailyLog? log) {
    _notesController.text = log?.notes ?? '';
    _acneController.text = _scoreText(log?.acneLevel);
    _drynessController.text = _scoreText(log?.drynessLevel);
    _rednessController.text = _scoreText(log?.rednessLevel);
    _hydrationController.text = _scoreText(log?.hydrationLevel);

    final feeling = (log?.skinFeeling ?? 'normal').trim().toLowerCase();
    _skinFeeling =
        _skinFeelingOptions.any((option) => option.value == feeling)
            ? feeling
            : 'normal';
    setState(() {});
  }

  String _scoreText(int? value) => value == null ? '' : value.toString();

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

  Future<void> _markAll(
    AppState appState,
    List<RegimenStep> steps,
    Set<String> completedIds,
  ) async {
    for (final step in steps) {
      if (!completedIds.contains(step.stepId)) {
        await appState.toggleRoutineStep(step.stepId, false);
      }
    }
  }

  Future<void> _save(AppState appState) async {
    await appState.saveDailyLog(
      skinFeeling: _skinFeeling,
      notes: _notesController.text.trim(),
      acneLevel: int.tryParse(_acneController.text.trim()),
      drynessLevel: int.tryParse(_drynessController.text.trim()),
      rednessLevel: int.tryParse(_rednessController.text.trim()),
      hydrationLevel: int.tryParse(_hydrationController.text.trim()),
      imageFile: _selectedImage,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Today Check-up saved successfully.')),
    );
    Navigator.of(context).maybePop();
  }
}

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({
    required this.tracking,
    required this.todayLog,
    required this.onOpenRoutine,
  });

  final RoutineTrackingToday? tracking;
  final DailyLog? todayLog;
  final VoidCallback onOpenRoutine;

  @override
  Widget build(BuildContext context) {
    final completed = tracking?.completedSteps ?? 0;
    final total = tracking?.totalSteps ?? 0;
    final diaryReady = todayLog?.hasDiaryDetails ?? false;

    return AppCard(
      backgroundColor: AppColors.surfaceStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today in one flow',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Confirm what you applied, then add a quick diary update so Dashboard and Progress stay in sync.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatusTile(
                  label: 'Routine today',
                  value: total == 0 ? 'No steps yet' : '$completed/$total done',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatusTile(
                  label: 'Diary today',
                  value: diaryReady ? 'Details added' : 'Not updated yet',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Open routine',
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.spa_outlined),
            onPressed: onOpenRoutine,
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RoutineBlock extends StatelessWidget {
  const _RoutineBlock({
    required this.title,
    required this.icon,
    required this.completed,
    required this.steps,
    required this.completedIds,
    required this.onMarkAll,
  });

  final String title;
  final IconData icon;
  final bool completed;
  final List<RegimenStep> steps;
  final Set<String> completedIds;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

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
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      completed ? 'Completed' : 'Still in progress',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: steps.isEmpty ? null : onMarkAll,
                child: const Text('Mark all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (steps.isEmpty)
            const _EmptyStateCard(
              title: 'No routine steps yet',
              body:
                  'Generate or edit your routine first, then come back here to track what you actually used today.',
            )
          else
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _CheckupStepCard(
                  step: step,
                  checked: completedIds.contains(step.stepId),
                  onToggle: () => appState.toggleRoutineStep(
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

class _CheckupStepCard extends StatelessWidget {
  const _CheckupStepCard({
    required this.step,
    required this.checked,
    required this.onToggle,
  });

  final RegimenStep step;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${step.stepOrder}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _productLine(step),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Checkbox(
            value: checked,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  String _productLine(RegimenStep step) {
    final items = [
      step.category.trim(),
      step.brand.trim(),
    ].where((item) => item.isNotEmpty);
    final value = items.join(' • ');
    return value.isEmpty ? 'Not provided yet' : value;
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.title,
    required this.subtitle,
    required this.imageFile,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final File? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fullUrl = (imageUrl ?? '').startsWith('http')
        ? imageUrl
        : ((imageUrl ?? '').isEmpty
              ? null
              : '${AppConfig.apiBaseUrl}$imageUrl');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 10),
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
                      : const Icon(Icons.add_a_photo_outlined),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0-10',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkinFeelingOption {
  const _SkinFeelingOption(this.label, this.value);

  final String label;
  final String value;
}

const _skinFeelingOptions = [
  _SkinFeelingOption('Good', 'good'),
  _SkinFeelingOption('Normal', 'normal'),
  _SkinFeelingOption('Dry', 'dry'),
  _SkinFeelingOption('Oily', 'oily'),
  _SkinFeelingOption('Sensitive', 'sensitive'),
  _SkinFeelingOption('Irritated', 'irritated'),
];
