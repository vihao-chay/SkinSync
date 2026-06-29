import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/l10n/app_locale.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_client.dart';
import 'core/services/session_store.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

class SkinSyncApp extends StatefulWidget {
  const SkinSyncApp({super.key});

  @override
  State<SkinSyncApp> createState() => _SkinSyncAppState();
}

class _SkinSyncAppState extends State<SkinSyncApp> {
  final _appLocale = AppLocale();

  @override
  void dispose() {
    _appLocale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        apiClient: ApiClient(baseUrl: AppConfig.apiBaseUrl),
        sessionStore: SessionStore(),
      )..bootstrap(),
      child: LocaleScope(
        locale: _appLocale,
        child: ListenableBuilder(
          listenable: _appLocale,
          builder: (context, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SkinSync',
            theme: AppTheme.lightTheme,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      ),
    );
  }
}
