import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/services/api_client.dart';
import 'core/services/session_store.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';

class SkinSyncApp extends StatelessWidget {
  const SkinSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(
        apiClient: ApiClient(baseUrl: AppConfig.apiBaseUrl),
        sessionStore: SessionStore(),
      )..bootstrap(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SkinSync',
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) => _AppErrorListener(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

class _AppErrorListener extends StatefulWidget {
  const _AppErrorListener({required this.child});

  final Widget child;

  @override
  State<_AppErrorListener> createState() => _AppErrorListenerState();
}

class _AppErrorListenerState extends State<_AppErrorListener> {
  int _lastVersion = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final message = appState.errorMessage;

    if (message != null && appState.messageVersion != _lastVersion) {
      _lastVersion = appState.messageVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    }

    return widget.child;
  }
}
