import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class SkinSyncApp extends StatelessWidget {
  const SkinSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkinSync',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
