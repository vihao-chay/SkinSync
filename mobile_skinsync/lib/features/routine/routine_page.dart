import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import 'widgets/product_detail_sheet.dart';
import 'widgets/routine_section.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  bool morning = true;
  bool editMode = false;
  final completedMorning = <int>{};
  final completedEvening = <int>{};
  bool morningReminder = true;
  bool eveningReminder = true;

  @override
  Widget build(BuildContext context) {
    final steps = morning ? MockSkinData.morningRoutine : MockSkinData.eveningRoutine;
    final completed = morning ? completedMorning : completedEvening;
    final progress = steps.isEmpty ? 0.0 : completed.length / steps.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        120,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Routine', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${completed.length} of ${steps.length} steps completed today',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _TopAction(
                icon: Icons.alarm_rounded,
                onTap: _showReminderSheet,
              ),
              const SizedBox(width: 10),
              _TopAction(
                icon: editMode ? Icons.close_rounded : Icons.edit_rounded,
                onTap: () => setState(() => editMode = !editMode),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentButton(
                    label: 'Morning',
                    selected: morning,
                    onTap: () => setState(() => morning = true),
                  ),
                ),
                Expanded(
                  child: _SegmentButton(
                    label: 'Evening',
                    selected: !morning,
                    onTap: () => setState(() => morning = false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${completed.length} of ${steps.length} steps completed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.secondary,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('12-day streak', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          RoutineSection(
            steps: steps,
            completed: completed,
            editMode: editMode,
            onToggleStep: (index) => setState(() {
              if (completed.contains(index)) {
                completed.remove(index);
              } else {
                completed.add(index);
              }
            }),
            onDetail: (step) => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              builder: (_) => ProductDetailSheet(step: step),
            ),
          ),
          if (editMode) ...[
            const SizedBox(height: AppSpacing.mediumGap),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Mode', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Preview reorder and delete affordances before API editing is connected.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: _EditPill(label: 'Add Step')),
                      SizedBox(width: 10),
                      Expanded(child: _EditPill(label: 'Reorder')),
                      SizedBox(width: 10),
                      Expanded(child: _EditPill(label: 'Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sectionGap),
          GradientPillButton(
            label: 'Save Routine Changes',
            expanded: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Future<void> _showReminderSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Reminder Settings', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: morningReminder,
                      onChanged: (value) => setModalState(() => morningReminder = value),
                      title: const Text('Morning reminder'),
                      subtitle: const Text('07:00 AM'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: eveningReminder,
                      onChanged: (value) => setModalState(() => eveningReminder = value),
                      title: const Text('Evening reminder'),
                      subtitle: const Text('09:00 PM'),
                    ),
                    const SizedBox(height: 16),
                    GradientPillButton(
                      label: 'Save Reminder Settings',
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: AppColors.primaryDark),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
