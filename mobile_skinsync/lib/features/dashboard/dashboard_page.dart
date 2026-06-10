import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final firstName = _firstName(user?.fullName ?? 'Dan');
    final analysis = appState.latestAnalysis;
    final concerns = _normalizedConcerns(
      appState.profile?.concerns ?? const <String>[],
    );

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
          _HomeTopBar(name: firstName, avatarUrl: user?.avatarUrl),
          const SizedBox(height: 24),
          Text(
            'Good morning, $firstName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 18),
          _HeroCard(
            score: analysis?.overallScore ?? 100,
            overview: _overviewText(analysis?.overview),
            onAnalyze: () => Navigator.pushNamed(context, AppRoutes.analysis),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'Chat with\nSkinDex',
                  subtitle:
                      'Quick questions about skin, routine, and products.',
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.analysis),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  title: 'Perfect\nProducts',
                  subtitle: 'View your routine and current products.',
                  icon: Icons.camera_alt_outlined,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.routine),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'Skin concerns',
            actionLabel: 'Update profile',
            onAction: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: concerns.isEmpty
                ? const [
                    _ConcernChip(
                      label: 'No concerns yet',
                      icon: Icons.sentiment_satisfied_alt_rounded,
                    ),
                  ]
                : concerns
                      .map((concern) => _ConcernChip(label: concern))
                      .toList(),
          ),
        ],
      ),
    );
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return 'Dan';
    }
    return parts.first;
  }

  static String _overviewText(String? overview) {
    final trimmed = overview?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'balanced overall condition.';
    }
    return trimmed.endsWith('.') ? trimmed : '$trimmed.';
  }

  static List<String> _normalizedConcerns(List<String> concerns) {
    if (concerns.isEmpty) {
      return concerns;
    }

    return concerns
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
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(name: name, avatarUrl: avatarUrl),
        const SizedBox(width: 10),
        const _StatusPill(
          label: 'Premium',
          icon: Icons.diamond_rounded,
          iconColor: AppColors.primaryDark,
        ),
        const Spacer(),
        const _StatusPill(
          label: '1',
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.warning,
          compact: true,
        ),
        const SizedBox(width: 8),
        const _CircleIcon(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.softPink,
      backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
      child: url == null || url.isEmpty
          ? Text(
              name.isEmpty ? 'D' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.iconColor,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.52)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
      ),
      child: Icon(icon, color: AppColors.foreground, size: 18),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.score,
    required this.overview,
    required this.onAnalyze,
  });

  final int score;
  final String overview;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How is your skin\ntoday?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Skin score $score/100 with $overview',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkPanel,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: onAnalyze,
              child: const Text('Analyze skin with AI'),
            ),
          ),
        ],
      ),
    );
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
    return _SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 142,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconTile(icon: icon),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: const Color(0xFF5655C7), size: 19),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: const Size(0, 32),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _ConcernChip extends StatelessWidget {
  const _ConcernChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
