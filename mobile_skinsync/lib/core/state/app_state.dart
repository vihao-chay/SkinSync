import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
  List<SubscriptionPlan> subscriptionPlans = const [];
  CurrentSubscription? subscription;
  bool isBusy = false;
  bool isBootstrapping = true;
  bool isRefreshingHome = false;
  bool isRefreshingProductRecommendations = false;
  bool hasPendingOnboarding = false;
  bool hasResolvedProfileState = false;
  String? errorMessage;
  String? profileLoadErrorMessage;
  String? analysisLoadErrorMessage;
  String? regimenLoadErrorMessage;
  String? trackingLoadErrorMessage;
  String? progressLoadErrorMessage;
  String? remindersLoadErrorMessage;
  String? todayLogLoadErrorMessage;
  String? subscriptionPlansLoadErrorMessage;
  String? subscriptionStatusLoadErrorMessage;
  int _messageVersion = 0;
  Future<AiProductRecommendResponse?>? _productRecommendationRefreshTask;
  String? _productRecommendationRefreshAnalysisId;
  Future<void>? _refreshHomeFuture;

  bool get isAuthenticated => session != null;
  bool get shouldShowOnboarding =>
      isAuthenticated &&
      (hasPendingOnboarding ||
          (hasResolvedProfileState &&
              profileLoadErrorMessage == null &&
              !_hasCompletedOnboarding(profile)));
  AppUser? get user => session?.user;
  ApiClient get apiClient => _apiClient;
  String? get homeDataErrorMessage => isRefreshingHome
      ? null
      : _firstErrorMessage([
          profileLoadErrorMessage,
          analysisLoadErrorMessage,
          regimenLoadErrorMessage,
          trackingLoadErrorMessage,
          progressLoadErrorMessage,
          todayLogLoadErrorMessage,
        ]);
  String? get routineDataErrorMessage => isRefreshingHome
      ? null
      : _firstErrorMessage([
          regimenLoadErrorMessage,
          trackingLoadErrorMessage,
          remindersLoadErrorMessage,
        ]);
  String? get todayCheckupDataErrorMessage => isRefreshingHome
      ? null
      : _firstErrorMessage([
          regimenLoadErrorMessage,
          trackingLoadErrorMessage,
          todayLogLoadErrorMessage,
        ]);
  String? get membershipLoadErrorMessage => isRefreshingHome
      ? null
      : _firstErrorMessage([
          subscriptionPlansLoadErrorMessage,
          subscriptionStatusLoadErrorMessage,
        ]);
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
    isBootstrapping = true;
    notifyListeners();

    try {
      unawaited(_recordFirstAppOpen());
      profile = null;
      latestAnalysis = null;
      regimen = null;
      trackingToday = null;
      progress = null;
      todayLog = null;
      reminders = const [];
      subscriptionPlans = const [];
      subscription = null;
      hasPendingOnboarding = false;
      hasResolvedProfileState = false;
      _resetLoadErrors();

      final savedSession = await _sessionStore.read();
      if (savedSession != null) {
        final restoredSession = await _withSelectedAvatar(savedSession);
        session = restoredSession;
        _apiClient.attachSession(restoredSession);

        final currentUserId = restoredSession.user.id;
        if (currentUserId.isNotEmpty) {
          hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
            currentUserId,
          );
        }
        await refreshHome();
      } else {
        session = null;
        _apiClient.attachSession(null);
      }
    } catch (_) {
      session = null;
      _apiClient.attachSession(null);
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> _recordFirstAppOpen() async {
    try {
      if (await _sessionStore.isAppInstallRecorded()) {
        return;
      }

      var installationId = await _sessionStore.readInstallationId();
      if (installationId == null || installationId.isEmpty) {
        installationId = _createInstallationId();
        await _sessionStore.saveInstallationId(installationId);
      }

      await _apiClient.postWithoutRefresh(
        '/api/app-installs/record',
        body: {
          'installationId': installationId,
          'platform': Platform.operatingSystem,
          'appVersion': AppConfig.appVersion,
        },
      );
      await _sessionStore.markAppInstallRecorded();
    } catch (error) {
      debugPrint('[SkinSync] app install record skipped: $error');
    }
  }

  String _createInstallationId() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final token = base64UrlEncode(bytes).replaceAll('=', '');
    return '${DateTime.now().microsecondsSinceEpoch}-$token';
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
      await _resolvePostAuthProfileState();
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
        await _resolvePostAuthProfileState();
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

  Future<void> updateAvatarSelection(String avatarUrl) async {
    final trimmed = avatarUrl.trim();
    final currentSession = session;
    if (trimmed.isEmpty || currentSession == null) {
      return;
    }

    await _apiClient.put(
      '/api/auth/avatar/selection',
      body: {'avatarUrl': trimmed},
    );
    await _sessionStore.saveSelectedAvatarFor(currentSession.user.id, trimmed);

    session = AuthSession(
      accessToken: currentSession.accessToken,
      refreshToken: currentSession.refreshToken,
      user: currentSession.user.copyWith(avatarUrl: trimmed),
    );
    _apiClient.attachSession(session);
    await _sessionStore.save(session!);
    notifyListeners();
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
    subscriptionPlans = const [];
    subscription = null;
    hasPendingOnboarding = false;
    hasResolvedProfileState = false;
    isRefreshingHome = false;
    _refreshHomeFuture = null;
    _resetLoadErrors();
    _apiClient.attachSession(null);
    await _sessionStore.clear();
    notifyListeners();
  }

  Future<void> refreshHome() async {
    if (session == null) {
      return;
    }

    final currentRefresh = _refreshHomeFuture;
    if (currentRefresh != null) {
      return currentRefresh;
    }

    final nextRefresh = _refreshHomeInternal();
    _refreshHomeFuture = nextRefresh;
    try {
      await nextRefresh;
    } finally {
      if (identical(_refreshHomeFuture, nextRefresh)) {
        _refreshHomeFuture = null;
      }
    }
  }

  Future<void> _refreshHomeInternal() async {
    isRefreshingHome = true;
    notifyListeners();
    try {
      await _runBusy(() async {
        await _loadProfile();
        await _loadLatestAnalysis();
        await _loadSubscription();
        await _syncOnboardingPendingFromProfile();
        notifyListeners();

        await _loadRegimen();
        notifyListeners();
        await _loadTracking();
        await _loadProgress();
        await _loadReminders();
        await _loadTodayLog();
      }, showBusy: false);
    } finally {
      isRefreshingHome = false;
      notifyListeners();
    }
  }

  Future<void> _resolvePostAuthProfileState() async {
    await _loadProfile();
    await _syncOnboardingPendingFromProfile();
  }

  Future<void> _syncOnboardingPendingFromProfile() async {
    if (profileLoadErrorMessage != null || !hasResolvedProfileState) {
      return;
    }

    if (_hasCompletedOnboarding(profile)) {
      await _clearOnboardingPendingForCurrentUser();
    } else {
      await _markOnboardingPendingForCurrentUser();
    }
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
    await analyzeSkinPhoto(imageFile);
  }

  Future<AnalysisResult> analyzeSkinPhoto(
    File imageFile, {
    String source = 'unknown',
    String additionalNote = '',
  }) async {
    late AnalysisResult parsedResult;
    await _runBusy(() async {
      final response = await _apiClient.multipart(
        '/api/skin-analysis',
        file: imageFile,
        fields: {'additionalNote': additionalNote, 'source': source},
        timeout: const Duration(seconds: 240),
      );
      parsedResult = _analysisResultFromAiResponse(response);
      latestAnalysis = parsedResult;

      await _loadProgress();
    });
    final primaryConcern = parsedResult.issues.isNotEmpty
        ? parsedResult.issues.first.issueType
        : null;
    unawaited(
      refreshRecommendationsForLatestAnalysis(
        concern: primaryConcern,
        silent: true,
      ),
    );
    return parsedResult;
  }

  Future<AiChatReply> sendAiChat(String message) async {
    return sendAiChatInConversation(message);
  }

  Future<AiChatReply> sendAiChatInConversation(
    String message, {
    String? conversationId,
    String? entryPoint,
    String? referenceId,
    String? prefillContext,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/ai/chat',
        body: {
          'message': message,
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
          if (entryPoint != null && entryPoint.isNotEmpty)
            'entryPoint': entryPoint,
          if (referenceId != null && referenceId.isNotEmpty)
            'referenceId': referenceId,
          if (prefillContext != null && prefillContext.isNotEmpty)
            'prefillContext': prefillContext,
        },
      );
      final data = _readAiData(response);
      return AiChatReply.fromJson(data);
    } on ApiException catch (error) {
      _setError(error.message, statusCode: error.statusCode);
      notifyListeners();
      rethrow;
    } catch (_) {
      _setError('Could not get a reply right now.');
      notifyListeners();
      rethrow;
    }
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

  Future<AiProductRecommendResponse> getLatestRecommendations() async {
    debugPrint('[SkinSync] latest recommendation read');
    return _fetchCatalogRecommendations();
  }

  Future<AiProductRecommendResponse> generateRecommendations({
    String? category,
    String? concern,
    double? budgetMax,
    int limitPerCategory = 5,
  }) async {
    debugPrint('[SkinSync] manual recommendation generate');
    return _fetchCatalogRecommendations(
      concernOverride: concern,
      categoryOverride: category,
    );
  }

  Future<AiProductRecommendResponse> _fetchCatalogRecommendations({
    String? concernOverride,
    String? categoryOverride,
  }) async {
    final request = _buildRecommendationRequest(
      concernOverride: concernOverride,
    );
    if (request == null) {
      return _emptyRecommendationResponse(
        message:
            'Complete your skin profile first so SkinSync can generate recommendations from the product catalog.',
      );
    }

    final response = await _apiClient.post(
      '/api/recommendations',
      timeout: const Duration(seconds: 240),
      body: request,
    );
    return _mapRecommendationEngineResponse(
      response,
      categoryOverride: categoryOverride,
    );
  }

  Future<AiProductRecommendResponse?> refreshRecommendationsForLatestAnalysis({
    String? category,
    String? concern,
    double? budgetMax,
    int limitPerCategory = 5,
    bool silent = true,
  }) {
    final analysis = latestAnalysis;
    final analysisId = analysis?.id.trim();
    if (analysis == null || analysisId == null || analysisId.isEmpty) {
      return Future.value(null);
    }

    final activeTask = _productRecommendationRefreshTask;
    if (activeTask != null &&
        _productRecommendationRefreshAnalysisId == analysisId) {
      return activeTask;
    }

    late final Future<AiProductRecommendResponse?> task;
    task =
        _generateRecommendationsForLatestAnalysis(
          category: category,
          concern: concern,
          budgetMax: budgetMax,
          limitPerCategory: limitPerCategory,
          silent: silent,
        ).whenComplete(() {
          if (_productRecommendationRefreshTask == task) {
            _productRecommendationRefreshTask = null;
            _productRecommendationRefreshAnalysisId = null;
            isRefreshingProductRecommendations = false;
            notifyListeners();
          }
        });

    _productRecommendationRefreshTask = task;
    _productRecommendationRefreshAnalysisId = analysisId;
    isRefreshingProductRecommendations = true;
    notifyListeners();
    return task;
  }

  Future<AiProductRecommendResponse?>
  _generateRecommendationsForLatestAnalysis({
    String? category,
    String? concern,
    double? budgetMax,
    int limitPerCategory = 5,
    bool silent = true,
  }) async {
    try {
      return await generateRecommendations(
        category: category,
        concern: concern,
        budgetMax: budgetMax,
        limitPerCategory: limitPerCategory,
      );
    } on ApiException catch (error) {
      if (!silent) {
        _setError(error.message, statusCode: error.statusCode);
        notifyListeners();
        rethrow;
      }
      debugPrint(
        '[SkinSync] product recommendation refresh skipped: ${error.message}',
      );
      return null;
    } catch (error) {
      if (!silent) {
        _setError('Could not refresh product recommendations right now.');
        notifyListeners();
        rethrow;
      }
      debugPrint('[SkinSync] product recommendation refresh skipped: $error');
      return null;
    }
  }

  Future<ProductDetail> getProductDetail(String productId) async {
    final response = await _apiClient.get('/api/products/$productId');
    final data = _readAiData(response);
    return ProductDetail.fromJson(data);
  }

  Future<List<ProductDetail>> getProductCatalog({
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/products',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    );
    return _readAiCollection(
      response,
    ).whereType<Map<String, dynamic>>().map(ProductDetail.fromJson).toList();
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

  Future<AiSavedProduct> saveIngredientProduct({
    required String productName,
    required String ingredientsText,
    String category = 'Custom',
  }) async {
    final response = await _apiClient.post(
      '/api/ai/ingredient-check/save-product',
      body: {
        'productName': productName,
        'ingredientsText': ingredientsText,
        'category': category,
      },
    );
    final data = _readAiData(response);
    return AiSavedProduct.fromJson(data);
  }

  Future<AiAddProductToRoutineResponse> addProductToRoutine({
    required String productId,
    required String routineType,
    bool allowConflicts = false,
    String? frequency,
    String? notes,
  }) async {
    debugPrint('[SkinSync] routine add');
    final response = await _apiClient.post(
      '/api/ai/products/$productId/add-to-routine',
      body: {
        'routineType': routineType,
        'allowConflicts': allowConflicts,
        if (frequency != null && frequency.trim().isNotEmpty)
          'frequency': frequency,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
      },
    );
    final data = _readAiData(response);
    final parsed = AiAddProductToRoutineResponse.fromJson(data);
    if (parsed.routine != null) {
      regimen = parsed.routine;
    } else {
      await _loadRegimen();
    }
    await _loadTracking();
    await _loadProgress();
    notifyListeners();
    return parsed;
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

  Future<void> refreshSubscription() async {
    await _runBusy(() async {
      await _loadSubscription();
    }, showBusy: false);
  }

  Future<void> subscribeToPlan(String planCode) async {
    final normalized = planCode.trim().toLowerCase();
    if (normalized != 'plus' && normalized != 'premium') {
      throw ApiException('Please choose Plus or Premium.', 400);
    }

    await _runBusy(() async {
      final data = await _apiClient.post(
        '/api/subscriptions/subscribe',
        body: {'planCode': normalized},
      );
      subscription = CurrentSubscription.fromJson(data);
      await _replaceCurrentUserPlanType(subscription?.plan.code);
    });
  }

  Future<PaymentLinkResponse> createPaymentLink(String planCode) async {
    final normalized = planCode.trim().toLowerCase();
    if (normalized != 'plus' && normalized != 'premium') {
      throw ApiException('Vui lòng chọn gói Plus hoặc Premium.', 400);
    }

    late PaymentLinkResponse paymentRes;
    await _runBusy(() async {
      final response = await _apiClient.post(
        '/api/payment/create-payment-link',
        body: {'planCode': normalized},
      );
      final data = _readAiData(response);
      paymentRes = PaymentLinkResponse.fromJson(data);
    });
    return paymentRes;
  }

  Future<VerifyPaymentResponse> verifyPayment(int orderCode) async {
    late VerifyPaymentResponse verifyRes;
    await _runBusy(() async {
      final response = await _apiClient.get('/api/payment/verify/$orderCode');
      final data = _readAiData(response);
      verifyRes = VerifyPaymentResponse.fromJson(data);
      if (verifyRes.status == 'paid') {
        await _loadSubscription();
      }
    }, showBusy: false);
    return verifyRes;
  }

  Future<void> cancelSubscription() async {
    await _runBusy(() async {
      final data = await _apiClient.post('/api/subscriptions/cancel');
      subscription = CurrentSubscription.fromJson(data);
      await _replaceCurrentUserPlanType(subscription?.plan.code ?? 'free');
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
    int? acneLevel,
    int? drynessLevel,
    int? rednessLevel,
    int? hydrationLevel,
    File? imageFile,
    List<String>? completedStepIds,
  }) async {
    debugPrint('[SkinSync] check-up save');
    await _runBusy(() async {
      final normalizedFeeling = skinFeeling.trim().toLowerCase();
      final fields = <String, String>{
        'skinFeeling': normalizedFeeling,
        'notes': notes,
        'morningCompleted':
            trackingToday?.morningCompleted.toString() ?? 'false',
        'eveningCompleted':
            trackingToday?.eveningCompleted.toString() ?? 'false',
        'isIrritated':
            (normalizedFeeling == 'irritated' ||
                    normalizedFeeling == 'sensitive')
                .toString(),
        if (completedStepIds != null)
          'completedStepIdsJson': jsonEncode(completedStepIds),
      };
      if (acneLevel != null) {
        fields['acneLevel'] = acneLevel.toString();
      }
      if (drynessLevel != null) {
        fields['drynessLevel'] = drynessLevel.toString();
      }
      if (rednessLevel != null) {
        fields['rednessLevel'] = rednessLevel.toString();
      }
      if (hydrationLevel != null) {
        fields['hydrationLevel'] = hydrationLevel.toString();
      }

      await _apiClient.multipart(
        '/api/diary/check-in',
        fields: fields,
        file: imageFile,
      );
      await _loadTracking();
      await _loadTodayLog();
      await _loadProgress();
    });
  }

  Future<void> _loadProfile() async {
    profileLoadErrorMessage = null;
    hasResolvedProfileState = false;
    try {
      profile = SkinProfile.fromJson(
        await _apiClient.get('/api/user-profiles/onboarding'),
      );
      hasResolvedProfileState = true;
      return;
    } on ApiException catch (error) {
      if (!_isExpectedEmptyError(error)) {
        profileLoadErrorMessage = _friendlyErrorMessage(
          error.message,
          statusCode: error.statusCode,
        );
      }
    } catch (_) {
      profileLoadErrorMessage =
          'Could not load your profile right now. Please try again.';
    }

    try {
      profile = SkinProfile.fromJson(await _apiClient.get('/api/users/survey'));
      profileLoadErrorMessage = null;
      hasResolvedProfileState = true;
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        profile = null;
        profileLoadErrorMessage = null;
        hasResolvedProfileState = true;
        return;
      }

      profileLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      profileLoadErrorMessage =
          'Could not load your profile right now. Please try again.';
    }
  }

  Future<void> refreshProfileState() async {
    await _loadProfile();
    notifyListeners();
  }

  Future<void> saveSkinProfile(
    Map<String, dynamic> payload, {
    bool refreshRoutine = false,
  }) async {
    await _runBusy(() async {
      final response = await _apiClient.post(
        '/api/user-profiles/onboarding',
        body: payload,
      );
      profile = SkinProfile.fromJson(response);
      profileLoadErrorMessage = null;
      hasResolvedProfileState = true;
      await _clearOnboardingPendingForCurrentUser();
      if (refreshRoutine) {
        await _generateRoutineFromLatestProfile();
      }
      await refreshHome();
    });
  }

  Future<void> submitOnboarding(Map<String, dynamic> payload) async {
    await saveSkinProfile(payload);
  }

  Future<void> markOnboardingPendingForCurrentUser() async {
    await _markOnboardingPendingForCurrentUser();
    notifyListeners();
  }

  Future<void> _markOnboardingPendingForCurrentUser() async {
    final currentUserId = session?.user.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      return;
    }

    hasPendingOnboarding = true;
    await _sessionStore.markOnboardingPendingFor(currentUserId);
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
    analysisLoadErrorMessage = null;
    String? pendingErrorMessage;
    final existingAnalysis = latestAnalysis;
    try {
      final history = await _apiClient.get('/api/skin-analysis/history');
      final items = (history['items'] as List?) ?? const [];
      if (items.isNotEmpty && items.first is Map<String, dynamic>) {
        final candidate = _analysisResultFromAiResponse(
          items.first as Map<String, dynamic>,
        );
        latestAnalysis = _mergeLatestAnalysis(existingAnalysis, candidate);
        return;
      }
    } on ApiException catch (error) {
      if (!_isExpectedEmptyError(error)) {
        pendingErrorMessage = _friendlyErrorMessage(
          error.message,
          statusCode: error.statusCode,
        );
      }
    } catch (_) {
      pendingErrorMessage =
          'Could not load your latest analysis right now. Please try again.';
    }

    try {
      final candidate = AnalysisResult.fromJson(
        await _apiClient.get('/api/analysis/latest'),
      );
      latestAnalysis = _mergeLatestAnalysis(existingAnalysis, candidate);
      analysisLoadErrorMessage = null;
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        latestAnalysis = null;
        analysisLoadErrorMessage = pendingErrorMessage;
        return;
      }

      latestAnalysis = null;
      analysisLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      latestAnalysis = null;
      analysisLoadErrorMessage =
          pendingErrorMessage ??
          'Could not load your latest analysis right now. Please try again.';
    }
  }

  Future<void> _loadRegimen() async {
    regimenLoadErrorMessage = null;
    try {
      regimen = CurrentRegimen.fromJson(
        await _apiClient.get('/api/regimens/current'),
      );
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        regimen = null;
        return;
      }

      regimenLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      regimenLoadErrorMessage =
          'Could not load your routine right now. Please try again.';
    }
  }

  Future<void> _loadTracking() async {
    trackingLoadErrorMessage = null;
    try {
      trackingToday = RoutineTrackingToday.fromJson(
        await _apiClient.get('/api/routine-tracking/today'),
      );
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        trackingToday = null;
        return;
      }

      trackingLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      trackingLoadErrorMessage =
          'Could not load today\'s routine tracking right now. Please try again.';
    }
  }

  Future<void> _loadProgress() async {
    progressLoadErrorMessage = null;
    try {
      progress = ProgressOverview.fromJson(
        await _apiClient.get('/api/progress/overview'),
      );
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        progress = null;
        return;
      }

      progressLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      progressLoadErrorMessage =
          'Could not load your progress overview right now. Please try again.';
    }
  }

  Future<void> _loadReminders() async {
    remindersLoadErrorMessage = null;
    try {
      final data = await _apiClient.get('/api/reminders');
      final list = (data['items'] as List?) ?? const [];
      reminders = list
          .whereType<Map<String, dynamic>>()
          .map(ReminderItem.fromJson)
          .toList();
    } on ApiException catch (error) {
      reminders = const [];
      if (_isExpectedEmptyError(error)) {
        return;
      }

      remindersLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      reminders = const [];
      remindersLoadErrorMessage =
          'Could not load your reminders right now. Please try again.';
    }
  }

  Future<void> _loadTodayLog() async {
    todayLogLoadErrorMessage = null;
    try {
      todayLog = DailyLog.fromJson(await _apiClient.get('/api/diary/today'));
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        todayLog = null;
        return;
      }

      todayLogLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      todayLogLoadErrorMessage =
          'Could not load today\'s diary right now. Please try again.';
    }
  }

  Future<void> _loadSubscription() async {
    subscriptionPlansLoadErrorMessage = null;
    subscriptionStatusLoadErrorMessage = null;
    try {
      final planData = await _apiClient.get('/api/subscription-plans');
      final items = (planData['items'] as List?) ?? const [];
      subscriptionPlans = items
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList();
    } on ApiException catch (error) {
      subscriptionPlans = const [];
      if (!_isExpectedEmptyError(error)) {
        subscriptionPlansLoadErrorMessage = _friendlyErrorMessage(
          error.message,
          statusCode: error.statusCode,
        );
      }
    } catch (_) {
      subscriptionPlans = const [];
      subscriptionPlansLoadErrorMessage =
          'Could not load membership plans right now. Please try again.';
    }

    try {
      subscription = CurrentSubscription.fromJson(
        await _apiClient.get('/api/subscriptions/me'),
      );
      await _replaceCurrentUserPlanType(subscription?.plan.code);
    } on ApiException catch (error) {
      if (_isExpectedEmptyError(error)) {
        subscription = null;
        return;
      }

      subscriptionStatusLoadErrorMessage = _friendlyErrorMessage(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      subscriptionStatusLoadErrorMessage =
          'Could not load your membership right now. Please try again.';
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
      return _withSelectedAvatar(refreshed);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSessionChange(AuthSession? nextSession) async {
    if (nextSession == null) {
      session = null;
      _apiClient.attachSession(null);
      hasPendingOnboarding = false;
      hasResolvedProfileState = false;
      isRefreshingHome = false;
      _refreshHomeFuture = null;
      _resetLoadErrors();
      await _sessionStore.clear();
      return;
    }

    final restoredSession = await _withSelectedAvatar(nextSession);
    session = restoredSession;
    _apiClient.attachSession(restoredSession);

    hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
      restoredSession.user.id,
    );
    await _sessionStore.save(restoredSession);
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
    session = await _withSelectedAvatar(_sessionFromPayload(data));
    _apiClient.attachSession(session);
    await _sessionStore.save(session!);
    hasPendingOnboarding = await _sessionStore.isOnboardingPendingFor(
      session!.user.id,
    );
    hasResolvedProfileState = false;
    _resetLoadErrors();
  }

  Future<AuthSession> _withSelectedAvatar(AuthSession source) async {
    var selectedAvatar = await _sessionStore.selectedAvatarFor(source.user.id);
    final currentAvatar = source.user.avatarUrl?.trim() ?? '';
    if (selectedAvatar == null && currentAvatar.startsWith('assets/avatars/')) {
      await _sessionStore.saveSelectedAvatarFor(source.user.id, currentAvatar);
      selectedAvatar = currentAvatar;
    }

    if (selectedAvatar == null || selectedAvatar == source.user.avatarUrl) {
      return source;
    }

    return AuthSession(
      accessToken: source.accessToken,
      refreshToken: source.refreshToken,
      user: source.user.copyWith(avatarUrl: selectedAvatar),
    );
  }

  Map<String, dynamic>? _buildRecommendationRequest({String? concernOverride}) {
    final skinType = profile?.skinType?.trim().isNotEmpty == true
        ? profile!.skinType!.trim()
        : latestAnalysis?.skinType.trim();
    if (skinType == null || skinType.isEmpty) {
      return null;
    }

    final concerns = <String>{
      ...?profile?.concerns.where((item) => item.trim().isNotEmpty),
      ...?latestAnalysis?.issues
          .map((item) => item.issueType.trim())
          .where((item) => item.isNotEmpty),
    };
    final normalizedConcern = concernOverride?.trim();
    if (normalizedConcern?.isNotEmpty == true) {
      concerns.add(normalizedConcern!);
    }

    final goals = <String>{
      ...?profile?.goals.where((item) => item.trim().isNotEmpty),
      ...?profile?.skinGoals.where((item) => item.trim().isNotEmpty),
    };

    return {
      'skinType': skinType,
      'concerns': concerns.toList(),
      'sensitivity': _mapSensitivityLevel(profile?.sensitivityLevel),
      'goals': goals.toList(),
    };
  }

  AiProductRecommendResponse _mapRecommendationEngineResponse(
    Map<String, dynamic> json, {
    String? categoryOverride,
  }) {
    final generatedAt = DateTime.tryParse(
      json['generatedAt']?.toString() ?? '',
    );
    final compatibility =
        (json['overallCompatibilityScore'] as num?)?.round() ?? 0;
    final skinSummary = json['skinSummary'] is Map<String, dynamic>
        ? json['skinSummary'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final morning = ((json['morningRoutine'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_mapRecommendationProduct)
        .toList();
    final night = ((json['nightRoutine'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_mapRecommendationProduct)
        .toList();
    final selectedProducts = [...morning, ...night];

    final categories = <AiProductRecommendationCategory>[
      ..._buildCategoriesFromProducts(selectedProducts),
      ...((json['alternatives'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_mapAlternativeCategory),
    ];

    final normalizedCategory = categoryOverride?.trim().toLowerCase();
    final visibleCategories =
        normalizedCategory == null || normalizedCategory.isEmpty
        ? categories
        : categories.where((category) {
            final key = category.key.trim().toLowerCase();
            final label = category.label.trim().toLowerCase();
            return key == normalizedCategory || label == normalizedCategory;
          }).toList();

    final products = visibleCategories
        .expand((category) => category.items)
        .toList();
    final warnings = ((json['warnings'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return AiProductRecommendResponse(
      hasRecommendation: products.isNotEmpty,
      status: products.isNotEmpty ? 'completed' : 'missing',
      summary: products.isEmpty
          ? null
          : 'Overall compatibility: $compatibility%. Recommendations were built from the live product catalog.',
      products: products,
      categories: [
        if (products.isNotEmpty)
          AiProductRecommendationCategory(
            key: 'all',
            label: 'All',
            reason:
                'Combined morning, night, and alternative product suggestions.',
            items: products,
          ),
        ...visibleCategories,
      ],
      profileSummary: AiProductRecommendationProfileSummary(
        skinType:
            (skinSummary['skinType'] ?? profile?.skinType ?? 'Not provided yet')
                .toString(),
        concerns:
            ((skinSummary['concerns'] as List?) ??
                    profile?.concerns ??
                    const <String>[])
                .map((item) => item.toString())
                .toList(),
        budget: profile?.budgetLabel?.trim().isNotEmpty == true
            ? profile!.budgetLabel!.trim()
            : profile?.monthlyBudget != null
            ? '${profile!.monthlyBudget!.round()} VND'
            : 'Not provided yet',
      ),
      message: products.isNotEmpty
          ? (warnings.isEmpty ? null : warnings.first)
          : 'No compatible recommendations were available from the current product catalog.',
      note: warnings.skip(1).join('\n').trim().isEmpty
          ? null
          : warnings.skip(1).join('\n').trim(),
      generatedAt: generatedAt,
    );
  }

  AiRecommendedProduct _mapRecommendationProduct(Map<String, dynamic> json) {
    final reasons = ((json['reasons'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final reason = (json['reason'] ?? '').toString().trim();
    final cautions = ((json['cautions'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final ingredients = ((json['keyIngredients'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return AiRecommendedProduct(
      productId: json['productId'].toString(),
      name: (json['name'] ?? '') as String,
      brand: (json['brand'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'VND') as String,
      matchScore: (json['score'] as num?)?.round() ?? 0,
      matchPercent: (json['score'] as num?)?.round(),
      aiReason: reasons.isNotEmpty ? reasons.join(' ') : reason,
      whyRecommended: reason.isNotEmpty
          ? reason
          : (reasons.isEmpty ? null : reasons.join(' ')),
      warnings: cautions,
      cautions: cautions,
      imageUrl: json['imageUrl'] as String?,
      description: (json['reasons'] as List?) != null && reasons.isNotEmpty
          ? reasons.join(' ')
          : null,
      ingredientsText: ingredients.join(', '),
      usageGuide: null,
    );
  }

  AiProductRecommendationCategory _mapAlternativeCategory(
    Map<String, dynamic> json,
  ) {
    final products = ((json['products'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_mapRecommendationProduct)
        .toList();
    return AiProductRecommendationCategory(
      key: _normalizeRecommendationCategoryKey(
        (json['categoryKey'] ?? json['categoryName'] ?? '').toString(),
      ),
      label: (json['categoryName'] ?? json['categoryKey'] ?? 'Alternatives')
          .toString(),
      reason:
          'Alternative options for the ${(json['routineTime'] ?? '').toString().toLowerCase()} routine.',
      items: products,
    );
  }

  List<AiProductRecommendationCategory> _buildCategoriesFromProducts(
    List<AiRecommendedProduct> products,
  ) {
    final byCategory = <String, List<AiRecommendedProduct>>{};
    for (final product in products) {
      final key = _normalizeRecommendationCategoryKey(product.category);
      byCategory.putIfAbsent(key, () => <AiRecommendedProduct>[]).add(product);
    }

    return byCategory.entries
        .map(
          (entry) => AiProductRecommendationCategory(
            key: entry.key,
            label: _titleCase(entry.key),
            reason:
                'Recommended products for ${_titleCase(entry.key).toLowerCase()}.',
            items: entry.value,
          ),
        )
        .toList();
  }

  AiProductRecommendResponse _emptyRecommendationResponse({
    required String message,
  }) {
    return AiProductRecommendResponse(
      hasRecommendation: false,
      status: 'missing',
      message: message,
      generatedAt: DateTime.now(),
      profileSummary: AiProductRecommendationProfileSummary(
        skinType: profile?.skinType ?? 'Not provided yet',
        concerns: profile?.concerns ?? const <String>[],
        budget: profile?.budgetLabel ?? 'Not provided yet',
      ),
    );
  }

  String _mapSensitivityLevel(int? level) {
    if (level == null) {
      return 'Medium';
    }
    if (level <= 2) {
      return 'Low';
    }
    if (level >= 4) {
      return 'High';
    }
    return 'Medium';
  }

  String _normalizeRecommendationCategoryKey(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
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

  Future<void> _replaceCurrentUserPlanType(String? planType) async {
    final trimmed = planType?.trim().toLowerCase() ?? '';
    final currentSession = session;
    if (trimmed.isEmpty || currentSession == null) {
      return;
    }

    session = AuthSession(
      accessToken: currentSession.accessToken,
      refreshToken: currentSession.refreshToken,
      user: currentSession.user.copyWith(planType: trimmed),
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
        .map((item) {
          if (item is Map<String, dynamic>) {
            return (item['description'] ?? item['content'] ?? '').toString();
          }
          return item.toString();
        })
        .toList();
    final warnings =
        (((data['riskFlags'] as List?) ??
                (data['warnings'] as List?) ??
                const []))
            .map((item) => item.toString())
            .toList();

    final issues = concerns
        .map(
          (item) => AnalysisIssue(
            issueType: (item['label'] ?? item['concern'] ?? 'unknown')
                .toString(),
            severityScore:
                (item['score'] as int?) ??
                _severityToScore((item['severity'] ?? 'low').toString()),
            description: item['description']?.toString(),
          ),
        )
        .toList();

    final confidenceValue = data['confidence'] ?? data['confidenceScore'];
    final poorImageQuality = warnings.any(
      (item) => item.trim().toLowerCase() == 'poor_image_quality',
    );
    final confidencePercent =
        (confidenceValue is num
                ? (confidenceValue <= 1
                          ? confidenceValue * 100
                          : confidenceValue)
                      .round()
                : concerns.isEmpty
                ? (poorImageQuality ? 40 : 82)
                : (concerns
                              .map(
                                (item) =>
                                    (((item['confidence'] as num?) ?? 0.8) > 1
                                            ? ((item['confidence'] as num?) ??
                                                  80)
                                            : (((item['confidence'] as num?) ??
                                                      0.8) *
                                                  100))
                                        .round(),
                              )
                              .reduce((a, b) => a + b) ~/
                          concerns.length)
                      .clamp(0, 100))
            .toInt();
    final legacySeverity =
        (data['overallConcernSeverity'] ??
                data['overallScore'] ??
                data['skinScore'])
            as num?;
    final skinHealthValue = data['skinHealthScore'] as num?;
    final rawMetrics = data['metrics'] is Map<String, dynamic>
        ? data['metrics'] as Map<String, dynamic>
        : <String, dynamic>{};
    final hasMeaningfulMetricSignal = _hasMeaningfulMetricSignal(
      rawMetrics,
      data,
    );
    final hasMeaningfulConcernSignal = concerns.any(
      (item) =>
          ((item['score'] as num?)?.round() ?? 0) > 0 ||
          (item['evidence']?.toString().trim().isNotEmpty ?? false) ||
          (item['description']?.toString().trim().isNotEmpty ?? false),
    );
    final hasMeaningfulScoreSignal =
        legacySeverity != null || skinHealthValue != null;
    final shouldHideFallbackScores =
        !hasMeaningfulScoreSignal &&
        !hasMeaningfulConcernSignal &&
        !hasMeaningfulMetricSignal;
    final resolvedMetrics = hasMeaningfulMetricSignal
        ? (data['metrics'] is Map<String, dynamic>
              ? AnalysisMetrics.fromJson(
                  data['metrics'] as Map<String, dynamic>,
                )
              : AnalysisMetrics(
                  acne: (data['acneLevel'] as num?)?.round(),
                  redness: (data['rednessLevel'] as num?)?.round(),
                  oiliness: (data['oilinessLevel'] as num?)?.round(),
                  dryness: (data['drynessLevel'] as num?)?.round(),
                  moisture: (data['hydrationLevel'] as num?)?.round(),
                  texture: (data['textureLevel'] as num?)?.round(),
                ))
        : const AnalysisMetrics();
    final overallConcernSeverity = shouldHideFallbackScores
        ? null
        : legacySeverity?.round();
    final skinHealthScore = shouldHideFallbackScores
        ? null
        : skinHealthValue?.round() ??
              (overallConcernSeverity == null
                  ? null
                  : (100 - overallConcernSeverity).clamp(0, 100));

    return AnalysisResult(
      id:
          (data['analysisResultId'] ??
                  data['analysisId'] ??
                  DateTime.now().millisecondsSinceEpoch)
              .toString(),
      analysisSessionId: data['analysisSessionId']?.toString(),
      progressEntryId: data['progressEntryId']?.toString(),
      photoId: data['photoId']?.toString(),
      source: data['source']?.toString(),
      createdAt: DateTime.tryParse(
        (data['createdAt'] ?? data['CreatedAt'])?.toString() ?? '',
      ),
      completedAt: DateTime.tryParse(
        (data['completedAt'] ?? data['CompletedAt'])?.toString() ?? '',
      ),
      imageUrl: data['imageUrl']?.toString() ?? '',
      skinType:
          data['skinType']?.toString() ??
          data['skinTypeEstimate']?.toString() ??
          profile?.skinType ??
          'Unknown',
      overallScore: overallConcernSeverity,
      skinHealthScore: skinHealthScore,
      overallConcernSeverity: overallConcernSeverity,
      confidenceScore: confidencePercent,
      metrics: resolvedMetrics,
      overview: (data['summary'] ?? data['skinSummary'] ?? data['overview'])
          ?.toString(),
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
      canGenerateProducts: (data['canGenerateProducts'] ?? false) as bool,
    );
  }

  AnalysisResult _mergeLatestAnalysis(
    AnalysisResult? existing,
    AnalysisResult incoming,
  ) {
    if (existing == null) {
      return incoming;
    }

    final sameAnalysis =
        existing.id == incoming.id ||
        (existing.analysisSessionId?.isNotEmpty == true &&
            existing.analysisSessionId == incoming.analysisSessionId) ||
        (existing.progressEntryId?.isNotEmpty == true &&
            existing.progressEntryId == incoming.progressEntryId) ||
        (existing.photoId?.isNotEmpty == true &&
            existing.photoId == incoming.photoId);
    if (!sameAnalysis) {
      return incoming;
    }

    final incomingHasMetricDetail = _hasMetricDetail(incoming);
    final existingHasMetricDetail = _hasMetricDetail(existing);
    return AnalysisResult(
      id: incoming.id,
      analysisSessionId:
          incoming.analysisSessionId ?? existing.analysisSessionId,
      progressEntryId: incoming.progressEntryId ?? existing.progressEntryId,
      photoId: incoming.photoId ?? existing.photoId,
      source: incoming.source ?? existing.source,
      createdAt: incoming.createdAt ?? existing.createdAt,
      completedAt: incoming.completedAt ?? existing.completedAt,
      imageUrl: incoming.imageUrl.isNotEmpty
          ? incoming.imageUrl
          : existing.imageUrl,
      skinType: incoming.skinType.trim().isNotEmpty
          ? incoming.skinType
          : existing.skinType,
      overallScore: incoming.overallScore ?? existing.overallScore,
      skinHealthScore: incoming.skinHealthScore ?? existing.skinHealthScore,
      overallConcernSeverity:
          incoming.overallConcernSeverity ?? existing.overallConcernSeverity,
      confidenceScore: incoming.confidenceScore > 0
          ? incoming.confidenceScore
          : existing.confidenceScore,
      metrics: incomingHasMetricDetail || !existingHasMetricDetail
          ? incoming.metrics
          : existing.metrics,
      overview: (incoming.overview?.trim().isNotEmpty ?? false)
          ? incoming.overview
          : existing.overview,
      disclaimer: (incoming.disclaimer?.trim().isNotEmpty ?? false)
          ? incoming.disclaimer
          : existing.disclaimer,
      warnings: incoming.warnings.isNotEmpty
          ? incoming.warnings
          : existing.warnings,
      issues: incoming.issues.isNotEmpty ? incoming.issues : existing.issues,
      recommendations: incoming.recommendations.isNotEmpty
          ? incoming.recommendations
          : existing.recommendations,
      canGenerateProducts:
          incoming.canGenerateProducts || existing.canGenerateProducts,
    );
  }

  static bool _hasMetricDetail(AnalysisResult value) {
    final metrics = value.metrics;
    return <int?>[
          metrics.acne,
          metrics.redness,
          metrics.oiliness,
          metrics.dryness,
          metrics.moisture,
          metrics.texture,
        ].any((item) => item != null && item > 0) ||
        value.issues.isNotEmpty;
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

  static bool _hasMeaningfulMetricSignal(
    Map<String, dynamic> metrics,
    Map<String, dynamic> data,
  ) {
    final metricValues = <num?>[
      metrics['acne'] as num?,
      metrics['redness'] as num?,
      metrics['oiliness'] as num?,
      metrics['dryness'] as num?,
      metrics['moisture'] as num?,
      metrics['texture'] as num?,
      data['acneLevel'] as num?,
      data['rednessLevel'] as num?,
      data['oilinessLevel'] as num?,
      data['drynessLevel'] as num?,
      data['hydrationLevel'] as num?,
      data['textureLevel'] as num?,
      data['darkSpotLevel'] as num?,
    ];

    return metricValues.any((value) => (value?.round() ?? 0) > 0);
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

  bool _hasCompletedOnboarding(SkinProfile? value) {
    if (value == null) {
      return false;
    }

    if (value.isOnboardingCompleted) {
      return true;
    }

    final hasDisplayName = value.displayName?.trim().isNotEmpty ?? false;
    final hasDateOfBirth = value.dateOfBirth?.trim().isNotEmpty ?? false;
    final hasGender = value.gender?.trim().isNotEmpty ?? false;
    final hasSkinType = value.skinType?.trim().isNotEmpty ?? false;
    final hasBudget =
        value.monthlyBudget != null ||
        (value.budgetLabel?.trim().isNotEmpty ?? false);
    final hasConcerns = value.concerns.any((item) => item.trim().isNotEmpty);
    final hasRoutineLevel =
        value.currentRoutineLevel?.trim().isNotEmpty ?? false;
    final hasGoals =
        value.goals.any((item) => item.trim().isNotEmpty) ||
        value.skinGoals.any((item) => item.trim().isNotEmpty);

    return hasDisplayName &&
        hasDateOfBirth &&
        hasGender &&
        hasSkinType &&
        hasBudget &&
        hasConcerns &&
        hasRoutineLevel &&
        hasGoals;
  }

  bool _isExpectedEmptyError(ApiException error) {
    return error.statusCode == 404;
  }

  String? _firstErrorMessage(List<String?> candidates) {
    for (final candidate in candidates) {
      final trimmed = candidate?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  void _resetLoadErrors() {
    profileLoadErrorMessage = null;
    analysisLoadErrorMessage = null;
    regimenLoadErrorMessage = null;
    trackingLoadErrorMessage = null;
    progressLoadErrorMessage = null;
    remindersLoadErrorMessage = null;
    todayLogLoadErrorMessage = null;
    subscriptionPlansLoadErrorMessage = null;
    subscriptionStatusLoadErrorMessage = null;
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

    if (lower.contains('monthly quota exceeded') &&
        lower.contains('skin_analysis')) {
      return 'You have reached this month\'s skin scan quota for your current plan.';
    }

    if (lower.contains('not available on your current plan')) {
      if (lower.contains('skin_progress_compare')) {
        return 'Progress compare is not included in your current plan yet.';
      }
      if (lower.contains('skin_analysis')) {
        return 'Skin analysis is not included in your current plan yet.';
      }
      return 'This feature is not included in your current plan yet.';
    }

    return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
