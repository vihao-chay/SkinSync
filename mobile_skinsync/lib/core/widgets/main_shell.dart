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

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.initialRoute});

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
    _ShellDestination('AI Scan', Icons.auto_awesome_rounded),
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
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox.expand(
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              height: 62,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
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
                          color: selected
                              ? AppColors.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _onTap(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destination.icon,
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.foreground,
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destination.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: selected
                                            ? AppColors.primaryDark
                                            : AppColors.foreground,
                                        fontSize: 9,
                                        fontWeight: selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
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
