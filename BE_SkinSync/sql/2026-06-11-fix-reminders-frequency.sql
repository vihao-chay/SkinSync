begin;

alter table if exists public.reminders
    add column if not exists "Frequency" character varying(30) not null default 'daily';

alter table if exists public.reminders
    add column if not exists "IsAdaptive" boolean not null default false;

alter table if exists public.reminders
    add column if not exists "Priority" character varying(20) not null default 'medium';

alter table if exists public.reminders
    add column if not exists "Reason" text null;

update public.reminders
set "Frequency" = 'daily'
where coalesce(trim("Frequency"), '') = '';

update public.reminders
set "Priority" = 'medium'
where coalesce(trim("Priority"), '') not in ('low', 'medium', 'high');

do $$
begin
    if exists (
        select 1
        from pg_constraint
        where conname = 'ck_reminders_priority'
    ) then
        alter table public.reminders
            drop constraint ck_reminders_priority;
    end if;

    alter table public.reminders
        add constraint ck_reminders_priority
        check ("Priority" in ('low', 'medium', 'high'));
end $$;

do $$
begin
    if exists (
        select 1
        from information_schema.tables
        where table_schema = 'public'
          and table_name = 'ai_usage_logs'
    ) then
        if exists (
            select 1
            from pg_constraint
            where conname = 'ck_ai_usage_logs_feature_name'
        ) then
            alter table public.ai_usage_logs
                drop constraint ck_ai_usage_logs_feature_name;
        end if;

        alter table public.ai_usage_logs
            add constraint ck_ai_usage_logs_feature_name
            check (
                "FeatureName" in (
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
                )
            );
    end if;
end $$;

insert into public."__EFMigrationsHistory" ("MigrationId", "ProductVersion")
select '20260611101500_AddAiSmartReminder', '8.0.13'
where exists (
    select 1
    from information_schema.tables
    where table_schema = 'public'
      and table_name = '__EFMigrationsHistory'
)
and not exists (
    select 1
    from public."__EFMigrationsHistory"
    where "MigrationId" = '20260611101500_AddAiSmartReminder'
);

commit;
