import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/dashboard/dashboard_page.dart';
import '../../features/products/products_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/routine/routine_page.dart';
import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'app_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.initialRoute});

  final String initialRoute;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _navRoutes = [
    AppRoutes.dashboard,
    AppRoutes.routine,
    AppRoutes.products,
    AppRoutes.progress,
    AppRoutes.profile,
  ];

  static const _destinations = [
    AppBottomNavigationDestination(
      label: 'Home',
      icon: Icons.home_rounded,
    ),
    AppBottomNavigationDestination(label: 'Routine', icon: Icons.spa_rounded),
    AppBottomNavigationDestination(
      label: 'Shop',
      icon: Icons.shopping_bag_rounded,
    ),
    AppBottomNavigationDestination(
      label: 'Stats',
      icon: Icons.insights_rounded,
    ),
    AppBottomNavigationDestination(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
    ),
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

      return const Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IndexedStack(
        index: _selectedIndex,
        sizing: StackFit.expand,
        children: const [
          _ShellPage(pageName: 'Home', child: DashboardPage()),
          _ShellPage(pageName: 'Routine', child: RoutinePage()),
          _ShellPage(pageName: 'Products', child: ProductsPage()),
          _ShellPage(pageName: 'Progress', child: ProgressPage()),
          _ShellPage(pageName: 'Profile', child: ProfilePage()),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        destinations: _destinations,
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({required this.pageName, required this.child});

  final String pageName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: child);
  }
}
