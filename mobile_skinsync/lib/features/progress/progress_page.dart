import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/user_shell.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserShell(
      currentRoute: AppRoutes.progress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skin Progress', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Track completion, logs, and trend surfaces before real chart packages are introduced.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          PremiumCard(
            child: Row(
              children: [
                const Expanded(child: _ProgressStat(title: 'Weekly completion', value: '86%')),
                const SizedBox(width: 12),
                const Expanded(child: _ProgressStat(title: 'Monthly consistency', value: '21 days')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress Chart Mock', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...[48, 62, 58, 74, 82].map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: value / 100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFC4A882), Color(0xFF8C6E52)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('$value%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Logs', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...MockSkinData.progressLogs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(log.date),
                      subtitle: Text('${log.skinFeeling} - Acne ${log.acneLevel} - Hydration ${log.hydration}'),
                      leading: const CircleAvatar(child: Icon(Icons.calendar_today_outlined, size: 18)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GradientPillButton(label: 'Add Daily Log', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}
