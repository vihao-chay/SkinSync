import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/user_shell.dart';
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
  TimeOfDay morningTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay eveningTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  Widget build(BuildContext context) {
    final steps = morning ? MockSkinData.morningRoutine : MockSkinData.eveningRoutine;
    final completed = morning ? completedMorning : completedEvening;

    return UserShell(
      currentRoute: AppRoutes.routine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Skincare Routine', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Switch between morning and evening, mark steps done, and preview routine editing UI.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Morning'),
                selected: morning,
                onSelected: (_) => setState(() => morning = true),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Evening'),
                selected: !morning,
                onSelected: (_) => setState(() => morning = false),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => setState(() => editMode = !editMode),
                icon: Icon(editMode ? Icons.visibility_outlined : Icons.edit_outlined),
                label: Text(editMode ? 'View Mode' : 'Edit Mode'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PremiumCard(
            child: Row(
              children: [
                const Expanded(child: Text('Reminder settings')),
                OutlinedButton(
                  onPressed: _showReminderSheet,
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          RoutineSection(
            title: morning ? 'Morning Routine' : 'Evening Routine',
            steps: steps,
            completed: completed,
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
              builder: (_) => ProductDetailSheet(step: step),
            ),
          ),
          if (editMode) ...[
            const SizedBox(height: 16),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Mode Preview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    'TODO: wire reorder, delete confirmation, and persistent routine editing to API later.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Expanded(child: _EditAction(label: 'Add Step')),
                      SizedBox(width: 10),
                      Expanded(child: _EditAction(label: 'Reorder')),
                      SizedBox(width: 10),
                      Expanded(child: _EditAction(label: 'Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          GradientPillButton(label: 'Save Routine UI State', onPressed: () {}),
        ],
      ),
    );
  }

  Future<void> _showReminderSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: morningReminder,
                      onChanged: (value) => setModalState(() => morningReminder = value),
                      title: const Text('Morning reminder'),
                      subtitle: Text(_formatTime(morningTime)),
                    ),
                    SwitchListTile(
                      value: eveningReminder,
                      onChanged: (value) => setModalState(() => eveningReminder = value),
                      title: const Text('Evening reminder'),
                      subtitle: Text(_formatTime(eveningTime)),
                    ),
                    const SizedBox(height: 12),
                    GradientPillButton(
                      label: 'Save Reminder Settings',
                      expanded: true,
                      onPressed: () => Navigator.pop(context),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }
}

class _EditAction extends StatelessWidget {
  const _EditAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label),
    );
  }
}
