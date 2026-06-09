import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final weekDays = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Stack(
      children: [
        ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            AppSpacing.pagePadding,
            140,
          ),
          children: [
            Text('Your Progress', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'See how your routine consistency is shaping your skin journey.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: _SummaryMetric(title: 'Completion', value: '86%')),
                      SizedBox(width: 12),
                      Expanded(child: _SummaryMetric(title: 'Streak', value: '12 days')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: const LinearProgressIndicator(
                      value: 0.86,
                      minHeight: 10,
                      backgroundColor: AppColors.secondary,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('This Week', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final selected = index == 3;
                  final complete = index < 5;
                  return Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.secondary : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(weekDays[index], style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: complete ? AppColors.primary : AppColors.secondary,
                          child: Icon(
                            complete ? Icons.check_rounded : Icons.remove_rounded,
                            size: 14,
                            color: complete ? Colors.white : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Skin Trend', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  const _TrendRow(label: 'Acne improved', value: '+18%'),
                  const SizedBox(height: 10),
                  const _TrendRow(label: 'Hydration stable', value: '4/5'),
                  const SizedBox(height: 10),
                  const _TrendRow(label: 'Redness reduced', value: '-12%'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('Daily Logs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...MockSkinData.progressLogs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.date, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(log.skinFeeling, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _LogTag(label: 'Acne ${log.acneLevel}'),
                          _LogTag(label: 'Hydration ${log.hydration}'),
                        ],
                      ),
                    ],
                  ),
                ),
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
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
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
                  Text('Add Daily Log', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const AppTextField(label: 'How does your skin feel?', hint: 'Calm, balanced, dry...'),
                  const SizedBox(height: 12),
                  const AppTextField(label: 'Acne level', hint: '2/5'),
                  const SizedBox(height: 12),
                  const AppTextField(label: 'Hydration', hint: '4/5'),
                  const SizedBox(height: 12),
                  const AppTextField(label: 'Notes', hint: 'What changed today?', maxLines: 3),
                  const SizedBox(height: 20),
                  GradientPillButton(
                    label: 'Save Daily Log',
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(),
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

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryDark,
              ),
        ),
      ],
    );
  }
}

class _LogTag extends StatelessWidget {
  const _LogTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
