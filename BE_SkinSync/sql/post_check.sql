\echo '=== SkinSync final schema post-check ==='

\echo ''
\echo '1. ingredient_conflict_rules indexes'
select
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
order by indexname;

\echo ''
\echo '2. ingredient_conflict_rules foreign keys'
select
    con.conname as constraint_name,
    pg_get_constraintdef(con.oid) as definition
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
join pg_namespace nsp on nsp.oid = rel.relnamespace
where nsp.nspname = 'public'
  and rel.relname = 'ingredient_conflict_rules'
  and con.contype = 'f'
order by con.conname;

\echo ''
\echo '3. Routine column defaults and check constraints'
select
    table_name,
    column_name,
    column_default,
    is_nullable
from information_schema.columns
where table_schema = 'public'
  and (
        (table_name = 'regimen_items' and column_name in ('RoutineTime', 'routine_time'))
     or (table_name = 'reminders' and column_name in ('RoutineType', 'routine_type'))
     or (table_name = 'routine_trackings' and column_name in ('RoutineTime', 'routine_time'))
  )
order by table_name, column_name;

select
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

\echo ''
\echo '4. daily_logs structured columns'
select
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'daily_logs'
  and column_name in ('AcneLevel', 'DrynessLevel', 'RednessLevel', 'IrritationLevel', 'HydrationLevel')
order by column_name;

\echo ''
\echo '5. routine_trackings timestamps and indexes'
select
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
from information_schema.columns
where table_schema = 'public'
  and table_name = 'routine_trackings'
  and column_name in ('CreatedAt', 'UpdatedAt', 'TrackingDate')
order by column_name;

select
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
  and tablename = 'routine_trackings'
order by indexname;

\echo ''
\echo '6. skin_progress_analyses defaults'
select
    column_name,
    column_default,
    is_nullable
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

\echo ''
\echo '7. skin_progress_reports defaults and report constraints'
select
    column_name,
    column_default,
    is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'skin_progress_reports'
  and column_name in (
      'ReportCategory',
      'Source',
      'PeriodType',
      'RelatedAnalysisId',
      'Summary',
      'ScoreChanges',
      'MainFindings',
      'NextSuggestions'
  )
order by column_name;

select
    tc.constraint_name,
    cc.check_clause
from information_schema.table_constraints tc
join information_schema.check_constraints cc
  on tc.constraint_name = cc.constraint_name
where tc.table_schema = 'public'
  and tc.table_name = 'skin_progress_reports'
  and tc.constraint_type = 'CHECK'
order by tc.constraint_name;

\echo ''
\echo '8. skin_photo_comparisons defaults'
select
    column_name,
    column_default,
    is_nullable
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

\echo ''
\echo '9. Quick duplicate index summary for ingredient_conflict_rules'
select
    case
        when count(*) = 1 then 'OK'
        else 'CHECK'
    end as status,
    count(*) as matching_indexes,
    'unique(PrimaryIngredientId, ConflictingIngredientId)' as target
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%unique index%'
  and indexdef ilike '%("PrimaryIngredientId", "ConflictingIngredientId")%'
union all
select
    case
        when count(*) = 1 then 'OK'
        else 'CHECK'
    end as status,
    count(*) as matching_indexes,
    'unique(PrimaryIngredient, ConflictingIngredient) filtered' as target
from pg_indexes
where schemaname = 'public'
  and tablename = 'ingredient_conflict_rules'
  and indexdef ilike '%unique index%'
  and indexdef ilike '%("PrimaryIngredient", "ConflictingIngredient")%'
  and indexdef ilike '%where ("PrimaryIngredient" is not null) and ("ConflictingIngredient" is not null)%';
