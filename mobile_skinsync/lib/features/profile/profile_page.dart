import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';

const _paymentQrAsset = 'bank.jpg';

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
      onRefresh: appState.refreshProfileState,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPadding,
        ),
        children: [
          _ProfileHeaderCard(
            name: appState.profileDisplayName,
            email: _friendlyText(user?.email),
            skinType: _friendlyText(profile?.skinType),
            avatarUrl: user?.avatarUrl,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _SubscriptionCard(
            plans: appState.subscriptionPlans,
            current: appState.subscription,
            fallbackPlanCode: user?.planType ?? 'free',
            isBusy: appState.isBusy,
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
                _SummaryRow(
                  label: 'Skin type',
                  value: _friendlyText(profile?.skinType),
                ),
                _SummaryRow(
                  label: 'Date of birth',
                  value: _formatDateOfBirth(profile?.dateOfBirth),
                ),
                _SummaryRow(
                  label: 'Gender',
                  value: _formatGender(profile?.gender),
                ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sign out safely whenever you need to switch accounts.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
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

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.plans,
    required this.current,
    required this.fallbackPlanCode,
    required this.isBusy,
  });

  final List<SubscriptionPlan> plans;
  final CurrentSubscription? current;
  final String fallbackPlanCode;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final currentCode = (current?.plan.code ?? fallbackPlanCode).toLowerCase();
    final visiblePlans = plans
        .where((plan) => plan.code == 'plus' || plan.code == 'premium')
        .toList();
    final currentPlan =
        current?.plan ??
        plans.cast<SubscriptionPlan?>().firstWhere(
          (plan) => plan?.code == currentCode,
          orElse: () => null,
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.aiSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.ai,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membership',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_planName(currentPlan, currentCode)} plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _planPrice(currentPlan),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if ((current?.usage ?? const []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: current!.usage
                  .where((item) => _isPrimaryUsage(item.featureKey))
                  .map((item) => _UsageChip(usage: item))
                  .toList(),
            ),
          ],
          if (visiblePlans.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ...visiblePlans.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlanOption(
                  plan: plan,
                  isCurrent: currentCode == plan.code,
                  isBusy: isBusy,
                  onSubscribe: () => _subscribe(context, plan),
                ),
              ),
            ),
          ],
          if (currentCode != 'free') ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel to Free',
              variant: AppButtonVariant.secondary,
              icon: const Icon(Icons.close_rounded),
              isLoading: isBusy,
              onPressed: isBusy ? null : () => _cancel(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, SubscriptionPlan plan) async {
    final shouldActivate = await _showPaymentDialog(context, plan);
    if (!shouldActivate || !context.mounted) {
      return;
    }

    try {
      await context.read<AppState>().subscribeToPlan(plan.code);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_capitalize(plan.code)} activated.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().errorMessage ??
                  'Could not update subscription.',
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showPaymentDialog(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Pay for ${plan.name}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _planPrice(plan),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 260),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: AspectRatio(
                      aspectRatio: 397 / 500,
                      child: Image.asset(
                        _paymentQrAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            'Payment image unavailable',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Scan this QR and complete the transfer, then confirm below to activate your plan.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('I paid'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _cancel(BuildContext context) async {
    try {
      await context.read<AppState>().cancelSubscription();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Plan changed to Free.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().errorMessage ??
                  'Could not cancel subscription.',
            ),
          ),
        );
      }
    }
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.plan,
    required this.isCurrent,
    required this.isBusy,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isBusy;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.surfaceStrong : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _planPrice(plan),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          AppButton(
            label: isCurrent ? 'Active' : 'Choose',
            expand: false,
            variant: isCurrent
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            icon: Icon(
              isCurrent ? Icons.check_rounded : Icons.arrow_upward_rounded,
            ),
            isLoading: isBusy && !isCurrent,
            onPressed: isCurrent || isBusy ? null : onSubscribe,
          ),
        ],
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  const _UsageChip({required this.usage});

  final SubscriptionUsage usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: usage.isEnabled ? AppColors.cream : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Text(
        '${_shortFeatureName(usage.displayName)} ${_usageValue(usage)}',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: usage.isEnabled ? AppColors.primaryDark : AppColors.subtleText,
          fontWeight: FontWeight.w700,
        ),
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
            backgroundImage: url == null || url.isEmpty
                ? null
                : NetworkImage(url),
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
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
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
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.primaryDark),
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
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

bool _isPrimaryUsage(String featureKey) {
  switch (featureKey) {
    case 'skin_analysis':
    case 'ai_chat':
    case 'routine_generation':
    case 'ingredient_check':
    case 'conflict_check':
    case 'progress_entry':
    case 'skin_progress_compare':
      return true;
    default:
      return false;
  }
}

String _planName(SubscriptionPlan? plan, String fallbackCode) {
  if (plan != null && plan.name.trim().isNotEmpty) {
    return plan.name;
  }

  return _capitalize(fallbackCode);
}

String _planPrice(SubscriptionPlan? plan) {
  if (plan == null || plan.priceVnd <= 0) {
    return 'Free';
  }

  final formatter = NumberFormat.decimalPattern('vi_VN');
  return '${formatter.format(plan.priceVnd.round())} VND/mo';
}

String _usageValue(SubscriptionUsage usage) {
  if (!usage.isEnabled) {
    return 'Locked';
  }
  if (usage.isUnlimited) {
    return '${usage.used}/Unlimited';
  }
  if (usage.monthlyLimit == null) {
    return 'Included';
  }
  return '${usage.used}/${usage.monthlyLimit}';
}

String _shortFeatureName(String value) {
  return value
      .replaceAll('Skin Analysis', 'Scan')
      .replaceAll('Routine Generator', 'Routine')
      .replaceAll('Ingredient Check', 'Ingredient')
      .replaceAll('Conflict Check', 'Conflict')
      .replaceAll('Progress Entries', 'Progress')
      .replaceAll('Before/After Compare', 'Compare');
}

String _capitalize(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Free';
  }

  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}
