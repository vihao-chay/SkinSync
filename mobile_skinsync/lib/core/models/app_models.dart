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
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String status;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'].toString(),
    fullName: (json['fullName'] ?? '') as String,
    email: (json['email'] ?? '') as String,
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    role: (json['role'] ?? 'user') as String,
    status: (json['status'] ?? 'active') as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role,
    'status': status,
  };

  AppUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? role,
    String? status,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
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
    issueType: ((json['issueType'] ?? json['label'] ?? json['concern']) ?? '') as String,
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
    required this.imageUrl,
    required this.skinType,
    required this.overallScore,
    required this.confidenceScore,
    this.overview,
    this.disclaimer,
    this.warnings = const [],
    this.issues = const [],
    this.recommendations = const [],
  });

  final String id;
  final String? analysisSessionId;
  final String? progressEntryId;
  final String? photoId;
  final String? source;
  final String imageUrl;
  final String skinType;
  final int overallScore;
  final int confidenceScore;
  final String? overview;
  final String? disclaimer;
  final List<String> warnings;
  final List<AnalysisIssue> issues;
  final List<AnalysisRecommendation> recommendations;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
    id: (json['id'] ?? json['analysisResultId'] ?? json['analysisId']).toString(),
    analysisSessionId: json['analysisSessionId']?.toString(),
    progressEntryId: json['progressEntryId']?.toString(),
    photoId: json['photoId']?.toString(),
    source: json['source']?.toString(),
    imageUrl: (json['imageUrl'] ?? '') as String,
    skinType: ((json['skinType'] ?? json['skinTypeEstimate']) ?? 'Unknown') as String,
    overallScore: ((json['overallScore'] ?? json['skinScore']) ?? 0) as int,
    confidenceScore: ((json['confidenceScore'] as num?)?.round() ??
            (((json['confidenceScore'] as num?) ?? (json['confidence'] as num?) ?? 0) * 100).round()),
    overview: (json['overview'] ?? json['skinSummary']) as String?,
    disclaimer: json['disclaimer'] as String?,
    warnings: (((json['warnings'] as List?) ?? (json['riskFlags'] as List?) ?? const []))
        .map((e) => e.toString())
        .toList(),
    issues: (((json['issues'] as List?) ?? (json['detectedConcerns'] as List?) ?? const []))
        .whereType<Map<String, dynamic>>()
        .map(AnalysisIssue.fromJson)
        .toList(),
    recommendations: ((json['recommendations'] as List?) ?? const [])
        .map((item) {
          if (item is Map<String, dynamic>) {
            return AnalysisRecommendation(
              title: (item['title'] ?? item['type'] ?? 'Recommendation') as String,
              content: (item['content'] ?? item['description'] ?? '') as String,
            );
          }
          return AnalysisRecommendation(
            title: 'Recommendation',
            content: item.toString(),
          );
        })
        .toList(),
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
    this.completedStepIds = const [],
  });

  final int totalSteps;
  final int completedSteps;
  final bool morningCompleted;
  final bool eveningCompleted;
  final List<String> completedStepIds;

  factory RoutineTrackingToday.fromJson(Map<String, dynamic> json) =>
      RoutineTrackingToday(
        totalSteps: (json['totalSteps'] ?? 0) as int,
        completedSteps: (json['completedSteps'] ?? 0) as int,
        morningCompleted: (json['morningCompleted'] ?? false) as bool,
        eveningCompleted: (json['eveningCompleted'] ?? false) as bool,
        completedStepIds: ((json['steps'] as List?) ?? const [])
            .map((e) => (e as Map<String, dynamic>)['stepId'].toString())
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
  final String? skinFeeling;
  final String? notes;
  final int? acneLevel;
  final int? drynessLevel;
  final int? rednessLevel;
  final int? irritationLevel;
  final int? hydrationLevel;
  final String? dailyImageUrl;

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    date: json['date'].toString(),
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
    this.warnings = const [],
  });

  final String productId;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String currency;
  final int matchScore;
  final String aiReason;
  final List<String> warnings;

  factory AiRecommendedProduct.fromJson(Map<String, dynamic> json) =>
      AiRecommendedProduct(
        productId: json['productId'].toString(),
        name: (json['name'] ?? '') as String,
        brand: (json['brand'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        currency: (json['currency'] ?? 'VND') as String,
        matchScore: (json['matchScore'] ?? 0) as int,
        aiReason: (json['aiReason'] ?? '') as String,
        warnings: ((json['warnings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
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

class ProductsPageArgs {
  const ProductsPageArgs({
    this.initialCategory,
    this.initialConcern,
    this.initialBudget,
    this.referenceId,
  });

  final String? initialCategory;
  final String? initialConcern;
  final double? initialBudget;
  final String? referenceId;
}

class AiProductRecommendResponse {
  const AiProductRecommendResponse({this.products = const []});

  final List<AiRecommendedProduct> products;

  factory AiProductRecommendResponse.fromJson(Map<String, dynamic> json) =>
      AiProductRecommendResponse(
        products: ((json['products'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AiRecommendedProduct.fromJson)
            .toList(),
      );
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
