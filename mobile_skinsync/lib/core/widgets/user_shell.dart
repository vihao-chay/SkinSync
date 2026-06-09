import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../utils/responsive.dart';
import 'glass_header.dart';
import 'responsive_container.dart';

class UserShell extends StatelessWidget {
  const UserShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  void _navigateToRootSection(BuildContext context, String route) {
    if (route == currentRoute) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(route, (page) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final navRoutes = const [
      AppRoutes.dashboard,
      AppRoutes.analysis,
      AppRoutes.routine,
      AppRoutes.progress,
      AppRoutes.profile,
    ];
    final routeIndex = navRoutes.indexOf(currentRoute);
    final selectedIndex = routeIndex < 0 ? 0 : routeIndex;

    return Scaffold(
      appBar: GlassHeader(
        currentRoute: currentRoute,
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              )
            : null,
      ),
      drawer: isMobile
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(child: Text('SkinSync')),
                  ...[
                    ('Dashboard', AppRoutes.dashboard),
                    ('Analysis', AppRoutes.analysis),
                    ('Routine', AppRoutes.routine),
                    ('Progress', AppRoutes.progress),
                    ('Profile', AppRoutes.profile),
                    ('Admin', AppRoutes.admin),
                  ].map(
                    (item) => ListTile(
                      title: Text(item.$1),
                      selected: item.$2 == currentRoute,
                      onTap: () {
                        Navigator.of(context).pop();
                        _navigateToRootSection(context, item.$2);
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  _navigateToRootSection(context, navRoutes[index]),
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Analysis'),
                NavigationDestination(icon: Icon(Icons.checklist_rtl_outlined), label: 'Routine'),
                NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Progress'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            )
          : null,
    );
  }
}
