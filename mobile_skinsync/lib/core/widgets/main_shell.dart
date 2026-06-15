import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
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
  const MainShell({
    super.key,
    required this.initialRoute,
    this.initialArgs,
  });

  final String initialRoute;
  final Object? initialArgs;

  static void navigateToTab(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    final shellState = context.findAncestorStateOfType<_MainShellState>();
    if (shellState != null) {
      shellState.selectRoute(route, arguments: arguments);
      return;
    }
    Navigator.pushNamed(context, route, arguments: arguments);
  }

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
  late ProductsPageArgs _productsArgs;
  late RoutinePageArgs _routineArgs;
  late ProgressPageArgs _progressArgs;

  @override
  void initState() {
    super.initState();
    _productsArgs = const ProductsPageArgs();
    _routineArgs = const RoutinePageArgs();
    _progressArgs = const ProgressPageArgs();
    _applyInitialArgs(widget.initialRoute, widget.initialArgs);
  }

  int _routeToIndex(String route) {
    final index = _navRoutes.indexOf(route);
    return index < 0 ? 0 : index;
  }

  void _applyInitialArgs(String route, Object? arguments) {
    switch (route) {
      case AppRoutes.products:
        if (arguments is ProductsPageArgs) {
          _productsArgs = arguments;
        }
        break;
      case AppRoutes.routine:
        if (arguments is RoutinePageArgs) {
          _routineArgs = arguments;
        }
        break;
      case AppRoutes.progress:
        if (arguments is ProgressPageArgs) {
          _progressArgs = arguments;
        }
        break;
    }
  }

  void selectRoute(String route, {Object? arguments}) {
    final nextIndex = _routeToIndex(route);
    setState(() {
      _selectedIndex = nextIndex;
      switch (route) {
        case AppRoutes.products:
          _productsArgs = arguments is ProductsPageArgs
              ? arguments
              : const ProductsPageArgs();
          break;
        case AppRoutes.routine:
          _routineArgs = arguments is RoutinePageArgs
              ? arguments
              : const RoutinePageArgs();
          break;
        case AppRoutes.progress:
          _progressArgs = arguments is ProgressPageArgs
              ? arguments
              : const ProgressPageArgs();
          break;
      }
    });
  }

  void _onTap(int index) {
    if (index == _selectedIndex) {
      return;
    }
    selectRoute(_navRoutes[index]);
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              sizing: StackFit.expand,
              children: [
                const _ShellPage(pageName: 'Home', child: DashboardPage()),
                _ShellPage(
                  key: ValueKey('routine-${_routineArgs.cacheKey}'),
                  pageName: 'Routine',
                  child: RoutinePage(args: _routineArgs),
                ),
                _ShellPage(
                  key: ValueKey('products-${_productsArgs.cacheKey}'),
                  pageName: 'Products',
                  child: ProductsPage(args: _productsArgs),
                ),
                _ShellPage(
                  key: ValueKey('progress-${_progressArgs.cacheKey}'),
                  pageName: 'Progress',
                  child: ProgressPage(args: _progressArgs),
                ),
                const _ShellPage(pageName: 'Profile', child: ProfilePage()),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavigation(
              destinations: _destinations,
              selectedIndex: _selectedIndex,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({super.key, required this.pageName, required this.child});

  final String pageName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: child);
  }
}
