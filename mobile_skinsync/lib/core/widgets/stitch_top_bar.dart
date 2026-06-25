import 'dart:ui';

import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
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
      padding: EdgeInsets.fromLTRB(
        Responsive.responsiveHorizontalPadding(context),
        8,
        Responsive.responsiveHorizontalPadding(context),
        8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _TopIconButton(
                      onTap: onLeadingTap,
                      child: imageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                imageUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _LeadingFallback(icon: leadingIcon),
                              ),
                            )
                          : _LeadingFallback(icon: leadingIcon),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 20, radius: 7, showShadow: false),
                    const SizedBox(width: 6),
                    Text(
                      'SkinSync',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TopIconButton(
                      onTap: onTrailingTap,
                      child: Icon(
                        trailingIcon,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      color: AppColors.primary,
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.78),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.58)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(dimension: 32, child: Center(child: child)),
      ),
    );
  }
}
