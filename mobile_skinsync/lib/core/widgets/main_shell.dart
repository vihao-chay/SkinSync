import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/ai_hub/ai_hub_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/products/products_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/routine/routine_page.dart';
import '../routes/app_routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'app_bottom_navigation.dart';
import 'floating_ai_button.dart';

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
    AppRoutes.aiHub,
    AppRoutes.products,
    AppRoutes.progress,
  ];

  static const _destinations = [
    AppBottomNavigationDestination(
      label: 'Dashboard',
      icon: Icons.home_rounded,
    ),
    AppBottomNavigationDestination(label: 'Routine', icon: Icons.spa_rounded),
    AppBottomNavigationDestination(
      label: 'AI',
      icon: Icons.auto_awesome_rounded,
    ),
    AppBottomNavigationDestination(
      label: 'Products',
      icon: Icons.shopping_bag_rounded,
    ),
    AppBottomNavigationDestination(
      label: 'Progress',
      icon: Icons.insights_rounded,
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
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: IndexedStack(
        index: _selectedIndex,
        sizing: StackFit.expand,
        children: const [
          _ShellPage(pageName: 'Dashboard', child: DashboardPage()),
          _ShellPage(pageName: 'Routine', child: RoutinePage()),
          _ShellPage(pageName: 'AI', child: AiHubPage()),
          _ShellPage(pageName: 'Products', child: ProductsPage()),
          _ShellPage(pageName: 'Progress', child: ProgressPage()),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        destinations: _destinations,
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const FloatingAiButton(),
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
