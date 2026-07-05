import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_locale.dart';
import '../../core/models/app_models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_image.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/skin_sync_header.dart';
import '../../core/widgets/status_chip.dart';

const _profileAvatarDirectory = 'assets/avatars/';
const _profileAvatarExtensions = {'.webp', '.png', '.jpg', '.jpeg'};

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
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
                padding: const EdgeInsets.only(bottom: 0),
                children: [
                  SkinSyncHeader(
                    name: appState.profileDisplayName,
                    avatarUrl: user?.avatarUrl,
                    onAvatarTap: () => _showAvatarPicker(context),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.responsiveHorizontalPadding(context),
                      12,
                      Responsive.responsiveHorizontalPadding(context),
                      Responsive.contentBottomSpacing(context, extra: 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHero(
                          name: appState.profileDisplayName,
                          email: _friendlyText(user?.email, locale),
                          avatarUrl: user?.avatarUrl,
                          skinType: _friendlyText(profile?.skinType, locale),
                          onAvatarTap: () => _showAvatarPicker(context),
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
                          errorMessage: appState.membershipLoadErrorMessage,
                          onRetry: appState.refreshSubscription,
                          onManage: () => Navigator.pushNamed(
                            context,
                            AppRoutes.membershipPlans,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionLabel(locale.tr('profile_skin_profile_label')),
                        const SizedBox(height: AppSpacing.sm),
                        _ProfileInfoGrid(
                          items: [
                            _ProfileInfoItem(
                              label: locale.tr('profile_age_range'),
                              value: _ageRange(profile?.dateOfBirth, locale),
                              icon: Icons.cake_outlined,
                            ),
                            _ProfileInfoItem(
                              label: locale.tr('profile_budget'),
                              value: _friendlyText(
                                profile?.budgetLabel,
                                locale,
                              ),
                              icon: Icons.payments_outlined,
                            ),
                            _ProfileInfoItem(
                              label: locale.tr('profile_primary_goal'),
                              value: _primaryGoal(profile, locale),
                              icon: Icons.track_changes_outlined,
                              fullWidth: true,
                            ),
                            _ProfileInfoItem(
                              label: locale.tr('profile_sensitivity'),
                              value: profile?.sensitivityLevel == null
                                  ? locale.tr('profile_not_provided')
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
                          label: locale.tr('profile_active_concerns'),
                          values: profile?.concerns ?? const [],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ChipSection(
                          label: locale.tr('profile_care_preferences'),
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

Future<void> _showAvatarPicker(BuildContext context) async {
  final locale = AppLocale.of(context);
  final appState = context.read<AppState>();
  final selectedAvatar = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AvatarPickerSheet(
      selectedAvatar: appState.user?.avatarUrl,
      avatarAssetsFuture: _loadProfileAvatarAssets(),
    ),
  );

  if (selectedAvatar == null || !context.mounted) {
    return;
  }

  await context.read<AppState>().updateAvatarSelection(selectedAvatar);
  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(locale.tr('profile_avatar_saved'))));
}

Future<List<String>> _loadProfileAvatarAssets() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final avatars = manifest.listAssets().where(_isProfileAvatarAsset).toList()
    ..sort();
  return avatars;
}

bool _isProfileAvatarAsset(String asset) {
  final normalized = asset.replaceAll('\\', '/');
  if (!normalized.startsWith(_profileAvatarDirectory)) {
    return false;
  }

  final lower = normalized.toLowerCase();
  return _profileAvatarExtensions.any(lower.endsWith);
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.skinType,
    required this.onAvatarTap,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final String skinType;
  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final imageUrl = avatarUrl?.trim() ?? '';
    return Column(
      children: [
        Semantics(
          button: true,
          label: locale.tr('profile_tap_avatar_hint'),
          child: GestureDetector(
            onTap: onAvatarTap,
            child: SizedBox.square(
              dimension: 102,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AvatarImage(
                          source: imageUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
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
                  ),
                  Positioned(
                    right: 6,
                    bottom: 8,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 15,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
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

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet({
    required this.selectedAvatar,
    required this.avatarAssetsFuture,
  });

  final String? selectedAvatar;
  final Future<List<String>> avatarAssetsFuture;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final selected = selectedAvatar?.trim();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: [
            BoxShadow(
              color: AppColors.foreground.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    locale.tr('profile_choose_avatar'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.heading,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<String>>(
              future: avatarAssetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                      ),
                    ),
                  );
                }

                final avatarAssets = snapshot.data ?? const <String>[];
                if (avatarAssets.isEmpty) {
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: Text(
                        locale.tr('profile_no_avatar_assets'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    itemCount: avatarAssets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final asset = avatarAssets[index];
                      final isSelected = selected == asset;
                      return SizedBox(
                        width: 150,
                        child: _AvatarOptionTile(
                          asset: asset,
                          selected: isSelected,
                          label: locale
                              .tr('profile_avatar_option')
                              .replaceAll('{number}', '${index + 1}'),
                          onTap: () => Navigator.pop(context, asset),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({
    required this.asset,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: selected ? AppColors.primaryDark : Colors.white,
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 108,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: Image.asset(
                            asset,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({
    required this.plans,
    required this.current,
    required this.fallbackPlanCode,
    required this.errorMessage,
    required this.onRetry,
    required this.onManage,
  });

  final List<SubscriptionPlan> plans;
  final CurrentSubscription? current;
  final String fallbackPlanCode;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final currentCode = (current?.plan.code ?? fallbackPlanCode).toLowerCase();
    final currentPlan =
        current?.plan ??
        plans.cast<SubscriptionPlan?>().firstWhere(
          (plan) => plan?.code.toLowerCase() == currentCode,
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
            title: locale.tr('profile_membership_error'),
            description: errorMessage!,
            ctaLabel: locale.tr('common_retry'),
            onCta: onRetry,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          backgroundColor: AppColors.primaryFixed.withValues(alpha: 0.18),
          borderColor: AppColors.primaryContainer.withValues(alpha: 0.34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.tr('profile_membership'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.heading,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _brandedPlanName(currentPlan, currentCode),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (currentCode != 'free')
                    StatusChip(
                      label: locale.tr('profile_active'),
                      tone: StatusChipTone.success,
                    ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: onManage,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.open_in_new_rounded, size: 13),
                    label: Text(
                      currentCode == 'free'
                          ? locale.tr('profile_upgrade_action')
                          : locale.tr('profile_manage'),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (usage.isEmpty)
                Text(
                  currentCode == 'free'
                      ? locale.tr('profile_free_upgrade_prompt')
                      : locale.tr('profile_premium_active_prompt'),
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
      ],
    );
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
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: Colors.white),
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
    final locale = AppLocale.of(context);
    final cleaned = values.where((item) => item.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label),
        const SizedBox(height: AppSpacing.sm),
        if (cleaned.isEmpty)
          StatusChip(
            label: locale.tr('profile_not_provided'),
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
                label: locale.tr('profile_add_concern'),
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
    final locale = AppLocale.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.edit_outlined,
            label: locale.tr('profile_edit_profile'),
            onTap: onEdit,
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.language_rounded,
            label: '${locale.tr('profile_language')}: ${locale.displayName}',
            onTap: () => _showLanguageDialog(context, locale),
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.notifications_none_rounded,
            label: locale.tr('profile_notifications'),
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.lock_outline_rounded,
            label: locale.tr('profile_security_privacy'),
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.logout_rounded,
            label: locale.tr('profile_logout'),
            danger: true,
            onTap: () => _confirmLogout(context, locale),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocale locale) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.tr('profile_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(locale.tr('profile_vietnamese')),
              trailing: locale.locale == 'vi'
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryDark,
                    )
                  : null,
              onTap: () {
                locale.setLocale('vi');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(locale.tr('profile_english')),
              trailing: locale.locale == 'en'
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryDark,
                    )
                  : null,
              onTap: () {
                locale.setLocale('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocale locale) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.tr('profile_logout')),
        content: Text(locale.tr('profile_confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.tr('profile_cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            child: Text(
              locale.tr('profile_logout'),
              style: const TextStyle(color: AppColors.error),
            ),
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

String _friendlyText(String? value, AppLocale locale) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? locale.tr('profile_not_provided') : trimmed;
}

String _ageRange(String? dateOfBirth, AppLocale locale) {
  final parsed = DateTime.tryParse(dateOfBirth ?? '');
  if (parsed == null) {
    return locale.tr('profile_not_provided');
  }
  final now = DateTime.now();
  var age = now.year - parsed.year;
  if (now.month < parsed.month ||
      (now.month == parsed.month && now.day < parsed.day)) {
    age--;
  }
  if (age < 20) {
    return locale.tr('profile_age_under_20');
  }
  if (age < 30) {
    return locale.tr('profile_age_late_20s');
  }
  if (age < 40) {
    return locale.tr('profile_age_30s');
  }
  return locale.tr('profile_age_40_plus');
}

String _primaryGoal(SkinProfile? profile, AppLocale locale) {
  final values = profile?.goals.isNotEmpty == true
      ? profile!.goals
      : profile?.skinGoals ?? const <String>[];
  for (final item in values) {
    if (item.trim().isNotEmpty) {
      return item;
    }
  }
  return locale.tr('profile_not_provided');
}

String _brandedPlanName(SubscriptionPlan? plan, String fallbackCode) {
  return plan != null && plan.name.trim().isNotEmpty
      ? plan.name.trim()
      : _capitalize(fallbackCode);
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
