using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddSubscriptionPlansAndQuotas : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS ck_users_plan_type;
                ALTER TABLE IF EXISTS skin_progress_reports DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_period_type;
                ALTER TABLE IF EXISTS ai_usage_logs DROP CONSTRAINT IF EXISTS ck_ai_usage_logs_feature_name;
                ALTER TABLE IF EXISTS ai_reports DROP CONSTRAINT IF EXISTS ck_ai_reports_report_type;

                CREATE TABLE IF NOT EXISTS subscription_plans (
                    "Id" uuid NOT NULL,
                    "Code" character varying(20) NOT NULL,
                    "Name" character varying(80) NOT NULL,
                    "Description" text,
                    "Price" numeric(12,2) NOT NULL,
                    "Currency" character varying(10) NOT NULL DEFAULT 'VND',
                    "BillingPeriod" character varying(20) NOT NULL DEFAULT 'monthly',
                    "SortOrder" integer NOT NULL,
                    "IsActive" boolean NOT NULL DEFAULT TRUE,
                    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (timezone('utc', now())),
                    "UpdatedAt" timestamp with time zone,
                    CONSTRAINT "PK_subscription_plans" PRIMARY KEY ("Id"),
                    CONSTRAINT ck_subscription_plans_billing_period CHECK ("BillingPeriod" IN ('none', 'monthly')),
                    CONSTRAINT ck_subscription_plans_code CHECK ("Code" IN ('free', 'plus', 'premium')),
                    CONSTRAINT ck_subscription_plans_price CHECK ("Price" >= 0)
                );

                CREATE TABLE IF NOT EXISTS subscription_plan_features (
                    "Id" uuid NOT NULL,
                    "PlanId" uuid NOT NULL,
                    "FeatureKey" character varying(80) NOT NULL,
                    "DisplayName" character varying(120) NOT NULL,
                    "MonthlyLimit" integer,
                    "IsEnabled" boolean NOT NULL DEFAULT TRUE,
                    "Unit" character varying(40) NOT NULL DEFAULT 'usage',
                    "AllowedValues" jsonb NOT NULL DEFAULT '[]',
                    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (timezone('utc', now())),
                    "UpdatedAt" timestamp with time zone,
                    CONSTRAINT "PK_subscription_plan_features" PRIMARY KEY ("Id"),
                    CONSTRAINT ck_subscription_plan_features_monthly_limit CHECK ("MonthlyLimit" IS NULL OR "MonthlyLimit" >= 0),
                    CONSTRAINT "FK_subscription_plan_features_subscription_plans_PlanId" FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE CASCADE
                );

                CREATE TABLE IF NOT EXISTS user_subscriptions (
                    "Id" uuid NOT NULL,
                    "UserId" uuid NOT NULL,
                    "PlanId" uuid NOT NULL,
                    "Status" character varying(20) NOT NULL DEFAULT 'active',
                    "StartedAt" timestamp with time zone NOT NULL DEFAULT (timezone('utc', now())),
                    "EndsAt" timestamp with time zone,
                    "CancelledAt" timestamp with time zone,
                    "PricePaid" numeric(12,2) NOT NULL,
                    "Currency" character varying(10) NOT NULL DEFAULT 'VND',
                    "BillingPeriod" character varying(20) NOT NULL DEFAULT 'monthly',
                    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (timezone('utc', now())),
                    "UpdatedAt" timestamp with time zone,
                    CONSTRAINT "PK_user_subscriptions" PRIMARY KEY ("Id"),
                    CONSTRAINT ck_user_subscriptions_billing_period CHECK ("BillingPeriod" IN ('none', 'monthly')),
                    CONSTRAINT ck_user_subscriptions_price_paid CHECK ("PricePaid" >= 0),
                    CONSTRAINT ck_user_subscriptions_status CHECK ("Status" IN ('active', 'cancelled', 'expired')),
                    CONSTRAINT "FK_user_subscriptions_subscription_plans_PlanId" FOREIGN KEY ("PlanId") REFERENCES subscription_plans ("Id") ON DELETE RESTRICT,
                    CONSTRAINT "FK_user_subscriptions_users_UserId" FOREIGN KEY ("UserId") REFERENCES users ("Id") ON DELETE CASCADE
                );

                DO $$
                BEGIN
                    IF to_regclass('public.users') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_users_plan_type') THEN
                        ALTER TABLE users ADD CONSTRAINT ck_users_plan_type CHECK ("PlanType" IN ('free', 'plus', 'premium'));
                    END IF;
                    IF to_regclass('public.skin_progress_reports') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_skin_progress_reports_period_type') THEN
                        ALTER TABLE skin_progress_reports ADD CONSTRAINT ck_skin_progress_reports_period_type CHECK ("PeriodType" IN ('weekly', 'monthly', 'yearly', 'custom'));
                    END IF;
                    IF to_regclass('public.ai_usage_logs') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_ai_usage_logs_feature_name') THEN
                        ALTER TABLE ai_usage_logs ADD CONSTRAINT ck_ai_usage_logs_feature_name CHECK ("FeatureName" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check', 'smart_reminder', 'progress_entry'));
                    END IF;
                    IF to_regclass('public.ai_reports') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_ai_reports_report_type') THEN
                        ALTER TABLE ai_reports ADD CONSTRAINT ck_ai_reports_report_type CHECK ("ReportType" IN ('weekly', 'monthly', 'after_analysis', 'custom'));
                    END IF;
                END $$;

                CREATE UNIQUE INDEX IF NOT EXISTS "IX_subscription_plan_features_PlanId_FeatureKey"
                    ON subscription_plan_features ("PlanId", "FeatureKey");
                CREATE UNIQUE INDEX IF NOT EXISTS "IX_subscription_plans_Code"
                    ON subscription_plans ("Code");
                CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_PlanId"
                    ON user_subscriptions ("PlanId");
                CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_UserId_StartedAt"
                    ON user_subscriptions ("UserId", "StartedAt" DESC);
                CREATE INDEX IF NOT EXISTS "IX_user_subscriptions_UserId_Status"
                    ON user_subscriptions ("UserId", "Status");
                """);

            migrationBuilder.Sql("""
                INSERT INTO subscription_plans ("Id", "Code", "Name", "Description", "Price", "Currency", "BillingPeriod", "SortOrder", "IsActive", "CreatedAt")
                VALUES
                    ('10000000-0000-0000-0000-000000000001', 'free', 'Free', 'Basic monthly skincare access.', 0, 'VND', 'none', 1, TRUE, timezone('utc', now())),
                    ('10000000-0000-0000-0000-000000000002', 'plus', 'Plus', 'Expanded AI skincare limits.', 49000, 'VND', 'monthly', 2, TRUE, timezone('utc', now())),
                    ('10000000-0000-0000-0000-000000000003', 'premium', 'Premium', 'Full AI skincare access with PDF export.', 99000, 'VND', 'monthly', 3, TRUE, timezone('utc', now()))
                ON CONFLICT ("Code") DO UPDATE SET
                    "Name" = EXCLUDED."Name",
                    "Description" = EXCLUDED."Description",
                    "Price" = EXCLUDED."Price",
                    "Currency" = EXCLUDED."Currency",
                    "BillingPeriod" = EXCLUDED."BillingPeriod",
                    "SortOrder" = EXCLUDED."SortOrder",
                    "IsActive" = EXCLUDED."IsActive",
                    "UpdatedAt" = timezone('utc', now());

                INSERT INTO subscription_plan_features ("Id", "PlanId", "FeatureKey", "DisplayName", "MonthlyLimit", "IsEnabled", "Unit", "AllowedValues", "CreatedAt")
                VALUES
                    ('20000000-0000-0000-0000-000000000101', '10000000-0000-0000-0000-000000000001', 'skin_analysis', 'Skin Analysis', 1, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000102', '10000000-0000-0000-0000-000000000001', 'ai_chat', 'AI Chat', 20, TRUE, 'message', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000103', '10000000-0000-0000-0000-000000000001', 'routine_generation', 'Routine Generator', 1, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000104', '10000000-0000-0000-0000-000000000001', 'ingredient_check', 'Ingredient Check', 3, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000105', '10000000-0000-0000-0000-000000000001', 'conflict_check', 'Conflict Check', 3, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000106', '10000000-0000-0000-0000-000000000001', 'progress_entry', 'Progress Entries', 3, TRUE, 'entry', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000107', '10000000-0000-0000-0000-000000000001', 'skin_progress_compare', 'Before/After Compare', 0, FALSE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000108', '10000000-0000-0000-0000-000000000001', 'report_generation', 'AI Report', 0, FALSE, 'report', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000109', '10000000-0000-0000-0000-000000000001', 'skin_progress_report', 'Progress Report', 0, FALSE, 'report', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000110', '10000000-0000-0000-0000-000000000001', 'export_pdf', 'Export PDF', 0, FALSE, 'file', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000201', '10000000-0000-0000-0000-000000000002', 'skin_analysis', 'Skin Analysis', 4, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000202', '10000000-0000-0000-0000-000000000002', 'ai_chat', 'AI Chat', 150, TRUE, 'message', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000203', '10000000-0000-0000-0000-000000000002', 'routine_generation', 'Routine Generator', 4, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000204', '10000000-0000-0000-0000-000000000002', 'ingredient_check', 'Ingredient Check', 20, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000205', '10000000-0000-0000-0000-000000000002', 'conflict_check', 'Conflict Check', 20, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000206', '10000000-0000-0000-0000-000000000002', 'progress_entry', 'Progress Entries', 50, TRUE, 'entry', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000207', '10000000-0000-0000-0000-000000000002', 'skin_progress_compare', 'Before/After Compare', 5, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000208', '10000000-0000-0000-0000-000000000002', 'report_generation', 'AI Report', NULL, TRUE, 'report', '["weekly"]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000209', '10000000-0000-0000-0000-000000000002', 'skin_progress_report', 'Progress Report', NULL, TRUE, 'report', '["weekly"]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000210', '10000000-0000-0000-0000-000000000002', 'export_pdf', 'Export PDF', 0, FALSE, 'file', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000301', '10000000-0000-0000-0000-000000000003', 'skin_analysis', 'Skin Analysis', 20, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000302', '10000000-0000-0000-0000-000000000003', 'ai_chat', 'AI Chat', 500, TRUE, 'message', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000303', '10000000-0000-0000-0000-000000000003', 'routine_generation', 'Routine Generator', 20, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000304', '10000000-0000-0000-0000-000000000003', 'ingredient_check', 'Ingredient Check', 100, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000305', '10000000-0000-0000-0000-000000000003', 'conflict_check', 'Conflict Check', 100, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000306', '10000000-0000-0000-0000-000000000003', 'progress_entry', 'Progress Entries', NULL, TRUE, 'entry', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000307', '10000000-0000-0000-0000-000000000003', 'skin_progress_compare', 'Before/After Compare', 30, TRUE, 'usage', '[]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000308', '10000000-0000-0000-0000-000000000003', 'report_generation', 'AI Report', NULL, TRUE, 'report', '["weekly","monthly","custom","after_analysis"]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000309', '10000000-0000-0000-0000-000000000003', 'skin_progress_report', 'Progress Report', NULL, TRUE, 'report', '["weekly","monthly","custom","yearly"]', timezone('utc', now())),
                    ('20000000-0000-0000-0000-000000000310', '10000000-0000-0000-0000-000000000003', 'export_pdf', 'Export PDF', NULL, TRUE, 'file', '[]', timezone('utc', now()))
                ON CONFLICT ("PlanId", "FeatureKey") DO UPDATE SET
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
                ALTER TABLE IF EXISTS ai_reports DROP CONSTRAINT IF EXISTS ck_ai_reports_report_type;

                DO $$
                BEGIN
                    IF to_regclass('public.users') IS NOT NULL THEN
                        ALTER TABLE users ADD CONSTRAINT ck_users_plan_type CHECK ("PlanType" IN ('free', 'premium'));
                    END IF;
                    IF to_regclass('public.skin_progress_reports') IS NOT NULL THEN
                        ALTER TABLE skin_progress_reports ADD CONSTRAINT ck_skin_progress_reports_period_type CHECK ("PeriodType" IN ('weekly', 'monthly', 'yearly'));
                    END IF;
                    IF to_regclass('public.ai_usage_logs') IS NOT NULL THEN
                        ALTER TABLE ai_usage_logs ADD CONSTRAINT ck_ai_usage_logs_feature_name CHECK ("FeatureName" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check', 'smart_reminder'));
                    END IF;
                    IF to_regclass('public.ai_reports') IS NOT NULL THEN
                        ALTER TABLE ai_reports ADD CONSTRAINT ck_ai_reports_report_type CHECK ("ReportType" IN ('weekly', 'monthly', 'after_analysis'));
                    END IF;
                END $$;
                """);
        }
    }
}
