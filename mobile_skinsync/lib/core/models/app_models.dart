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
    issueType: (json['issueType'] ?? '') as String,
    severityScore: (json['severityScore'] ?? 0) as int,
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

class AnalysisResult {
  const AnalysisResult({
    required this.id,
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
    id: json['id'].toString(),
    imageUrl: (json['imageUrl'] ?? '') as String,
    skinType: (json['skinType'] ?? 'Unknown') as String,
    overallScore: (json['overallScore'] ?? 0) as int,
    confidenceScore: (json['confidenceScore'] ?? 0) as int,
    overview: json['overview'] as String?,
    disclaimer: json['disclaimer'] as String?,
    warnings: ((json['warnings'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
    issues: ((json['issues'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AnalysisIssue.fromJson)
        .toList(),
    recommendations: ((json['recommendations'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(AnalysisRecommendation.fromJson)
        .toList(),
  );
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
  });

  final String date;
  final String? skinFeeling;
  final String? notes;
  final int? acneLevel;
  final int? drynessLevel;
  final int? rednessLevel;
  final int? irritationLevel;
  final int? hydrationLevel;

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    date: json['date'].toString(),
    skinFeeling: json['skinFeeling'] as String?,
    notes: json['notes'] as String?,
    acneLevel: json['acneLevel'] as int?,
    drynessLevel: json['drynessLevel'] as int?,
    rednessLevel: json['rednessLevel'] as int?,
    irritationLevel: json['irritationLevel'] as int?,
    hydrationLevel: json['hydrationLevel'] as int?,
  );
}

class ReminderItem {
  const ReminderItem({
    required this.reminderId,
    required this.time,
    required this.routineType,
    required this.isEnabled,
  });

  final String reminderId;
  final String time;
  final String routineType;
  final bool isEnabled;

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    reminderId: json['reminderId'].toString(),
    time: (json['time'] ?? '') as String,
    routineType: (json['routineType'] ?? '') as String,
    isEnabled: (json['isEnabled'] ?? false) as bool,
  );
}
