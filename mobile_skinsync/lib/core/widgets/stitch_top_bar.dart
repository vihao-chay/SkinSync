import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.pageBackground),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.responsiveHorizontalPadding(context),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _TopAvatarButton(
                        imageUrl: imageUrl,
                        icon: leadingIcon,
                        onTap: onLeadingTap,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'SkinSync',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _TopIconButton(
                        onTap: onTrailingTap,
                        transparent: true,
                        child: Icon(
                          trailingIcon,
                          size: 19,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outline.withValues(alpha: 0.28),
          ),
        ],
      ),
    );
  }
}

class _TopAvatarButton extends StatelessWidget {
  const _TopAvatarButton({
    required this.imageUrl,
    required this.icon,
    this.onTap,
  });

  final String imageUrl;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 28,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _LeadingFallback(icon: icon),
                )
              : _LeadingFallback(icon: icon),
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
  const _TopIconButton({
    required this.child,
    this.onTap,
    this.transparent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: transparent ? Colors.transparent : AppColors.surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(dimension: 32, child: Center(child: child)),
      ),
    );
  }
}
