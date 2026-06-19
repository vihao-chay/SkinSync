# Skin Analysis Score Mapping

This file locks the meaning of score fields used by `analyze skin`.

## Rules

- `skinHealthScore` is the primary positive score. Higher is better.
- `overallConcernSeverity` is the primary negative score. Higher means more visible concerns.
- `skinScore` and `overallScore` are legacy severity aliases only.
- New UI must never present `skinScore` or `overallScore` as `Skin Health` or `Skin Score`.
- `confidence` is the canonical display percent `0..100`.
- `confidenceScore` is a legacy ratio `0..1` and should only be used as fallback.
- Public API `hydrationLevel` is numeric. Prompt-side `hydrationLevel` text is internal AI normalization only.
- `metrics.moisture` is a positive wellness metric. Other current metrics are concern metrics.

## End-to-End Mapping

| Meaning | Prompt field | Backend canonical | DB field | API field | Flutter field/helper | UI label |
| --- | --- | --- | --- | --- | --- | --- |
| Skin health, higher is better | `skinHealthScore` | `SkinHealthScore` | `SkinHealthScore` | `skinHealthScore` | `displaySkinHealthScore` | `Skin Health` |
| Visible concern severity, higher is worse | `overallConcernSeverity` | `OverallConcernSeverity` | `OverallConcernSeverity` | `overallConcernSeverity` | `displayConcernSeverity` / `displayConcernSeverityScore` | `Visible Concern Level` |
| Legacy severity alias | `scores.overallScore` or legacy payload | `OverallScore` | `OverallScore` | `skinScore` / `overallScore` | fallback only | hidden in new UI |
| Confidence percent | `confidence` | `Confidence` | `ConfidenceScore` as ratio after normalization | `confidence` | `displayConfidencePercent` | `Confidence` |
| Legacy confidence ratio | legacy payload | `ConfidenceScore` | `ConfidenceScore` | `confidenceScore` | fallback only | hidden in new UI |
| Estimated skin type | `skinTypeEstimate` | `SkinTypeEstimate` | `SkinTypeEstimate` | `skinType` | `skinType` | `Skin type estimate` |
| Moisture balance, higher is better | `metrics.moisture` | `Metrics.Moisture` | derived from analysis fields | `metrics.moisture` / `hydrationLevel` | `metrics.moisture` | `Moisture` |
| Hydration label, internal only | `hydrationLevel` | `HydrationLevel` | `HydrationLevel` | not preferred for new UI | do not treat as numeric source | not shown directly |

## Metric Semantics

- Concern metrics:
  - `metrics.acne`
  - `metrics.redness`
  - `metrics.oiliness`
  - `metrics.dryness`
  - `metrics.texture`
- Wellness metric:
  - `metrics.moisture`

UI should not render all metrics with the same “higher is better” meaning unless the metric label and caption make the polarity explicit.
