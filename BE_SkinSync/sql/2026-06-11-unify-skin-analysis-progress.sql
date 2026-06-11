alter table if exists public.skin_progress_photos
    add column if not exists source text not null default 'unknown',
    add column if not exists image_metadata_json text null;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'ck_skin_progress_photos_source'
    ) then
        alter table public.skin_progress_photos
            add constraint ck_skin_progress_photos_source
            check (source in ('dashboard', 'ai_hub', 'progress', 'onboarding', 'unknown'));
    end if;
end $$;

alter table if exists public.skin_progress_analyses
    add column if not exists status text not null default 'completed',
    add column if not exists ai_model text null,
    add column if not exists confidence_score numeric(5,4) null,
    add column if not exists routine_suggestions text not null default '{}',
    add column if not exists product_suggestions text not null default '[]',
    add column if not exists safety_notes text not null default '[]',
    add column if not exists parsed_ai_response text null,
    add column if not exists error_message text null,
    add column if not exists completed_at timestamptz null,
    add column if not exists discarded_at timestamptz null;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'ck_skin_progress_analyses_status'
    ) then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_status
            check (status in ('pending', 'processing', 'completed', 'failed', 'discarded'));
    end if;
end $$;

do $$
begin
    if not exists (
        select 1
        from pg_constraint
        where conname = 'ck_skin_progress_analyses_confidence_score'
    ) then
        alter table public.skin_progress_analyses
            add constraint ck_skin_progress_analyses_confidence_score
            check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 1));
    end if;
end $$;

create index if not exists ix_skin_progress_analyses_status
    on public.skin_progress_analyses (status);
