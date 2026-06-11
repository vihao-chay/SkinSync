-- SkinSync current-schema reconcile script
-- Safe to run on an existing database before using the current backend code.
-- Scope: schema only, no seed data inserts.

begin;

-- users
alter table if exists public.users
    add column if not exists "Phone" character varying(30) null,
    add column if not exists "AvatarUrl" character varying(500) null,
    add column if not exists "Role" character varying(20) not null default 'user',
    add column if not exists "Status" character varying(20) not null default 'active',
    add column if not exists "PlanType" character varying(20) not null default 'free',
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_users_role') then
        alter table public.users
            add constraint ck_users_role
            check ("Role" in ('user', 'admin', 'expert'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_users_status') then
        alter table public.users
            add constraint ck_users_status
            check ("Status" in ('active', 'inactive', 'banned'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_users_plan_type') then
        alter table public.users
            add constraint ck_users_plan_type
            check ("PlanType" in ('free', 'premium'));
    end if;
end $$;

create unique index if not exists "IX_users_Email" on public.users ("Email");

-- user_profiles
alter table if exists public.user_profiles
    add column if not exists "BirthYear" integer null,
    add column if not exists "Allergies" jsonb null,
    add column if not exists "SensitiveIngredients" jsonb null,
    add column if not exists "SkinGoals" jsonb null,
    add column if not exists "RoutinePreference" character varying(20) null,
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_user_profiles_skin_type') then
        alter table public.user_profiles
            add constraint ck_user_profiles_skin_type
            check ("SkinType" is null or "SkinType" in ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_user_profiles_monthly_budget') then
        alter table public.user_profiles
            add constraint ck_user_profiles_monthly_budget
            check ("MonthlyBudget" is null or "MonthlyBudget" >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_user_profiles_age') then
        alter table public.user_profiles
            add constraint ck_user_profiles_age
            check ("Age" is null or "Age" >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_user_profiles_sensitivity_level') then
        alter table public.user_profiles
            add constraint ck_user_profiles_sensitivity_level
            check ("SensitivityLevel" is null or "SensitivityLevel" between 1 and 5);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_user_profiles_routine_preference') then
        alter table public.user_profiles
            add constraint ck_user_profiles_routine_preference
            check ("RoutinePreference" is null or "RoutinePreference" in ('simple', 'balanced', 'advanced'));
    end if;
end $$;

-- ai_reports
create table if not exists public.ai_reports (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "ReportType" character varying(30) not null,
    "Summary" text not null,
    "ProgressEvaluation" character varying(30) not null,
    "MainFindings" jsonb not null,
    "RoutineFeedback" text null,
    "ProductFeedback" text null,
    "NextPlan" jsonb not null,
    "Warnings" jsonb not null,
    "RawAiResponse" jsonb null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_ai_reports_report_type') then
        alter table public.ai_reports
            add constraint ck_ai_reports_report_type
            check ("ReportType" in ('weekly', 'monthly', 'after_analysis'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_ai_reports_progress_evaluation') then
        alter table public.ai_reports
            add constraint ck_ai_reports_progress_evaluation
            check ("ProgressEvaluation" in ('improved', 'stable', 'worse', 'insufficient_data'));
    end if;
end $$;

create index if not exists "IX_ai_reports_UserId_CreatedAt"
    on public.ai_reports ("UserId", "CreatedAt" desc);

-- ai_usage_logs
create table if not exists public.ai_usage_logs (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "FeatureName" character varying(50) not null,
    "UsedAt" timestamp with time zone not null default timezone('utc', now()),
    "InputTokens" integer null,
    "OutputTokens" integer null,
    "Model" character varying(100) null,
    "CostEstimate" numeric(12,4) null
);

alter table if exists public.ai_usage_logs
    drop constraint if exists ck_ai_usage_logs_feature_name;

alter table public.ai_usage_logs
    add constraint ck_ai_usage_logs_feature_name
    check ("FeatureName" in (
        'skin_analysis',
        'skin_progress_analysis',
        'skin_progress_compare',
        'skin_progress_report',
        'ai_chat',
        'routine_generation',
        'product_recommendation',
        'ingredient_check',
        'report_generation',
        'conflict_check',
        'smart_reminder'
    ));

create index if not exists "IX_ai_usage_logs_UserId_FeatureName_UsedAt"
    on public.ai_usage_logs ("UserId", "FeatureName", "UsedAt" desc);

-- products
alter table if exists public.products
    add column if not exists "Description" text null,
    add column if not exists "Ingredient" jsonb null,
    add column if not exists "UsageGuide" text null,
    add column if not exists "Currency" character varying(10) not null default 'VND',
    add column if not exists "KeyIngredients" jsonb null,
    add column if not exists "TargetConcerns" jsonb null,
    add column if not exists "AvoidForConcerns" jsonb null,
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_products_price') then
        alter table public.products add constraint ck_products_price check ("Price" >= 0);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_products_rating') then
        alter table public.products add constraint ck_products_rating check ("Rating" is null or "Rating" between 0 and 5);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_products_status') then
        alter table public.products add constraint ck_products_status check ("Status" in ('active', 'out_of_stock', 'inactive'));
    end if;
end $$;

create index if not exists "IX_products_Status_Category" on public.products ("Status", "Category");
create index if not exists "IX_products_Brand" on public.products ("Brand");
create index if not exists "IX_products_Price" on public.products ("Price");

-- ingredient_conflict_rules
create table if not exists public.ingredient_conflict_rules (
    "Id" uuid primary key,
    "PrimaryIngredientId" uuid null references public.ingredients("Id") on delete restrict,
    "ConflictingIngredientId" uuid null references public.ingredients("Id") on delete restrict,
    "PrimaryIngredient" character varying(120) null,
    "ConflictingIngredient" character varying(120) null,
    "Severity" character varying(20) not null default 'medium',
    "Message" text not null default '',
    "Recommendation" text not null default '',
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_ingredient_conflict_rules_severity') then
        alter table public.ingredient_conflict_rules
            add constraint ck_ingredient_conflict_rules_severity
            check ("Severity" in ('low', 'medium', 'high'));
    end if;
end $$;

create unique index if not exists "IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIngredientId"
    on public.ingredient_conflict_rules ("PrimaryIngredientId", "ConflictingIngredientId");
create unique index if not exists "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngredient"
    on public.ingredient_conflict_rules ("PrimaryIngredient", "ConflictingIngredient")
    where "PrimaryIngredient" is not null and "ConflictingIngredient" is not null;

-- user_regimens
alter table if exists public.user_regimens
    add column if not exists "Name" character varying(120) not null default 'Skin care routine',
    add column if not exists "IsCustom" boolean not null default false,
    add column if not exists "Source" character varying(20) not null default 'ai',
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_user_regimens_source') then
        alter table public.user_regimens
            add constraint ck_user_regimens_source
            check ("Source" in ('ai', 'user', 'expert', 'system'));
    end if;
end $$;

-- regimen_items
alter table if exists public.regimen_items
    add column if not exists "Instruction" text null,
    add column if not exists "Frequency" character varying(50) null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_regimen_items_routine_time') then
        alter table public.regimen_items
            add constraint ck_regimen_items_routine_time
            check ("RoutineTime" in ('Morning', 'Evening'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_regimen_items_step_order') then
        alter table public.regimen_items
            add constraint ck_regimen_items_step_order
            check ("StepOrder" > 0);
    end if;
end $$;

create unique index if not exists "IX_regimen_items_RegimenId_RoutineTime_StepOrder"
    on public.regimen_items ("RegimenId", "RoutineTime", "StepOrder");

-- reminders
create table if not exists public.reminders (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "Time" time without time zone not null,
    "RoutineType" character varying(20) not null,
    "Frequency" character varying(30) not null default 'daily',
    "Reason" text null,
    "Priority" character varying(20) not null default 'medium',
    "IsAdaptive" boolean not null default false,
    "IsEnabled" boolean not null default true,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now()),
    "UpdatedAt" timestamp with time zone null
);

alter table if exists public.reminders
    add column if not exists "Frequency" character varying(30) not null default 'daily',
    add column if not exists "Reason" text null,
    add column if not exists "Priority" character varying(20) not null default 'medium',
    add column if not exists "IsAdaptive" boolean not null default false,
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_reminders_routine_type') then
        alter table public.reminders
            add constraint ck_reminders_routine_type
            check ("RoutineType" in ('Morning', 'Evening'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_reminders_priority') then
        alter table public.reminders
            add constraint ck_reminders_priority
            check ("Priority" in ('low', 'medium', 'high'));
    end if;
end $$;

create unique index if not exists "IX_reminders_UserId_RoutineType"
    on public.reminders ("UserId", "RoutineType");

-- routine_trackings
create table if not exists public.routine_trackings (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "StepId" uuid not null references public.regimen_items("Id") on delete restrict,
    "Status" character varying(20) not null default 'completed',
    "Note" text null,
    "CompletedAt" timestamp with time zone not null default timezone('utc', now())
);

alter table if exists public.routine_trackings
    add column if not exists "Note" text null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_routine_trackings_status') then
        alter table public.routine_trackings
            add constraint ck_routine_trackings_status
            check ("Status" in ('completed', 'skipped', 'missed'));
    end if;
end $$;

create index if not exists "IX_routine_trackings_UserId_CompletedAt"
    on public.routine_trackings ("UserId", "CompletedAt" desc);
create index if not exists "IX_routine_trackings_UserId_StepId_CompletedAt"
    on public.routine_trackings ("UserId", "StepId", "CompletedAt" desc);

-- daily_logs
alter table if exists public.daily_logs
    add column if not exists "IsIrritated" boolean not null default false,
    add column if not exists "Notes" text null,
    add column if not exists "DailyImageUrl" character varying(500) null,
    add column if not exists "UpdatedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_daily_logs_skin_feeling') then
        alter table public.daily_logs
            add constraint ck_daily_logs_skin_feeling
            check ("SkinFeeling" is null or "SkinFeeling" in ('good', 'normal', 'dry', 'oily', 'irritated', 'acne_flare', 'sensitive'));
    end if;
end $$;

create unique index if not exists "IX_daily_logs_UserId_Date"
    on public.daily_logs ("UserId", "Date" desc);

-- ai_chat_conversations
create table if not exists public.ai_chat_conversations (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "Title" character varying(120) not null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now()),
    "UpdatedAt" timestamp with time zone not null default timezone('utc', now()),
    "LastMessageAt" timestamp with time zone not null default timezone('utc', now())
);

create index if not exists "IX_ai_chat_conversations_UserId_LastMessageAt"
    on public.ai_chat_conversations ("UserId", "LastMessageAt" desc);

-- ai_chat_messages
create table if not exists public.ai_chat_messages (
    "Id" uuid primary key,
    "ConversationId" uuid not null references public.ai_chat_conversations("Id") on delete cascade,
    "Role" character varying(20) not null,
    "Content" text not null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_ai_chat_messages_role') then
        alter table public.ai_chat_messages
            add constraint ck_ai_chat_messages_role
            check ("Role" in ('user', 'assistant', 'system'));
    end if;
end $$;

create index if not exists "IX_ai_chat_messages_ConversationId_CreatedAt"
    on public.ai_chat_messages ("ConversationId", "CreatedAt");

-- skin progress base tables
create table if not exists public.skin_progress_photos (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "ImageUrl" character varying(500) not null,
    "ThumbnailUrl" character varying(500) null,
    "Source" character varying(30) not null default 'unknown',
    "ImageMetadataJson" jsonb null,
    "PhotoDate" date not null,
    "TimeOfDay" character varying(20) not null default 'unknown',
    "LightingCondition" character varying(20) not null default 'unknown',
    "FaceAngle" character varying(20) not null default 'unknown',
    "Note" text null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

alter table if exists public.skin_progress_photos
    add column if not exists "Source" character varying(30) not null default 'unknown',
    add column if not exists "ImageMetadataJson" jsonb null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_photos_time_of_day') then
        alter table public.skin_progress_photos
            add constraint ck_skin_progress_photos_time_of_day
            check ("TimeOfDay" in ('morning', 'afternoon', 'night', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_photos_lighting_condition') then
        alter table public.skin_progress_photos
            add constraint ck_skin_progress_photos_lighting_condition
            check ("LightingCondition" in ('good', 'medium', 'poor', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_photos_face_angle') then
        alter table public.skin_progress_photos
            add constraint ck_skin_progress_photos_face_angle
            check ("FaceAngle" in ('front', 'left', 'right', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_photos_source') then
        alter table public.skin_progress_photos
            add constraint ck_skin_progress_photos_source
            check ("Source" in ('dashboard', 'ai_hub', 'progress', 'onboarding', 'unknown'));
    end if;
end $$;

create index if not exists "IX_skin_progress_photos_UserId_PhotoDate"
    on public.skin_progress_photos ("UserId", "PhotoDate" desc);

create table if not exists public.skin_progress_analyses (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "PhotoId" uuid not null references public.skin_progress_photos("Id") on delete cascade,
    "Status" character varying(20) not null default 'completed',
    "AiModel" character varying(100) null,
    "SkinTypeEstimate" character varying(30) not null default 'unknown',
    "HydrationLevel" character varying(20) not null default 'unknown',
    "OilinessLevel" character varying(20) not null default 'unknown',
    "AcneScore" integer not null,
    "RednessScore" integer not null,
    "DarkSpotScore" integer not null,
    "OilinessScore" integer not null,
    "DrynessScore" integer not null,
    "TextureScore" integer not null,
    "SensitivityScore" integer not null,
    "OverallScore" integer not null,
    "ConfidenceScore" numeric(5,4) null,
    "DetectedConcerns" jsonb not null,
    "AiSummary" text not null,
    "Recommendations" jsonb not null,
    "RoutineSuggestions" jsonb not null default '{}'::jsonb,
    "ProductSuggestions" jsonb not null default '[]'::jsonb,
    "SafetyNotes" jsonb not null default '[]'::jsonb,
    "RiskFlags" jsonb not null,
    "RawAiResponse" jsonb null,
    "ParsedAiResponse" jsonb null,
    "ErrorMessage" text null,
    "CompletedAt" timestamp with time zone null,
    "DiscardedAt" timestamp with time zone null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

alter table if exists public.skin_progress_analyses
    add column if not exists "Status" character varying(20) not null default 'completed',
    add column if not exists "AiModel" character varying(100) null,
    add column if not exists "ConfidenceScore" numeric(5,4) null,
    add column if not exists "RoutineSuggestions" jsonb not null default '{}'::jsonb,
    add column if not exists "ProductSuggestions" jsonb not null default '[]'::jsonb,
    add column if not exists "SafetyNotes" jsonb not null default '[]'::jsonb,
    add column if not exists "ParsedAiResponse" jsonb null,
    add column if not exists "ErrorMessage" text null,
    add column if not exists "CompletedAt" timestamp with time zone null,
    add column if not exists "DiscardedAt" timestamp with time zone null;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_status') then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_status
            check ("Status" in ('pending', 'processing', 'completed', 'failed', 'discarded'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_skin_type') then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_skin_type
            check ("SkinTypeEstimate" in ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_hydration') then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_hydration
            check ("HydrationLevel" in ('low', 'balanced', 'high', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_oiliness') then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_oiliness
            check ("OilinessLevel" in ('low', 'medium', 'high', 'only_t_zone', 'unknown'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_acne_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_acne_score check ("AcneScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_redness_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_redness_score check ("RednessScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_dark_spot_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_dark_spot_score check ("DarkSpotScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_oiliness_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_oiliness_score check ("OilinessScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_dryness_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_dryness_score check ("DrynessScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_texture_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_texture_score check ("TextureScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_sensitivity_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_sensitivity_score check ("SensitivityScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_overall_score') then
        alter table public.skin_progress_analyses add constraint ck_skin_progress_analyses_overall_score check ("OverallScore" between 0 and 100);
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_analyses_confidence_score') then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_confidence_score
            check ("ConfidenceScore" is null or "ConfidenceScore" between 0 and 1);
    end if;
end $$;

create unique index if not exists "IX_skin_progress_analyses_PhotoId"
    on public.skin_progress_analyses ("PhotoId");
create index if not exists "IX_skin_progress_analyses_UserId_CreatedAt"
    on public.skin_progress_analyses ("UserId", "CreatedAt" desc);
create index if not exists "IX_skin_progress_analyses_Status"
    on public.skin_progress_analyses ("Status");

create table if not exists public.skin_photo_comparisons (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "BeforePhotoId" uuid not null references public.skin_progress_photos("Id") on delete restrict,
    "AfterPhotoId" uuid not null references public.skin_progress_photos("Id") on delete restrict,
    "BeforeAnalysisId" uuid not null references public.skin_progress_analyses("Id") on delete restrict,
    "AfterAnalysisId" uuid not null references public.skin_progress_analyses("Id") on delete restrict,
    "ProgressStatus" character varying(30) not null default 'insufficient_data',
    "ComparisonSummary" text not null,
    "Improvements" jsonb not null,
    "WorsenedAreas" jsonb not null,
    "StableAreas" jsonb not null,
    "ScoreChanges" jsonb not null,
    "Recommendations" jsonb not null,
    "ConfidenceNote" text null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_photo_comparisons_progress_status') then
        alter table public.skin_photo_comparisons
            add constraint ck_skin_photo_comparisons_progress_status
            check ("ProgressStatus" in ('improved', 'stable', 'worse', 'mixed', 'insufficient_data'));
    end if;
end $$;

create unique index if not exists "IX_skin_photo_comparisons_BeforePhotoId_AfterPhotoId"
    on public.skin_photo_comparisons ("BeforePhotoId", "AfterPhotoId");
create index if not exists "IX_skin_photo_comparisons_AfterAnalysisId"
    on public.skin_photo_comparisons ("AfterAnalysisId");
create index if not exists "IX_skin_photo_comparisons_BeforeAnalysisId"
    on public.skin_photo_comparisons ("BeforeAnalysisId");
create index if not exists "IX_skin_photo_comparisons_AfterPhotoId"
    on public.skin_photo_comparisons ("AfterPhotoId");
create index if not exists "IX_skin_photo_comparisons_UserId_CreatedAt"
    on public.skin_photo_comparisons ("UserId", "CreatedAt" desc);

create table if not exists public.skin_progress_reports (
    "Id" uuid primary key,
    "UserId" uuid not null references public.users("Id") on delete cascade,
    "PeriodType" character varying(20) not null default 'monthly',
    "PeriodStart" date not null,
    "PeriodEnd" date not null,
    "ProgressStatus" character varying(30) not null default 'insufficient_data',
    "Summary" text not null,
    "ScoreChanges" jsonb not null,
    "MainFindings" jsonb not null,
    "RoutineFeedback" text null,
    "NextSuggestions" jsonb not null,
    "RawAiResponse" jsonb null,
    "CreatedAt" timestamp with time zone not null default timezone('utc', now())
);

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_reports_period_type') then
        alter table public.skin_progress_reports
            add constraint ck_skin_progress_reports_period_type
            check ("PeriodType" in ('weekly', 'monthly', 'yearly'));
    end if;
    if not exists (select 1 from pg_constraint where conname = 'ck_skin_progress_reports_progress_status') then
        alter table public.skin_progress_reports
            add constraint ck_skin_progress_reports_progress_status
            check ("ProgressStatus" in ('improved', 'stable', 'worse', 'mixed', 'insufficient_data'));
    end if;
end $$;

create unique index if not exists "IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodEnd"
    on public.skin_progress_reports ("UserId", "PeriodType", "PeriodStart", "PeriodEnd");
create index if not exists "IX_skin_progress_reports_UserId_CreatedAt"
    on public.skin_progress_reports ("UserId", "CreatedAt" desc);

commit;
