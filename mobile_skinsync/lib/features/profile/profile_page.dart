import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/membership_usage_card.dart';
import '../../core/widgets/profile_header_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_chip.dart';

const _paymentQrAsset = 'bank.jpg';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final profile = appState.profile;

    return AppScaffold(
      title: 'Skin Profile',
      subtitle: 'Your skin details, preferences, and membership in one polished summary.',
      onRefresh: appState.refreshProfileState,
      compactHeader: true,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.pageBottomPaddingWithActions,
        ),
        children: [
          ProfileHeaderCard(
            name: appState.profileDisplayName,
            email: _friendlyText(user?.email),
            skinType: _friendlyText(profile?.skinType),
            avatarUrl: user?.avatarUrl,
            onEdit: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _SubscriptionSection(
            plans: appState.subscriptionPlans,
            current: appState.subscription,
            fallbackPlanCode: user?.planType ?? 'free',
            isBusy: appState.isBusy,
            errorMessage: appState.membershipLoadErrorMessage,
            onRetry: appState.refreshSubscription,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          SectionHeader(
            icon: Icons.badge_outlined,
            title: 'Skin profile summary',
            subtitle: 'Compact fields SkinSync uses for routines, products, and analysis.',
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileInfoGrid(
            items: [
              _ProfileInfoItem(label: 'Skin type', value: _friendlyText(profile?.skinType)),
              _ProfileInfoItem(label: 'Gender', value: _formatGender(profile?.gender)),
              _ProfileInfoItem(label: 'Date of birth', value: _formatDateOfBirth(profile?.dateOfBirth)),
              _ProfileInfoItem(label: 'Budget', value: _friendlyText(profile?.budgetLabel)),
              _ProfileInfoItem(
                label: 'Sensitivity',
                value: profile?.sensitivityLevel == null ? 'Not provided yet' : '${profile!.sensitivityLevel}/10',
                emphasizeValue: profile?.sensitivityLevel != null,
              ),
              _ProfileInfoItem(label: 'Routine level', value: _friendlyText(profile?.currentRoutineLevel)),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'Concerns & goals',
                  subtitle: 'Short chips are easier to scan than long vertical lists.',
                ),
                const SizedBox(height: AppSpacing.md),
                _ChipSection(label: 'Concerns', values: profile?.concerns ?? const []),
                const SizedBox(height: AppSpacing.md),
                _ChipSection(
                  label: 'Goals',
                  values: profile?.goals.isNotEmpty == true ? profile!.goals : profile?.skinGoals ?? const [],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.favorite_border_rounded,
                  title: 'Care preferences',
                  subtitle: 'Signals that help recommendations stay gentle and relevant.',
                ),
                const SizedBox(height: AppSpacing.md),
                _ChipSection(label: 'Allergies', values: profile?.allergies ?? const []),
                const SizedBox(height: AppSpacing.md),
                _ChipSection(label: 'Avoid ingredients', values: profile?.avoidIngredients ?? const []),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          AppCard(
            variant: AppCardVariant.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  icon: Icons.logout_rounded,
                  title: 'Account actions',
                  subtitle: 'Sign out safely whenever you need to switch accounts.',
                ),
                const SizedBox(height: AppSpacing.md),
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

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({
    required this.plans,
    required this.current,
    required this.fallbackPlanCode,
    required this.isBusy,
    required this.errorMessage,
    required this.onRetry,
  });

  final List<SubscriptionPlan> plans;
  final CurrentSubscription? current;
  final String fallbackPlanCode;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final currentCode = (current?.plan.code ?? fallbackPlanCode).toLowerCase();
    final visiblePlans = plans.where((plan) => plan.code == 'plus' || plan.code == 'premium').toList();
    final currentPlan = current?.plan ??
        plans.cast<SubscriptionPlan?>().firstWhere(
              (plan) => plan?.code == currentCode,
              orElse: () => null,
            );

    return Column(
      children: [
        if (errorMessage != null) ...[
          ErrorStateCard(
            title: 'Membership data could not load',
            description: errorMessage!,
            ctaLabel: 'Try again',
            onCta: onRetry,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        MembershipUsageCard(
          planName: _planName(currentPlan, currentCode),
          planCode: currentCode,
          priceLabel: _planPrice(currentPlan),
          usage: (current?.usage ?? const []).where(_isPrimaryUsage).toList(),
          showUpgrade: currentCode == 'free',
          onUpgrade: () {
            if (visiblePlans.isNotEmpty) {
              _subscribe(context, visiblePlans.first);
            }
          },
        ),
        if (visiblePlans.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
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
              context.read<AppState>().errorMessage ?? 'Could not update subscription.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancel(BuildContext context) async {
    try {
      await context.read<AppState>().cancelSubscription();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan changed to Free.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<AppState>().errorMessage ?? 'Could not cancel subscription.',
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showPaymentDialog(BuildContext context, SubscriptionPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return AlertDialog(
          title: Text('Pay for ${plan.name}'),
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
                            style: textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
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
    return AppCard(
      variant: isCurrent ? AppCardVariant.accent : AppCardVariant.metric,
      padding: const EdgeInsets.all(14),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          AppButton(
            label: isCurrent ? 'Active' : 'Choose',
            expand: false,
            variant: isCurrent ? AppButtonVariant.secondary : AppButtonVariant.primary,
            icon: Icon(isCurrent ? Icons.check_rounded : Icons.arrow_upward_rounded),
            isLoading: isBusy && !isCurrent,
            onPressed: isCurrent || isBusy ? null : onSubscribe,
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoGrid extends StatelessWidget {
  const _ProfileInfoGrid({required this.items});

  final List<_ProfileInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: constraints.maxWidth < 340
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: AppCard(
                    variant: AppCardVariant.metric,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.primaryDark,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: item.emphasizeValue
                              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  )
                              : Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProfileInfoItem {
  const _ProfileInfoItem({
    required this.label,
    required this.value,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final bool emphasizeValue;
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.values,
  });

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryDark,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (cleaned.isEmpty)
          const StatusChip(
            label: 'Not provided yet',
            icon: Icons.info_outline_rounded,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: cleaned
                .map(
                  (item) => StatusChip(
                    label: item,
                    icon: Icons.circle_outlined,
                    tone: StatusChipTone.accent,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
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

bool _isPrimaryUsage(SubscriptionUsage usage) {
  switch (usage.featureKey) {
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

String _capitalize(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Free';
  }
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}
