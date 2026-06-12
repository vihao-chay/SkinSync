using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscriptionPlansAndUserSubscriptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS ck_users_plan_type;
ALTER TABLE IF EXISTS skin_progress_reports DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_period_type;
ALTER TABLE IF EXISTS ai_usage_logs DROP CONSTRAINT IF EXISTS ck_ai_usage_logs_feature_name;
ALTER TABLE IF EXISTS subscription_plans DROP CONSTRAINT IF EXISTS ck_subscription_plans_billing_period;
ALTER TABLE IF EXISTS subscription_plans DROP CONSTRAINT IF EXISTS ck_subscription_plans_code;
ALTER TABLE IF EXISTS subscription_plans DROP CONSTRAINT IF EXISTS ck_subscription_plans_price;
ALTER TABLE IF EXISTS subscription_plan_features DROP CONSTRAINT IF EXISTS ck_subscription_plan_features_limit;
ALTER TABLE IF EXISTS user_subscriptions DROP CONSTRAINT IF EXISTS ck_user_subscriptions_status;

CREATE TABLE IF NOT EXISTS subscription_plans (
    "Id" uuid NOT NULL,
    "Code" character varying(20) NOT NULL,
    "Name" character varying(80) NOT NULL,
    "Description" character varying(500) NULL,
    "Price" numeric(12,2) NOT NULL DEFAULT 0,
    "Currency" character varying(10) NOT NULL DEFAULT 'VND',
    "BillingPeriod" character varying(20) NOT NULL DEFAULT 'monthly',
    "IsActive" boolean NOT NULL DEFAULT TRUE,
    "SortOrder" integer NOT NULL DEFAULT 0,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_subscription_plans" PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS subscription_plan_features (
    "Id" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "FeatureKey" character varying(80) NOT NULL,
    "DisplayName" character varying(120) NOT NULL,
    "MonthlyLimit" integer NULL,
    "IsEnabled" boolean NOT NULL DEFAULT TRUE,
    "Unit" character varying(40) NOT NULL DEFAULT 'usage',
    "AllowedValues" jsonb NOT NULL DEFAULT '[]'::jsonb,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_subscription_plan_features" PRIMARY KEY ("Id")
);

CREATE TABLE IF NOT EXISTS user_subscriptions (
    "Id" uuid NOT NULL,
    "UserId" uuid NOT NULL,
    "PlanId" uuid NOT NULL,
    "Status" character varying(20) NOT NULL DEFAULT 'active',
    "StartedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
    "EndsAt" timestamp with time zone NULL,
    "CancelledAt" timestamp with time zone NULL,
    "PricePaid" numeric(12,2) NOT NULL DEFAULT 0,
    "Currency" character varying(10) NOT NULL DEFAULT 'VND',
    "BillingPeriod" character varying(20) NOT NULL DEFAULT 'monthly',
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
    "UpdatedAt" timestamp with time zone NULL,
    CONSTRAINT "PK_user_subscriptions" PRIMARY KEY ("Id")
);

ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "Code" character varying(20);
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "Name" character varying(80);
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "Description" character varying(500);
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "Price" numeric(12,2) DEFAULT 0;
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "Currency" character varying(10) DEFAULT 'VND';
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "BillingPeriod" character varying(20) DEFAULT 'monthly';
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "IsActive" boolean DEFAULT TRUE;
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "SortOrder" integer DEFAULT 0;
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone DEFAULT timezone('utc', now());
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS "UpdatedAt" timestamp with time zone;

UPDATE subscription_plans
SET
    "Code" = lower(COALESCE(NULLIF("Code", ''), 'free')),
    "Name" = COALESCE(NULLIF("Name", ''), "Code", 'Free'),
    "Price" = COALESCE("Price", 0),
    "Currency" = COALESCE(NULLIF("Currency", ''), 'VND'),
    "BillingPeriod" = lower(trim(COALESCE(NULLIF("BillingPeriod", ''), 'monthly'))),
    "IsActive" = COALESCE("IsActive", TRUE),
    "SortOrder" = COALESCE("SortOrder", 0),
    "CreatedAt" = COALESCE("CreatedAt", timezone('utc', now()));

UPDATE subscription_plans
SET "BillingPeriod" = 'monthly'
WHERE "BillingPeriod" IS NULL OR "BillingPeriod" <> 'monthly';

ALTER TABLE subscription_plans ALTER COLUMN "Code" TYPE character varying(20);
ALTER TABLE subscription_plans ALTER COLUMN "Code" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "Name" TYPE character varying(80);
ALTER TABLE subscription_plans ALTER COLUMN "Name" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "Description" TYPE character varying(500);
ALTER TABLE subscription_plans ALTER COLUMN "Price" TYPE numeric(12,2);
ALTER TABLE subscription_plans ALTER COLUMN "Price" SET DEFAULT 0;
ALTER TABLE subscription_plans ALTER COLUMN "Price" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "Currency" TYPE character varying(10);
ALTER TABLE subscription_plans ALTER COLUMN "Currency" SET DEFAULT 'VND';
ALTER TABLE subscription_plans ALTER COLUMN "Currency" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "BillingPeriod" TYPE character varying(20);
ALTER TABLE subscription_plans ALTER COLUMN "BillingPeriod" SET DEFAULT 'monthly';
ALTER TABLE subscription_plans ALTER COLUMN "BillingPeriod" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "IsActive" SET DEFAULT TRUE;
ALTER TABLE subscription_plans ALTER COLUMN "IsActive" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "SortOrder" SET DEFAULT 0;
ALTER TABLE subscription_plans ALTER COLUMN "SortOrder" SET NOT NULL;
ALTER TABLE subscription_plans ALTER COLUMN "CreatedAt" SET DEFAULT timezone('utc', now());
ALTER TABLE subscription_plans ALTER COLUMN "CreatedAt" SET NOT NULL;

ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "PlanId" uuid;
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "FeatureKey" character varying(80);
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "DisplayName" character varying(120);
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "MonthlyLimit" integer;
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "IsEnabled" boolean DEFAULT TRUE;
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "Unit" character varying(40) DEFAULT 'usage';
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "AllowedValues" jsonb DEFAULT '[]'::jsonb;
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone DEFAULT timezone('utc', now());
ALTER TABLE subscription_plan_features ADD COLUMN IF NOT EXISTS "UpdatedAt" timestamp with time zone;

UPDATE subscription_plan_features
SET
    "FeatureKey" = lower(COALESCE(NULLIF("FeatureKey", ''), 'unknown')),
    "DisplayName" = COALESCE(NULLIF("DisplayName", ''), "FeatureKey", 'Feature'),
    "IsEnabled" = COALESCE("IsEnabled", TRUE),
    "Unit" = COALESCE(NULLIF("Unit", ''), 'usage'),
    "AllowedValues" = COALESCE("AllowedValues", '[]'::jsonb),
    "CreatedAt" = COALESCE("CreatedAt", timezone('utc', now()));

ALTER TABLE subscription_plan_features ALTER COLUMN "PlanId" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "FeatureKey" TYPE character varying(80);
ALTER TABLE subscription_plan_features ALTER COLUMN "FeatureKey" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "DisplayName" TYPE character varying(120);
ALTER TABLE subscription_plan_features ALTER COLUMN "DisplayName" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "IsEnabled" SET DEFAULT TRUE;
ALTER TABLE subscription_plan_features ALTER COLUMN "IsEnabled" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "Unit" TYPE character varying(40);
ALTER TABLE subscription_plan_features ALTER COLUMN "Unit" SET DEFAULT 'usage';
ALTER TABLE subscription_plan_features ALTER COLUMN "Unit" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "AllowedValues" SET DEFAULT '[]'::jsonb;
ALTER TABLE subscription_plan_features ALTER COLUMN "AllowedValues" SET NOT NULL;
ALTER TABLE subscription_plan_features ALTER COLUMN "CreatedAt" SET DEFAULT timezone('utc', now());
ALTER TABLE subscription_plan_features ALTER COLUMN "CreatedAt" SET NOT NULL;

ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "UserId" uuid;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "PlanId" uuid;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "Status" character varying(20) DEFAULT 'active';
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "StartedAt" timestamp with time zone DEFAULT timezone('utc', now());
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "EndsAt" timestamp with time zone;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "CancelledAt" timestamp with time zone;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "PricePaid" numeric(12,2) DEFAULT 0;
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "Currency" character varying(10) DEFAULT 'VND';
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "BillingPeriod" character varying(20) DEFAULT 'monthly';
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone DEFAULT timezone('utc', now());
ALTER TABLE user_subscriptions ADD COLUMN IF NOT EXISTS "UpdatedAt" timestamp with time zone;

UPDATE user_subscriptions
SET
    "Status" = CASE WHEN lower(COALESCE("Status", 'active')) = 'cancelled' THEN 'canceled' ELSE lower(COALESCE(NULLIF("Status", ''), 'active')) END,
    "StartedAt" = COALESCE("StartedAt", timezone('utc', now())),
    "PricePaid" = COALESCE("PricePaid", 0),
    "Currency" = COALESCE(NULLIF("Currency", ''), 'VND'),
    "BillingPeriod" = COALESCE(NULLIF("BillingPeriod", ''), 'monthly'),
    "CreatedAt" = COALESCE("CreatedAt", timezone('utc', now()));

UPDATE user_subscriptions
SET "Status" = 'active'
WHERE "Status" IS NULL OR "Status" NOT IN ('active', 'canceled', 'expired');

ALTER TABLE user_subscriptions ALTER COLUMN "UserId" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "PlanId" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "Status" TYPE character varying(20);
ALTER TABLE user_subscriptions ALTER COLUMN "Status" SET DEFAULT 'active';
ALTER TABLE user_subscriptions ALTER COLUMN "Status" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "StartedAt" SET DEFAULT timezone('utc', now());
ALTER TABLE user_subscriptions ALTER COLUMN "StartedAt" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "PricePaid" TYPE numeric(12,2);
ALTER TABLE user_subscriptions ALTER COLUMN "PricePaid" SET DEFAULT 0;
ALTER TABLE user_subscriptions ALTER COLUMN "PricePaid" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "Currency" TYPE character varying(10);
ALTER TABLE user_subscriptions ALTER COLUMN "Currency" SET DEFAULT 'VND';
ALTER TABLE user_subscriptions ALTER COLUMN "Currency" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "BillingPeriod" TYPE character varying(20);
ALTER TABLE user_subscriptions ALTER COLUMN "BillingPeriod" SET DEFAULT 'monthly';
ALTER TABLE user_subscriptions ALTER COLUMN "BillingPeriod" SET NOT NULL;
ALTER TABLE user_subscriptions ALTER COLUMN "CreatedAt" SET DEFAULT timezone('utc', now());
ALTER TABLE user_subscriptions ALTER COLUMN "CreatedAt" SET NOT NULL;

UPDATE users
SET "PlanType" = lower("PlanType")
WHERE "PlanType" IS NOT NULL AND lower("PlanType") IN ('free', 'plus', 'premium');

UPDATE users
SET "PlanType" = 'free'
WHERE "PlanType" IS NULL OR lower("PlanType") NOT IN ('free', 'plus', 'premium');

UPDATE skin_progress_reports
SET "PeriodType" = lower("PeriodType")
WHERE "PeriodType" IS NOT NULL AND lower("PeriodType") IN ('weekly', 'monthly', 'yearly', 'custom');

UPDATE skin_progress_reports
SET "PeriodType" = 'custom'
WHERE "PeriodType" IS NOT NULL AND lower("PeriodType") NOT IN ('weekly', 'monthly', 'yearly', 'custom');

UPDATE ai_usage_logs
SET "FeatureName" = lower("FeatureName")
WHERE "FeatureName" IS NOT NULL;

UPDATE ai_usage_logs
SET "FeatureName" = 'ai_chat'
WHERE "FeatureName" IS NULL OR "FeatureName" NOT IN (
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
    'smart_reminder',
    'progress_entry'
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_subscription_plans_Code"
ON subscription_plans ("Code");

CREATE UNIQUE INDEX IF NOT EXISTS "IX_subscription_plan_features_PlanId_FeatureKey"
ON subscription_plan_features ("PlanId", "FeatureKey");

CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_PlanId"
ON user_subscriptions ("PlanId");

CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_UserId_StartedAt"
ON user_subscriptions ("UserId", "StartedAt" DESC);

CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_UserId_Status"
ON user_subscriptions ("UserId", "Status");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_subscription_plan_features_subscription_plans_PlanId'
          AND conrelid = 'subscription_plan_features'::regclass
    ) THEN
        ALTER TABLE subscription_plan_features
        ADD CONSTRAINT "FK_subscription_plan_features_subscription_plans_PlanId"
        FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE CASCADE NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_user_subscriptions_subscription_plans_PlanId'
          AND conrelid = 'user_subscriptions'::regclass
    ) THEN
        ALTER TABLE user_subscriptions
        ADD CONSTRAINT "FK_user_subscriptions_subscription_plans_PlanId"
        FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE RESTRICT NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'FK_user_subscriptions_users_UserId'
          AND conrelid = 'user_subscriptions'::regclass
    ) THEN
        ALTER TABLE user_subscriptions
        ADD CONSTRAINT "FK_user_subscriptions_users_UserId"
        FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE NOT VALID;
    END IF;
END $$;

ALTER TABLE users
ADD CONSTRAINT ck_users_plan_type
CHECK ("PlanType" IN ('free', 'plus', 'premium'));

ALTER TABLE skin_progress_reports
ADD CONSTRAINT ck_skin_progress_reports_period_type
CHECK ("PeriodType" IS NULL OR "PeriodType" IN ('weekly', 'monthly', 'yearly', 'custom'));

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
    'smart_reminder',
    'progress_entry'
));

ALTER TABLE subscription_plans
ADD CONSTRAINT ck_subscription_plans_code
CHECK ("Code" IN ('free', 'plus', 'premium'));

ALTER TABLE subscription_plans
ADD CONSTRAINT ck_subscription_plans_price
CHECK ("Price" >= 0);

ALTER TABLE subscription_plans
ADD CONSTRAINT ck_subscription_plans_billing_period
CHECK ("BillingPeriod" IN ('monthly'));

ALTER TABLE subscription_plan_features
ADD CONSTRAINT ck_subscription_plan_features_limit
CHECK ("MonthlyLimit" IS NULL OR "MonthlyLimit" >= 0);

ALTER TABLE user_subscriptions
ADD CONSTRAINT ck_user_subscriptions_status
CHECK ("Status" IN ('active', 'canceled', 'expired'));

INSERT INTO subscription_plans (
    "Id", "Code", "Name", "Description", "Price", "Currency", "BillingPeriod", "IsActive", "SortOrder", "CreatedAt"
)
VALUES
    ('10000000-0000-0000-0000-000000000001', 'free', 'Free', 'Starter plan for light monthly usage.', 0, 'VND', 'monthly', TRUE, 1, timezone('utc', now())),
    ('10000000-0000-0000-0000-000000000002', 'plus', 'Plus', 'Expanded monthly quota with weekly progress reporting.', 49000, 'VND', 'monthly', TRUE, 2, timezone('utc', now())),
    ('10000000-0000-0000-0000-000000000003', 'premium', 'Premium', 'Highest monthly quota with advanced reports and PDF export.', 99000, 'VND', 'monthly', TRUE, 3, timezone('utc', now()))
ON CONFLICT ("Code") DO UPDATE
SET
    "Name" = EXCLUDED."Name",
    "Description" = EXCLUDED."Description",
    "Price" = EXCLUDED."Price",
    "Currency" = EXCLUDED."Currency",
    "BillingPeriod" = EXCLUDED."BillingPeriod",
    "IsActive" = EXCLUDED."IsActive",
    "SortOrder" = EXCLUDED."SortOrder",
    "UpdatedAt" = timezone('utc', now());

WITH feature_seed (
    "Id",
    "PlanCode",
    "FeatureKey",
    "DisplayName",
    "MonthlyLimit",
    "IsEnabled",
    "Unit",
    "AllowedValues"
) AS (
    VALUES
    ('20000000-0000-0000-0000-000000000001'::uuid, 'free', 'skin_analysis', 'Skin Analysis', 1, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000002'::uuid, 'free', 'ai_chat', 'AI Chat', 20, TRUE, 'message', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000003'::uuid, 'free', 'routine_generation', 'Routine Generator', 1, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000004'::uuid, 'free', 'ingredient_check', 'Ingredient Check', 3, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000005'::uuid, 'free', 'conflict_check', 'Conflict Check', 3, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000006'::uuid, 'free', 'progress_entry', 'Progress Entries', 3, TRUE, 'entry', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000007'::uuid, 'free', 'skin_progress_compare', 'Before/After Compare', 0, FALSE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000008'::uuid, 'free', 'report_weekly', 'Weekly Report', 0, FALSE, 'report', '["weekly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000009'::uuid, 'free', 'report_monthly', 'Monthly Report', 0, FALSE, 'report', '["monthly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000010'::uuid, 'free', 'report_custom', 'Custom Report', 0, FALSE, 'report', '["custom"]'::jsonb),
    ('20000000-0000-0000-0000-000000000011'::uuid, 'free', 'export_pdf', 'Export PDF', 0, FALSE, 'export', '[]'::jsonb),

    ('20000000-0000-0000-0000-000000000012'::uuid, 'plus', 'skin_analysis', 'Skin Analysis', 4, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000013'::uuid, 'plus', 'ai_chat', 'AI Chat', 150, TRUE, 'message', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000014'::uuid, 'plus', 'routine_generation', 'Routine Generator', 4, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000015'::uuid, 'plus', 'ingredient_check', 'Ingredient Check', 20, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000016'::uuid, 'plus', 'conflict_check', 'Conflict Check', 20, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000017'::uuid, 'plus', 'progress_entry', 'Progress Entries', 50, TRUE, 'entry', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000018'::uuid, 'plus', 'skin_progress_compare', 'Before/After Compare', 5, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000019'::uuid, 'plus', 'report_weekly', 'Weekly Report', NULL, TRUE, 'report', '["weekly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000020'::uuid, 'plus', 'report_monthly', 'Monthly Report', 0, FALSE, 'report', '["monthly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000021'::uuid, 'plus', 'report_custom', 'Custom Report', 0, FALSE, 'report', '["custom"]'::jsonb),
    ('20000000-0000-0000-0000-000000000022'::uuid, 'plus', 'export_pdf', 'Export PDF', 0, FALSE, 'export', '[]'::jsonb),

    ('20000000-0000-0000-0000-000000000023'::uuid, 'premium', 'skin_analysis', 'Skin Analysis', 20, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000024'::uuid, 'premium', 'ai_chat', 'AI Chat', 500, TRUE, 'message', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000025'::uuid, 'premium', 'routine_generation', 'Routine Generator', 20, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000026'::uuid, 'premium', 'ingredient_check', 'Ingredient Check', 100, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000027'::uuid, 'premium', 'conflict_check', 'Conflict Check', 100, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000028'::uuid, 'premium', 'progress_entry', 'Progress Entries', NULL, TRUE, 'entry', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000029'::uuid, 'premium', 'skin_progress_compare', 'Before/After Compare', 30, TRUE, 'usage', '[]'::jsonb),
    ('20000000-0000-0000-0000-000000000030'::uuid, 'premium', 'report_weekly', 'Weekly Report', NULL, TRUE, 'report', '["weekly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000031'::uuid, 'premium', 'report_monthly', 'Monthly Report', NULL, TRUE, 'report', '["monthly"]'::jsonb),
    ('20000000-0000-0000-0000-000000000032'::uuid, 'premium', 'report_custom', 'Custom Report', NULL, TRUE, 'report', '["custom"]'::jsonb),
    ('20000000-0000-0000-0000-000000000033'::uuid, 'premium', 'export_pdf', 'Export PDF', NULL, TRUE, 'export', '[]'::jsonb)
)
INSERT INTO subscription_plan_features (
    "Id", "PlanId", "FeatureKey", "DisplayName", "MonthlyLimit", "IsEnabled", "Unit", "AllowedValues", "CreatedAt"
)
SELECT
    feature_seed."Id",
    subscription_plans."Id",
    feature_seed."FeatureKey",
    feature_seed."DisplayName",
    feature_seed."MonthlyLimit",
    feature_seed."IsEnabled",
    feature_seed."Unit",
    feature_seed."AllowedValues",
    timezone('utc', now())
FROM feature_seed
JOIN subscription_plans ON subscription_plans."Code" = feature_seed."PlanCode"
ON CONFLICT ("PlanId", "FeatureKey") DO UPDATE
SET
    "DisplayName" = EXCLUDED."DisplayName",
    "MonthlyLimit" = EXCLUDED."MonthlyLimit",
    "IsEnabled" = EXCLUDED."IsEnabled",
    "Unit" = EXCLUDED."Unit",
    "AllowedValues" = EXCLUDED."AllowedValues",
    "UpdatedAt" = timezone('utc', now());
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
DROP TABLE IF EXISTS subscription_plan_features;
DROP TABLE IF EXISTS user_subscriptions;
DROP TABLE IF EXISTS subscription_plans;

ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS ck_users_plan_type;
ALTER TABLE IF EXISTS skin_progress_reports DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_period_type;
ALTER TABLE IF EXISTS ai_usage_logs DROP CONSTRAINT IF EXISTS ck_ai_usage_logs_feature_name;

UPDATE users
SET "PlanType" = 'free'
WHERE "PlanType" IS NULL OR lower("PlanType") NOT IN ('free', 'premium');

ALTER TABLE users
ADD CONSTRAINT ck_users_plan_type
CHECK ("PlanType" IN ('free', 'premium'));

ALTER TABLE skin_progress_reports
ADD CONSTRAINT ck_skin_progress_reports_period_type
CHECK ("PeriodType" IS NULL OR "PeriodType" IN ('weekly', 'monthly', 'yearly'));

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
""");
        }
    }
}
