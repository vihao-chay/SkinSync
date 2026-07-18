import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_skinasync/core/config/app_config.dart';
import 'package:mobile_skinasync/core/l10n/app_locale.dart';
import 'package:mobile_skinasync/core/models/app_models.dart';
import 'package:mobile_skinasync/core/services/api_client.dart';
import 'package:mobile_skinasync/core/services/session_store.dart';
import 'package:mobile_skinasync/core/state/app_state.dart';
import 'package:mobile_skinasync/core/theme/app_theme.dart';
import 'package:mobile_skinasync/features/progress/progress_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  AppState createAppState() => AppState(
    apiClient: ApiClient(baseUrl: AppConfig.apiBaseUrl),
    sessionStore: SessionStore(),
  );

  Widget buildPage(AppState appState) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: LocaleScope(
        locale: AppLocale(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProgressPage(),
        ),
      ),
    );
  }

  testWidgets('progress page shows an empty state when no data is loaded', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});

    await tester.pumpWidget(buildPage(createAppState()));

    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('No progress data yet'), findsOneWidget);
    expect(find.text('Analyze skin'), findsOneWidget);
  });

  testWidgets('progress page clamps routine completion from backend data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = createAppState()
      ..progress = const ProgressOverview(
        currentScore: 82,
        improvementPercent: 12,
        currentStreak: 3,
        progressInsight: 'Your skin barrier is trending well.',
      )
      ..trackingToday = const RoutineTrackingToday(
        totalSteps: 4,
        completedSteps: 5,
        morningCompleted: true,
        eveningCompleted: true,
      );

    await tester.pumpWidget(buildPage(appState));

    await tester.pumpAndSettle();

    expect(find.text('Routine Completion'), findsOneWidget);
    expect(find.text('100% complete today.'), findsOneWidget);
  });
}
