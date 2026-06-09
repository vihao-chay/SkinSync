import 'package:flutter/material.dart';

import '../../../core/mock/mock_skin_data.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/routine_step_card.dart';

class RoutineSection extends StatelessWidget {
  const RoutineSection({
    super.key,
    required this.steps,
    required this.completed,
    required this.onToggleStep,
    required this.onDetail,
    required this.editMode,
  });

  final List<RoutineStep> steps;
  final Set<int> completed;
  final void Function(int index) onToggleStep;
  final void Function(RoutineStep step) onDetail;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.mediumGap),
          child: RoutineStepCard(
            step: entry.value,
            index: entry.key,
            isCompleted: completed.contains(entry.key),
            editMode: editMode,
            onToggleComplete: () => onToggleStep(entry.key),
            onDetail: () => onDetail(entry.value),
          ),
        );
      }).toList(),
    );
  }
}
