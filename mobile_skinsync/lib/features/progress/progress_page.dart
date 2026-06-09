import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final progress = appState.progress;
    final log = appState.todayLog;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            140,
          ),
          children: [
            Text('Your Progress', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current score', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  Text('${progress?.currentScore ?? 0}', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text('Streak: ${progress?.currentStreak ?? 0} days'),
                  const SizedBox(height: 6),
                  Text('Improvement: ${progress?.improvementPercent?.toStringAsFixed(1) ?? '0.0'}%'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insight', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(progress?.progressInsight ?? 'Track more activity to unlock stronger insights.'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today log', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(log?.skinFeeling ?? 'No log yet'),
                  if ((log?.notes ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(log!.notes!),
                  ],
                  const SizedBox(height: 10),
                  Text('Acne: ${log?.acneLevel ?? '-'}'),
                  Text('Hydration: ${log?.hydrationLevel ?? '-'}'),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              onPressed: () => _showAddLogSheet(context),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddLogSheet(BuildContext context) async {
    final skinFeelingController = TextEditingController();
    final acneController = TextEditingController();
    final hydrationController = TextEditingController();
    final notesController = TextEditingController();
    final appState = context.read<AppState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Daily Log', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  AppTextField(label: 'How does your skin feel?', controller: skinFeelingController),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Acne level (0-100)', controller: acneController, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Hydration level (0-100)', controller: hydrationController, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Notes', controller: notesController, maxLines: 3),
                  const SizedBox(height: 20),
                  GradientPillButton(
                    label: 'Save Daily Log',
                    expanded: true,
                    onPressed: () async {
                      await appState.saveDailyLog(
                        skinFeeling: skinFeelingController.text.trim(),
                        notes: notesController.text.trim(),
                        acneLevel: int.tryParse(acneController.text) ?? 0,
                        hydrationLevel: int.tryParse(hydrationController.text) ?? 0,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
