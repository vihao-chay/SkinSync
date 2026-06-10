import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class AppState extends ChangeNotifier {
  AppState({required ApiClient apiClient, required SessionStore sessionStore})
    : this._(apiClient, sessionStore);

  AppState._(this._apiClient, this._sessionStore) {
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
  bool hasPendingOnboarding = false;
  String? errorMessage;
  int _messageVersion = 0;

  bool get isAuthenticated => session != null;
  bool get shouldShowOnboarding =>
      isAuthenticated &&
      hasPendingOnboarding &&
      profile?.isOnboardingCompleted != true;
  AppUser? get user => session?.user;
  ApiClient get apiClient => _apiClient;
  String get onboardingDisplayNameSeed {
    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty && !_looksLikeEmail(fullName)) {
      return fullName;
    }

    final displayName = profile?.displayName?.trim() ?? '';
    return displayName.isEmpty ? '' : displayName;
  }

  String get profileDisplayName {
    final seededName = onboardingDisplayNameSeed;
    if (seededName.isNotEmpty) {
      return seededName;
    }

    final fullName = user?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return user?.email.trim() ?? 'SkinSync user';
  }

  int get messageVersion => _messageVersion;

  Future<void> bootstrap() async {
    session = await _sessionStore.read();
    _apiClient.attachSession(session);
    if (session != null) {
      hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
        session!.user.id,
      );
      await _loadProfile();
      if (profile?.isOnboardingCompleted == true) {
        await _clearOnboardingPendingForCurrentUser();
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
      final data = await _apiClient.postWithoutRefresh(
        '/api/auth/login',
        body: {'email': email, 'password': password},
      );

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
      await _apiClient.post(
        '/api/auth/register',
        body: {
          'fullName': fullName?.trim() ?? '',
          'email': email,
          'password': password,
          'phone': phone,
        },
      );
      await login(email, password);
      await _replaceCurrentUserFullName(fullName);
      await markOnboardingPendingForCurrentUser();
    });
  }

  Future<void> loginWithGoogle() async {
    await _runBusy(
      () async {
        final googleUrlData = await _apiClient.get(
          '/api/auth/google/url',
          query: {'redirectTo': AppConfig.authCallbackUrl},
        );

        final authUrl = (googleUrlData['url'] ?? '').toString();
        if (authUrl.isEmpty) {
          throw ApiException('Could not start Google login.', 500);
        }

        final callbackUrl = await FlutterWebAuth2.authenticate(
          url: authUrl,
          callbackUrlScheme: AppConfig.authCallbackScheme,
        );

        _throwIfOAuthReturnedError(callbackUrl);
        final accessToken = _extractAccessToken(callbackUrl);
        if (accessToken == null || accessToken.isEmpty) {
          throw ApiException(
            'Google login completed but no Supabase access token was returned.',
            401,
          );
        }

        final data = await _apiClient.postWithoutRefresh(
          '/api/auth/google',
          body: {'supabaseAccessToken': accessToken},
        );

        await _applySessionFromLoginPayload(data);
        await refreshHome();
      },
      onError: (error) {
        if (error is PlatformException) {
          if ((error.code).toLowerCase().contains('cancel')) {
            _setError('Google sign-in was cancelled.');
            return;
          }
        }
      },
    );
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
    hasPendingOnboarding = false;
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
      if (profile?.isOnboardingCompleted == true) {
        await _clearOnboardingPendingForCurrentUser();
      }
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

      await _apiClient.post(
        '/api/user-profiles/onboarding',
        body: {
          'skinType': skinType.toLowerCase(),
          'monthlyBudget': monthlyBudget,
          'budgetLabel': budgetLabel,
          'concerns': concerns,
          'goals': ['Healthy skin barrier', 'Consistent skincare'],
          'allergies': const [],
          'avoidIngredients': const [],
        },
      );

      await _loadProfile();
      if (imageFile != null) {
        await analyzeSkin(imageFile);
      }
    });
  }

  Future<void> analyzeSkin(File imageFile) async {
    await _runBusy(() async {
      final response = await _apiClient.multipart(
        '/api/ai/skin-analysis',
        file: imageFile,
        fields: const {'additionalNote': ''},
      );
      final data = _readAiData(response);
      latestAnalysis = _analysisResultFromAiResponse(data);

      await _generateRoutineFromLatestProfile();
      await _loadRegimen();
      await _loadTracking();
      await _loadProgress();
    });
  }

  Future<AiChatReply> sendAiChat(String message) async {
    return sendAiChatInConversation(message);
  }

  Future<AiChatReply> sendAiChatInConversation(
    String message, {
    String? conversationId,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/chat',
      body: {
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
      },
    );
    final data = _readAiData(response);
    return AiChatReply.fromJson(data);
  }

  Future<List<AiChatConversationSummary>> fetchAiChatConversations() async {
    final response = await _apiClient.get('/api/ai/chat/conversations');
    final data = _readAiCollection(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(AiChatConversationSummary.fromJson)
        .toList();
  }

  Future<AiChatConversationSummary> createAiChatConversation({
    String? title,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/chat/conversations',
      body: {'title': title ?? ''},
    );
    final data = _readAiData(response);
    return AiChatConversationSummary.fromJson(data);
  }

  Future<AiChatConversationDetail> fetchAiChatConversationDetail(
    String conversationId,
  ) async {
    final response = await _apiClient.get(
      '/api/ai/chat/conversations/$conversationId',
    );
    final data = _readAiData(response);
    return AiChatConversationDetail.fromJson(data);
  }

  Future<AiRoutinePlan> generateRoutine({
    String? routinePreference,
    double? budgetMax,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/routine/generate',
      body: {
        'routinePreference':
            routinePreference ??
            _mapRoutinePreference(profile?.currentRoutineLevel),
        if (budgetMax != null)
          'budgetRange': {
            'min': 0,
            'max': budgetMax.round(),
            'currency': 'VND',
          },
      },
    );
    final data = _readAiData(response);
    await _loadRegimen();
    await _loadTracking();
    await _loadProgress();
    notifyListeners();
    return AiRoutinePlan.fromJson(data);
  }

  Future<AiProductRecommendResponse> recommendProducts({
    required String category,
    required String concern,
    double? budgetMax,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/products/recommend',
      body: {
        'category': category,
        'concern': concern,
        if (budgetMax != null)
          'budgetRange': {
            'min': 0,
            'max': budgetMax.round(),
            'currency': 'VND',
          },
      },
    );
    final data = _readAiData(response);
    return AiProductRecommendResponse.fromJson(data);
  }

  Future<AiIngredientCheckResponse> checkIngredients({
    required String productName,
    required String ingredientsText,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/ingredient-check',
      body: {'productName': productName, 'ingredientsText': ingredientsText},
    );
    final data = _readAiData(response);
    return AiIngredientCheckResponse.fromJson(data);
  }

  Future<AiRoutineConflictCheckResponse> checkRoutineConflicts({
    String? routineId,
  }) async {
    final activeRoutineId = routineId ?? regimen?.regimenId;
    if (activeRoutineId == null || activeRoutineId.isEmpty) {
      throw ApiException('Generate a routine before checking conflicts.', 400);
    }

    final response = await _apiClient.post(
      '/api/ai/routine/conflict-check',
      body: {'routineId': activeRoutineId},
    );
    final data = _readAiData(response);
    return AiRoutineConflictCheckResponse.fromJson(data);
  }

  Future<List<AiReportSummary>> fetchAiReports() async {
    final response = await _apiClient.get('/api/ai/reports');
    final data = _readAiCollection(response);
    return data
        .whereType<Map<String, dynamic>>()
        .map(AiReportSummary.fromJson)
        .toList();
  }

  Future<AiReportGenerateResponse> generateAiReport(String reportType) async {
    final response = await _apiClient.post(
      '/api/ai/report/generate',
      body: {'reportType': reportType},
    );
    final data = _readAiData(response);
    return AiReportGenerateResponse.fromJson(data);
  }

  Future<AiReportGenerateResponse> fetchAiReport(String reportId) async {
    final response = await _apiClient.get('/api/ai/reports/$reportId');
    final data = _readAiData(response);
    return AiReportGenerateResponse.fromJson(data);
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

  Future<void> saveReminder(
    String routineType,
    String time,
    bool isEnabled,
  ) async {
    await _runBusy(() async {
      await _apiClient.put(
        '/api/reminders',
        body: {
          'time': time,
          'routineType': routineType,
          'isEnabled': isEnabled,
        },
      );
      await _loadReminders();
    }, showBusy: false);
  }

  Future<AiReminderSuggestResponse> optimizeAiReminders({
    bool applySuggestions = true,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/reminders/suggest',
      body: {'applySuggestions': applySuggestions},
    );
    final data = _readAiData(response);
    final parsed = AiReminderSuggestResponse.fromJson(data);
    await _loadReminders();
    notifyListeners();
    return parsed;
  }

  Future<void> saveDailyLog({
    required String skinFeeling,
    required String notes,
    required int acneLevel,
    required int hydrationLevel,
    File? imageFile,
  }) async {
    await _runBusy(() async {
      await _apiClient.multipart(
        '/api/diary/check-in',
        fields: {
          'skinFeeling': skinFeeling,
          'notes': notes,
          'morningCompleted':
              trackingToday?.morningCompleted.toString() ?? 'false',
          'eveningCompleted':
              trackingToday?.eveningCompleted.toString() ?? 'false',
          'isIrritated': 'false',
          'acneLevel': acneLevel.toString(),
          'hydrationLevel': hydrationLevel.toString(),
        },
        file: imageFile,
      );
      await _loadTodayLog();
      await _loadProgress();
    });
  }

  Future<void> _loadProfile() async {
    try {
      profile = SkinProfile.fromJson(
        await _apiClient.get('/api/user-profiles/onboarding'),
      );
    } catch (_) {
      try {
        profile = SkinProfile.fromJson(
          await _apiClient.get('/api/users/survey'),
        );
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
      final response = await _apiClient.post(
        '/api/user-profiles/onboarding',
        body: payload,
      );
      profile = SkinProfile.fromJson(response);
      await _clearOnboardingPendingForCurrentUser();
      await refreshHome();
    });
  }

  Future<void> markOnboardingPendingForCurrentUser() async {
    final currentUserId = session?.user.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    hasPendingOnboarding = true;
    await _sessionStore.markOnboardingPendingFor(currentUserId);
    notifyListeners();
  }

  Future<void> _clearOnboardingPendingForCurrentUser() async {
    final currentUserId = session?.user.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      hasPendingOnboarding = false;
      return;
    }

    hasPendingOnboarding = false;
    await _sessionStore.clearOnboardingPendingFor(currentUserId);
  }

  Future<void> _loadLatestAnalysis() async {
    try {
      latestAnalysis = AnalysisResult.fromJson(
        await _apiClient.get('/api/analysis/latest'),
      );
    } catch (_) {
      latestAnalysis = null;
    }
  }

  Future<void> _loadRegimen() async {
    try {
      regimen = CurrentRegimen.fromJson(
        await _apiClient.get('/api/regimens/current'),
      );
    } catch (_) {
      regimen = null;
    }
  }

  Future<void> _loadTracking() async {
    try {
      trackingToday = RoutineTrackingToday.fromJson(
        await _apiClient.get('/api/routine-tracking/today'),
      );
    } catch (_) {
      trackingToday = null;
    }
  }

  Future<void> _loadProgress() async {
    try {
      progress = ProgressOverview.fromJson(
        await _apiClient.get('/api/progress/overview'),
      );
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
      _setError(error.message, statusCode: error.statusCode);
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
      final data = await _apiClient.postWithoutRefresh(
        '/api/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

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
      hasPendingOnboarding = false;
      await _sessionStore.clear();
      return;
    }

    hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
      nextSession.user.id,
    );
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
    hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
      session!.user.id,
    );
  }

  Future<void> _replaceCurrentUserFullName(String? fullName) async {
    final trimmed = fullName?.trim() ?? '';
    final currentSession = session;
    if (trimmed.isEmpty || currentSession == null) {
      return;
    }

    session = AuthSession(
      accessToken: currentSession.accessToken,
      refreshToken: currentSession.refreshToken,
      user: currentSession.user.copyWith(fullName: trimmed),
    );
    _apiClient.attachSession(session);
    await _sessionStore.save(session!);
  }

  AuthSession _sessionFromPayload(Map<String, dynamic> data) {
    final accessToken = _readString(data, 'accessToken', 'AccessToken');
    final refreshToken = _readString(data, 'refreshToken', 'RefreshToken');
    final userJson = _readMap(data, 'user', 'User');

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        userJson == null) {
      throw ApiException('Unexpected login response from backend.', 500);
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AppUser.fromJson(userJson),
    );
  }

  String? _readString(
    Map<String, dynamic> data,
    String lowerKey,
    String upperKey,
  ) {
    final value = data[lowerKey] ?? data[upperKey];
    return value?.toString();
  }

  Map<String, dynamic>? _readMap(
    Map<String, dynamic> data,
    String lowerKey,
    String upperKey,
  ) {
    final value = data[lowerKey] ?? data[upperKey];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  Future<void> _generateRoutineFromLatestProfile() async {
    try {
      final routinePreference = _mapRoutinePreference(
        profile?.currentRoutineLevel,
      );
      final monthlyBudget = profile?.monthlyBudget;
      await _apiClient.post(
        '/api/ai/routine/generate',
        body: {
          'routinePreference': routinePreference,
          if (monthlyBudget != null)
            'budgetRange': {
              'min': 0,
              'max': monthlyBudget.round(),
              'currency': 'VND',
            },
        },
      );
    } catch (_) {
      // Keep the analysis result even if routine generation is temporarily unavailable.
    }
  }

  Map<String, dynamic> _readAiData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }

  List<dynamic> _readAiCollection(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data;
    }

    final items = response['items'];
    if (items is List) {
      return items;
    }

    return const [];
  }

  AnalysisResult _analysisResultFromAiResponse(Map<String, dynamic> data) {
    final concerns = ((data['detectedConcerns'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final recommendations = ((data['recommendations'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final warnings = ((data['riskFlags'] as List?) ?? const [])
        .map((item) => item.toString())
        .toList();

    final issues = concerns
        .map(
          (item) => AnalysisIssue(
            issueType: (item['concern'] ?? 'unknown').toString(),
            severityScore: _severityToScore(
              (item['severity'] ?? 'low').toString(),
            ),
            description: item['description']?.toString(),
          ),
        )
        .toList();

    final confidenceScore =
        (concerns.isEmpty
                ? 80
                : (concerns
                              .map(
                                (item) =>
                                    (((item['confidence'] as num?) ?? 0.8) *
                                            100)
                                        .round(),
                              )
                              .reduce((a, b) => a + b) ~/
                          concerns.length)
                      .clamp(0, 100))
            .toInt();
    final overallScore =
        (issues.isEmpty
                ? 88
                : (100 -
                          (issues
                                  .map((item) => item.severityScore)
                                  .reduce((a, b) => a + b) ~/
                              issues.length))
                      .clamp(0, 100))
            .toInt();

    return AnalysisResult(
      id: (data['analysisId'] ?? DateTime.now().millisecondsSinceEpoch)
          .toString(),
      imageUrl: '',
      skinType: profile?.skinType ?? 'Unknown',
      overallScore: overallScore,
      confidenceScore: confidenceScore,
      overview: data['skinSummary']?.toString(),
      disclaimer: data['disclaimer']?.toString(),
      warnings: warnings,
      issues: issues,
      recommendations: recommendations
          .asMap()
          .entries
          .map(
            (entry) => AnalysisRecommendation(
              title: 'Recommendation ${entry.key + 1}',
              content: entry.value,
            ),
          )
          .toList(),
    );
  }

  int _severityToScore(String severity) {
    switch (severity.trim().toLowerCase()) {
      case 'high':
        return 85;
      case 'medium':
        return 60;
      default:
        return 35;
    }
  }

  String _mapRoutinePreference(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.contains('simple') || normalized.contains('beginner')) {
      return 'simple';
    }
    if (normalized.contains('advanced')) {
      return 'advanced';
    }
    return 'balanced';
  }

  void _setError(String message, {int? statusCode}) {
    errorMessage = _friendlyErrorMessage(message, statusCode: statusCode);
    _messageVersion++;
  }

  bool _looksLikeEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  String _friendlyErrorMessage(String message, {int? statusCode}) {
    final raw = message.trim();
    final lower = raw.toLowerCase();

    if (statusCode == 401 ||
        lower.contains('email') && lower.contains('password') ||
        lower.contains('mật khẩu') ||
        lower.contains('khẩu') ||
        lower.contains('khÃ') ||
        lower.contains('kháº©u')) {
      return 'Email or password is incorrect.';
    }

    if (lower.contains('password should contain') ||
        lower.contains('password must contain') ||
        lower.contains('at least one character of each')) {
      return 'Password must include lowercase, uppercase, number, and special character.';
    }

    if (lower.contains('already') && lower.contains('email')) {
      return 'This email is already registered.';
    }

    return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
