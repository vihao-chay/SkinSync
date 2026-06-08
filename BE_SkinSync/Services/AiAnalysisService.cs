namespace SkinSync.Services;

public interface IAiAnalysisService
{
    AiResult Analyze(string fileName);
}

public class AiResult
{
    public int OverallScore { get; init; }
    public int? SkinAge { get; init; }
    public int? RecoveryCapacity { get; init; }
    public int? UvDamage { get; init; }
    public int? AgingRisk { get; init; }
    public string IssuesDetectedJson { get; init; } = "{}";
    public string RootCausesJson { get; init; } = "[]";
    public string SuggestedSkinType { get; init; } = "Normal";
    public string AiModel { get; init; } = "local-simulator";
    public string RawResponseJson { get; init; } = "{}";
}

public class AiAnalysisService : IAiAnalysisService
{
    public AiResult Analyze(string fileName)
    {
        var seed = Math.Abs(fileName.GetHashCode());
        var random = new Random(seed);
        var score = random.Next(58, 92);
        var skinType = score < 68 ? "Sensitive" : score < 76 ? "Oily" : score < 84 ? "Combination" : "Normal";

        var issuesJson = """
        {
          "acne": {{acne}},
          "pores": {{pores}},
          "wrinkles": {{wrinkles}},
          "redness": {{redness}}
        }
        """
            .Replace("{{acne}}", random.Next(15, 90).ToString())
            .Replace("{{pores}}", random.Next(20, 85).ToString())
            .Replace("{{wrinkles}}", random.Next(10, 70).ToString())
            .Replace("{{redness}}", random.Next(8, 65).ToString());

        return new AiResult
        {
            OverallScore = score,
            SkinAge = random.Next(18, 45),
            RecoveryCapacity = random.Next(40, 95),
            UvDamage = random.Next(15, 88),
            AgingRisk = random.Next(15, 85),
            IssuesDetectedJson = issuesJson,
            RootCausesJson = """["Possible dehydration","Inconsistent sunscreen usage","Mild barrier stress"]""",
            SuggestedSkinType = skinType
        };
    }
}
