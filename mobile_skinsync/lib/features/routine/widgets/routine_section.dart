import 'package:flutter/material.dart';

import '../../../core/mock/mock_skin_data.dart';
import '../../../core/widgets/routine_step_card.dart';

class RoutineSection extends StatelessWidget {
  const RoutineSection({
    super.key,
    required this.title,
    required this.steps,
    required this.completed,
    required this.onToggleStep,
    required this.onDetail,
  });

  final String title;
  final List<RoutineStep> steps;
  final Set<int> completed;
  final void Function(int index) onToggleStep;
  final void Function(RoutineStep step) onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RoutineStepCard(
                  step: entry.value,
                  index: entry.key,
                  isCompleted: completed.contains(entry.key),
                  onToggleComplete: () => onToggleStep(entry.key),
                  onDetail: () => onDetail(entry.value),
                ),
              ),
            ),
      ],
    );
  }
}
