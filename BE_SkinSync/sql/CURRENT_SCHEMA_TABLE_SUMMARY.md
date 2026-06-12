# SkinSync Current Table Summary

Nguon tong hop: `BE_SkinSync/Data/AppDbContext.cs` va cac entity hien tai trong `BE_SkinSync/Models/Entities`.

## 1. Core User

### `users`
- PK: `Id`
- Chuc nang: tai khoan nguoi dung
- Cot chinh:
  - `FullName`, `Email`, `Phone`
  - `PasswordHash`
  - `AvatarUrl`
  - `Role` = `user | admin | expert`
  - `Status` = `active | inactive | banned`
  - `PlanType` = `free | premium`
  - `CreatedAt`, `UpdatedAt`
- Lien ket:
  - 1-1 `user_profiles`
  - 1-n `ai_analyses`, `ai_recommendations`, `user_regimens`, `daily_logs`
  - 1-n `routine_trackings`, `reminders`
  - 1-n `ai_reports`, `ai_usage_logs`, `ai_chat_conversations`
  - 1-n `skin_progress_photos`, `skin_progress_analyses`, `skin_photo_comparisons`, `skin_progress_reports`

### `user_profiles`
- PK/FK: `UserId -> users.Id`
- Chuc nang: onboarding + ho so da
- Cot chinh:
  - `SkinType`
  - `SkinConcerns` (jsonb)
  - `MonthlyBudget`
  - `Age`, `BirthYear`, `Gender`
  - `SensitivityLevel`
  - `Allergies` (jsonb)
  - `SensitiveIngredients` (jsonb)
  - `SkinGoals` (jsonb)
  - `RoutinePreference` = `simple | balanced | advanced`
  - `CreatedAt`, `UpdatedAt`

## 2. Legacy Analysis + Recommendations

### `ai_analyses`
- PK: `Id`
- Chuc nang: legacy skin analysis history
- Cot chinh:
  - `UserId`
  - `ImageUrl`
  - `OverallScore`
  - `SkinAge`, `RecoveryCapacity`, `UvDamage`, `AgingRisk`
  - `IssuesDetected` (jsonb)
  - `RootCauses` (jsonb)
  - `AiModel`
  - `RawResponse` (jsonb)
  - `Status` = `pending | processing | completed | failed`
  - `CreatedAt`
- Lien ket:
  - 1-n `ai_analysis_issues`
  - 1-n `ai_recommendations`
  - 1-n `user_regimens` qua `AnalysisId`

### `ai_analysis_issues`
- PK: `Id`
- Chuc nang: chi tiet van de phat hien tu `ai_analyses`
- Cot chinh:
  - `AnalysisId`
  - `IssueType`
  - `SeverityScore`
  - `ConfidenceScore`
  - `Description`
  - `CreatedAt`

### `ai_recommendations`
- PK: `Id`
- Chuc nang: khuyen nghi AI legacy
- Cot chinh:
  - `UserId`
  - `AnalysisId` (nullable tuy theo data)
  - `RecommendationType` = `routine | product | lifestyle | warning | ingredient`
  - `Title`
  - `Content`
  - `Priority` (1-5)
  - `CreatedAt`

## 3. Product + Ingredient Catalog

### `products`
- PK: `Id`
- Chuc nang: product catalog
- Cot chinh:
  - `Name`, `Brand`, `Category`
  - `Description`
  - `Ingredient` (jsonb)
  - `KeyIngredients` (jsonb)
  - `TargetConcerns` (jsonb)
  - `AvoidForConcerns` (jsonb)
  - `UsageGuide`
  - `Price`, `Currency`
  - `SuitableSkinTypes` (jsonb)
  - `ImageUrl`
  - `Rating`
  - `Status` = `active | out_of_stock | inactive`
  - `CreatedAt`, `UpdatedAt`

### `ingredients`
- PK: `Id`
- Chuc nang: ingredient master data
- Cot chinh:
  - `Name`
  - `Description`
  - `Benefit`
  - `RiskLevel` = `low | medium | high`
  - `SuitableSkinTypes` (jsonb)
  - `NotSuitableFor` (jsonb)
  - `CreatedAt`

### `product_ingredients`
- PK: `Id`
- Chuc nang: join table giua product va ingredient
- Cot chinh:
  - `ProductId`
  - `IngredientId`
  - `Concentration`
  - `Note`
- Rang buoc:
  - unique `(ProductId, IngredientId)`

### `ingredient_conflict_rules`
- PK: `Id`
- Chuc nang: luat xung dot ingredient
- Cot chinh:
  - `PrimaryIngredientId`, `ConflictingIngredientId` (nullable)
  - `PrimaryIngredient`, `ConflictingIngredient` (text fallback)
  - `Severity` = `low | medium | high`
  - `Message`
  - `Recommendation`
  - `CreatedAt`

## 4. Routine System

### `user_regimens`
- PK: `Id`
- Chuc nang: routine cua user
- Cot chinh:
  - `UserId`
  - `AnalysisId` (nullable)
  - `Name`
  - `StartDate`, `EndDate`
  - `IsActive`
  - `IsCustom`
  - `Source` = `ai | user | expert | system`
  - `CreatedAt`, `UpdatedAt`

### `regimen_items`
- PK: `Id`
- Chuc nang: tung step trong routine
- Cot chinh:
  - `RegimenId`
  - `ProductId`
  - `RoutineTime` = `Morning | Evening`
  - `StepOrder`
  - `Instruction`
  - `Frequency`
  - `CreatedAt`
- Rang buoc:
  - unique `(RegimenId, RoutineTime, StepOrder)`

### `routine_trackings`
- PK: `Id`
- Chuc nang: log user complete/skip step
- Cot chinh:
  - `UserId`
  - `StepId`
  - `Status` = `completed | skipped | missed`
  - `Note`
  - `CompletedAt`

### `reminders`
- PK: `Id`
- Chuc nang: reminder cho routine
- Cot chinh:
  - `UserId`
  - `Time`
  - `RoutineType` = `Morning | Evening`
  - `Frequency`
  - `Reason`
  - `Priority` = `low | medium | high`
  - `IsAdaptive`
  - `IsEnabled`
  - `CreatedAt`, `UpdatedAt`
- Rang buoc:
  - unique `(UserId, RoutineType)`

## 5. Daily Check-in

### `daily_logs`
- PK: `Id`
- Chuc nang: daily diary / check-in
- Cot chinh:
  - `UserId`
  - `Date`
  - `MorningCompleted`, `EveningCompleted`
  - `SkinFeeling` = `good | normal | dry | oily | irritated | acne_flare | sensitive`
  - `IsIrritated`
  - `Notes`
  - `AcneLevel`, `DrynessLevel`, `RednessLevel`, `IrritationLevel`, `HydrationLevel`
  - `DailyImageUrl`
  - `CreatedAt`, `UpdatedAt`
- Rang buoc:
  - unique `(UserId, Date)`

## 6. AI Platform Support

### `ai_reports`
- PK: `Id`
- Chuc nang: AI-generated summary/report ngoai progress timeline
- Cot chinh:
  - `UserId`
  - `ReportType` = `weekly | monthly | after_analysis`
  - `Summary`
  - `ProgressEvaluation` = `improved | stable | worse | insufficient_data`
  - `MainFindings` (jsonb)
  - `RoutineFeedback`
  - `ProductFeedback`
  - `NextPlan` (jsonb)
  - `Warnings` (jsonb)
  - `RawAiResponse` (jsonb)
  - `CreatedAt`

### `ai_usage_logs`
- PK: `Id`
- Chuc nang: theo doi AI usage va quota
- Cot chinh:
  - `UserId`
  - `FeatureName`
  - `UsedAt`
  - `InputTokens`, `OutputTokens`
  - `Model`
  - `CostEstimate`
- `FeatureName` hien tai cho phep:
  - `skin_analysis`
  - `skin_progress_analysis`
  - `skin_progress_compare`
  - `skin_progress_report`
  - `ai_chat`
  - `routine_generation`
  - `product_recommendation`
  - `ingredient_check`
  - `report_generation`
  - `conflict_check`
  - `smart_reminder`

### `ai_chat_conversations`
- PK: `Id`
- Chuc nang: danh sach conversation cua AI chat
- Cot chinh:
  - `UserId`
  - `Title`
  - `CreatedAt`, `UpdatedAt`
  - `LastMessageAt`

### `ai_chat_messages`
- PK: `Id`
- Chuc nang: message trong conversation
- Cot chinh:
  - `ConversationId`
  - `Role` = `user | assistant | system`
  - `Content`
  - `CreatedAt`

## 7. Skin Progress Canonical System

### `skin_progress_photos`
- PK: `Id`
- Chuc nang: anh dau vao cho progress timeline
- Cot chinh:
  - `UserId`
  - `ImageUrl`
  - `ThumbnailUrl`
  - `Source` = `dashboard | ai_hub | progress | onboarding | unknown`
  - `ImageMetadataJson` (jsonb)
  - `PhotoDate`
  - `TimeOfDay` = `morning | afternoon | night | unknown`
  - `LightingCondition` = `good | medium | poor | unknown`
  - `FaceAngle` = `front | left | right | unknown`
  - `Note`
  - `CreatedAt`

### `skin_progress_analyses`
- PK: `Id`
- Chuc nang: ket qua AI normalize cho tung progress photo
- Cot chinh:
  - `UserId`
  - `PhotoId` (unique)
  - `Status` = `pending | processing | completed | failed | discarded`
  - `AiModel`
  - `SkinTypeEstimate`
  - `HydrationLevel`
  - `OilinessLevel`
  - `AcneScore`, `RednessScore`, `DarkSpotScore`
  - `OilinessScore`, `DrynessScore`, `TextureScore`, `SensitivityScore`
  - `OverallScore`
  - `ConfidenceScore`
  - `DetectedConcerns` (jsonb)
  - `AiSummary`
  - `Recommendations` (jsonb)
  - `RoutineSuggestions` (jsonb)
  - `ProductSuggestions` (jsonb)
  - `SafetyNotes` (jsonb)
  - `RiskFlags` (jsonb)
  - `RawAiResponse` (jsonb)
  - `ParsedAiResponse` (jsonb)
  - `ErrorMessage`
  - `CompletedAt`, `DiscardedAt`
  - `CreatedAt`

### `skin_photo_comparisons`
- PK: `Id`
- Chuc nang: compare before/after giua 2 anh da duoc analyze
- Cot chinh:
  - `UserId`
  - `BeforePhotoId`, `AfterPhotoId`
  - `BeforeAnalysisId`, `AfterAnalysisId`
  - `ProgressStatus` = `improved | stable | worse | mixed | insufficient_data`
  - `ComparisonSummary`
  - `Improvements` (jsonb)
  - `WorsenedAreas` (jsonb)
  - `StableAreas` (jsonb)
  - `ScoreChanges` (jsonb)
  - `Recommendations` (jsonb)
  - `ConfidenceNote`
  - `CreatedAt`
- Rang buoc:
  - unique `(BeforePhotoId, AfterPhotoId)`

### `skin_progress_reports`
- PK: `Id`
- Chuc nang: weekly/monthly/yearly report dua tren progress timeline
- Cot chinh:
  - `UserId`
  - `PeriodType` = `weekly | monthly | yearly`
  - `PeriodStart`, `PeriodEnd`
  - `ProgressStatus` = `improved | stable | worse | mixed | insufficient_data`
  - `Summary`
  - `ScoreChanges` (jsonb)
  - `MainFindings` (jsonb)
  - `RoutineFeedback`
  - `NextSuggestions` (jsonb)
  - `RawAiResponse` (jsonb)
  - `CreatedAt`
- Rang buoc:
  - unique `(UserId, PeriodType, PeriodStart, PeriodEnd)`

## 8. Quan he tong the

### User-centered
- `users`
  - `1 - 1` `user_profiles`
  - `1 - n` `user_regimens`
  - `1 - n` `daily_logs`
  - `1 - n` `reminders`
  - `1 - n` `routine_trackings`
  - `1 - n` `ai_*`
  - `1 - n` `skin_progress_*`

### Progress-centered
- `skin_progress_photos`
  - `1 - 1` gan nhu thuc te voi `skin_progress_analyses` qua unique `PhotoId`
  - `1 - n` logic compare/report read model
- `skin_progress_analyses`
  - duoc dung lam canonical analysis layer moi
- `ai_analyses`
  - van ton tai de compatibility voi flow cu

## 9. File SQL nen dung

- Neu chi muon dong bo schema backend hien tai:
  - `BE_SkinSync/sql/2026-06-11-reconcile-current-schema.sql`
- Neu chi muon fix reminder:
  - `BE_SkinSync/sql/2026-06-11-fix-reminders-frequency.sql`
- Neu chi muon fix phan unify progress moi:
  - `BE_SkinSync/sql/2026-06-11-unify-skin-analysis-progress.sql`
