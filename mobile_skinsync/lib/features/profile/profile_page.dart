import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/stitch_top_bar.dart';
import '../../core/widgets/status_chip.dart';

const _paymentQrAsset = 'bank.jpg';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final profile = appState.profile;

    return ColoredBox(
      color: AppColors.pageBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(
                context,
                mobile: double.infinity,
                tablet: 760,
                desktop: 960,
              ),
            ),
            child: RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: appState.refreshProfileState,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 0,
                ),
                children: [
                  StitchTopBar(
                    avatarUrl: user?.avatarUrl,
                    onTrailingTap: () =>
                        Navigator.pushNamed(context, AppRoutes.editProfile),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.responsiveHorizontalPadding(context),
                      4,
                      Responsive.responsiveHorizontalPadding(context),
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHero(
                          name: appState.profileDisplayName,
                          email: _friendlyText(user?.email),
                          avatarUrl: user?.avatarUrl,
                          skinType: _friendlyText(profile?.skinType),
                          onEdit: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SubscriptionSection(
                          plans: appState.subscriptionPlans,
                          current: appState.subscription,
                          fallbackPlanCode: user?.planType ?? 'free',
                          isBusy: appState.isBusy,
                          errorMessage: appState.membershipLoadErrorMessage,
                          onRetry: appState.refreshSubscription,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionLabel('Skin Profile'),
                        const SizedBox(height: AppSpacing.sm),
                        _ProfileInfoGrid(
                          items: [
                            _ProfileInfoItem(
                              label: 'Age Range',
                              value: _ageRange(profile?.dateOfBirth),
                              icon: Icons.cake_outlined,
                            ),
                            _ProfileInfoItem(
                              label: 'Budget',
                              value: _friendlyText(profile?.budgetLabel),
                              icon: Icons.payments_outlined,
                            ),
                            _ProfileInfoItem(
                              label: 'Primary Goal',
                              value: _primaryGoal(profile),
                              icon: Icons.track_changes_outlined,
                              fullWidth: true,
                            ),
                            _ProfileInfoItem(
                              label: 'Skin Sensitivity',
                              value: profile?.sensitivityLevel == null
                                  ? 'Not provided yet'
                                  : '${profile!.sensitivityLevel}/10',
                              icon: Icons.warning_amber_outlined,
                              fullWidth: true,
                              progress: profile?.sensitivityLevel == null
                                  ? null
                                  : profile!.sensitivityLevel! / 10,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ChipSection(
                          label: 'Active Concerns',
                          values: profile?.concerns ?? const [],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ChipSection(
                          label: 'Care Preferences',
                          values: [
                            ...?profile?.allergies,
                            ...?profile?.avoidIngredients,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _AccountActions(
                          onEdit: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                          onLogout: () => context.read<AppState>().logout(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.skinType,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String skinType;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarUrl?.trim() ?? '';
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl.isEmpty
                ? Container(
                    color: AppColors.surfaceStrong,
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primaryDark,
                      size: 42,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.surfaceStrong,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primaryDark,
                        size: 42,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          email,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.foreground),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onEdit,
          child: StatusChip(
            label: skinType,
            icon: Icons.spa_outlined,
            tone: StatusChipTone.accent,
          ),
        ),
      ],
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
    final visiblePlans = plans
        .where((plan) => plan.code == 'plus' || plan.code == 'premium')
        .toList();
    final currentPlan =
        current?.plan ??
        plans.cast<SubscriptionPlan?>().firstWhere(
          (plan) => plan?.code == currentCode,
          orElse: () => null,
        );
    final usage = (current?.usage ?? const [])
        .where(_isPrimaryUsage)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorMessage != null) ...[
          ErrorStateCard(
            title: 'Membership data could not load',
            description: errorMessage!,
            ctaLabel: 'Try again',
            onCta: onRetry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membership',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _planName(currentPlan, currentCode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: currentCode == 'free' ? 'Add' : 'Active',
                    expand: false,
                    variant: currentCode == 'free'
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    onPressed: currentCode == 'free' && visiblePlans.isNotEmpty
                        ? () => _subscribe(context, visiblePlans.first)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (usage.isEmpty)
                Text(
                  _planPrice(currentPlan),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Row(
                  children: usage
                      .map(
                        (item) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _UsageMiniTile(usage: item),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        if (visiblePlans.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
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
              context.read<AppState>().errorMessage ??
                  'Could not update subscription.',
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

  Future<bool> _showPaymentDialog(
    BuildContext context,
    SubscriptionPlan plan,
  ) async {
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
                      borderRadius: BorderRadius.circular(AppRadius.medium),
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
}

class _UsageMiniTile extends StatelessWidget {
  const _UsageMiniTile({required this.usage});

  final SubscriptionUsage usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Icon(_usageIcon(usage.featureKey), color: AppColors.primaryDark),
          const SizedBox(height: 6),
          Text(
            '${usage.used}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            usage.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  IconData _usageIcon(String key) {
    return switch (key) {
      'skin_analysis' => Icons.document_scanner_outlined,
      'ai_chat' => Icons.chat_bubble_outline_rounded,
      'routine_generation' => Icons.science_outlined,
      'ingredient_check' => Icons.fact_check_outlined,
      'conflict_check' => Icons.warning_amber_outlined,
      _ => Icons.workspace_premium_outlined,
    };
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  _planPrice(plan),
                  style: Theme.of(context).textTheme.labelSmall,
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
                  width: item.fullWidth || constraints.maxWidth < 340
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: AppCard(
                    variant: AppCardVariant.metric,
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.heading,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (item.progress != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: item.progress,
                              minHeight: 6,
                              backgroundColor: AppColors.secondary,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
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
    required this.icon,
    this.fullWidth = false,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;
  final double? progress;
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
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
            children: [
              ...cleaned.map(
                (item) => StatusChip(
                  label: item,
                  icon: Icons.circle_outlined,
                  tone: StatusChipTone.accent,
                ),
              ),
              StatusChip(
                label: '+ Add',
                icon: Icons.add_rounded,
                tone: StatusChipTone.neutral,
              ),
            ],
          ),
      ],
    );
  }
}

class _AccountActions extends StatelessWidget {
  const _AccountActions({required this.onEdit, required this.onLogout});

  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: onEdit,
          ),
          const Divider(height: 1),
          const _ActionRow(
            icon: Icons.notifications_none_rounded,
            label: 'Notifications',
          ),
          const Divider(height: 1),
          const _ActionRow(
            icon: Icons.lock_outline_rounded,
            label: 'Security & Privacy',
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.logout_rounded,
            label: 'Log Out',
            danger: true,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.heading;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 18, color: color),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: danger
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.heading,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _friendlyText(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? 'Not provided yet' : trimmed;
}

String _ageRange(String? dateOfBirth) {
  final parsed = DateTime.tryParse(dateOfBirth ?? '');
  if (parsed == null) {
    return 'Not provided yet';
  }
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month ||
      (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  if (age < 20) {
    return 'Under 20';
  }
  if (age < 30) {
    return 'Late 20s';
  }
  if (age < 40) {
    return '30s';
  }
  return '40+';
}

String _primaryGoal(SkinProfile? profile) {
  final values = profile?.goals.isNotEmpty == true
      ? profile!.goals
      : profile?.skinGoals ?? const <String>[];
  for (final item in values) {
    if (item.trim().isNotEmpty) {
      return item;
    }
  }
  return 'Not provided yet';
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
