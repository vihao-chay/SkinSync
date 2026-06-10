import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_header.dart';

class AiConflictCheckPage extends StatefulWidget {
  const AiConflictCheckPage({super.key});

  @override
  State<AiConflictCheckPage> createState() => _AiConflictCheckPageState();
}

class _AiConflictCheckPageState extends State<AiConflictCheckPage> {
  AiRoutineConflictCheckResponse? _result;
  bool _loading = false;

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<AppState>().checkRoutineConflicts();
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRoutine = context.watch<AppState>().regimen != null;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const GlassHeader(
        currentRoute: '/ai/conflict-check',
        title: 'Conflict Check',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (!hasRoutine)
            _EmptyCard(
              title: 'No active routine yet',
              body: 'Generate a routine first so the backend can evaluate conflicts from your current steps.',
              actionLabel: 'Open routine',
              onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
            )
          else ...[
            FilledButton(
              onPressed: _loading ? null : _check,
              child: Text(_loading ? 'Checking...' : 'Check current routine'),
            ),
            const SizedBox(height: 16),
            if (_result != null)
              _ResultCard(result: _result!)
            else
              const _EmptyCard(
                title: 'Ready to scan your routine',
                body: 'This uses `/api/ai/routine/conflict-check` and shows conflicts plus overall advice you can act on directly.',
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final AiRoutineConflictCheckResponse result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.hasConflict ? 'Conflicts found' : 'No high-risk conflicts found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(result.overallAdvice),
          if (result.conflicts.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...result.conflicts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${item.ingredientA} + ${item.ingredientB}\n${item.reason}\nAdvice: ${item.recommendation}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onTap,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
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
          Text(body),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
