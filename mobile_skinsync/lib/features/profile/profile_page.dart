import 'package:flutter/material.dart';

import '../../core/mock/mock_skin_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/premium_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
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
              Text(MockSkinData.user.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(MockSkinData.user.email, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  MockSkinData.user.skinType,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primaryDark,
                      ),
                ),
              ),
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
              _SummaryRow(label: 'Skin type', value: MockSkinData.user.skinType),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Concerns', value: MockSkinData.user.concerns.join(', ')),
              const SizedBox(height: 10),
              _SummaryRow(label: 'Goals', value: MockSkinData.user.goal),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        ...const [
          _MenuCard(
            title: 'Edit Profile',
            subtitle: 'Update your personal and skin details',
            icon: Icons.edit_outlined,
          ),
          _MenuCard(
            title: 'Analysis History',
            subtitle: 'Review previous AI scan results',
            icon: Icons.history_rounded,
          ),
          _MenuCard(
            title: 'Reminders',
            subtitle: 'Manage morning and evening alerts',
            icon: Icons.notifications_outlined,
          ),
          _MenuCard(
            title: 'Settings',
            subtitle: 'Preferences, language, and app behavior',
            icon: Icons.settings_outlined,
          ),
          _MenuCard(
            title: 'Help Center',
            subtitle: 'FAQs and support for your skincare journey',
            icon: Icons.help_outline_rounded,
          ),
          _MenuCard(
            title: 'Logout',
            subtitle: 'End the current session',
            icon: Icons.logout_rounded,
            destructive: true,
          ),
        ],
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
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.destructive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? AppColors.error : AppColors.foreground;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: destructive ? AppColors.error.withValues(alpha: 0.1) : AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: destructive ? AppColors.error : AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.subtleText),
          ],
        ),
      ),
    );
  }
}
