import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/premium_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final profile = appState.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        120,
      ),
      children: [
        PremiumCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.softPink,
                child: Icon(Icons.person_rounded, size: 36, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 12),
              Text(user?.fullName ?? 'SkinSync user', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Text(profile?.skinType ?? 'No skin type yet'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Skin Profile Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              _SummaryRow(label: 'Skin type', value: profile?.skinType ?? '-'),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Concerns', value: (profile?.concerns ?? const []).join(', ')),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Goals', value: (profile?.goals ?? const []).join(', ')),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Budget', value: profile?.budgetLabel ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        PremiumCard(
          onTap: () => context.read<AppState>().logout(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '-' : value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
