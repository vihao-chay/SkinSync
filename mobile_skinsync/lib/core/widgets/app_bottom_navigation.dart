import 'package:flutter/material.dart';

import '../responsive/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

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
      minimum: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.foreground.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
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
