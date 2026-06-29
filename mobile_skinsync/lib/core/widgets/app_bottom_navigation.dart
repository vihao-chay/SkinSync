import 'dart:ui';

import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<AppBottomNavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxWidth = Responsive.maxContentWidth(
      context,
      mobile: double.infinity,
      tablet: 720,
      desktop: 960,
    );
    final horizontalPadding = Responsive.responsiveHorizontalPadding(context);
    final navHeight = Responsive.responsiveValue<double>(
      context,
      mobileSmall: 58,
      mobile: 62,
      tablet: 64,
      desktop: 66,
    );
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.44),
                    ),
                  ),
                  boxShadow: AppShadows.soft,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding.clamp(8, 16),
                    8,
                    horizontalPadding.clamp(8, 16),
                    7,
                  ),
                  child: Row(
                    children: List.generate(destinations.length, (index) {
                      final destination = destinations[index];
                      final selected = selectedIndex == index;
                      return Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onTap: () => onTap(index),
                            child: SizedBox(
                              height: navHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    width: selected ? 66 : 48,
                                    height: selected ? 58 : 48,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primaryFixed.withValues(
                                              alpha: 0.55,
                                            )
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        destination.icon,
                                        size: 24,
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        destination.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: selected
                                                  ? AppColors.primary
                                                  : AppColors.onSurfaceVariant,
                                              fontSize:
                                                  Responsive.isSmallMobile(
                                                    context,
                                                  )
                                                  ? 11
                                                  : 12,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}

class AppBottomNavigationDestination {
  const AppBottomNavigationDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
