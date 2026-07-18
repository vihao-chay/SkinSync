import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_state_card.dart';
import 'subscription_success_page.dart';

class PlanSelectionPage extends StatefulWidget {
  const PlanSelectionPage({super.key});

  @override
  State<PlanSelectionPage> createState() => _PlanSelectionPageState();
}

class _PlanSelectionPageState extends State<PlanSelectionPage> {
  String? _selectedPlanCode;
  bool _startingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final appState = context.read<AppState>();
      if (appState.subscriptionPlans.isEmpty || appState.subscription == null) {
        appState.refreshSubscription();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final appState = context.watch<AppState>();
    final currentCode =
        (appState.subscription?.plan.code ?? appState.user?.planType ?? 'free')
            .trim()
            .toLowerCase();
    final plans =
        appState.subscriptionPlans
            .where(
              (plan) =>
                  plan.isActive &&
                  (plan.code.toLowerCase() == 'plus' ||
                      plan.code.toLowerCase() == 'premium'),
            )
            .toList()
          ..sort((a, b) => a.priceVnd.compareTo(b.priceVnd));
    final selectedCode =
        _selectedPlanCode ??
        _defaultSelectedCode(plans: plans, currentCode: currentCode);
    final selectedPlan = _findPlan(plans, selectedCode);
    final scanUsage = _findUsage(
      appState.subscription?.usage ?? const [],
      'skin_analysis',
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              children: [
                _PlanTopBar(
                  title: locale.tr('plan_title'),
                  onBack: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: appState.refreshSubscription,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        4,
                        AppSpacing.pagePadding,
                        24,
                      ),
                      children: [
                        Text(
                          locale.tr('plan_subtitle'),
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _CurrentUsagePanel(
                          currentPlanName: _planDisplayName(
                            appState.subscription?.plan.name,
                            currentCode,
                          ),
                          usage: scanUsage,
                        ),
                        if (appState.membershipLoadErrorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          ErrorStateCard(
                            title: locale.tr('common_plans_error'),
                            description: appState.membershipLoadErrorMessage!,
                            ctaLabel: locale.tr('common_try_again'),
                            onCta: appState.refreshSubscription,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (plans.isEmpty &&
                            appState.membershipLoadErrorMessage == null)
                          const _PlansLoading()
                        else
                          ...plans.map(
                            (plan) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _PlanChoiceCard(
                                plan: plan,
                                selected:
                                    selectedCode.toLowerCase() ==
                                    plan.code.toLowerCase(),
                                current: currentCode == plan.code.toLowerCase(),
                                bestValue: plan.code.toLowerCase() == 'premium',
                                onTap: () => setState(
                                  () => _selectedPlanCode = plan.code,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _PlanBottomAction(
                  plan: selectedPlan,
                  isCurrent: selectedPlan?.code.toLowerCase() == currentCode,
                  isLoading: _startingPayment,
                  canCancel: currentCode != 'free',
                  onContinue: selectedPlan == null
                      ? null
                      : () => _startPayment(selectedPlan),
                  onCancelPlan: currentCode == 'free'
                      ? null
                      : () => _cancelMembership(appState),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPayment(SubscriptionPlan plan) async {
    if (_startingPayment) {
      return;
    }
    setState(() => _startingPayment = true);

    try {
      final appState = context.read<AppState>();
      final payment = await appState.createPaymentLink(plan.code);
      final checkoutUri = Uri.tryParse(payment.checkoutUrl);
      if (checkoutUri == null || payment.checkoutUrl.trim().isEmpty) {
        throw StateError('Payment checkout link is unavailable.');
      }

      final launched = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open the payment page.');
      }
      if (!mounted) {
        return;
      }

      final paid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _PaymentStatusDialog(plan: plan, orderCode: payment.orderCode),
      );
      if (paid == true && mounted) {
        final currentSubscription = appState.subscription;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => SubscriptionSuccessPage(
              plan: currentSubscription?.plan ?? plan,
              orderCode: payment.orderCode,
              renewalDate: currentSubscription?.subscription.currentPeriodEnd,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final message = context.read<AppState>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message?.trim().isNotEmpty == true
                  ? message!
                  : AppLocale.of(context).tr('payment_error'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _startingPayment = false);
      }
    }
  }

  Future<void> _cancelMembership(AppState appState) async {
    final locale = AppLocale.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(locale.tr('plan_cancel_confirm')),
        content: Text(locale.tr('plan_cancel_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(locale.tr('plan_keep')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(locale.tr('plan_cancel')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await appState.cancelSubscription();
      if (mounted) {
        setState(() => _selectedPlanCode = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locale.tr('plan_cancelled_success'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.errorMessage ?? locale.tr('common_could_not_cancel'),
            ),
          ),
        );
      }
    }
  }
}

class _PlanTopBar extends StatelessWidget {
  const _PlanTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        8,
        AppSpacing.pagePadding,
        4,
      ),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: locale.tr('common_back'),
                onPressed: onBack,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                color: AppColors.heading,
                iconSize: 30,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUsagePanel extends StatelessWidget {
  const _CurrentUsagePanel({
    required this.currentPlanName,
    required this.usage,
  });

  final String currentPlanName;
  final SubscriptionUsage? usage;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final limit = usage?.monthlyLimit;
    final used = usage?.used ?? 0;
    final unlimited = usage?.isUnlimited ?? false;
    final progress = unlimited
        ? 1.0
        : limit == null || limit <= 0
        ? 0.0
        : (used / limit).clamp(0.0, 1.0);
    final exhausted = !unlimited && limit != null && limit > 0 && used >= limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                locale.tr('plan_current_usage'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.heading,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              unlimited
                  ? locale.tr('plan_unlimited_scans')
                  : limit == null
                  ? currentPlanName
                  : '$used/$limit ${locale.tr('plan_scans')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: exhausted ? AppColors.error : AppColors.heading,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              exhausted ? AppColors.error : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          exhausted ? locale.tr('plan_limit_reached') : currentPlanName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: exhausted ? AppColors.error : AppColors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _PlanChoiceCard extends StatelessWidget {
  const _PlanChoiceCard({
    required this.plan,
    required this.selected,
    required this.current,
    required this.bestValue,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final bool current;
  final bool bestValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final features = plan.features
        .where(
          (feature) =>
              feature.isEnabled &&
              (feature.monthlyLimit == null || feature.monthlyLimit != 0),
        )
        .take(5)
        .toList();

    return AppCard(
      onTap: onTap,
      radius: AppRadius.card,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      backgroundColor: selected
          ? AppColors.primaryFixed.withValues(alpha: 0.22)
          : AppColors.surface,
      borderColor: selected ? AppColors.primaryContainer : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _planDisplayName(plan.name, plan.code),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _formatPlanPrice(plan, locale),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (current)
                _PlanBadge(label: locale.tr('plan_current'))
              else if (bestValue)
                _PlanBadge(label: locale.tr('plan_best_value')),
            ],
          ),
          if (_planDescription(plan, locale).trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _planDescription(plan, locale),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.heading,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _featureLabel(feature, locale),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.heading,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onPrimary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlanBottomAction extends StatelessWidget {
  const _PlanBottomAction({
    required this.plan,
    required this.isCurrent,
    required this.isLoading,
    required this.canCancel,
    required this.onContinue,
    required this.onCancelPlan,
  });

  final SubscriptionPlan? plan;
  final bool isCurrent;
  final bool isLoading;
  final bool canCancel;
  final VoidCallback? onContinue;
  final VoidCallback? onCancelPlan;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final selectedPlan = plan;
    final label = selectedPlan == null
        ? locale.tr('plan_choose')
        : isCurrent
        ? locale.tr('plan_current_plan')
        : '${locale.tr('plan_continue_with')} ${_planDisplayName(selectedPlan.name, selectedPlan.code)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        10,
        AppSpacing.pagePadding,
        12,
      ),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: isCurrent || isLoading ? null : onContinue,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 18),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (canCancel) ...[
            const SizedBox(height: 2),
            TextButton(
              onPressed: isLoading ? null : onCancelPlan,
              child: Text(locale.tr('plan_cancel_membership')),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentStatusDialog extends StatefulWidget {
  const _PaymentStatusDialog({required this.plan, required this.orderCode});

  final SubscriptionPlan plan;
  final int orderCode;

  @override
  State<_PaymentStatusDialog> createState() => _PaymentStatusDialogState();
}

class _PaymentStatusDialogState extends State<_PaymentStatusDialog>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _verifying = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    if (_verifying || !mounted) {
      return;
    }
    setState(() {
      _verifying = true;
    });

    try {
      final result = await context.read<AppState>().verifyPayment(
        widget.orderCode,
      );
      if (!mounted) {
        return;
      }

      switch (result.status.trim().toLowerCase()) {
        case 'paid':
          Navigator.pop(context, true);
          return;
        case 'cancelled':
          setState(() {
            _statusMessage = AppLocale.of(context).tr('payment_cancelled');
          });
          break;
        default:
          setState(() {
            _statusMessage = AppLocale.of(context).tr('payment_waiting_payos');
          });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _statusMessage = AppLocale.of(context).tr('payment_still_waiting');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    return AlertDialog(
      title: Text(
        '${locale.tr('payment_complete')} ${_planDisplayName(widget.plan.name, widget.plan.code)}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: 36,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            locale.tr('payment_browser'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _statusMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(locale.tr('payment_later')),
        ),
      ],
    );
  }
}

class _PlansLoading extends StatelessWidget {
  const _PlansLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

String _defaultSelectedCode({
  required List<SubscriptionPlan> plans,
  required String currentCode,
}) {
  if (plans.any((plan) => plan.code.toLowerCase() == currentCode)) {
    return currentCode;
  }
  if (plans.any((plan) => plan.code.toLowerCase() == 'premium')) {
    return 'premium';
  }
  return plans.isEmpty ? '' : plans.first.code;
}

SubscriptionPlan? _findPlan(List<SubscriptionPlan> plans, String planCode) {
  final normalizedCode = planCode.trim().toLowerCase();
  for (final plan in plans) {
    if (plan.code.trim().toLowerCase() == normalizedCode) {
      return plan;
    }
  }
  return null;
}

SubscriptionUsage? _findUsage(
  List<SubscriptionUsage> usage,
  String featureKey,
) {
  final normalizedKey = featureKey.trim().toLowerCase();
  for (final item in usage) {
    if (item.featureKey.trim().toLowerCase() == normalizedKey) {
      return item;
    }
  }
  return null;
}

String _planDisplayName(String? name, String code) {
  final normalizedCode = code.trim().toLowerCase();
  if (normalizedCode == 'plus' || normalizedCode == 'premium') {
    return _capitalize(normalizedCode);
  }

  final resolved = name?.trim().isNotEmpty == true
      ? name!.trim()
      : _capitalize(code);
  final withoutBrand = resolved.replaceFirst(
    RegExp(r'^SkinSync[\s_-]*', caseSensitive: false),
    '',
  );
  return withoutBrand.trim().isEmpty ? _capitalize(code) : withoutBrand.trim();
}

String _formatPlanPrice(SubscriptionPlan plan, AppLocale locale) {
  if (plan.priceVnd <= 0) {
    return locale.tr('plan_free');
  }
  final formatter = NumberFormat.decimalPattern('vi_VN');
  final cycle = plan.billingCycle.toLowerCase() == 'yearly'
      ? locale.tr('plan_per_year')
      : locale.tr('plan_per_month');
  return '${formatter.format(plan.priceVnd.round())} VND$cycle';
}

String _planDescription(SubscriptionPlan plan, AppLocale locale) {
  final normalizedCode = plan.code.trim().toLowerCase();
  return switch (normalizedCode) {
    'plus' => locale.tr('plan_plus_description'),
    'premium' => locale.tr('plan_premium_description'),
    _ => plan.description?.trim() ?? '',
  };
}

String _featureLabel(SubscriptionPlanFeature feature, AppLocale locale) {
  final name = _featureName(feature, locale);
  if (feature.isUnlimited) {
    return '${locale.tr('membership_unlimited')} $name';
  }
  final limit = feature.monthlyLimit;
  if (limit != null && limit > 0) {
    return '$limit $name ${locale.tr('plan_feature_month_suffix')}';
  }
  return name;
}

String _featureName(SubscriptionPlanFeature feature, AppLocale locale) {
  final key = feature.featureKey.trim().toLowerCase();
  return switch (key) {
    'skin_analysis' ||
    'skin_analyses' ||
    'analysis' => locale.tr('plan_feature_skin_analysis'),
    'ai_chat' || 'chat' => locale.tr('plan_feature_ai_chat'),
    'routine_generation' ||
    'routine_generator' ||
    'routine' => locale.tr('plan_feature_routine'),
    'ingredient_check' ||
    'ingredients_check' => locale.tr('plan_feature_ingredient'),
    'conflict_check' ||
    'routine_conflict_check' => locale.tr('plan_feature_conflict'),
    _ =>
      feature.displayName.trim().isEmpty
          ? _capitalize(feature.featureKey.replaceAll('_', ' '))
          : feature.displayName.trim(),
  };
}

String _capitalize(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
