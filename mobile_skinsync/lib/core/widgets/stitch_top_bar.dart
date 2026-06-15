import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'brand_logo.dart';

class StitchTopBar extends StatelessWidget {
  const StitchTopBar({
    super.key,
    this.avatarUrl,
    this.leadingIcon,
    this.trailingIcon = Icons.notifications_none_rounded,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String? avatarUrl;
  final IconData? leadingIcon;
  final IconData trailingIcon;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = avatarUrl?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        8,
        AppSpacing.pagePadding,
        8,
      ),
      child: SizedBox(
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _TopIconButton(
                onTap: onLeadingTap,
                child: imageUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          imageUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _LeadingFallback(
                            icon: leadingIcon,
                          ),
                        ),
                      )
                    : _LeadingFallback(icon: leadingIcon),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 18, radius: 6, showShadow: false),
                const SizedBox(width: 6),
                Text(
                  'SkinSync',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _TopIconButton(
                onTap: onTrailingTap,
                child: Icon(
                  trailingIcon,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadingFallback extends StatelessWidget {
  const _LeadingFallback({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon ?? Icons.person_outline_rounded,
      size: 17,
      color: AppColors.primaryDark,
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.child,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.86),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 30,
          child: Center(child: child),
        ),
      ),
    );
  }
}
