class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': user.toJson(),
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.status,
    this.planType = 'free',
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String status;
  final String planType;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'].toString(),
    fullName: (json['fullName'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    role: (json['role'] ?? 'user') as String,
    status: (json['status'] ?? 'active') as String,
    planType: (json['planType'] ?? 'free') as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role,
    'status': status,
    'planType': planType,
  };

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
    String? status,
    String? planType,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
      planType: planType ?? this.planType,
    );
  }
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.priceVnd,
    required this.billingCycle,
    required this.isActive,
    this.features = const [],
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final double priceVnd;
  final String billingCycle;
  final bool isActive;
  final List<SubscriptionPlanFeature> features;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id'].toString(),
        code: (json['code'] ?? 'free').toString(),
        name: (json['name'] ?? '').toString(),
        description: json['description']?.toString(),
        priceVnd: (json['priceVnd'] as num?)?.toDouble() ?? 0,
        billingCycle: (json['billingCycle'] ?? 'monthly').toString(),
        isActive: (json['isActive'] ?? true) as bool,
        features: ((json['features'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionPlanFeature.fromJson)
            .toList(),
      );
}

class SubscriptionPlanFeature {
  const SubscriptionPlanFeature({
    required this.featureKey,
    required this.displayName,
    this.monthlyLimit,
    this.isUnlimited = false,
    this.isEnabled = true,
  });

  final String featureKey;
  final String displayName;
  final int? monthlyLimit;
  final bool isUnlimited;
  final bool isEnabled;

  factory SubscriptionPlanFeature.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlanFeature(
        featureKey: (json['featureKey'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        monthlyLimit: (json['monthlyLimit'] as num?)?.toInt(),
        isUnlimited: (json['isUnlimited'] ?? false) as bool,
        isEnabled: (json['isEnabled'] ?? true) as bool,
      );
}

class SubscriptionStatus {
  const SubscriptionStatus({
    this.subscriptionId,
    required this.status,
    required this.planCode,
    this.startedAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.canceledAt,
  });

  final String? subscriptionId;
  final String status;
  final String planCode;
  final DateTime? startedAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? canceledAt;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        subscriptionId: json['subscriptionId']?.toString(),
        status: (json['status'] ?? 'active').toString(),
        planCode: (json['planCode'] ?? 'free').toString(),
        startedAt: _tryParseDateTime(json['startedAt']),
        currentPeriodStart: _tryParseDateTime(json['currentPeriodStart']),
        currentPeriodEnd: _tryParseDateTime(json['currentPeriodEnd']),
        canceledAt: _tryParseDateTime(json['canceledAt']),
      );
}

class SubscriptionUsage {
  const SubscriptionUsage({
    required this.featureKey,
    required this.displayName,
    required this.used,
    this.monthlyLimit,
    this.remaining,
    this.isUnlimited = false,
    this.isEnabled = true,
  });

  final String featureKey;
  final String displayName;
  final int used;
  final int? monthlyLimit;
  final int? remaining;
  final bool isUnlimited;
  final bool isEnabled;

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      SubscriptionUsage(
        featureKey: (json['featureKey'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        used: (json['used'] as num?)?.toInt() ?? 0,
        monthlyLimit: (json['monthlyLimit'] as num?)?.toInt(),
        remaining: (json['remaining'] as num?)?.toInt(),
        isUnlimited: (json['isUnlimited'] ?? false) as bool,
        isEnabled: (json['isEnabled'] ?? true) as bool,
      );
}

class CurrentSubscription {
  const CurrentSubscription({
    required this.plan,
    required this.subscription,
    this.usage = const [],
  });

  final SubscriptionPlan plan;
  final SubscriptionStatus subscription;
  final List<SubscriptionUsage> usage;

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) =>
      CurrentSubscription(
        plan: SubscriptionPlan.fromJson(
          (json['plan'] as Map<String, dynamic>?) ?? const {},
        ),
        subscription: SubscriptionStatus.fromJson(
          (json['subscription'] as Map<String, dynamic>?) ?? const {},
        ),
        usage: ((json['usage'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SubscriptionUsage.fromJson)
            .toList(),
      );
}

DateTime? _tryParseDateTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

class SkinProfile {
  const SkinProfile({
    this.displayName,
    this.dateOfBirth,
    this.gender,
    this.healthIssues = const [],
    this.skinType,
    this.monthlyBudget,
    this.budgetLabel,
    this.concerns = const [],
    this.currentRoutineLevel,
    this.goals = const [],
    this.allergies = const [],
    this.avoidIngredients = const [],
    this.skinGoals = const [],
    this.rednessWhenNewProducts,
    this.rednessWhenSunOrExercise,
    this.sensitivityLevel,
    this.isOnboardingCompleted = false,
  });

  final String? displayName;
  final String? dateOfBirth;
  final String? gender;
  final List<String> healthIssues;
  final String? skinType;
  final double? monthlyBudget;
  final String? budgetLabel;
  final List<String> concerns;
  final String? currentRoutineLevel;
  final List<String> goals;
  final List<String> allergies;
  final List<String> avoidIngredients;
  final List<String> skinGoals;
  final String? rednessWhenNewProducts;
  final String? rednessWhenSunOrExercise;
  final int? sensitivityLevel;
  final bool isOnboardingCompleted;

  factory SkinProfile.fromJson(Map<String, dynamic> json) => SkinProfile(
    displayName: json['displayName'] as String?,
    dateOfBirth: json['dateOfBirth'] as String?,
    gender: json['gender'] as String?,
    healthIssues: ((json['healthIssues'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    skinType: json['skinType'] as String?,
    monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
    budgetLabel: json['budgetLabel'] as String?,
    concerns: ((json['concerns'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    currentRoutineLevel: json['currentRoutineLevel'] as String?,
    goals: ((json['goals'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    allergies: ((json['allergies'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    avoidIngredients: ((json['avoidIngredients'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    skinGoals: ((json['skinGoals'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    rednessWhenNewProducts: json['rednessWhenNewProducts'] as String?,
    rednessWhenSunOrExercise: json['rednessWhenSunOrExercise'] as String?,
    sensitivityLevel: json['sensitivityLevel'] as int?,
    isOnboardingCompleted: (json['isOnboardingCompleted'] ?? false) as bool,
  );
}

class AnalysisIssue {
  const AnalysisIssue({
    required this.issueType,
    required this.severityScore,
    this.description,
  });

  final String issueType;
  final int severityScore;
  final String? description;

  factory AnalysisIssue.fromJson(Map<String, dynamic> json) => AnalysisIssue(
    issueType:
        ((json['issueType'] ?? json['label'] ?? json['concern']) ?? '')
            as String,
    severityScore:
        (json['severityScore'] as int?) ??
        _severityToLegacyScore((json['severity'] ?? 'low').toString()),
    description: json['description'] as String?,
  );
}

class AnalysisRecommendation {
  const AnalysisRecommendation({required this.title, required this.content});

  final String title;
  final String content;

  factory AnalysisRecommendation.fromJson(Map<String, dynamic> json) =>
      AnalysisRecommendation(
        title: (json['title'] ?? '') as String,
        content: (json['content'] ?? '') as String,
      );
}

int _severityToLegacyScore(String severity) {
  switch (severity.trim().toLowerCase()) {
    case 'high':
      return 85;
    case 'medium':
      return 60;
    default:
      return 35;
  }
}

class AnalysisResult {
  const AnalysisResult({
    required this.id,
    this.analysisSessionId,
    this.progressEntryId,
    this.photoId,
    this.source,
    this.createdAt,
    this.completedAt,
    required this.imageUrl,
    required this.skinType,
    this.overallScore,
    this.skinHealthScore,
    this.overallConcernSeverity,
    required this.confidenceScore,
    this.metrics = const AnalysisMetrics(),
    this.overview,
    this.disclaimer,
    this.warnings = const [],
    this.issues = const [],
    this.recommendations = const [],
    this.canGenerateProducts = false,
  });

  final String id;
  final String? analysisSessionId;
  final String? progressEntryId;
  final String? photoId;
  final String? source;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String imageUrl;
  final String skinType;
  final int? overallScore;
  final int? skinHealthScore;
  final int? overallConcernSeverity;
  final int confidenceScore;
  final AnalysisMetrics metrics;
  final String? overview;
  final String? disclaimer;
  final List<String> warnings;
  final List<AnalysisIssue> issues;
  final List<AnalysisRecommendation> recommendations;
  final bool canGenerateProducts;

  DateTime? get lastScanAt => completedAt ?? createdAt;

  int? get displaySkinHealthScore =>
      skinHealthScore ??
      (displayConcernSeverityScore == null
          ? null
          : 100 - displayConcernSeverityScore!);

  int? get legacyConcernScore => overallConcernSeverity ?? overallScore;

  int? get displayConcernSeverityScore =>
      overallConcernSeverity ??
      overallScore ??
      (skinHealthScore == null ? null : 100 - skinHealthScore!);

  int? get displayConcernSeverity => displayConcernSeverityScore;

  int get displayConfidencePercent => confidenceScore.clamp(0, 100);

  int get displayConfidence => displayConfidencePercent;

  bool get hasScoreData =>
      displaySkinHealthScore != null || displayConcernSeverityScore != null;

  bool get isLegacySeverityRecord =>
      skinHealthScore == null &&
      overallConcernSeverity == null &&
      overallScore != null;

  static int _parseConfidenceScore(Map<String, dynamic> json) {
    final rawValue = json['confidence'] ?? json['confidenceScore'];
    if (rawValue is num) {
      final normalized = rawValue <= 1 ? rawValue * 100 : rawValue;
      return normalized.round().clamp(0, 100);
    }

    return 0;
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    id: (json['id'] ?? json['analysisResultId'] ?? json['analysisId'])
        .toString(),
    analysisSessionId: json['analysisSessionId']?.toString(),
    progressEntryId: json['progressEntryId']?.toString(),
    photoId: json['photoId']?.toString(),
    source: json['source']?.toString(),
    createdAt: _tryParseDateTime(json['createdAt'] ?? json['CreatedAt']),
    completedAt: _tryParseDateTime(json['completedAt'] ?? json['CompletedAt']),
    imageUrl: (json['imageUrl'] ?? '') as String,
    skinType:
        ((json['skinType'] ?? json['skinTypeEstimate']) ?? 'Unknown') as String,
    overallScore:
        ((json['overallScore'] as num?) ?? (json['skinScore'] as num?))
            ?.round(),
    skinHealthScore:
        ((json['skinHealthScore'] as num?) ?? (json['skinHealth'] as num?))
            ?.round(),
    overallConcernSeverity:
        ((json['overallConcernSeverity'] as num?) ??
                (json['visibleConcernLevel'] as num?))
            ?.round(),
    confidenceScore: _parseConfidenceScore(json),
    metrics: json['metrics'] is Map<String, dynamic>
        ? AnalysisMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
        : AnalysisMetrics(
            acne: (json['acneLevel'] as num?)?.round(),
            redness: (json['rednessLevel'] as num?)?.round(),
            oiliness: (json['oilinessLevel'] as num?)?.round(),
            dryness: (json['drynessLevel'] as num?)?.round(),
            moisture: (json['hydrationLevel'] as num?)?.round(),
            texture: (json['textureLevel'] as num?)?.round(),
          ),
    overview:
        (json['overview'] ?? json['summary'] ?? json['skinSummary']) as String?,
    disclaimer: json['disclaimer'] as String?,
    warnings:
        (((json['warnings'] as List?) ??
                (json['riskFlags'] as List?) ??
                const []))
            .map((e) => e.toString())
            .toList(),
    issues:
        (((json['issues'] as List?) ??
                (json['detectedConcerns'] as List?) ??
                const []))
            .whereType<Map<String, dynamic>>()
            .map(AnalysisIssue.fromJson)
            .toList(),
    recommendations: ((json['recommendations'] as List?) ?? const []).map((
      item,
    ) {
      if (item is Map<String, dynamic>) {
        return AnalysisRecommendation(
          title: (item['title'] ?? item['type'] ?? 'Recommendation') as String,
          content:
              (item['content'] ?? item['description'] ?? item['reason'] ?? '')
                  as String,
        );
      }
      return AnalysisRecommendation(
        title: 'Recommendation',
        content: item.toString(),
      );
    }).toList(),
    canGenerateProducts: (json['canGenerateProducts'] ?? false) as bool,
  );
}

class SkinAnalysisFlowArgs {
  const SkinAnalysisFlowArgs({this.source = 'unknown'});

  final String source;
}

class RegimenStep {
  const RegimenStep({
    required this.stepId,
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.stepOrder,
    this.instruction,
    this.purpose,
    this.frequency,
    this.caution,
    this.imageUrl,
    this.price,
  });

  final String stepId;
  final String productId;
  final String name;
  final String brand;
  final String category;
  final int stepOrder;
  final String? instruction;
  final String? purpose;
  final String? frequency;
  final String? caution;
  final String? imageUrl;
  final double? price;

  factory RegimenStep.fromJson(Map<String, dynamic> json) => RegimenStep(
    stepId: json['stepId'].toString(),
    productId: json['productId'].toString(),
    name: (json['name'] ?? '') as String,
    brand: (json['brand'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    stepOrder: (json['stepOrder'] ?? 0) as int,
    instruction: json['instruction'] as String?,
    purpose: json['purpose'] as String?,
    frequency: json['frequency'] as String?,
    caution: json['caution'] as String?,
    imageUrl: json['imageUrl'] as String?,
    price: (json['price'] as num?)?.toDouble(),
  );
}

class CurrentRegimen {
  const CurrentRegimen({
    required this.regimenId,
    required this.name,
    this.morning = const [],
    this.evening = const [],
  });

  final String regimenId;
  final String name;
  final List<RegimenStep> morning;
  final List<RegimenStep> evening;

  factory CurrentRegimen.fromJson(Map<String, dynamic> json) => CurrentRegimen(
    regimenId: json['regimenId'].toString(),
    name: (json['name'] ?? '') as String,
    morning: ((json['morning'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RegimenStep.fromJson)
        .toList(),
    evening: ((json['evening'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RegimenStep.fromJson)
        .toList(),
  );
}

class RoutineTrackingToday {
  const RoutineTrackingToday({
    required this.totalSteps,
    required this.completedSteps,
    required this.morningCompleted,
    required this.eveningCompleted,
    this.steps = const [],
    this.completedStepIds = const [],
  });

  final int totalSteps;
  final int completedSteps;
  final bool morningCompleted;
  final bool eveningCompleted;
  final List<RoutineTrackingStep> steps;
  final List<String> completedStepIds;

  factory RoutineTrackingToday.fromJson(Map<String, dynamic> json) =>
      RoutineTrackingToday(
        totalSteps: (json['totalSteps'] ?? 0) as int,
        completedSteps: (json['completedSteps'] ?? 0) as int,
        morningCompleted: (json['morningCompleted'] ?? false) as bool,
        eveningCompleted: (json['eveningCompleted'] ?? false) as bool,
        steps: ((json['steps'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RoutineTrackingStep.fromJson)
            .toList(),
        completedStepIds: ((json['steps'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .where(
              (item) =>
                  (item['status']?.toString().trim().toLowerCase() ?? '') ==
                  'completed',
            )
            .map((item) => item['stepId'].toString())
            .toList(),
      );
}

class ProgressOverview {
  const ProgressOverview({
    this.currentScore,
    this.improvementPercent,
    this.currentStreak,
    this.dailyTip,
    this.progressInsight,
  });

  final int? currentScore;
  final double? improvementPercent;
  final int? currentStreak;
  final String? dailyTip;
  final String? progressInsight;

  factory ProgressOverview.fromJson(Map<String, dynamic> json) =>
      ProgressOverview(
        currentScore: json['currentScore'] as int?,
        improvementPercent: (json['improvementPercent'] as num?)?.toDouble(),
        currentStreak: json['currentStreak'] as int?,
        dailyTip: json['dailyTip'] as String?,
        progressInsight: json['progressInsight'] as String?,
      );
}

class DailyLog {
  const DailyLog({
    required this.date,
    this.morningCompleted = false,
    this.eveningCompleted = false,
    this.skinFeeling,
    this.notes,
    this.acneLevel,
    this.drynessLevel,
    this.rednessLevel,
    this.irritationLevel,
    this.hydrationLevel,
    this.dailyImageUrl,
  });

  final String date;
  final bool morningCompleted;
  final bool eveningCompleted;
  final String? skinFeeling;
  final String? notes;
  final int? acneLevel;
  final int? drynessLevel;
  final int? rednessLevel;
  final int? irritationLevel;
  final int? hydrationLevel;
  final String? dailyImageUrl;

  bool get hasDiaryDetails {
    return (notes?.trim().isNotEmpty ?? false) ||
        acneLevel != null ||
        drynessLevel != null ||
        rednessLevel != null ||
        irritationLevel != null ||
        hydrationLevel != null ||
        (dailyImageUrl?.trim().isNotEmpty ?? false) ||
        _hasMeaningfulSkinFeeling(skinFeeling);
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    date: json['date'].toString(),
    morningCompleted: (json['morningCompleted'] ?? false) as bool,
    eveningCompleted: (json['eveningCompleted'] ?? false) as bool,
    skinFeeling: json['skinFeeling'] as String?,
    notes: json['notes'] as String?,
    acneLevel: json['acneLevel'] as int?,
    drynessLevel: json['drynessLevel'] as int?,
    rednessLevel: json['rednessLevel'] as int?,
    irritationLevel: json['irritationLevel'] as int?,
    hydrationLevel: json['hydrationLevel'] as int?,
    dailyImageUrl: json['dailyImageUrl'] as String?,
  );
}

bool _hasMeaningfulSkinFeeling(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return false;
  }

  return normalized != 'normal';
}

class ReminderItem {
  const ReminderItem({
    required this.reminderId,
    required this.time,
    required this.routineType,
    this.frequency = 'daily',
    this.reason,
    this.priority = 'medium',
    this.isAdaptive = false,
    required this.isEnabled,
  });

  final String reminderId;
  final String time;
  final String routineType;
  final String frequency;
  final String? reason;
  final String priority;
  final bool isAdaptive;
  final bool isEnabled;

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    reminderId: json['reminderId'].toString(),
    time: (json['time'] ?? '') as String,
    routineType: (json['routineType'] ?? '') as String,
    frequency: (json['frequency'] ?? 'daily') as String,
    reason: json['reason'] as String?,
    priority: (json['priority'] ?? 'medium') as String,
    isAdaptive: (json['isAdaptive'] ?? false) as bool,
    isEnabled: (json['isEnabled'] ?? false) as bool,
  );
}

class AiReminderSuggestion {
  const AiReminderSuggestion({
    required this.routineType,
    required this.time,
    required this.frequency,
    required this.reason,
    required this.priority,
    required this.isAdaptive,
    required this.isEnabled,
  });

  final String routineType;
  final String time;
  final String frequency;
  final String reason;
  final String priority;
  final bool isAdaptive;
  final bool isEnabled;

  factory AiReminderSuggestion.fromJson(Map<String, dynamic> json) =>
      AiReminderSuggestion(
        routineType: (json['routineType'] ?? 'Morning') as String,
        time: (json['time'] ?? '07:00') as String,
        frequency: (json['frequency'] ?? 'daily') as String,
        reason: (json['reason'] ?? '') as String,
        priority: (json['priority'] ?? 'medium') as String,
        isAdaptive: (json['isAdaptive'] ?? false) as bool,
        isEnabled: (json['isEnabled'] ?? true) as bool,
      );
}

class AiReminderSuggestResponse {
  const AiReminderSuggestResponse({
    this.suggestions = const [],
    this.overallAdvice = '',
  });

  final List<AiReminderSuggestion> suggestions;
  final String overallAdvice;

  factory AiReminderSuggestResponse.fromJson(Map<String, dynamic> json) =>
      AiReminderSuggestResponse(
        suggestions: ((json['suggestions'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiReminderSuggestion.fromJson)
            .toList(),
        overallAdvice: (json['overallAdvice'] ?? '') as String,
      );
}

class AiChatLaunchArgs {
  const AiChatLaunchArgs({
    this.conversationId,
    this.entryPoint,
    this.referenceId,
    this.prefillMessage,
    this.prefillContext,
  });

  final String? conversationId;
  final String? entryPoint;
  final String? referenceId;
  final String? prefillMessage;
  final String? prefillContext;
}

class AiSuggestedAction {
  const AiSuggestedAction({
    required this.type,
    required this.label,
    required this.route,
    this.referenceId,
  });

  final String type;
  final String label;
  final String route;
  final String? referenceId;

  factory AiSuggestedAction.fromJson(Map<String, dynamic> json) =>
      AiSuggestedAction(
        type: (json['type'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        route: (json['route'] ?? '') as String,
        referenceId: json['referenceId']?.toString(),
      );
}

class AiChatReply {
  const AiChatReply({
    this.conversationId,
    required this.reply,
    this.suggestedActions = const [],
    this.needMoreInfo = false,
    this.missingInfoQuestions = const [],
    this.safetyWarning,
  });

  final String? conversationId;
  final String reply;
  final List<AiSuggestedAction> suggestedActions;
  final bool needMoreInfo;
  final List<String> missingInfoQuestions;
  final String? safetyWarning;

  factory AiChatReply.fromJson(Map<String, dynamic> json) => AiChatReply(
    conversationId: json['conversationId']?.toString(),
    reply: (json['reply'] ?? '') as String,
    suggestedActions: ((json['suggestedActions'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AiSuggestedAction.fromJson)
        .toList(),
    needMoreInfo: (json['needMoreInfo'] ?? false) as bool,
    missingInfoQuestions: ((json['missingInfoQuestions'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    safetyWarning: json['safetyWarning'] as String?,
  );
}

class AiChatConversationSummary {
  const AiChatConversationSummary({
    required this.conversationId,
    required this.title,
    this.lastMessagePreview,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });

  final String conversationId;
  final String title;
  final String? lastMessagePreview;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;

  factory AiChatConversationSummary.fromJson(Map<String, dynamic> json) =>
      AiChatConversationSummary(
        conversationId: json['conversationId'].toString(),
        title: (json['title'] ?? 'New chat') as String,
        lastMessagePreview: json['lastMessagePreview'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        lastMessageAt:
            DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class AiChatMessageItem {
  const AiChatMessageItem({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role.toLowerCase() == 'user';

  factory AiChatMessageItem.fromJson(Map<String, dynamic> json) =>
      AiChatMessageItem(
        id: json['id'].toString(),
        role: (json['role'] ?? 'assistant') as String,
        content: (json['content'] ?? '') as String,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class AiChatConversationDetail {
  const AiChatConversationDetail({
    required this.conversationId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.messages = const [],
  });

  final String conversationId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final List<AiChatMessageItem> messages;

  factory AiChatConversationDetail.fromJson(Map<String, dynamic> json) =>
      AiChatConversationDetail(
        conversationId: json['conversationId'].toString(),
        title: (json['title'] ?? 'New chat') as String,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
        lastMessageAt:
            DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ??
            DateTime.now(),
        messages: ((json['messages'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiChatMessageItem.fromJson)
            .toList(),
      );
}

class AiRoutineStepPlan {
  const AiRoutineStepPlan({
    required this.stepOrder,
    required this.stepName,
    required this.productId,
    required this.productName,
    required this.frequency,
    required this.instruction,
    required this.aiReason,
    this.warning,
  });

  final int stepOrder;
  final String stepName;
  final String productId;
  final String productName;
  final String frequency;
  final String instruction;
  final String aiReason;
  final String? warning;

  factory AiRoutineStepPlan.fromJson(Map<String, dynamic> json) =>
      AiRoutineStepPlan(
        stepOrder: (json['stepOrder'] ?? 0) as int,
        stepName: (json['stepName'] ?? '') as String,
        productId: json['productId'].toString(),
        productName: (json['productName'] ?? '') as String,
        frequency: (json['frequency'] ?? 'daily') as String,
        instruction: (json['instruction'] ?? '') as String,
        aiReason: (json['aiReason'] ?? '') as String,
        warning: json['warning'] as String?,
      );
}

class AiRoutinePlan {
  const AiRoutinePlan({
    required this.routineId,
    required this.routineName,
    this.morning = const [],
    this.night = const [],
    this.warnings = const [],
    this.missingCategories = const [],
    this.overallAdvice,
  });

  final String routineId;
  final String routineName;
  final List<AiRoutineStepPlan> morning;
  final List<AiRoutineStepPlan> night;
  final List<String> warnings;
  final List<String> missingCategories;
  final String? overallAdvice;

  factory AiRoutinePlan.fromJson(Map<String, dynamic> json) => AiRoutinePlan(
    routineId: json['routineId'].toString(),
    routineName: (json['routineName'] ?? '') as String,
    morning: ((json['morning'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AiRoutineStepPlan.fromJson)
        .toList(),
    night: ((json['night'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AiRoutineStepPlan.fromJson)
        .toList(),
    warnings: ((json['warnings'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    missingCategories: ((json['missingCategories'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    overallAdvice: json['overallAdvice'] as String?,
  );
}

class AiRecommendedProduct {
  const AiRecommendedProduct({
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.currency,
    required this.matchScore,
    required this.aiReason,
    this.matchPercent,
    this.whyRecommended,
    this.warnings = const [],
    this.cautions = const [],
    this.alreadyInRoutine = false,
    this.imageUrl,
    this.description,
    this.ingredientsText,
    this.usageGuide,
  });

  final String productId;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String currency;
  final int matchScore;
  final String aiReason;
  final int? matchPercent;
  final String? whyRecommended;
  final List<String> warnings;
  final List<String> cautions;
  final bool alreadyInRoutine;
  final String? imageUrl;
  final String? description;
  final String? ingredientsText;
  final String? usageGuide;

  factory AiRecommendedProduct.fromJson(Map<String, dynamic> json) =>
      AiRecommendedProduct(
        productId: json['productId'].toString(),
        name: (json['name'] ?? '') as String,
        brand: (json['brand'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency: (json['currency'] ?? 'VND') as String,
        matchScore: ((json['matchPercent'] ?? json['matchScore']) ?? 0) as int,
        aiReason: (json['aiReason'] ?? '') as String,
        matchPercent: (json['matchPercent'] as num?)?.toInt(),
        whyRecommended: json['whyRecommended'] as String?,
        warnings: ((json['warnings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        cautions: ((json['cautions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        alreadyInRoutine: (json['alreadyInRoutine'] ?? false) as bool,
        imageUrl: json['imageUrl'] as String?,
        description: json['description'] as String?,
        ingredientsText: json['ingredientsText'] as String?,
        usageGuide: json['usageGuide'] as String?,
      );
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.currency,
    this.description,
    this.imageUrl,
    this.howToUse,
    this.usageTime,
    this.ingredients = const [],
    this.skinTypes = const [],
    this.skinConcerns = const [],
    this.keyIngredients = const [],
    this.cautions = const [],
    this.conflicts = const [],
    this.matchPercent,
    this.whyRecommended,
    this.alreadyInRoutine = false,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String currency;
  final String? description;
  final String? imageUrl;
  final String? howToUse;
  final String? usageTime;
  final List<String> ingredients;
  final List<String> skinTypes;
  final List<String> skinConcerns;
  final List<String> keyIngredients;
  final List<String> cautions;
  final List<String> conflicts;
  final int? matchPercent;
  final String? whyRecommended;
  final bool alreadyInRoutine;

  bool get hasIngredientData => ingredients.isNotEmpty;

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
    id: json['id'].toString(),
    name: (json['name'] ?? '') as String,
    brand: (json['brand'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    currency: (json['currency'] ?? 'VND') as String,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    howToUse: (json['howToUse'] ?? json['usageGuide']) as String?,
    usageTime: json['usageTime'] as String?,
    ingredients: ((json['ingredients'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    skinTypes:
        ((json['suitableSkinTypes'] as List?) ??
                (json['skinTypes'] as List?) ??
                const [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList(),
    skinConcerns: ((json['skinConcerns'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    keyIngredients: ((json['keyIngredients'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    cautions: ((json['cautions'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    conflicts: ((json['conflicts'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(),
    matchPercent: (json['matchPercent'] as num?)?.toInt(),
    whyRecommended: json['whyRecommended'] as String?,
    alreadyInRoutine: (json['alreadyInRoutine'] ?? false) as bool,
  );

  ProductDetail mergeRecommendation(
    AiRecommendedProduct? recommendation, {
    bool? alreadyInRoutineOverride,
  }) {
    if (recommendation == null) {
      return ProductDetail(
        id: id,
        name: name,
        brand: brand,
        category: category,
        price: price,
        currency: currency,
        description: description,
        imageUrl: imageUrl,
        howToUse: howToUse,
        usageTime: usageTime,
        ingredients: ingredients,
        skinTypes: skinTypes,
        skinConcerns: skinConcerns,
        keyIngredients: keyIngredients,
        cautions: cautions,
        conflicts: conflicts,
        matchPercent: matchPercent,
        whyRecommended: whyRecommended,
        alreadyInRoutine: alreadyInRoutineOverride ?? alreadyInRoutine,
      );
    }

    return ProductDetail(
      id: id,
      name: name.isEmpty ? recommendation.name : name,
      brand: brand.isEmpty ? recommendation.brand : brand,
      category: category.isEmpty ? recommendation.category : category,
      price: price == 0 ? recommendation.price : price,
      currency: currency.isEmpty ? recommendation.currency : currency,
      description: description?.trim().isNotEmpty == true
          ? description
          : recommendation.description,
      imageUrl: imageUrl?.trim().isNotEmpty == true
          ? imageUrl
          : recommendation.imageUrl,
      howToUse: howToUse?.trim().isNotEmpty == true
          ? howToUse
          : recommendation.usageGuide,
      usageTime: usageTime,
      ingredients: ingredients.isNotEmpty
          ? ingredients
          : ((recommendation.ingredientsText?.trim().isNotEmpty ?? false)
                ? recommendation.ingredientsText!
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                : const <String>[]),
      skinTypes: skinTypes,
      skinConcerns: skinConcerns,
      keyIngredients: keyIngredients,
      cautions: cautions.isNotEmpty ? cautions : recommendation.cautions,
      conflicts: conflicts,
      matchPercent:
          matchPercent ??
          recommendation.matchPercent ??
          recommendation.matchScore,
      whyRecommended: whyRecommended?.trim().isNotEmpty == true
          ? whyRecommended
          : (recommendation.whyRecommended?.trim().isNotEmpty == true
                ? recommendation.whyRecommended
                : recommendation.aiReason),
      alreadyInRoutine:
          alreadyInRoutineOverride ??
          (alreadyInRoutine || recommendation.alreadyInRoutine),
    );
  }
}

class AnalysisMetrics {
  const AnalysisMetrics({
    this.acne,
    this.redness,
    this.oiliness,
    this.dryness,
    this.moisture,
    this.texture,
  });

  final int? acne;
  final int? redness;
  final int? oiliness;
  final int? dryness;
  final int? moisture;
  final int? texture;

  List<AnalysisMetricDisplay> get displayItems => [
    AnalysisMetricDisplay(
      key: 'acne',
      label: 'Acne visibility',
      value: acne,
      tone: AnalysisMetricTone.concern,
      caption: 'Higher means acne is more visible.',
    ),
    AnalysisMetricDisplay(
      key: 'redness',
      label: 'Redness',
      value: redness,
      tone: AnalysisMetricTone.concern,
      caption: 'Higher means redness is more visible.',
    ),
    AnalysisMetricDisplay(
      key: 'oiliness',
      label: 'Oiliness',
      value: oiliness,
      tone: AnalysisMetricTone.concern,
      caption: 'Higher means visible shine or oil is stronger.',
    ),
    AnalysisMetricDisplay(
      key: 'dryness',
      label: 'Dryness',
      value: dryness,
      tone: AnalysisMetricTone.concern,
      caption: 'Higher means dryness is more noticeable.',
    ),
    AnalysisMetricDisplay(
      key: 'moisture',
      label: 'Moisture',
      value: moisture,
      tone: AnalysisMetricTone.wellness,
      caption: 'Higher is better for moisture balance.',
    ),
    AnalysisMetricDisplay(
      key: 'texture',
      label: 'Texture',
      value: texture,
      tone: AnalysisMetricTone.concern,
      caption: 'Higher means uneven texture is more visible.',
    ),
  ];

  factory AnalysisMetrics.fromJson(Map<String, dynamic> json) =>
      AnalysisMetrics(
        acne: (json['acne'] as num?)?.round(),
        redness: (json['redness'] as num?)?.round(),
        oiliness: (json['oiliness'] as num?)?.round(),
        dryness: (json['dryness'] as num?)?.round(),
        moisture: (json['moisture'] as num?)?.round(),
        texture: (json['texture'] as num?)?.round(),
      );
}

enum AnalysisMetricTone { concern, wellness }

class AnalysisMetricDisplay {
  const AnalysisMetricDisplay({
    required this.key,
    required this.label,
    required this.value,
    required this.tone,
    required this.caption,
  });

  final String key;
  final String label;
  final int? value;
  final AnalysisMetricTone tone;
  final String caption;
}

class AiProductRecommendationProfileSummary {
  const AiProductRecommendationProfileSummary({
    this.skinType = 'Not provided yet',
    this.concerns = const [],
    this.budget = 'Not provided yet',
  });

  final String skinType;
  final List<String> concerns;
  final String budget;

  factory AiProductRecommendationProfileSummary.fromJson(
    Map<String, dynamic> json,
  ) => AiProductRecommendationProfileSummary(
    skinType: (json['skinType'] ?? 'Not provided yet') as String,
    concerns: ((json['concerns'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    budget: (json['budget'] ?? 'Not provided yet') as String,
  );
}

class AiProductRecommendationCategory {
  const AiProductRecommendationCategory({
    required this.key,
    required this.label,
    this.reason = '',
    this.items = const [],
  });

  final String key;
  final String label;
  final String reason;
  final List<AiRecommendedProduct> items;

  factory AiProductRecommendationCategory.fromJson(Map<String, dynamic> json) =>
      AiProductRecommendationCategory(
        key: (json['key'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        reason: (json['reason'] ?? '') as String,
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiRecommendedProduct.fromJson)
            .toList(),
      );
}

class RoutineTrackingStep {
  const RoutineTrackingStep({
    required this.stepId,
    required this.productId,
    required this.routineTime,
    required this.stepOrder,
    required this.productName,
    required this.status,
    this.completedAt,
  });

  final String stepId;
  final String productId;
  final String routineTime;
  final int stepOrder;
  final String productName;
  final String status;
  final DateTime? completedAt;

  bool get isCompleted => status.trim().toLowerCase() == 'completed';
  bool get isMorning => routineTime.trim().toLowerCase() == 'morning';
  bool get isEvening => routineTime.trim().toLowerCase() == 'evening';

  factory RoutineTrackingStep.fromJson(Map<String, dynamic> json) =>
      RoutineTrackingStep(
        stepId: json['stepId'].toString(),
        productId: json['productId'].toString(),
        routineTime: (json['routineTime'] ?? '') as String,
        stepOrder: (json['stepOrder'] ?? 0) as int,
        productName: (json['productName'] ?? '') as String,
        status: (json['status'] ?? 'pending') as String,
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      );
}

class AiRoutineConflictWarning {
  const AiRoutineConflictWarning({
    required this.productAId,
    required this.productAName,
    required this.productBId,
    required this.productBName,
    required this.ingredientA,
    required this.ingredientB,
    required this.severity,
    required this.message,
    required this.recommendation,
  });

  final String productAId;
  final String productAName;
  final String productBId;
  final String productBName;
  final String ingredientA;
  final String ingredientB;
  final String severity;
  final String message;
  final String recommendation;

  factory AiRoutineConflictWarning.fromJson(Map<String, dynamic> json) =>
      AiRoutineConflictWarning(
        productAId: json['productAId'].toString(),
        productAName: (json['productAName'] ?? '') as String,
        productBId: json['productBId'].toString(),
        productBName: (json['productBName'] ?? '') as String,
        ingredientA: (json['ingredientA'] ?? '') as String,
        ingredientB: (json['ingredientB'] ?? '') as String,
        severity: (json['severity'] ?? '') as String,
        message: (json['message'] ?? '') as String,
        recommendation: (json['recommendation'] ?? '') as String,
      );
}

class AiAddProductToRoutineResponse {
  const AiAddProductToRoutineResponse({
    required this.added,
    required this.requiresConfirmation,
    required this.message,
    this.routine,
    this.warnings = const [],
  });

  final bool added;
  final bool requiresConfirmation;
  final String message;
  final CurrentRegimen? routine;
  final List<AiRoutineConflictWarning> warnings;

  factory AiAddProductToRoutineResponse.fromJson(Map<String, dynamic> json) =>
      AiAddProductToRoutineResponse(
        added: (json['added'] ?? false) as bool,
        requiresConfirmation: (json['requiresConfirmation'] ?? false) as bool,
        message: (json['message'] ?? '') as String,
        routine: json['routine'] is Map<String, dynamic>
            ? CurrentRegimen.fromJson(json['routine'] as Map<String, dynamic>)
            : null,
        warnings: ((json['warnings'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiRoutineConflictWarning.fromJson)
            .toList(),
      );
}

class AiSavedProduct {
  const AiSavedProduct({
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.isCustom,
  });

  final String productId;
  final String name;
  final String brand;
  final String category;
  final bool isCustom;

  factory AiSavedProduct.fromJson(Map<String, dynamic> json) => AiSavedProduct(
    productId: json['productId'].toString(),
    name: (json['name'] ?? '') as String,
    brand: (json['brand'] ?? 'My Product') as String,
    category: (json['category'] ?? 'Custom') as String,
    isCustom: (json['isCustom'] ?? false) as bool,
  );
}

enum ProductsEntryPoint { bottomNav, analysisResult, progressCta, routineEmpty }

enum RoutineEntryPoint { bottomNav, productAdded }

enum ProgressEntryPoint { bottomNav, checkupSaved, analysisResult }

class ProductsPageArgs {
  const ProductsPageArgs({
    this.initialCategory,
    this.initialConcern,
    this.initialBudget,
    this.referenceId,
    this.entryPoint = ProductsEntryPoint.bottomNav,
  });

  final String? initialCategory;
  final String? initialConcern;
  final double? initialBudget;
  final String? referenceId;
  final ProductsEntryPoint entryPoint;

  bool get showGeneratePrompt =>
      entryPoint == ProductsEntryPoint.analysisResult;

  String get cacheKey => [
    entryPoint.name,
    initialCategory ?? '',
    initialConcern ?? '',
    initialBudget?.toString() ?? '',
    referenceId ?? '',
  ].join('|');
}

class RoutinePageArgs {
  const RoutinePageArgs({this.entryPoint = RoutineEntryPoint.bottomNav});

  final RoutineEntryPoint entryPoint;

  String get cacheKey => entryPoint.name;
}

class ProgressPageArgs {
  const ProgressPageArgs({this.entryPoint = ProgressEntryPoint.bottomNav});

  final ProgressEntryPoint entryPoint;

  String get cacheKey => entryPoint.name;
}

class ProductDetailPageArgs {
  const ProductDetailPageArgs({
    required this.productId,
    this.recommendationItem,
    this.sourceProductsEntryPoint = ProductsEntryPoint.bottomNav,
    this.alreadyInRoutine,
  });

  final String productId;
  final AiRecommendedProduct? recommendationItem;
  final ProductsEntryPoint sourceProductsEntryPoint;
  final bool? alreadyInRoutine;
}

class ProductDetailActionResult {
  const ProductDetailActionResult({required this.addedToRoutine});

  final bool addedToRoutine;
}

class AiProductRecommendResponse {
  const AiProductRecommendResponse({
    this.hasRecommendation = false,
    this.sessionId,
    this.sourceAnalysisId,
    this.expiresAt,
    this.status,
    this.summary,
    this.products = const [],
    this.categories = const [],
    this.profileSummary = const AiProductRecommendationProfileSummary(),
    this.message,
    this.note,
    this.generatedAt,
  });

  final bool hasRecommendation;
  final String? sessionId;
  final String? sourceAnalysisId;
  final DateTime? expiresAt;
  final String? status;
  final String? summary;
  final List<AiRecommendedProduct> products;
  final List<AiProductRecommendationCategory> categories;
  final AiProductRecommendationProfileSummary profileSummary;
  final String? message;
  final String? note;
  final DateTime? generatedAt;

  factory AiProductRecommendResponse.fromJson(Map<String, dynamic> json) {
    final categories = ((json['categories'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AiProductRecommendationCategory.fromJson)
        .toList();
    final products = ((json['products'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AiRecommendedProduct.fromJson)
        .toList();

    return AiProductRecommendResponse(
      hasRecommendation: (json['hasRecommendation'] ?? false) as bool,
      sessionId: json['sessionId']?.toString(),
      sourceAnalysisId: json['sourceAnalysisId']?.toString(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      status: json['status'] as String?,
      summary: json['summary'] as String?,
      products: products.isNotEmpty
          ? products
          : categories.expand((category) => category.items).toList(),
      categories: categories,
      profileSummary: json['profileSummary'] is Map<String, dynamic>
          ? AiProductRecommendationProfileSummary.fromJson(
              json['profileSummary'] as Map<String, dynamic>,
            )
          : const AiProductRecommendationProfileSummary(),
      message: json['message'] as String?,
      note: json['note'] as String?,
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? ''),
    );
  }
}

class AiIngredientReason {
  const AiIngredientReason({required this.ingredient, required this.reason});

  final String ingredient;
  final String reason;

  factory AiIngredientReason.fromJson(Map<String, dynamic> json) =>
      AiIngredientReason(
        ingredient: (json['ingredient'] ?? '') as String,
        reason: (json['reason'] ?? '') as String,
      );
}

class AiIngredientCheckResponse {
  const AiIngredientCheckResponse({
    required this.suitability,
    this.beneficialIngredients = const [],
    this.cautionIngredients = const [],
    this.overallExplanation = '',
    this.usageSuggestion = '',
    this.warnings = const [],
  });

  final String suitability;
  final List<AiIngredientReason> beneficialIngredients;
  final List<AiIngredientReason> cautionIngredients;
  final String overallExplanation;
  final String usageSuggestion;
  final List<String> warnings;

  factory AiIngredientCheckResponse.fromJson(Map<String, dynamic> json) =>
      AiIngredientCheckResponse(
        suitability: (json['suitability'] ?? 'caution') as String,
        beneficialIngredients:
            ((json['beneficialIngredients'] as List?) ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(AiIngredientReason.fromJson)
                .toList(),
        cautionIngredients: ((json['cautionIngredients'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiIngredientReason.fromJson)
            .toList(),
        overallExplanation: (json['overallExplanation'] ?? '') as String,
        usageSuggestion: (json['usageSuggestion'] ?? '') as String,
        warnings: ((json['warnings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class AiConflictItem {
  const AiConflictItem({
    required this.ingredientA,
    required this.ingredientB,
    required this.severity,
    required this.reason,
    required this.recommendation,
  });

  final String ingredientA;
  final String ingredientB;
  final String severity;
  final String reason;
  final String recommendation;

  factory AiConflictItem.fromJson(Map<String, dynamic> json) => AiConflictItem(
    ingredientA: (json['ingredientA'] ?? '') as String,
    ingredientB: (json['ingredientB'] ?? '') as String,
    severity: (json['severity'] ?? 'low') as String,
    reason: (json['reason'] ?? '') as String,
    recommendation: (json['recommendation'] ?? '') as String,
  );
}

class AiRoutineConflictCheckResponse {
  const AiRoutineConflictCheckResponse({
    required this.hasConflict,
    this.conflicts = const [],
    this.overallAdvice = '',
  });

  final bool hasConflict;
  final List<AiConflictItem> conflicts;
  final String overallAdvice;

  factory AiRoutineConflictCheckResponse.fromJson(Map<String, dynamic> json) =>
      AiRoutineConflictCheckResponse(
        hasConflict: (json['hasConflict'] ?? false) as bool,
        conflicts: ((json['conflicts'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiConflictItem.fromJson)
            .toList(),
        overallAdvice: (json['overallAdvice'] ?? '') as String,
      );
}

class AiReportSummary {
  const AiReportSummary({
    required this.reportId,
    required this.reportType,
    required this.summary,
    required this.progressEvaluation,
    required this.createdAt,
  });

  final String reportId;
  final String reportType;
  final String summary;
  final String progressEvaluation;
  final DateTime createdAt;

  factory AiReportSummary.fromJson(Map<String, dynamic> json) =>
      AiReportSummary(
        reportId: json['reportId'].toString(),
        reportType: (json['reportType'] ?? 'after_analysis') as String,
        summary: (json['summary'] ?? '') as String,
        progressEvaluation:
            (json['progressEvaluation'] ?? 'insufficient_data') as String,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class AiReportGenerateResponse {
  const AiReportGenerateResponse({
    required this.reportId,
    required this.reportType,
    required this.createdAt,
    required this.summary,
    required this.progressEvaluation,
    this.mainFindings = const [],
    this.routineFeedback,
    this.productFeedback,
    this.nextPlan = const [],
    this.warnings = const [],
  });

  final String reportId;
  final String reportType;
  final DateTime createdAt;
  final String summary;
  final String progressEvaluation;
  final List<String> mainFindings;
  final String? routineFeedback;
  final String? productFeedback;
  final List<String> nextPlan;
  final List<String> warnings;

  factory AiReportGenerateResponse.fromJson(Map<String, dynamic> json) =>
      AiReportGenerateResponse(
        reportId: json['reportId'].toString(),
        reportType: (json['reportType'] ?? 'after_analysis') as String,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        summary: (json['summary'] ?? '') as String,
        progressEvaluation:
            (json['progressEvaluation'] ?? 'insufficient_data') as String,
        mainFindings: ((json['mainFindings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        routineFeedback: json['routineFeedback'] as String?,
        productFeedback: json['productFeedback'] as String?,
        nextPlan: ((json['nextPlan'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        warnings: ((json['warnings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class PaymentLinkResponse {
  const PaymentLinkResponse({
    required this.checkoutUrl,
    required this.orderCode,
  });

  final String checkoutUrl;
  final int orderCode;

  factory PaymentLinkResponse.fromJson(Map<String, dynamic> json) =>
      PaymentLinkResponse(
        checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
        orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      );
}

class VerifyPaymentResponse {
  const VerifyPaymentResponse({required this.status, required this.planCode});

  final String status;
  final String planCode;

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) =>
      VerifyPaymentResponse(
        status: (json['status'] ?? 'pending').toString(),
        planCode: (json['planCode'] ?? '').toString(),
      );
}
