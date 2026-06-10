import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class AppState extends ChangeNotifier {
  AppState({
    required ApiClient apiClient,
    required SessionStore sessionStore,
  })  : _apiClient = apiClient,
        _sessionStore = sessionStore {
    _apiClient.configureAuth(
      refreshSessionHandler: _refreshSession,
      sessionChangedHandler: _persistSessionChange,
    );
  }

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
  int _messageVersion = 0;

  bool get isAuthenticated => session != null;
  AppUser? get user => session?.user;
  int get messageVersion => _messageVersion;

  Future<void> bootstrap() async {
    session = await _sessionStore.read();
    _apiClient.attachSession(session);
    if (session != null) {
      await refreshProfileState();
      if (profile?.isOnboardingCompleted == true) {
        await refreshHome();
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Please enter both email and password.');
      notifyListeners();
      throw ApiException('Please enter both email and password.', 400);
    }

    await _runBusy(() async {
      final data = await _apiClient.postWithoutRefresh('/api/auth/login', body: {
        'email': email,
        'password': password,
      });

      await _applySessionFromLoginPayload(data);
      await refreshHome();
    });
  }

  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String phone = '',
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Please complete email and password.');
      notifyListeners();
      throw ApiException('Please complete email and password.', 400);
    }

    await _runBusy(() async {
      await _apiClient.post('/api/auth/register', body: {
        'fullName': fullName?.trim() ?? '',
        'email': email,
        'password': password,
        'phone': phone,
      });
      await login(email, password);
    });
  }

  Future<void> loginWithGoogle() async {
    await _runBusy(() async {
      final googleUrlData = await _apiClient.get(
        '/api/auth/google/url',
        query: {
          'redirectTo': AppConfig.authCallbackUrl,
        },
      );

      final authUrl = (googleUrlData['url'] ?? '').toString();
      if (authUrl.isEmpty) {
        throw ApiException('Could not start Google login.', 500);
      }

      final callbackUrl = await FlutterWebAuth2.authenticate(url: authUrl, callbackUrlScheme: AppConfig.authCallbackScheme);

      _throwIfOAuthReturnedError(callbackUrl);
      final accessToken = _extractAccessToken(callbackUrl);
      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException('Google login completed but no Supabase access token was returned.', 401);
      }

      final data = await _apiClient.postWithoutRefresh('/api/auth/google', body: {
        'supabaseAccessToken': accessToken,
      });

      await _applySessionFromLoginPayload(data);
      await refreshHome();
    }, onError: (error) {
      if (error is PlatformException) {
        if ((error.code).toLowerCase().contains('cancel')) {
          _setError('Google sign-in was cancelled.');
          return;
        }
      }
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

      await _apiClient.post('/api/user-profiles/onboarding', body: {
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
      profile = SkinProfile.fromJson(await _apiClient.get('/api/user-profiles/onboarding'));
    } catch (_) {
      try {
        profile = SkinProfile.fromJson(await _apiClient.get('/api/users/survey'));
      } catch (_) {
        profile = null;
      }
    }
  }

  Future<void> refreshProfileState() async {
    await _loadProfile();
    notifyListeners();
  }

  Future<void> submitOnboarding(Map<String, dynamic> payload) async {
    await _runBusy(() async {
      final response = await _apiClient.post('/api/user-profiles/onboarding', body: payload);
      profile = SkinProfile.fromJson(response);
      await refreshHome();
    });
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

  Future<void> _runBusyInternal(
    Future<void> Function() action, {
    required bool showBusy,
    void Function(Object error)? onError,
  }) async {
    if (showBusy) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      await action();
    } on ApiException catch (error) {
      _setError(error.message);
      onError?.call(error);
      rethrow;
    } on PlatformException catch (error) {
      _setError(error.message ?? 'Platform error occurred.');
      onError?.call(error);
      rethrow;
    } catch (error) {
      _setError('Unexpected error occurred. Please try again.');
      onError?.call(error);
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    bool showBusy = true,
    void Function(Object error)? onError,
  }) async {
    await _runBusyInternal(action, showBusy: showBusy, onError: onError);
  }

  Future<AuthSession?> _refreshSession(String refreshToken) async {
    try {
      final data = await _apiClient.postWithoutRefresh('/api/auth/refresh', body: {
        'refreshToken': refreshToken,
      });

      final refreshed = _sessionFromPayload(data);
      return refreshed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSessionChange(AuthSession? nextSession) async {
    session = nextSession;
    _apiClient.attachSession(nextSession);
    if (nextSession == null) {
      await _sessionStore.clear();
      return;
    }

    await _sessionStore.save(nextSession);
  }

  String? _extractAccessToken(String callbackUrl) {
    final uri = Uri.parse(callbackUrl);
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      return fragmentParams['access_token'];
    }

    return uri.queryParameters['access_token'];
  }

  void _throwIfOAuthReturnedError(String callbackUrl) {
    final uri = Uri.parse(callbackUrl);
    Map<String, String> params = uri.queryParameters;
    if (params.isEmpty && uri.fragment.isNotEmpty) {
      params = Uri.splitQueryString(uri.fragment);
    }

    final error = params['error'];
    final description = params['error_description'];
    if (error != null && error.isNotEmpty) {
      throw ApiException(description ?? error, 401);
    }
  }

  Future<void> _applySessionFromLoginPayload(Map<String, dynamic> data) async {
    session = _sessionFromPayload(data);
    _apiClient.attachSession(session);
    await _sessionStore.save(session!);
  }

  AuthSession _sessionFromPayload(Map<String, dynamic> data) {
    final accessToken = _readString(data, 'accessToken', 'AccessToken');
    final refreshToken = _readString(data, 'refreshToken', 'RefreshToken');
    final userJson = _readMap(data, 'user', 'User');

    if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty || userJson == null) {
      throw ApiException('Unexpected login response from backend.', 500);
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AppUser.fromJson(userJson),
    );
  }

  String? _readString(Map<String, dynamic> data, String lowerKey, String upperKey) {
    final value = data[lowerKey] ?? data[upperKey];
    return value?.toString();
  }

  Map<String, dynamic>? _readMap(Map<String, dynamic> data, String lowerKey, String upperKey) {
    final value = data[lowerKey] ?? data[upperKey];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  void _setError(String message) {
    errorMessage = message;
    _messageVersion++;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
