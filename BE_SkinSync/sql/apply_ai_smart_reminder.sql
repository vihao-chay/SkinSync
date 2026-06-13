ALTER TABLE reminders
    ADD COLUMN IF NOT EXISTS "Frequency" character varying(30) NOT NULL DEFAULT 'daily',
    ADD COLUMN IF NOT EXISTS "IsAdaptive" boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS "Priority" character varying(20) NOT NULL DEFAULT 'medium',
    ADD COLUMN IF NOT EXISTS "Reason" text NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'ck_reminders_priority'
    ) THEN
        ALTER TABLE reminders
            ADD CONSTRAINT ck_reminders_priority
            CHECK ("Priority" IN ('low', 'medium', 'high'));
    END IF;
END $$;

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
        'conflict_check',
        'smart_reminder'
    ));
