import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
        16,
        AppSpacing.pagePadding,
        106,
      ),
      children: [
        _ProfileHeaderCard(
          name: appState.profileDisplayName,
          email: user?.email ?? '',
          skinType: profile?.skinType ?? 'No skin type yet',
          avatarUrl: user?.avatarUrl,
        ),
        const SizedBox(height: 14),
        _SummaryCard(
          skinType: profile?.skinType,
          dateOfBirth: profile?.dateOfBirth,
          gender: profile?.gender,
          concerns: profile?.concerns ?? const [],
          goals: profile?.goals ?? const [],
          budget: profile?.budgetLabel,
        ),
        const SizedBox(height: 14),
        _LogoutCard(onTap: () => context.read<AppState>().logout()),
      ],
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

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.secondary,
            backgroundImage: url == null || url.isEmpty
                ? null
                : NetworkImage(url),
            child: url == null || url.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.primaryDark,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              skinType,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.skinType,
    required this.dateOfBirth,
    required this.gender,
    required this.concerns,
    required this.goals,
    required this.budget,
  });

  final String? skinType;
  final String? dateOfBirth;
  final String? gender;
  final List<String> concerns;
  final List<String> goals;
  final String? budget;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skin Profile Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.border.withValues(alpha: 0.35), height: 1),
          const SizedBox(height: 14),
          _SummaryRow(label: 'SKIN TYPE', value: _empty(skinType)),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'DATE OF BIRTH',
            value: _formatDateOfBirth(dateOfBirth),
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'GENDER', value: _formatGender(gender)),
          const SizedBox(height: 14),
          _SummaryRow(label: 'CONCERNS', value: _listValue(concerns)),
          const SizedBox(height: 14),
          _SummaryRow(label: 'GOALS', value: _listValue(goals)),
          const SizedBox(height: 14),
          _SummaryRow(label: 'BUDGET', value: _empty(budget)),
        ],
      ),
    );
  }

  String _empty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _listValue(List<String> values) {
    final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
    return cleaned.isEmpty ? '-' : cleaned.join(', ');
  }

  String _formatDateOfBirth(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return '-';
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
        return _empty(value);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.foreground,
            fontSize: 10,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.mutedText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 17,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Logout',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
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
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
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

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
