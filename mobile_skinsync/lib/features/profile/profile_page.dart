import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final profile = appState.profile;

    return AppScaffold(
      title: 'Profile',
      subtitle:
          'Your personal skin profile, concerns, and preferences in one premium summary.',
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.bottomNavHeight + 64,
        ),
        children: [
          _ProfileHeaderCard(
            name: appState.profileDisplayName,
            email: _friendlyText(user?.email),
            skinType: _friendlyText(profile?.skinType),
            avatarUrl: user?.avatarUrl,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Skin profile summary',
            subtitle:
                'The information SkinSync uses to personalize analysis, routine, and product suggestions.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Skin type', value: _friendlyText(profile?.skinType)),
                _SummaryRow(
                  label: 'Date of birth',
                  value: _formatDateOfBirth(profile?.dateOfBirth),
                ),
                _SummaryRow(label: 'Gender', value: _formatGender(profile?.gender)),
                _SummaryRow(
                  label: 'Concerns',
                  value: _listValue(profile?.concerns ?? const []),
                ),
                _SummaryRow(
                  label: 'Goals',
                  value: _listValue(profile?.goals ?? const []),
                ),
                _SummaryRow(
                  label: 'Budget',
                  value: _friendlyText(profile?.budgetLabel),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            title: 'Care preferences',
            subtitle:
                'Additional signals that help SkinSync keep recommendations gentle and relevant.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Allergies',
                  value: _listValue(profile?.allergies ?? const []),
                ),
                _SummaryRow(
                  label: 'Avoid ingredients',
                  value: _listValue(profile?.avoidIngredients ?? const []),
                ),
                _SummaryRow(
                  label: 'Skin goals',
                  value: _listValue(profile?.skinGoals ?? const []),
                ),
                _SummaryRow(
                  label: 'Sensitivity level',
                  value: profile?.sensitivityLevel == null
                      ? 'Not provided yet'
                      : '${profile!.sensitivityLevel}/10',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign out safely whenever you need to switch accounts.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Logout',
                  variant: AppButtonVariant.danger,
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => context.read<AppState>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.email,
    required this.skinType,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String skinType;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    return AppCard(
      backgroundColor: AppColors.surfaceStrong,
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withValues(alpha: 0.85),
            backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
            child: url == null || url.isEmpty
                ? Text(
                    name.isEmpty ? 'S' : name[0].toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              skinType,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!isLast) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: AppColors.border.withValues(alpha: 0.7), height: 1),
          ],
        ],
      ),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}

String _listValue(List<String> values) {
  final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
  return cleaned.isEmpty ? 'Not provided yet' : cleaned.join(', ');
}

String _formatDateOfBirth(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Not provided yet';
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return trimmed;
  }

  return DateFormat('dd/MM/yyyy').format(parsed);
}

String _formatGender(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'male':
      return 'Male';
    case 'female':
      return 'Female';
    case 'other':
      return 'Other';
    case 'prefernotosay':
    case 'prefer_not_to_say':
    case 'prefer not to say':
      return 'Prefer not to say';
    default:
      return _friendlyText(value);
  }
}
