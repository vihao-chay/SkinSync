class SkinProgressPhoto {
  const SkinProgressPhoto({
    required this.photoId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.photoDate,
    required this.timeOfDay,
    required this.lightingCondition,
    required this.faceAngle,
    this.note,
    required this.createdAt,
  });

  final String photoId;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime photoDate;
  final String timeOfDay;
  final String lightingCondition;
  final String faceAngle;
  final String? note;
  final DateTime createdAt;

  factory SkinProgressPhoto.fromJson(Map<String, dynamic> json) =>
      SkinProgressPhoto(
        photoId: json['photoId'].toString(),
        imageUrl: (json['imageUrl'] ?? '') as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        photoDate:
            DateTime.tryParse(json['photoDate']?.toString() ?? '') ??
            DateTime.now(),
        timeOfDay: (json['timeOfDay'] ?? 'unknown') as String,
        lightingCondition:
            (json['lightingCondition'] ?? 'unknown') as String,
        faceAngle: (json['faceAngle'] ?? 'unknown') as String,
        note: json['note'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class SkinProgressSummary {
  const SkinProgressSummary({
    required this.skinType,
    required this.hydration,
    required this.oiliness,
  });

  final String skinType;
  final String hydration;
  final String oiliness;

  factory SkinProgressSummary.fromJson(Map<String, dynamic> json) =>
      SkinProgressSummary(
        skinType: (json['skinType'] ?? 'Unknown') as String,
        hydration: (json['hydration'] ?? 'Unknown') as String,
        oiliness: (json['oiliness'] ?? 'Unknown') as String,
      );
}

class SkinProgressConditionScore {
  const SkinProgressConditionScore({
    required this.label,
    required this.score,
    this.change,
  });

  final String label;
  final int score;
  final int? change;

  factory SkinProgressConditionScore.fromJson(Map<String, dynamic> json) =>
      SkinProgressConditionScore(
        label: (json['label'] ?? '') as String,
        score: (json['score'] ?? 0) as int,
        change: json['change'] as int?,
      );
}

class SkinProgressVisualJourney {
  const SkinProgressVisualJourney({this.beforePhoto, this.afterPhoto});

  final SkinProgressPhoto? beforePhoto;
  final SkinProgressPhoto? afterPhoto;

  factory SkinProgressVisualJourney.fromJson(Map<String, dynamic> json) =>
      SkinProgressVisualJourney(
        beforePhoto: json['beforePhoto'] is Map<String, dynamic>
            ? SkinProgressPhoto.fromJson(json['beforePhoto'])
            : null,
        afterPhoto: json['afterPhoto'] is Map<String, dynamic>
            ? SkinProgressPhoto.fromJson(json['afterPhoto'])
            : null,
      );
}

class SkinProgressDashboard {
  const SkinProgressDashboard({
    required this.periodType,
    required this.periodLabel,
    required this.summary,
    this.conditionScores = const [],
    required this.visualJourney,
    this.photoGallery = const [],
    required this.progressStatus,
    this.aiReportSummary,
  });

  final String periodType;
  final String periodLabel;
  final SkinProgressSummary summary;
  final List<SkinProgressConditionScore> conditionScores;
  final SkinProgressVisualJourney visualJourney;
  final List<SkinProgressPhoto> photoGallery;
  final String progressStatus;
  final String? aiReportSummary;

  bool get hasPhotos => photoGallery.isNotEmpty;
  bool get canCompare =>
      visualJourney.beforePhoto != null && visualJourney.afterPhoto != null;

  factory SkinProgressDashboard.fromJson(Map<String, dynamic> json) =>
      SkinProgressDashboard(
        periodType: (json['periodType'] ?? 'monthly') as String,
        periodLabel: (json['periodLabel'] ?? '') as String,
        summary: SkinProgressSummary.fromJson(
          (json['summary'] as Map<String, dynamic>?) ?? const {},
        ),
        conditionScores: ((json['conditionScores'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SkinProgressConditionScore.fromJson)
            .toList(),
        visualJourney: SkinProgressVisualJourney.fromJson(
          (json['visualJourney'] as Map<String, dynamic>?) ?? const {},
        ),
        photoGallery: ((json['photoGallery'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SkinProgressPhoto.fromJson)
            .toList(),
        progressStatus:
            (json['progressStatus'] ?? 'insufficient_data') as String,
        aiReportSummary: json['aiReportSummary'] as String?,
      );
}

class SkinProgressScoreChanges {
  const SkinProgressScoreChanges({
    required this.acneScoreChange,
    required this.rednessScoreChange,
    required this.darkSpotScoreChange,
    required this.oilinessScoreChange,
    required this.drynessScoreChange,
    required this.textureScoreChange,
    required this.sensitivityScoreChange,
    required this.overallScoreChange,
  });

  final int acneScoreChange;
  final int rednessScoreChange;
  final int darkSpotScoreChange;
  final int oilinessScoreChange;
  final int drynessScoreChange;
  final int textureScoreChange;
  final int sensitivityScoreChange;
  final int overallScoreChange;

  factory SkinProgressScoreChanges.fromJson(Map<String, dynamic> json) =>
      SkinProgressScoreChanges(
        acneScoreChange: (json['acneScoreChange'] ?? 0) as int,
        rednessScoreChange: (json['rednessScoreChange'] ?? 0) as int,
        darkSpotScoreChange: (json['darkSpotScoreChange'] ?? 0) as int,
        oilinessScoreChange: (json['oilinessScoreChange'] ?? 0) as int,
        drynessScoreChange: (json['drynessScoreChange'] ?? 0) as int,
        textureScoreChange: (json['textureScoreChange'] ?? 0) as int,
        sensitivityScoreChange: (json['sensitivityScoreChange'] ?? 0) as int,
        overallScoreChange: (json['overallScoreChange'] ?? 0) as int,
      );
}

class SkinProgressComparison {
  const SkinProgressComparison({
    required this.comparisonId,
    required this.progressStatus,
    required this.comparisonSummary,
    required this.scoreChanges,
    this.improvements = const [],
    this.worsenedAreas = const [],
    this.stableAreas = const [],
    this.recommendations = const [],
    this.confidenceNote,
    this.beforePhoto,
    this.afterPhoto,
  });

  final String comparisonId;
  final String progressStatus;
  final String comparisonSummary;
  final SkinProgressScoreChanges scoreChanges;
  final List<String> improvements;
  final List<String> worsenedAreas;
  final List<String> stableAreas;
  final List<String> recommendations;
  final String? confidenceNote;
  final SkinProgressPhoto? beforePhoto;
  final SkinProgressPhoto? afterPhoto;

  factory SkinProgressComparison.fromJson(Map<String, dynamic> json) =>
      SkinProgressComparison(
        comparisonId: json['comparisonId'].toString(),
        progressStatus:
            (json['progressStatus'] ?? 'insufficient_data') as String,
        comparisonSummary: (json['comparisonSummary'] ?? '') as String,
        scoreChanges: SkinProgressScoreChanges.fromJson(
          (json['scoreChanges'] as Map<String, dynamic>?) ?? const {},
        ),
        improvements: ((json['improvements'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        worsenedAreas: ((json['worsenedAreas'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        stableAreas: ((json['stableAreas'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        recommendations: ((json['recommendations'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        confidenceNote: json['confidenceNote'] as String?,
        beforePhoto: json['beforePhoto'] is Map<String, dynamic>
            ? SkinProgressPhoto.fromJson(json['beforePhoto'])
            : null,
        afterPhoto: json['afterPhoto'] is Map<String, dynamic>
            ? SkinProgressPhoto.fromJson(json['afterPhoto'])
            : null,
      );
}

class SkinProgressReportSummary {
  const SkinProgressReportSummary({
    required this.reportId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.progressStatus,
    required this.summary,
    required this.createdAt,
  });

  final String reportId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String progressStatus;
  final String summary;
  final DateTime createdAt;

  factory SkinProgressReportSummary.fromJson(Map<String, dynamic> json) =>
      SkinProgressReportSummary(
        reportId: json['reportId'].toString(),
        periodType: (json['periodType'] ?? 'monthly') as String,
        periodStart:
            DateTime.tryParse(json['periodStart']?.toString() ?? '') ??
            DateTime.now(),
        periodEnd:
            DateTime.tryParse(json['periodEnd']?.toString() ?? '') ??
            DateTime.now(),
        progressStatus:
            (json['progressStatus'] ?? 'insufficient_data') as String,
        summary: (json['summary'] ?? '') as String,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class SkinProgressReportDetail {
  const SkinProgressReportDetail({
    required this.reportId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.progressStatus,
    required this.summary,
    required this.scoreChanges,
    this.mainFindings = const [],
    this.routineFeedback,
    this.nextSuggestions = const [],
    required this.createdAt,
  });

  final String reportId;
  final String periodType;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String progressStatus;
  final String summary;
  final SkinProgressScoreChanges scoreChanges;
  final List<String> mainFindings;
  final String? routineFeedback;
  final List<String> nextSuggestions;
  final DateTime createdAt;

  factory SkinProgressReportDetail.fromJson(Map<String, dynamic> json) =>
      SkinProgressReportDetail(
        reportId: json['reportId'].toString(),
        periodType: (json['periodType'] ?? 'monthly') as String,
        periodStart:
            DateTime.tryParse(json['periodStart']?.toString() ?? '') ??
            DateTime.now(),
        periodEnd:
            DateTime.tryParse(json['periodEnd']?.toString() ?? '') ??
            DateTime.now(),
        progressStatus:
            (json['progressStatus'] ?? 'insufficient_data') as String,
        summary: (json['summary'] ?? '') as String,
        scoreChanges: SkinProgressScoreChanges.fromJson(
          (json['scoreChanges'] as Map<String, dynamic>?) ?? const {},
        ),
        mainFindings: ((json['mainFindings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        routineFeedback: json['routineFeedback'] as String?,
        nextSuggestions: ((json['nextSuggestions'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
