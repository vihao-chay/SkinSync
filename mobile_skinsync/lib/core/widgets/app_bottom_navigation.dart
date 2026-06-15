import 'package:flutter/material.dart';

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
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.section),
            boxShadow: AppShadows.elevated,
          ),
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppRadius.section),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.section),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.92),
                ),
              ),
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final destination = destinations[index];
                  final selected = selectedIndex == index;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      onTap: () => onTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppRadius.medium,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              destination.icon,
                              size: 21,
                              color: selected
                                  ? AppColors.primaryDark
                                  : AppColors.mutedText,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              destination.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.mutedText,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
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
