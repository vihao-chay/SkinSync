import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_pill_button.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final progress = appState.progress;
    final log = appState.todayLog;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: appState.refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              26,
              AppSpacing.pagePadding,
              118,
            ),
            children: [
              Text(
                'Your Progress',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 22),
              _ScoreCard(
                score: progress?.currentScore ?? 100,
                streak: progress?.currentStreak ?? 0,
                improvement: progress?.improvementPercent ?? 0,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Insight',
                body:
                    progress?.progressInsight ??
                    'Over your tracked period, your skin score has stayed stable. You completed routine tracking on 1 of the last 28 days.',
              ),
              const SizedBox(height: 16),
              _TodayLogCard(
                skinFeeling: log?.skinFeeling,
                notes: log?.notes,
                acne: log?.acneLevel,
                hydration: log?.hydrationLevel,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                icon: Icons.eco_outlined,
                title: 'Daily Tip',
                body:
                    progress?.dailyTip ??
                    'Your skin often improves with consistency; try completing both morning and evening steps today.',
              ),
            ],
          ),
        ),
        Positioned(
          right: 24,
          bottom: 22,
          child: FloatingActionButton(
            heroTag: 'progress-add-log',
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: const CircleBorder(),
            onPressed: () => _showAddLogSheet(context),
            child: const Icon(Icons.add_rounded),
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
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Add Daily Log',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'How does your skin feel?',
                    controller: skinFeelingController,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Acne level (0-100)',
                    controller: acneController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Hydration level (0-100)',
                    controller: hydrationController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Notes',
                    controller: notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  GradientPillButton(
                    label: 'Save Daily Log',
                    expanded: true,
                    onPressed: () async {
                      await appState.saveDailyLog(
                        skinFeeling: skinFeelingController.text.trim(),
                        notes: notesController.text.trim(),
                        acneLevel: int.tryParse(acneController.text) ?? 0,
                        hydrationLevel:
                            int.tryParse(hydrationController.text) ?? 0,
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

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.streak,
    required this.improvement,
  });

  final int score;
  final int streak;
  final double improvement;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT SCORE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: AppColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF35D66B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Streak: $streak days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Improvement: ${improvement.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TinyIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.foreground,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  const _TodayLogCard({
    required this.skinFeeling,
    required this.notes,
    required this.acne,
    required this.hydration,
  });

  final String? skinFeeling;
  final String? notes;
  final int? acne;
  final int? hydration;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            top: 6,
            child: Icon(
              Icons.calendar_month_outlined,
              size: 58,
              color: AppColors.border.withValues(alpha: 0.32),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Log",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Text(
                skinFeeling?.trim().isNotEmpty == true
                    ? skinFeeling!
                    : 'No log yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedText,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  notes!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.foreground),
                ),
              ],
              const SizedBox(height: 18),
              _LogMetric(label: 'Acne', value: acne?.toString() ?? '-'),
              const SizedBox(height: 12),
              _LogMetric(
                label: 'Hydration',
                value: hydration?.toString() ?? '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogMetric extends StatelessWidget {
  const _LogMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _TinyIcon extends StatelessWidget {
  const _TinyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: AppColors.primaryDark),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
