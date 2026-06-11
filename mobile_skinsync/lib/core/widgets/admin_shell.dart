import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../utils/responsive.dart';
import 'glass_header.dart';
import 'premium_card.dart';
import 'responsive_container.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Dashboard', AppRoutes.admin),
      ('Users', AppRoutes.adminUsers),
      ('Products', AppRoutes.adminProducts),
      ('AI Config', AppRoutes.adminAiConfig),
      ('Profile', AppRoutes.adminProfile),
    ];

    return Scaffold(
      appBar: GlassHeader(
        currentRoute: currentRoute,
        leading: Responsive.isMobile(context)
            ? Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              )
            : null,
      ),
      drawer: Responsive.isMobile(context)
          ? Drawer(
              child: ListView(
                children: items
                    .map((item) => ListTile(
                          title: Text(item.$1),
                          onTap: () => Navigator.pushNamed(context, item.$2),
                        ))
                    .toList(),
              ),
            )
          : null,
      body: ResponsiveContainer(
        maxWidth: 1200,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Responsive.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.$1),
                                  selected: item.$2 == currentRoute,
                                  onTap: () => Navigator.pushNamed(context, item.$2),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(child: child),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
