import 'package:flutter/material.dart';

import '../../features/admin/admin_ai_config_page.dart';
import '../../features/admin/admin_dashboard_page.dart';
import '../../features/admin/admin_products_page.dart';
import '../../features/admin/admin_profile_page.dart';
import '../../features/admin/admin_users_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/landing/landing_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/quiz/quiz_page.dart';
import '../../features/upload/upload_page.dart';
import '../widgets/main_shell.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? AppRoutes.onboarding;
    final Widget page;

    switch (name) {
      case AppRoutes.onboarding:
        page = const OnboardingPage();
        break;
      case AppRoutes.login:
        page = const LoginPage();
        break;
      case AppRoutes.landing:
        page = const LandingPage();
        break;
      case AppRoutes.quiz:
        page = const QuizPage();
        break;
      case AppRoutes.upload:
        page = const UploadPage();
        break;
      case AppRoutes.dashboard:
      case AppRoutes.analysis:
      case AppRoutes.routine:
      case AppRoutes.progress:
      case AppRoutes.profile:
        page = MainShell(initialRoute: name);
        break;
      case AppRoutes.admin:
        page = const AdminDashboardPage();
        break;
      case AppRoutes.adminUsers:
        page = const AdminUsersPage();
        break;
      case AppRoutes.adminProducts:
        page = const AdminProductsPage();
        break;
      case AppRoutes.adminAiConfig:
        page = const AdminAiConfigPage();
        break;
      case AppRoutes.adminProfile:
        page = const AdminProfilePage();
        break;
      default:
        page = const OnboardingPage();
        break;
    }

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, animation, _) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: page,
        ),
      ),
    );
  }
}
