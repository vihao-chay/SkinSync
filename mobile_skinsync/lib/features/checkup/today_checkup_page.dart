import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class TodayCheckupPage extends StatefulWidget {
  const TodayCheckupPage({super.key});

  @override
  State<TodayCheckupPage> createState() => _TodayCheckupPageState();
}

class _TodayCheckupPageState extends State<TodayCheckupPage> {
  final _notesController = TextEditingController();
  final _acneController = TextEditingController();
  final _hydrationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String _skinFeeling = 'normal';
  bool _morning = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final log = context.read<AppState>().todayLog;
      _notesController.text = log?.notes ?? '';
      _acneController.text = (log?.acneLevel ?? '').toString();
      _hydrationController.text = (log?.hydrationLevel ?? '').toString();
      _skinFeeling = (log?.skinFeeling ?? 'normal').trim().isEmpty
          ? 'normal'
          : (log?.skinFeeling ?? 'normal');
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _acneController.dispose();
    _hydrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final todayLog = appState.todayLog;
    final steps = _morning
        ? regimen?.morning ?? const <RegimenStep>[]
        : regimen?.evening ?? const <RegimenStep>[];
    final completedIds = tracking?.completedStepIds.toSet() ?? <String>{};

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/today-checkup',
        title: 'Today Check up',
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SegmentedTab(
              morning: _morning,
              onChanged: (value) => setState(() => _morning = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pick the products you applied today',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                  ),
                ),
                TextButton(
                  onPressed: steps.isEmpty
                      ? null
                      : () => _markAll(appState, steps, completedIds),
                  child: const Text('Mark all'),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.routine),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (steps.isEmpty)
              const _EmptyStateCard(
                title: 'No routine steps yet',
                body:
                    'Generate or edit your routine first, then come back here to log what you applied today.',
              )
            else
              ...steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
            const SizedBox(height: 16),
            Text(
              'Skin photo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PhotoCard(
                    title: 'Main check-in',
                    subtitle: 'Saved to diary',
                    imageFile: _selectedImage,
                    imageUrl: todayLog?.dailyImageUrl,
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: _SecondaryPhotoCard()),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'How does your skin feel today?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const [
                    'good',
                    'normal',
                    'dry',
                    'oily',
                    'irritated',
                    'sensitive',
                  ].map((item) {
                    return _FeelingChip(label: item);
                  }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Notes',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _acneController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Acne level',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hydrationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Hydration',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: appState.isBusy ? null : () => _save(appState),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                appState.isBusy ? 'Saving...' : 'Save Today Check-up',
              ),
            ),
          ],
        ),
      ),
    );
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
      acneLevel: int.tryParse(_acneController.text.trim()) ?? 0,
      hydrationLevel: int.tryParse(_hydrationController.text.trim()) ?? 0,
      imageFile: _selectedImage,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).maybePop();
  }
}

class _SegmentedTab extends StatelessWidget {
  const _SegmentedTab({required this.morning, required this.onChanged});

  final bool morning;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'Morning',
              selected: morning,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentItem(
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

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
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
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary,
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
                  '${step.category} - ${step.brand}',
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
        height: 150,
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

class _SecondaryPhotoCard extends StatelessWidget {
  const _SecondaryPhotoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next angle',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Stored later',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.flip_camera_ios_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_TodayCheckupPageState>();
    final selected = state?._skinFeeling.toLowerCase() == label.toLowerCase();
    return InkWell(
      onTap: () {
        if (state == null) {
          return;
        }
        state.setState(() => state._skinFeeling = label);
      },
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
        color: Colors.white.withValues(alpha: 0.96),
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
