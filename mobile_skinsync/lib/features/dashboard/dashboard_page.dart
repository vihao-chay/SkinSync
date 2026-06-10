import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final firstName = _firstName(appState.profileDisplayName);
    final analysis = appState.latestAnalysis;
    final regimen = appState.regimen;
    final tracking = appState.trackingToday;
    final morningSteps = regimen?.morning ?? const <RegimenStep>[];
    final eveningSteps = regimen?.evening ?? const <RegimenStep>[];
    final currentDate = DateTime.now();

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: appState.refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          12,
          AppSpacing.pagePadding,
          104,
        ),
        children: [
          _GreetingRow(name: firstName, avatarUrl: user?.avatarUrl),
          const SizedBox(height: 18),
          _DayStrip(currentDate: currentDate),
          const SizedBox(height: 16),
          _PrimaryPromptCard(
            overview: _overviewText(analysis?.overview),
            onTap: () => Navigator.pushNamed(context, AppRoutes.todayCheckup),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniInsightCard(
                  title: 'Index UV',
                  value: _uvIndexLabel(analysis),
                  subtitle: 'Do not forget to use SPF',
                  accent: const Color(0xFFD1EA8B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInsightCard(
                  title: 'SkinSync AI',
                  value: _quoteText(analysis),
                  subtitle: 'Small, steady progress matters.',
                  accent: const Color(0xFFF2C8D8),
                  isQuote: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _RoutineSummaryCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Morning Routine',
            timeLabel: _reminderLabel(appState.reminders, 'morning', '7:00 AM'),
            steps: morningSteps,
            completed: tracking?.morningCompleted ?? false,
            onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
          ),
          const SizedBox(height: 14),
          _RoutineSummaryCard(
            icon: Icons.nightlight_round_outlined,
            title: 'Evening Routine',
            timeLabel: _reminderLabel(appState.reminders, 'evening', '9:00 PM'),
            steps: eveningSteps,
            completed: tracking?.eveningCompleted ?? false,
            onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
            activeColor: const Color(0xFFF4D9E4),
          ),
          const SizedBox(height: 14),
          _ActionRow(
            onCheckup: () =>
                Navigator.pushNamed(context, AppRoutes.todayCheckup),
            onChat: () => Navigator.pushNamed(
              context,
              AppRoutes.aiChatConversation,
              arguments: const AiChatLaunchArgs(entryPoint: 'home'),
            ),
            onScan: () => Navigator.pushNamed(
              context,
              AppRoutes.upload,
            ),
            onProducts: () => Navigator.pushNamed(
              context,
              AppRoutes.aiProductRecommend,
              arguments: ProductsPageArgs(
                initialConcern: analysis?.issues.isNotEmpty == true
                    ? analysis!.issues.first.issueType
                    : 'any',
                referenceId: analysis?.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'there';
    }
    return parts.first;
  }

  static String _overviewText(String? overview) {
    final trimmed = overview?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Start your routine';
    }
    return trimmed;
  }

  static String _uvIndexLabel(AnalysisResult? analysis) {
    final score = analysis?.overallScore ?? 84;
    final uv = ((100 - score) / 12).clamp(2, 10).round();
    return '$uv/10';
  }

  static String _quoteText(AnalysisResult? analysis) {
    if (analysis?.warnings.isNotEmpty == true) {
      return '"Stay gentle and consistent while your skin calms down."';
    }
    return '"You are doing great. Keep going with the routine."';
  }

  static String _reminderLabel(
    List<ReminderItem> reminders,
    String type,
    String fallback,
  ) {
    for (final item in reminders) {
      if (item.routineType.toLowerCase().contains(type)) {
        return item.time;
      }
    }
    return fallback;
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: const Color(0xFFF3D8E8),
          backgroundImage: url == null || url.isEmpty
              ? null
              : NetworkImage(url),
          child: url == null || url.isEmpty
              ? Text(
                  name.isEmpty ? 'S' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Hi, $name',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'Day 2',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.currentDate});

  final DateTime currentDate;

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      6,
      (index) => currentDate.add(Duration(days: index)),
    );

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final day = items[index];
          final isActive = index >= 3;
          return Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFD1EA8B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekday(day.weekday),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 6),
                Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
      ),
    );
  }

  String _weekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }
}

class _PrimaryPromptCard extends StatelessWidget {
  const _PrimaryPromptCard({required this.overview, required this.onTap});

  final String overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How is your skin today?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD1EA8B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  const _MiniInsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    this.isQuote = false,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final bool isQuote;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQuote ? Icons.edit_note_rounded : Icons.wb_sunny_outlined,
                size: 18,
                color: AppColors.foreground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.mutedText),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_outward_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: isQuote ? 3 : 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (!isQuote)
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF0ED92),
                    Color(0xFFEFC1D8),
                    Color(0xFFE5A85B),
                  ],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          SizedBox(height: isQuote ? 0 : 12),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _RoutineSummaryCard extends StatelessWidget {
  const _RoutineSummaryCard({
    required this.icon,
    required this.title,
    required this.timeLabel,
    required this.steps,
    required this.completed,
    required this.onTap,
    this.activeColor = const Color(0xFFD1EA8B),
  });

  final IconData icon;
  final String title;
  final String timeLabel;
  final List<RegimenStep> steps;
  final bool completed;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final chips = steps.isEmpty
        ? const ['Cleanser', 'Serum', 'Moisturizer']
        : steps.map((step) => step.category).take(5).toList();

    return _SurfaceCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: completed ? activeColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    completed ? Icons.check_rounded : Icons.circle_outlined,
                    size: 20,
                    color: completed ? AppColors.foreground : AppColors.border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              timeLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((item) => _RoutineChip(label: _normalizeCategory(item)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeCategory(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return 'Step';
    }

    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }
}

class _RoutineChip extends StatelessWidget {
  const _RoutineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFF8D7D7),
      const Color(0xFFD8E9AF),
      const Color(0xFFF2D9E8),
      const Color(0xFFF4E79F),
    ];
    final color = colors[label.length % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onCheckup,
    required this.onChat,
    required this.onScan,
    required this.onProducts,
  });

  final VoidCallback onCheckup;
  final VoidCallback onChat;
  final VoidCallback onScan;
  final VoidCallback onProducts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 154,
          child: _ActionButton(
            label: 'Today Check-up',
            icon: Icons.checklist_rounded,
            onTap: onCheckup,
            accent: const Color(0xFFD1EA8B),
          ),
        ),
        SizedBox(
          width: 172,
          child: _ActionButton(
            label: 'Chat with SkinSync AI',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: onChat,
          ),
        ),
        SizedBox(
          width: 154,
          child: _ActionButton(
            label: 'Scan Skin',
            icon: Icons.auto_awesome_rounded,
            onTap: onScan,
          ),
        ),
        SizedBox(
          width: 154,
          child: _ActionButton(
            label: 'View Products',
            icon: Icons.shopping_bag_outlined,
            onTap: onProducts,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = Colors.white,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.foreground, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
