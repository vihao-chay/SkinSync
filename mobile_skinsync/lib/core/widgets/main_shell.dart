import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/analysis/skin_analysis_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/routine/routine_page.dart';
import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'responsive_container.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.initialRoute,
  });

  final String initialRoute;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _navRoutes = [
    AppRoutes.dashboard,
    AppRoutes.analysis,
    AppRoutes.routine,
    AppRoutes.progress,
    AppRoutes.profile,
  ];

  static const _destinations = [
    _ShellDestination('Home', Icons.home_rounded),
    _ShellDestination('AI', Icons.auto_awesome_rounded),
    _ShellDestination('Routine', Icons.spa_rounded),
    _ShellDestination('Progress', Icons.insights_rounded),
    _ShellDestination('Profile', Icons.person_rounded),
  ];

  late int _selectedIndex = _routeToIndex(widget.initialRoute);

  int _routeToIndex(String route) {
    final index = _navRoutes.indexOf(route);
    return index < 0 ? 0 : index;
  }

  void _onTap(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AppState>().isAuthenticated;
    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ResponsiveContainer(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _selectedIndex,
            children: const [
              DashboardPage(),
              SkinAnalysisPage(),
              RoutinePage(),
              ProgressPage(),
              ProfilePage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          margin: const EdgeInsets.fromLTRB(2, 0, 2, 0),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_destinations.length, (index) {
              final destination = _destinations[index];
              final selected = index == _selectedIndex;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withValues(alpha: 0.10) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _onTap(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            destination.icon,
                            color: selected ? AppColors.primary : AppColors.subtleText,
                            size: 20,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            destination.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: selected ? AppColors.primary : AppColors.subtleText,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                ),
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
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon);

  final String label;
  final IconData icon;
}
