namespace SkinSync.Models.Configurations;

public class RecommendationScoringOptions
{
    public const string SectionName = "RecommendationEngine";

    public RecommendationScoreWeightsOptions Weights { get; set; } = new();
    public List<RecommendationRoutineSlotOptions> Slots { get; set; } = [];
    public List<IngredientScoreRuleOptions> IngredientRules { get; set; } = [];
    public List<SensitiveIngredientPenaltyOptions> SensitiveIngredientPenalties { get; set; } = [];
    public List<TimingPreferenceRuleOptions> TimingPreferences { get; set; } = [];
    public Dictionary<string, string[]> ConcernAliases { get; set; } = new();
    public Dictionary<string, string[]> GoalAliases { get; set; } = new();
    public Dictionary<string, string[]> SkinTypeAliases { get; set; } = new();
    public Dictionary<string, int> ConflictSeverityPenalties { get; set; } = new();
    public List<string> HighConcentrationAcidAliases { get; set; } = [];
    public decimal HighConcentrationAcidThresholdPercent { get; set; } = 8m;
}

public class RecommendationScoreWeightsOptions
{
    public int BaseScore { get; set; } = 15;
    public int ProductConcernMatchBonus { get; set; } = 12;
    public int ProductGoalMatchBonus { get; set; } = 8;
    public int ProductSkinTypeMatchBonus { get; set; } = 12;
    public int ProductAvoidConcernPenalty { get; set; } = 18;
    public int VerifiedProductBonus { get; set; } = 4;
    public int CompleteCatalogDataBonus { get; set; } = 4;
    public int LowIrritationBonus { get; set; } = 6;
    public int DescriptionKeywordBonus { get; set; } = 4;
    public decimal RatingMultiplier { get; set; } = 3m;
    public int PopularityMaxBonus { get; set; } = 8;
    public int UsageTimeMatchBonus { get; set; } = 6;
    public int UsageTimeMismatchPenalty { get; set; } = 10;
    public int MinimumRoutineScore { get; set; } = 45;
    public int NormalizationMinRawScore { get; set; } = -20;
    public int NormalizationMaxRawScore { get; set; } = 140;
    public Dictionary<string, int> SensitivityRiskPenalties { get; set; } = new();
}

public class RecommendationRoutineSlotOptions
{
    public string Key { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string RoutineTime { get; set; } = string.Empty;
    public int StepOrder { get; set; }
    public int CategoryWeight { get; set; }
    public bool Required { get; set; } = true;
    public int AlternativeLimit { get; set; } = 3;
    public List<string> ProductCategories { get; set; } = [];
}

public class IngredientScoreRuleOptions
{
    public string Ingredient { get; set; } = string.Empty;
    public List<string> Aliases { get; set; } = [];
    public Dictionary<string, int> SkinTypeWeights { get; set; } = new();
    public Dictionary<string, int> ConcernWeights { get; set; } = new();
    public Dictionary<string, int> GoalWeights { get; set; } = new();
    public Dictionary<string, int> SensitivityWeights { get; set; } = new();
    public List<string> BenefitTags { get; set; } = [];
}

public class SensitiveIngredientPenaltyOptions
{
    public string Ingredient { get; set; } = string.Empty;
    public List<string> Aliases { get; set; } = [];
    public int Penalty { get; set; }
}

public class TimingPreferenceRuleOptions
{
    public string Ingredient { get; set; } = string.Empty;
    public List<string> Aliases { get; set; } = [];
    public string PreferredRoutineTime { get; set; } = string.Empty;
    public int Bonus { get; set; }
    public int OppositeTimePenalty { get; set; }
}
