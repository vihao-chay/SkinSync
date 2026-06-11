begin;

-- =========================================================
-- SkinSync canonical skin progress schema
-- Safe rerun version for Supabase / Postgres
-- =========================================================

-- 0. Drop legacy foreign key/index state on user_regimens if present.
alter table public.user_regimens
    drop constraint if exists "FK_user_regimens_skin_progress_analyses_SourceAnalysisId";

do $$
declare
    fk_name text;
begin
    select tc.constraint_name
    into fk_name
    from information_schema.table_constraints tc
    join information_schema.key_column_usage kcu
      on tc.constraint_name = kcu.constraint_name
     and tc.table_schema = kcu.table_schema
    where tc.table_schema = 'public'
      and tc.table_name = 'user_regimens'
      and tc.constraint_type = 'FOREIGN KEY'
      and kcu.column_name in ('AnalysisId', 'SourceAnalysisId')
    limit 1;

    if fk_name is not null then
        execute format('alter table public.user_regimens drop constraint %I', fk_name);
    end if;
end $$;

drop index if exists "IX_user_regimens_AnalysisId";
drop index if exists "IX_user_regimens_SourceAnalysisId";

-- 1. Remove legacy tables if they still exist.
drop table if exists public.ai_analysis_issues cascade;
drop table if exists public.ai_recommendations cascade;
drop table if exists public.ai_analyses cascade;
drop table if exists public.ai_reports cascade;

-- 2. user_regimens -> SourceAnalysisId
alter table public.user_regimens
    add column if not exists "SourceAnalysisId" uuid null;

do $$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'user_regimens'
          and column_name = 'AnalysisId'
    ) then
        execute '
            update public.user_regimens ur
            set "SourceAnalysisId" = coalesce(ur."SourceAnalysisId", ur."AnalysisId")
            where ur."AnalysisId" is not null
              and exists (
                  select 1
                  from public.skin_progress_analyses spa
                  where spa."Id" = ur."AnalysisId"
              )
        ';
    end if;
end $$;

update public.user_regimens ur
set "SourceAnalysisId" = null
where ur."SourceAnalysisId" is not null
  and not exists (
      select 1
      from public.skin_progress_analyses spa
      where spa."Id" = ur."SourceAnalysisId"
  );

alter table public.user_regimens
    drop column if exists "AnalysisId";

create index if not exists "IX_user_regimens_SourceAnalysisId"
    on public.user_regimens ("SourceAnalysisId");

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'FK_user_regimens_skin_progress_analyses_SourceAnalysisId'
    ) then
        alter table public.user_regimens
            add constraint "FK_user_regimens_skin_progress_analyses_SourceAnalysisId"
            foreign key ("SourceAnalysisId")
            references public.skin_progress_analyses("Id")
            on delete set null;
    end if;
end $$;

-- 3. routine_trackings canonical contract
alter table public.routine_trackings
    add column if not exists "TrackingDate" date null,
    add column if not exists "RoutineTime" varchar(20) null;

update public.routine_trackings rt
set "TrackingDate" = coalesce(rt."TrackingDate", (rt."CompletedAt" at time zone 'utc')::date)
where rt."TrackingDate" is null;

update public.routine_trackings rt
set "RoutineTime" = coalesce(rt."RoutineTime", ri."RoutineTime")
from public.regimen_items ri
where rt."StepId" = ri."Id"
  and rt."RoutineTime" is null;

update public.routine_trackings
set "RoutineTime" = 'Morning'
where "RoutineTime" is null;

alter table public.routine_trackings
    alter column "TrackingDate" set not null,
    alter column "RoutineTime" set not null,
    alter column "CompletedAt" drop not null,
    alter column "CompletedAt" drop default;

alter table public.routine_trackings
    drop constraint if exists ck_routine_trackings_status,
    drop constraint if exists ck_routine_trackings_routine_time;

alter table public.routine_trackings
    add constraint ck_routine_trackings_status
    check ("Status" in ('completed', 'skipped', 'missed'));

alter table public.routine_trackings
    add constraint ck_routine_trackings_routine_time
    check ("RoutineTime" in ('Morning', 'Evening'));

drop index if exists "IX_routine_trackings_UserId_CompletedAt";
drop index if exists "IX_routine_trackings_UserId_StepId_CompletedAt";
drop index if exists "IX_routine_trackings_UserId_TrackingDate";
drop index if exists "IX_routine_trackings_UserId_RoutineTime_TrackingDate";
drop index if exists "IX_routine_trackings_UserId_StepId_TrackingDate";

delete from public.routine_trackings a
using public.routine_trackings b
where a.ctid < b.ctid
  and a."UserId" = b."UserId"
  and a."StepId" = b."StepId"
  and a."TrackingDate" = b."TrackingDate";

create index if not exists "IX_routine_trackings_UserId_TrackingDate"
    on public.routine_trackings ("UserId", "TrackingDate" desc);

create index if not exists "IX_routine_trackings_UserId_RoutineTime_TrackingDate"
    on public.routine_trackings ("UserId", "RoutineTime", "TrackingDate" desc);

create unique index if not exists "IX_routine_trackings_UserId_StepId_TrackingDate"
    on public.routine_trackings ("UserId", "StepId", "TrackingDate");

-- 4. skin_progress_reports unified report table
alter table public.skin_progress_reports
    add column if not exists "ReportCategory" varchar(30) null,
    add column if not exists "Source" varchar(30) null,
    add column if not exists "RelatedAnalysisId" uuid null,
    add column if not exists "ProductFeedback" text null;

update public.skin_progress_reports
set "ReportCategory" = coalesce("ReportCategory", 'progress_timeline'),
    "Source" = coalesce("Source", 'system');

alter table public.skin_progress_reports
    alter column "ReportCategory" set not null,
    alter column "Source" set not null,
    alter column "PeriodType" drop not null,
    alter column "PeriodStart" drop not null,
    alter column "PeriodEnd" drop not null;

alter table public.skin_progress_reports
    drop constraint if exists ck_skin_progress_reports_report_category,
    drop constraint if exists ck_skin_progress_reports_source,
    drop constraint if exists ck_skin_progress_reports_period_type,
    drop constraint if exists ck_skin_progress_reports_progress_status;

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_report_category
    check ("ReportCategory" in ('progress_timeline', 'after_analysis', 'routine_feedback', 'product_feedback', 'general_summary'));

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_source
    check ("Source" in ('dashboard', 'ai_hub', 'progress', 'onboarding', 'system'));

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_period_type
    check ("PeriodType" is null or "PeriodType" in ('weekly', 'monthly', 'yearly'));

alter table public.skin_progress_reports
    add constraint ck_skin_progress_reports_progress_status
    check ("ProgressStatus" in ('improved', 'stable', 'worse', 'mixed', 'insufficient_data'));

drop index if exists "IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodEnd";
drop index if exists "IX_skin_progress_reports_UserId_ReportCategory_PeriodType_PeriodStart_PeriodEnd_RelatedAnalysisId";

create index if not exists "IX_skin_progress_reports_UserId_CreatedAt"
    on public.skin_progress_reports ("UserId", "CreatedAt" desc);

create unique index if not exists "IX_skin_progress_reports_UserId_ReportCategory_PeriodType_PeriodStart_PeriodEnd_RelatedAnalysisId"
    on public.skin_progress_reports ("UserId", "ReportCategory", "PeriodType", "PeriodStart", "PeriodEnd", "RelatedAnalysisId");

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'FK_skin_progress_reports_skin_progress_analyses_RelatedAnalysisId'
    ) then
        alter table public.skin_progress_reports
            add constraint "FK_skin_progress_reports_skin_progress_analyses_RelatedAnalysisId"
            foreign key ("RelatedAnalysisId")
            references public.skin_progress_analyses("Id")
            on delete set null;
    end if;
end $$;

commit;
