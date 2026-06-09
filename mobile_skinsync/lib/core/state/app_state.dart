import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class AppState extends ChangeNotifier {
  AppState({
    required ApiClient apiClient,
    required SessionStore sessionStore,
  })  : _apiClient = apiClient,
        _sessionStore = sessionStore;

  final ApiClient _apiClient;
  final SessionStore _sessionStore;

  AuthSession? session;
  SkinProfile? profile;
  AnalysisResult? latestAnalysis;
  CurrentRegimen? regimen;
  RoutineTrackingToday? trackingToday;
  ProgressOverview? progress;
  DailyLog? todayLog;
  List<ReminderItem> reminders = const [];
  bool isBusy = false;
  String? errorMessage;

  bool get isAuthenticated => session != null;
  AppUser? get user => session?.user;

  Future<void> bootstrap() async {
    session = await _sessionStore.read();
    _apiClient.attachSession(session);
    if (session != null) {
      await refreshHome();
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _runBusy(() async {
      final data = await _apiClient.post('/api/auth/login', body: {
        'email': email,
        'password': password,
      });

      session = AuthSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
      _apiClient.attachSession(session);
      await _sessionStore.save(session!);
      await refreshHome();
    });
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    await _runBusy(() async {
      await _apiClient.post('/api/auth/register', body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      });
      await login(email, password);
    });
  }

  Future<void> logout() async {
    session = null;
    profile = null;
    latestAnalysis = null;
    regimen = null;
    trackingToday = null;
    progress = null;
    todayLog = null;
    reminders = const [];
    _apiClient.attachSession(null);
    await _sessionStore.clear();
    notifyListeners();
  }

  Future<void> refreshHome() async {
    if (session == null) {
      return;
    }

    await _runBusy(() async {
      await Future.wait([
        _loadProfile(),
        _loadLatestAnalysis(),
        _loadRegimen(),
        _loadTracking(),
        _loadProgress(),
        _loadReminders(),
        _loadTodayLog(),
      ]);
    }, showBusy: false);
  }

  Future<void> saveSurvey({
    required String skinType,
    required String budgetLabel,
    required List<String> concerns,
    File? imageFile,
  }) async {
    await _runBusy(() async {
      final monthlyBudget = switch (budgetLabel.toLowerCase()) {
        'tiet kiem' => 300000,
        'trung binh' => 700000,
        'cao cap' => 1200000,
        _ => 500000,
      };

      await _apiClient.put('/api/users/survey', body: {
        'skinType': skinType.toLowerCase(),
        'monthlyBudget': monthlyBudget,
        'budgetLabel': budgetLabel,
        'concerns': concerns,
        'goals': ['Healthy skin barrier', 'Consistent skincare'],
        'allergies': const [],
        'avoidIngredients': const [],
      });

      await _loadProfile();
      if (imageFile != null) {
        await analyzeSkin(imageFile);
      }
    });
  }

  Future<void> analyzeSkin(File imageFile) async {
    await _runBusy(() async {
      final response = await _apiClient.multipart(
        '/api/analysis/scan',
        file: imageFile,
        fields: const {},
      );

      latestAnalysis = AnalysisResult.fromJson(response['analysis'] as Map<String, dynamic>);
      regimen = CurrentRegimen(
        regimenId: response['regimenId'].toString(),
        name: 'AI generated routine',
      );
      await _loadRegimen();
      await _loadTracking();
      await _loadProgress();
    });
  }

  Future<void> toggleRoutineStep(String stepId, bool completed) async {
    await _runBusy(() async {
      if (completed) {
        await _apiClient.delete('/api/routine-tracking/steps/$stepId/complete');
      } else {
        await _apiClient.post('/api/routine-tracking/steps/$stepId/complete');
      }
      await _loadTracking();
      await _loadProgress();
      await _loadTodayLog();
    }, showBusy: false);
  }

  Future<void> saveReminder(String routineType, String time, bool isEnabled) async {
    await _runBusy(() async {
      await _apiClient.put('/api/reminders', body: {
        'time': time,
        'routineType': routineType,
        'isEnabled': isEnabled,
      });
      await _loadReminders();
    }, showBusy: false);
  }

  Future<void> saveDailyLog({
    required String skinFeeling,
    required String notes,
    required int acneLevel,
    required int hydrationLevel,
  }) async {
    await _runBusy(() async {
      await _apiClient.multipart('/api/diary/check-in', fields: {
        'skinFeeling': skinFeeling,
        'notes': notes,
        'morningCompleted': trackingToday?.morningCompleted.toString() ?? 'false',
        'eveningCompleted': trackingToday?.eveningCompleted.toString() ?? 'false',
        'isIrritated': 'false',
        'acneLevel': acneLevel.toString(),
        'hydrationLevel': hydrationLevel.toString(),
      });
      await _loadTodayLog();
      await _loadProgress();
    });
  }

  Future<void> _loadProfile() async {
    try {
      profile = SkinProfile.fromJson(await _apiClient.get('/api/users/survey'));
    } catch (_) {
      profile = null;
    }
  }

  Future<void> _loadLatestAnalysis() async {
    try {
      latestAnalysis = AnalysisResult.fromJson(await _apiClient.get('/api/analysis/latest'));
    } catch (_) {
      latestAnalysis = null;
    }
  }

  Future<void> _loadRegimen() async {
    try {
      regimen = CurrentRegimen.fromJson(await _apiClient.get('/api/regimens/current'));
    } catch (_) {
      regimen = null;
    }
  }

  Future<void> _loadTracking() async {
    try {
      trackingToday = RoutineTrackingToday.fromJson(await _apiClient.get('/api/routine-tracking/today'));
    } catch (_) {
      trackingToday = null;
    }
  }

  Future<void> _loadProgress() async {
    try {
      progress = ProgressOverview.fromJson(await _apiClient.get('/api/progress/overview'));
    } catch (_) {
      progress = null;
    }
  }

  Future<void> _loadReminders() async {
    try {
      final data = await _apiClient.get('/api/reminders');
      final list = (data['items'] as List?) ?? const [];
      reminders = list
          .whereType<Map<String, dynamic>>()
          .map(ReminderItem.fromJson)
          .toList();
    } catch (_) {
      reminders = const [];
    }
  }

  Future<void> _loadTodayLog() async {
    try {
      todayLog = DailyLog.fromJson(await _apiClient.get('/api/diary/today'));
    } catch (_) {
      todayLog = null;
    }
  }

  Future<void> _runBusy(Future<void> Function() action, {bool showBusy = true}) async {
    if (showBusy) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      await action();
    } on ApiException catch (error) {
      errorMessage = error.message;
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }
}
