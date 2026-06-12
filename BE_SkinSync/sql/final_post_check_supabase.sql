-- =========================================================
-- SkinSync final schema post-check for Supabase SQL editor
-- Pure SQL only, no psql meta commands
-- =========================================================

-- 1. ingredient_conflict_rules indexes
select
    'ingredient_conflict_rules_indexes' as section,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
order by indexname;

-- 2. ingredient_conflict_rules foreign keys
select
    'ingredient_conflict_rules_fks' as section,
    con.conname as constraint_name,
    pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
join pg_namespace nsp on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'ingredient_conflict_rules'
  and con.contype = 'f'
order by con.conname;

-- 3. ingredient_conflict_rules final summary
select
    'ingredient_pk' as target,
    case when count(*) = 1 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%("Id")%'
  and indexdef ilike '%unique index%'
union all
select
    'ingredient_conflicting_id_index' as target,
    case when count(*) >= 1 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%("ConflictingIngredientId")%'
  and indexdef not ilike '%("PrimaryIngredientId", "ConflictingIngredientId")%'
union all
select
    'ingredient_id_pair_unique' as target,
    case when count(*) = 1 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%unique index%'
  and indexdef ilike '%("PrimaryIngredientId", "ConflictingIngredientId")%'
union all
select
    'ingredient_text_pair_unique_filtered' as target,
    case when count(*) = 1 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%unique index%'
  and indexdef ilike '%("PrimaryIngredient", "ConflictingIngredient")%'
  and indexdef ilike '%where ((\"PrimaryIngredient\" is not null) and (\"ConflictingIngredient\" is not null))%';

-- 4. routine columns defaults/nullability
select
    'routine_columns' as section,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and (
        (table_name = 'regimen_items' and column_name in ('RoutineTime', 'routine_time'))
     or (table_name = 'reminders' and column_name in ('RoutineType', 'routine_type'))
     or (table_name = 'routine_trackings' and column_name in ('RoutineTime', 'routine_time', 'TrackingDate', 'CreatedAt', 'UpdatedAt'))
  )
order by table_name, column_name;

-- 5. routine check constraints
select
    'routine_checks' as section,
    tc.table_name,
    tc.constraint_name,
    cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name
where tc.table_schema = 'public'
  and tc.table_name in ('regimen_items', 'reminders', 'routine_trackings')
  and tc.constraint_type = 'CHECK'
order by tc.table_name, tc.constraint_name;

-- 6. routine_trackings indexes
select
    'routine_trackings_indexes' as section,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'routine_trackings'
order by indexname;

-- 7. daily_logs structured level columns
select
    'daily_logs_columns' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'daily_logs'
  and column_name in ('AcneLevel', 'DrynessLevel', 'RednessLevel', 'IrritationLevel', 'HydrationLevel')
order by column_name;

-- 8. daily_logs level check constraints
select
    'daily_logs_checks' as section,
    tc.constraint_name,
    cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name
where tc.table_schema = 'public'
  and tc.table_name = 'daily_logs'
  and tc.constraint_type = 'CHECK'
order by tc.constraint_name;

-- 9. skin_progress_analyses defaults
select
    'skin_progress_analyses_defaults' as section,
    column_name,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_progress_analyses'
  and column_name in (
      'Status',
      'DetectedConcerns',
      'Recommendations',
      'RoutineSuggestions',
      'ProductSuggestions',
      'SafetyNotes',
      'RiskFlags',
      'AiSummary',
      'AcneScore',
      'RednessScore',
      'DarkSpotScore',
      'OilinessScore',
      'DrynessScore',
      'TextureScore',
      'SensitivityScore',
      'OverallScore'
  )
order by column_name;

-- 10. skin_progress_analyses status constraint
select
    'skin_progress_analyses_checks' as section,
    tc.constraint_name,
    cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name
where tc.table_schema = 'public'
  and tc.table_name = 'skin_progress_analyses'
  and tc.constraint_type = 'CHECK'
order by tc.constraint_name;

-- 11. skin_progress_reports defaults
select
    'skin_progress_reports_defaults' as section,
    column_name,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_progress_reports'
  and column_name in (
      'ReportCategory',
      'Source',
      'PeriodType',
      'PeriodStart',
      'PeriodEnd',
      'RelatedAnalysisId',
      'Summary',
      'ScoreChanges',
      'MainFindings',
      'NextSuggestions'
  )
order by column_name;

-- 12. skin_progress_reports checks
select
    'skin_progress_reports_checks' as section,
    tc.constraint_name,
    cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name
where tc.table_schema = 'public'
  and tc.table_name = 'skin_progress_reports'
  and tc.constraint_type = 'CHECK'
order by tc.constraint_name;

-- 13. skin_photo_comparisons defaults
select
    'skin_photo_comparisons_defaults' as section,
    column_name,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_photo_comparisons'
  and column_name in (
      'ComparisonSummary',
      'Improvements',
      'WorsenedAreas',
      'StableAreas',
      'ScoreChanges',
      'Recommendations'
  )
order by column_name;

-- 14. final quick summary
select
    'skin_progress_reports_json_defaults' as target,
    case when count(*) = 3 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_progress_reports'
  and (
        (column_name = 'ScoreChanges' and column_default ilike '%{}%')
     or (column_name = 'MainFindings' and column_default ilike '%[]%')
     or (column_name = 'NextSuggestions' and column_default ilike '%[]%')
  )
union all
select
    'skin_photo_comparisons_json_defaults' as target,
    case when count(*) = 5 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_photo_comparisons'
  and (
        (column_name = 'Improvements' and column_default ilike '%[]%')
     or (column_name = 'WorsenedAreas' and column_default ilike '%[]%')
     or (column_name = 'StableAreas' and column_default ilike '%[]%')
     or (column_name = 'ScoreChanges' and column_default ilike '%{}%')
     or (column_name = 'Recommendations' and column_default ilike '%[]%')
  )
union all
select
    'skin_progress_analyses_pending_default' as target,
    case when count(*) = 1 then 'OK' else 'CHECK' end as status,
    count(*) as matching_items
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_progress_analyses'
  and column_name = 'Status'
  and column_default ilike '%pending%';
