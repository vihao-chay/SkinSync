import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _didRoute = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!_didRoute && !appState.isBootstrapping) {
      _didRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final nextRoute = !appState.isAuthenticated
            ? AppRoutes.login
            : appState.shouldShowOnboarding
            ? AppRoutes.onboardingIntro
            : AppRoutes.dashboard;

        Navigator.pushNamedAndRemoveUntil(context, nextRoute, (route) => false);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 72, radius: 22),
              const SizedBox(height: 20),
              Text(
                'SkinSync',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
