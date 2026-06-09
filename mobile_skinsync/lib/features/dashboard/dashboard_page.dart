import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/gradient_pill_button.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/skin_chip.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final name = appState.user?.fullName ?? 'bạn';
    final firstName = _firstName(name);
    final analysis = appState.latestAnalysis;
    final overview = analysis?.overview ?? '';
    final tracking = appState.trackingToday;
    final concerns = _normalizedConcerns(appState.profile?.concerns ?? const <String>[]);
    final routineCompleted = tracking?.completedSteps ?? 0;
    final routineTotal = tracking?.totalSteps ?? 0;
    final progressValue = routineTotal == 0 ? 0.0 : (routineCompleted / routineTotal).clamp(0.0, 1.0);

    return RefreshIndicator(
      onRefresh: appState.refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.pagePadding,
          AppSpacing.pagePadding,
          120,
        ),
        children: [
          _HeroCard(
            name: firstName,
            analysis: analysis,
            overview: overview,
            onAnalyze: () => Navigator.pushNamed(context, AppRoutes.analysis),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Chat với SkinDex',
                  subtitle: 'Hỏi nhanh về da, routine và sản phẩm.',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.analysis),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  title: 'Sản phẩm phù hợp',
                  subtitle: 'Xem routine và sản phẩm đang dùng.',
                  icon: Icons.camera_alt_outlined,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _SectionHeader(
            title: 'Skin concerns',
            actionLabel: concerns.isEmpty ? 'Cập nhật hồ sơ' : null,
            onAction: concerns.isEmpty ? () => Navigator.pushNamed(context, AppRoutes.profile) : null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concerns.isEmpty
                ? [
                    const SkinChip(label: 'No concerns yet', icon: Icons.sentiment_satisfied_rounded),
                  ]
                : concerns.map((concern) => SkinChip(label: concern)).toList(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Daily skin check-in', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    const Icon(Icons.today_outlined, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hôm nay da bạn thế nào?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _FeelingChip(label: 'Ổn định'),
                    _FeelingChip(label: 'Khô'),
                    _FeelingChip(label: 'Dầu'),
                    _FeelingChip(label: 'Mụn'),
                    _FeelingChip(label: 'Kích ứng'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Routine hôm nay', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    Text(
                      '${tracking?.completedSteps ?? 0}/${tracking?.totalSteps ?? 0}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Morning routine: ${tracking?.morningCompleted == true ? 'đã xong' : 'chưa xong'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: progressValue,
                    backgroundColor: AppColors.secondary,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                GradientPillButton(
                  label: 'Xem routine',
                  expanded: true,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.routine),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'Bạn';
    }
    return parts.first;
  }

  List<String> _normalizedConcerns(List<String> concerns) {
    if (concerns.isEmpty) {
      return concerns;
    }

    final mapped = concerns
        .map((item) {
          switch (item.toLowerCase()) {
            case 'acne':
              return 'Acne';
            case 'oilyskin':
            case 'oily_skin':
            case 'oily':
              return 'Oily skin';
            case 'dryskin':
            case 'dry_skin':
            case 'dry':
              return 'Dryness';
            case 'sensitiveskin':
            case 'sensitive_skin':
            case 'sensitive':
              return 'Sensitive skin';
            case 'darkspots':
            case 'dark_spots':
              return 'Dark spots';
            case 'redness':
              return 'Redness';
            default:
              return item;
          }
        })
        .toSet()
        .toList();

    return mapped;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.analysis,
    required this.overview,
    required this.onAnalyze,
  });

  final String name;
  final dynamic analysis;
  final String overview;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F4FF), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFF5A4B6),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'K',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Badge(label: 'Premium', icon: Icons.diamond_rounded, outlined: true),
                  const Spacer(),
                  _Badge(label: '1', icon: Icons.local_fire_department_rounded, compact: true),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.94),
                    child: const Icon(Icons.notifications_none_rounded, color: AppColors.foreground),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '$greeting, $name',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 8),
              Text(
                'Hôm nay da bạn thế nào?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (overview.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  overview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
              ],
              const SizedBox(height: 18),
              GradientPillButton(
                label: 'Phân tích da với AI',
                expanded: true,
                onPressed: onAnalyze,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: SizedBox(
        height: 128,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 24),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: AppColors.primary)),
          ),
      ],
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primaryDark)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    this.compact = false,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final bool compact;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 10),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: outlined ? 0.9 : 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: compact ? AppColors.warning : AppColors.error),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
