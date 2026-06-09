import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlassHeader({
    super.key,
    required this.currentRoute,
    this.title,
    this.showBack = true,
    this.leading,
    this.actions,
  });

  final String currentRoute;
  final String? title;
  final bool showBack;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: AppColors.pageBackground,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      leadingWidth: leading != null || (showBack && canPop) ? 52 : 16,
      automaticallyImplyLeading: false,
      leading: leading != null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: leading,
            )
          : showBack && canPop
              ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
              : null,
      title: Text(
        title ?? _resolveTitle(currentRoute),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
      ),
      actions: [
        ...?actions,
        const SizedBox(width: 8),
      ],
    );
  }

  String _resolveTitle(String route) {
    switch (route) {
      case '/onboarding':
        return 'SkinSync';
      case '/login':
        return 'Sign In';
      case '/quiz':
        return 'Skin Quiz';
      case '/upload':
        return 'Upload Photo';
      case '/analysis':
        return 'Skin Analysis';
      case '/dashboard':
        return 'Home';
      case '/routine':
        return 'My Routine';
      case '/progress':
        return 'Your Progress';
      case '/profile':
        return 'Profile';
      default:
        return 'SkinSync';
    }
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}
