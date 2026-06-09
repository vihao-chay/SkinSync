import 'package:flutter/material.dart';

import '../../features/admin/admin_ai_config_page.dart';
import '../../features/admin/admin_dashboard_page.dart';
import '../../features/admin/admin_products_page.dart';
import '../../features/admin/admin_profile_page.dart';
import '../../features/admin/admin_users_page.dart';
import '../../features/analysis/skin_analysis_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/landing/landing_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/quiz/quiz_page.dart';
import '../../features/routine/routine_page.dart';
import '../../features/upload/upload_page.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case AppRoutes.landing:
        page = const LandingPage();
        break;
      case AppRoutes.quiz:
        page = const QuizPage();
        break;
      case AppRoutes.upload:
        page = const UploadPage();
        break;
      case AppRoutes.analysis:
        page = const SkinAnalysisPage();
        break;
      case AppRoutes.dashboard:
        page = const DashboardPage();
        break;
      case AppRoutes.routine:
        page = const RoutinePage();
        break;
      case AppRoutes.progress:
        page = const ProgressPage();
        break;
      case AppRoutes.profile:
        page = const ProfilePage();
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
        page = const LandingPage();
        break;
    }

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, animation, _) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: page,
        ),
      ),
    );
  }
}
