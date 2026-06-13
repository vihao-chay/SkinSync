begin;

-- =========================================================
-- SkinSync schema normalization pass 2
-- Safe rerun for Supabase / PostgreSQL
-- =========================================================

-- 1. Canonical lowercase routine values across regimen/reminder/tracking.
update public.regimen_items
set "RoutineTime" = lower(trim("RoutineTime"))
where "RoutineTime" is not null
  and lower(trim("RoutineTime")) in ('morning', 'evening')
  and "RoutineTime" <> lower(trim("RoutineTime"));

update public.reminders
set "RoutineType" = lower(trim("RoutineType"))
where "RoutineType" is not null
  and lower(trim("RoutineType")) in ('morning', 'evening')
  and "RoutineType" <> lower(trim("RoutineType"));

update public.routine_trackings
set "RoutineTime" = lower(trim("RoutineTime"))
where "RoutineTime" is not null
  and lower(trim("RoutineTime")) in ('morning', 'evening')
  and "RoutineTime" <> lower(trim("RoutineTime"));

alter table public.regimen_items
    alter column "RoutineTime" set default 'morning';

alter table public.reminders
    alter column "RoutineType" set default 'morning';

alter table public.routine_trackings
    alter column "RoutineTime" set default 'morning';

alter table public.regimen_items
    drop constraint if exists ck_regimen_items_routine_time;

alter table public.reminders
    drop constraint if exists ck_reminders_routine_type;

alter table public.routine_trackings
    drop constraint if exists ck_routine_trackings_routine_time;

alter table public.regimen_items
    add constraint ck_regimen_items_routine_time
    check ("RoutineTime" in ('morning', 'evening'));

alter table public.reminders
    add constraint ck_reminders_routine_type
    check ("RoutineType" in ('morning', 'evening'));

alter table public.routine_trackings
    add constraint ck_routine_trackings_routine_time
    check ("RoutineTime" in ('morning', 'evening'));

-- 2. Routine tracking timestamps and indexes.
alter table public.routine_trackings
    add column if not exists "CreatedAt" timestamp with time zone not null default timezone('utc', now()),
    add column if not exists "UpdatedAt" timestamp with time zone null;

update public.routine_trackings
set "CreatedAt" = coalesce("CreatedAt", "CompletedAt", timezone('utc', now()))
where "CreatedAt" is null;

alter table public.routine_trackings
    alter column "CreatedAt" set default timezone('utc', now()),
    alter column "CreatedAt" set not null;

drop index if exists "IX_routine_trackings_UserId_TrackingDate";
drop index if exists "IX_routine_trackings_UserId_RoutineTime_TrackingDate";
drop index if exists "IX_routine_trackings_UserId_StepId_TrackingDate";

create index if not exists "IX_routine_trackings_UserId_TrackingDate"
    on public.routine_trackings ("UserId", "TrackingDate" desc);

create index if not exists "IX_routine_trackings_UserId_RoutineTime_TrackingDate"
    on public.routine_trackings ("UserId", "RoutineTime", "TrackingDate" desc);

create unique index if not exists "IX_routine_trackings_UserId_StepId_TrackingDate"
    on public.routine_trackings ("UserId", "StepId", "TrackingDate");

-- 2b. Async-safe defaults for photo comparisons.
update public.skin_photo_comparisons
set "Improvements" = coalesce("Improvements", '[]'::jsonb),
    "WorsenedAreas" = coalesce("WorsenedAreas", '[]'::jsonb),
    "StableAreas" = coalesce("StableAreas", '[]'::jsonb),
    "ScoreChanges" = coalesce("ScoreChanges", '{}'::jsonb),
    "Recommendations" = coalesce("Recommendations", '[]'::jsonb);

alter table public.skin_photo_comparisons
    alter column "Improvements" set default '[]'::jsonb,
    alter column "WorsenedAreas" set default '[]'::jsonb,
    alter column "StableAreas" set default '[]'::jsonb,
    alter column "ScoreChanges" set default '{}'::jsonb,
    alter column "Recommendations" set default '[]'::jsonb;

-- 3. Structured daily log levels.
alter table public.daily_logs
    add column if not exists "AcneLevel" integer null,
    add column if not exists "DrynessLevel" integer null,
    add column if not exists "RednessLevel" integer null,
    add column if not exists "IrritationLevel" integer null,
    add column if not exists "HydrationLevel" integer null;

alter table public.daily_logs
    drop constraint if exists ck_daily_logs_acne_level,
    drop constraint if exists ck_daily_logs_dryness_level,
    drop constraint if exists ck_daily_logs_redness_level,
    drop constraint if exists ck_daily_logs_irritation_level,
    drop constraint if exists ck_daily_logs_hydration_level;

alter table public.daily_logs
    add constraint ck_daily_logs_acne_level
    check ("AcneLevel" is null or "AcneLevel" between 0 and 5);

alter table public.daily_logs
    add constraint ck_daily_logs_dryness_level
    check ("DrynessLevel" is null or "DrynessLevel" between 0 and 5);

alter table public.daily_logs
    add constraint ck_daily_logs_redness_level
    check ("RednessLevel" is null or "RednessLevel" between 0 and 5);

alter table public.daily_logs
    add constraint ck_daily_logs_irritation_level
    check ("IrritationLevel" is null or "IrritationLevel" between 0 and 5);

alter table public.daily_logs
    add constraint ck_daily_logs_hydration_level
    check ("HydrationLevel" is null or "HydrationLevel" between 0 and 5);

-- 4. Async-safe defaults for skin progress analyses.
update public.skin_progress_analyses
set "Status" = coalesce(nullif(trim("Status"), ''), 'pending');

update public.skin_progress_analyses
set "DetectedConcerns" = coalesce("DetectedConcerns", '[]'::jsonb),
    "Recommendations" = coalesce("Recommendations", '[]'::jsonb),
    "RoutineSuggestions" = coalesce("RoutineSuggestions", '{}'::jsonb),
    "ProductSuggestions" = coalesce("ProductSuggestions", '[]'::jsonb),
    "SafetyNotes" = coalesce("SafetyNotes", '[]'::jsonb),
    "RiskFlags" = coalesce("RiskFlags", '[]'::jsonb),
    "AiSummary" = coalesce("AiSummary", ''),
    "AcneScore" = coalesce("AcneScore", 0),
    "RednessScore" = coalesce("RednessScore", 0),
    "DarkSpotScore" = coalesce("DarkSpotScore", 0),
    "OilinessScore" = coalesce("OilinessScore", 0),
    "DrynessScore" = coalesce("DrynessScore", 0),
    "TextureScore" = coalesce("TextureScore", 0),
    "SensitivityScore" = coalesce("SensitivityScore", 0),
    "OverallScore" = coalesce("OverallScore", 0);

alter table public.skin_progress_analyses
    alter column "Status" set default 'pending',
    alter column "DetectedConcerns" set default '[]'::jsonb,
    alter column "Recommendations" set default '[]'::jsonb,
    alter column "RoutineSuggestions" set default '{}'::jsonb,
    alter column "ProductSuggestions" set default '[]'::jsonb,
    alter column "SafetyNotes" set default '[]'::jsonb,
    alter column "RiskFlags" set default '[]'::jsonb,
    alter column "AiSummary" set default '',
    alter column "AcneScore" set default 0,
    alter column "RednessScore" set default 0,
    alter column "DarkSpotScore" set default 0,
    alter column "OilinessScore" set default 0,
    alter column "DrynessScore" set default 0,
    alter column "TextureScore" set default 0,
    alter column "SensitivityScore" set default 0,
    alter column "OverallScore" set default 0;

alter table public.skin_progress_analyses
    drop constraint if exists ck_skin_progress_analyses_status;

alter table public.skin_progress_analyses
    add constraint ck_skin_progress_analyses_status
    check ("Status" in ('pending', 'processing', 'completed', 'failed', 'discarded'));

-- 5. Conditional report rules.
update public.skin_progress_reports
set "ScoreChanges" = coalesce("ScoreChanges", '{}'::jsonb),
    "MainFindings" = coalesce("MainFindings", '[]'::jsonb),
    "NextSuggestions" = coalesce("NextSuggestions", '[]'::jsonb);

alter table public.skin_progress_reports
    alter column "ScoreChanges" set default '{}'::jsonb,
    alter column "MainFindings" set default '[]'::jsonb,
    alter column "NextSuggestions" set default '[]'::jsonb;

alter table public.skin_progress_reports
    drop constraint if exists ck_skin_progress_reports_progress_timeline_period,
    drop constraint if exists ck_skin_progress_reports_after_analysis_related_analysis;

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_progress_timeline_period
    check (
        "ReportCategory" <> 'progress_timeline'
        or ("PeriodType" is not null and "PeriodStart" is not null and "PeriodEnd" is not null)
    );

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_after_analysis_related_analysis
    check (
        "ReportCategory" <> 'after_analysis'
        or "RelatedAnalysisId" is not null
    );

-- 6. Cleanup migration drift on ingredient_conflict_rules.
do $$
declare
    rec record;
begin
    if exists (
        select 1
        from pg_constraint
        where conname = 'FK_ingredient_conflict_rules_ingredients_ConflictingIngredientId'
    ) then
        alter table public.ingredient_conflict_rules
            drop constraint "FK_ingredient_conflict_rules_ingredients_ConflictingIngredientId";
    end if;

    if exists (
        select 1
        from pg_constraint
        where conname = 'FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId'
    ) then
        alter table public.ingredient_conflict_rules
            drop constraint "FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId";
    end if;

    for rec in
        select con.conname
        from pg_constraint con
        join pg_class rel on rel.oid = con.conrelid
        join pg_namespace nsp on nsp.oid = rel.relnamespace
        join unnest(con.conkey) with ordinality as cols(attnum, ordinality) on true
        join pg_attribute att on att.attrelid = rel.oid and att.attnum = cols.attnum
        where nsp.nspname = 'public'
          and rel.relname = 'ingredient_conflict_rules'
          and con.contype = 'f'
        group by con.conname
        having array_agg(att.attname order by cols.ordinality) = array['ConflictingIngredientId']
           and con.conname <> 'FK_ingredient_conflict_rules_ingredients_ConflictingIngredientId'
    loop
        execute format('alter table public.ingredient_conflict_rules drop constraint if exists %I', rec.conname);
    end loop;

    for rec in
        select con.conname
        from pg_constraint con
        join pg_class rel on rel.oid = con.conrelid
        join pg_namespace nsp on nsp.oid = rel.relnamespace
        join unnest(con.conkey) with ordinality as cols(attnum, ordinality) on true
        join pg_attribute att on att.attrelid = rel.oid and att.attnum = cols.attnum
        where nsp.nspname = 'public'
          and rel.relname = 'ingredient_conflict_rules'
          and con.contype = 'f'
        group by con.conname
        having array_agg(att.attname order by cols.ordinality) = array['PrimaryIngredientId']
           and con.conname <> 'FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId'
    loop
        execute format('alter table public.ingredient_conflict_rules drop constraint if exists %I', rec.conname);
    end loop;
end $$;

do $$
declare
    rec record;
begin
    for rec in
        select indexname
        from pg_indexes
        where schemaname = 'public'
          and tablename = 'ingredient_conflict_rules'
          and indexname <> 'IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIngredientId'
          and indexdef ilike '%unique index%'
          and indexdef ilike '%("PrimaryIngredientId", "ConflictingIngredientId")%'
    loop
        execute format('drop index if exists public.%I', rec.indexname);
    end loop;

    for rec in
        select indexname
        from pg_indexes
        where schemaname = 'public'
          and tablename = 'ingredient_conflict_rules'
          and indexname <> 'IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngredient'
          and indexdef ilike '%unique index%'
          and indexdef ilike '%("PrimaryIngredient", "ConflictingIngredient")%'
          and indexdef ilike '%where ("PrimaryIngredient" is not null) and ("ConflictingIngredient" is not null)%'
    loop
        execute format('drop index if exists public.%I', rec.indexname);
    end loop;
end $$;

create unique index if not exists "IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIngredientId"
    on public.ingredient_conflict_rules ("PrimaryIngredientId", "ConflictingIngredientId");

create unique index if not exists "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngredient"
    on public.ingredient_conflict_rules ("PrimaryIngredient", "ConflictingIngredient")
    where "PrimaryIngredient" is not null and "ConflictingIngredient" is not null;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId'
    ) then
        alter table public.ingredient_conflict_rules
            add constraint "FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId"
            foreign key ("PrimaryIngredientId")
            references public.ingredients("Id")
            on delete restrict;
    end if;

    if not exists (
        select 1
        from pg_constraint
        where conname = 'FK_ingredient_conflict_rules_ingredients_ConflictingIngredientId'
    ) then
        alter table public.ingredient_conflict_rules
            add constraint "FK_ingredient_conflict_rules_ingredients_ConflictingIngredientId"
            foreign key ("ConflictingIngredientId")
            references public.ingredients("Id")
            on delete restrict;
    end if;
end $$;

commit;
