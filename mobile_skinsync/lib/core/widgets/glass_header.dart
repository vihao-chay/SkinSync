import 'dart:ui';

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../utils/responsive.dart';
import 'section_badge.dart';

class GlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlassHeader({
    super.key,
    required this.currentRoute,
    this.onMenuPressed,
  });

  final String currentRoute;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  static const _items = [
    ('Home', AppRoutes.landing),
    ('Quiz', AppRoutes.quiz),
    ('Analysis', AppRoutes.analysis),
    ('Routine', AppRoutes.routine),
    ('Progress', AppRoutes.progress),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: preferredSize.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            border: Border(
              bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (mobile)
                    IconButton(
                      onPressed: onMenuPressed,
                      icon: const Icon(Icons.menu_rounded),
                    ),
                  if (!mobile)
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.landing),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.spa_rounded, color: Colors.white, size: 20),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'SkinSync',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!mobile) const Spacer(),
                  if (!mobile)
                    Wrap(
                      spacing: 8,
                      children: _items.map((item) {
                        final selected = currentRoute == item.$2;
                        return TextButton(
                          onPressed: () => Navigator.pushNamed(context, item.$2),
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              color: selected ? AppColors.primaryDark : AppColors.mutedText,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const Spacer(),
                  if (mobile)
                    const Text(
                      'SkinSync',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (mobile) const Spacer(),
                  const SectionBadge(
                    label: 'Premium',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.softPink,
                    child: Icon(Icons.person_outline_rounded, color: AppColors.primaryDark),
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
