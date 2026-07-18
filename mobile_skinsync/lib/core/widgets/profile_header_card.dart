import 'package:flutter/material.dart';

import '../l10n/app_locale.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'status_chip.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.skinType,
    required this.onEdit,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String skinType;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocale.of(context);
    final url = avatarUrl?.trim();
    return AppCard(
      variant: AppCardVariant.accent,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                backgroundImage: url == null || url.isEmpty
                    ? null
                    : NetworkImage(url),
                child: url == null || url.isEmpty
                    ? Text(
                        name.isEmpty ? 'S' : name[0].toUpperCase(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    StatusChip(
                      label: skinType,
                      icon: Icons.spa_outlined,
                      tone: StatusChipTone.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: locale.tr('profile_edit_profile'),
            variant: AppButtonVariant.secondary,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
