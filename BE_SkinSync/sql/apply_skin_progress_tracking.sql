ALTER TABLE ai_usage_logs DROP CONSTRAINT IF EXISTS ck_ai_usage_logs_feature_name;

ALTER TABLE ai_usage_logs
ADD CONSTRAINT ck_ai_usage_logs_feature_name
CHECK ("FeatureName" IN (
  'skin_analysis',
  'skin_progress_analysis',
  'skin_progress_compare',
  'skin_progress_report',
  'ai_chat',
  'routine_generation',
  'product_recommendation',
  'ingredient_check',
  'report_generation',
  'conflict_check'
));

CREATE TABLE IF NOT EXISTS skin_progress_photos (
  "Id" uuid PRIMARY KEY,
  "UserId" uuid NOT NULL REFERENCES users("Id") ON DELETE CASCADE,
  "ImageUrl" character varying(500) NOT NULL,
  "ThumbnailUrl" character varying(500),
  "PhotoDate" date NOT NULL,
  "TimeOfDay" character varying(20) NOT NULL DEFAULT 'unknown',
  "LightingCondition" character varying(20) NOT NULL DEFAULT 'unknown',
  "FaceAngle" character varying(20) NOT NULL DEFAULT 'unknown',
  "Note" text,
  "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT ck_skin_progress_photos_time_of_day CHECK ("TimeOfDay" IN ('morning', 'afternoon', 'night', 'unknown')),
  CONSTRAINT ck_skin_progress_photos_lighting_condition CHECK ("LightingCondition" IN ('good', 'medium', 'poor', 'unknown')),
  CONSTRAINT ck_skin_progress_photos_face_angle CHECK ("FaceAngle" IN ('front', 'left', 'right', 'unknown'))
);

CREATE INDEX IF NOT EXISTS "IX_skin_progress_photos_UserId_PhotoDate"
ON skin_progress_photos ("UserId", "PhotoDate" DESC);

CREATE TABLE IF NOT EXISTS skin_progress_reports (
  "Id" uuid PRIMARY KEY,
  "UserId" uuid NOT NULL REFERENCES users("Id") ON DELETE CASCADE,
  "PeriodType" character varying(20) NOT NULL DEFAULT 'monthly',
  "PeriodStart" date NOT NULL,
  "PeriodEnd" date NOT NULL,
  "ProgressStatus" character varying(30) NOT NULL DEFAULT 'insufficient_data',
  "Summary" text NOT NULL,
  "ScoreChanges" jsonb NOT NULL,
  "MainFindings" jsonb NOT NULL,
  "RoutineFeedback" text,
  "NextSuggestions" jsonb NOT NULL,
  "RawAiResponse" jsonb,
  "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT ck_skin_progress_reports_period_type CHECK ("PeriodType" IN ('weekly', 'monthly', 'yearly')),
  CONSTRAINT ck_skin_progress_reports_progress_status CHECK ("ProgressStatus" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data'))
);

CREATE INDEX IF NOT EXISTS "IX_skin_progress_reports_UserId_CreatedAt"
ON skin_progress_reports ("UserId", "CreatedAt" DESC);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodEnd"
ON skin_progress_reports ("UserId", "PeriodType", "PeriodStart", "PeriodEnd");

CREATE TABLE IF NOT EXISTS skin_progress_analyses (
  "Id" uuid PRIMARY KEY,
  "UserId" uuid NOT NULL REFERENCES users("Id") ON DELETE CASCADE,
  "PhotoId" uuid NOT NULL REFERENCES skin_progress_photos("Id") ON DELETE CASCADE,
  "SkinTypeEstimate" character varying(30) NOT NULL DEFAULT 'unknown',
  "HydrationLevel" character varying(20) NOT NULL DEFAULT 'unknown',
  "OilinessLevel" character varying(20) NOT NULL DEFAULT 'unknown',
  "AcneScore" integer NOT NULL,
  "RednessScore" integer NOT NULL,
  "DarkSpotScore" integer NOT NULL,
  "OilinessScore" integer NOT NULL,
  "DrynessScore" integer NOT NULL,
  "TextureScore" integer NOT NULL,
  "SensitivityScore" integer NOT NULL,
  "OverallScore" integer NOT NULL,
  "DetectedConcerns" jsonb NOT NULL,
  "AiSummary" text NOT NULL,
  "Recommendations" jsonb NOT NULL,
  "RiskFlags" jsonb NOT NULL,
  "RawAiResponse" jsonb,
  "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT ck_skin_progress_analyses_skin_type CHECK ("SkinTypeEstimate" IN ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown')),
  CONSTRAINT ck_skin_progress_analyses_hydration CHECK ("HydrationLevel" IN ('low', 'balanced', 'high', 'unknown')),
  CONSTRAINT ck_skin_progress_analyses_oiliness CHECK ("OilinessLevel" IN ('low', 'medium', 'high', 'only_t_zone', 'unknown')),
  CONSTRAINT ck_skin_progress_analyses_acne_score CHECK ("AcneScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_redness_score CHECK ("RednessScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_dark_spot_score CHECK ("DarkSpotScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_oiliness_score CHECK ("OilinessScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_dryness_score CHECK ("DrynessScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_texture_score CHECK ("TextureScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_sensitivity_score CHECK ("SensitivityScore" BETWEEN 0 AND 100),
  CONSTRAINT ck_skin_progress_analyses_overall_score CHECK ("OverallScore" BETWEEN 0 AND 100)
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_skin_progress_analyses_PhotoId"
ON skin_progress_analyses ("PhotoId");

CREATE INDEX IF NOT EXISTS "IX_skin_progress_analyses_UserId_CreatedAt"
ON skin_progress_analyses ("UserId", "CreatedAt" DESC);

CREATE TABLE IF NOT EXISTS skin_photo_comparisons (
  "Id" uuid PRIMARY KEY,
  "UserId" uuid NOT NULL REFERENCES users("Id") ON DELETE CASCADE,
  "BeforePhotoId" uuid NOT NULL REFERENCES skin_progress_photos("Id") ON DELETE RESTRICT,
  "AfterPhotoId" uuid NOT NULL REFERENCES skin_progress_photos("Id") ON DELETE RESTRICT,
  "BeforeAnalysisId" uuid NOT NULL REFERENCES skin_progress_analyses("Id") ON DELETE RESTRICT,
  "AfterAnalysisId" uuid NOT NULL REFERENCES skin_progress_analyses("Id") ON DELETE RESTRICT,
  "ProgressStatus" character varying(30) NOT NULL DEFAULT 'insufficient_data',
  "ComparisonSummary" text NOT NULL,
  "Improvements" jsonb NOT NULL,
  "WorsenedAreas" jsonb NOT NULL,
  "StableAreas" jsonb NOT NULL,
  "ScoreChanges" jsonb NOT NULL,
  "Recommendations" jsonb NOT NULL,
  "ConfidenceNote" text,
  "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
  CONSTRAINT ck_skin_photo_comparisons_progress_status CHECK ("ProgressStatus" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data'))
);

CREATE INDEX IF NOT EXISTS "IX_skin_photo_comparisons_AfterAnalysisId"
ON skin_photo_comparisons ("AfterAnalysisId");

CREATE INDEX IF NOT EXISTS "IX_skin_photo_comparisons_AfterPhotoId"
ON skin_photo_comparisons ("AfterPhotoId");

CREATE INDEX IF NOT EXISTS "IX_skin_photo_comparisons_BeforeAnalysisId"
ON skin_photo_comparisons ("BeforeAnalysisId");

CREATE UNIQUE INDEX IF NOT EXISTS "IX_skin_photo_comparisons_BeforePhotoId_AfterPhotoId"
ON skin_photo_comparisons ("BeforePhotoId", "AfterPhotoId");

CREATE INDEX IF NOT EXISTS "IX_skin_photo_comparisons_UserId_CreatedAt"
ON skin_photo_comparisons ("UserId", "CreatedAt" DESC);
