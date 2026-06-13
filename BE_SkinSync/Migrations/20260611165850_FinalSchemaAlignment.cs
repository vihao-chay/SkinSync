using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class FinalSchemaAlignment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                ALTER TABLE IF EXISTS public.user_regimens
                    DROP CONSTRAINT IF EXISTS "FK_user_regimens_ai_analyses_AnalysisId";

                DROP TABLE IF EXISTS public.ai_analysis_issues CASCADE;
                DROP TABLE IF EXISTS public.ai_recommendations CASCADE;
                DROP TABLE IF EXISTS public.ai_reports CASCADE;
                DROP TABLE IF EXISTS public.ai_analyses CASCADE;

                DROP INDEX IF EXISTS public."IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodE~";
                DROP INDEX IF EXISTS public."IX_routine_trackings_UserId_CompletedAt";
                DROP INDEX IF EXISTS public."IX_routine_trackings_UserId_StepId_CompletedAt";

                ALTER TABLE IF EXISTS public.skin_progress_reports
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_period_type;

                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1
                        FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND table_name = 'user_regimens'
                          AND column_name = 'AnalysisId'
                    ) AND NOT EXISTS (
                        SELECT 1
                        FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND table_name = 'user_regimens'
                          AND column_name = 'SourceAnalysisId'
                    ) THEN
                        ALTER TABLE public.user_regimens RENAME COLUMN "AnalysisId" TO "SourceAnalysisId";
                    END IF;

                    IF EXISTS (
                        SELECT 1
                        FROM pg_indexes
                        WHERE schemaname = 'public'
                          AND tablename = 'user_regimens'
                          AND indexname = 'IX_user_regimens_AnalysisId'
                    ) AND NOT EXISTS (
                        SELECT 1
                        FROM pg_indexes
                        WHERE schemaname = 'public'
                          AND tablename = 'user_regimens'
                          AND indexname = 'IX_user_regimens_SourceAnalysisId'
                    ) THEN
                        ALTER INDEX public."IX_user_regimens_AnalysisId" RENAME TO "IX_user_regimens_SourceAnalysisId";
                    END IF;
                END $$;
                """);

            migrationBuilder.Sql("""
                UPDATE public.user_regimens
                SET "SourceAnalysisId" = NULL
                WHERE "SourceAnalysisId" IS NOT NULL
                  AND NOT EXISTS (
                      SELECT 1
                      FROM public.skin_progress_analyses spa
                      WHERE spa."Id" = public.user_regimens."SourceAnalysisId"
                  );
                """);

            migrationBuilder.AlterColumn<string>(
                name: "ScoreChanges",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'{}'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "PeriodType",
                table: "skin_progress_reports",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldDefaultValue: "monthly");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "PeriodStart",
                table: "skin_progress_reports",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "PeriodEnd",
                table: "skin_progress_reports",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");

            migrationBuilder.AlterColumn<string>(
                name: "NextSuggestions",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "MainFindings",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.Sql("""
                ALTER TABLE public.skin_progress_reports
                    ADD COLUMN IF NOT EXISTS "ProductFeedback" text,
                    ADD COLUMN IF NOT EXISTS "RelatedAnalysisId" uuid,
                    ADD COLUMN IF NOT EXISTS "ReportCategory" character varying(30) NOT NULL DEFAULT 'progress_timeline',
                    ADD COLUMN IF NOT EXISTS "Source" character varying(30) NOT NULL DEFAULT 'system';

                ALTER TABLE public.skin_progress_photos
                    ADD COLUMN IF NOT EXISTS "ImageMetadataJson" jsonb,
                    ADD COLUMN IF NOT EXISTS "Source" character varying(30) NOT NULL DEFAULT 'unknown';
                """);

            migrationBuilder.AlterColumn<string>(
                name: "RiskFlags",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Recommendations",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "DetectedConcerns",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "AiSummary",
                table: "skin_progress_analyses",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.Sql("""
                ALTER TABLE public.skin_progress_analyses
                    ADD COLUMN IF NOT EXISTS "AiModel" character varying(100),
                    ADD COLUMN IF NOT EXISTS "CompletedAt" timestamp with time zone,
                    ADD COLUMN IF NOT EXISTS "ConfidenceScore" numeric(5,4),
                    ADD COLUMN IF NOT EXISTS "DiscardedAt" timestamp with time zone,
                    ADD COLUMN IF NOT EXISTS "ErrorMessage" text,
                    ADD COLUMN IF NOT EXISTS "ParsedAiResponse" jsonb,
                    ADD COLUMN IF NOT EXISTS "ProductSuggestions" jsonb NOT NULL DEFAULT '[]'::jsonb,
                    ADD COLUMN IF NOT EXISTS "RoutineSuggestions" jsonb NOT NULL DEFAULT '{}'::jsonb,
                    ADD COLUMN IF NOT EXISTS "SafetyNotes" jsonb NOT NULL DEFAULT '[]'::jsonb,
                    ADD COLUMN IF NOT EXISTS "Status" character varying(20) NOT NULL DEFAULT 'pending';
                """);

            migrationBuilder.AlterColumn<string>(
                name: "WorsenedAreas",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "StableAreas",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "ScoreChanges",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'{}'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Recommendations",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Improvements",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                defaultValueSql: "'[]'::jsonb",
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CompletedAt",
                table: "routine_trackings",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldDefaultValueSql: "timezone('utc', now())");

            migrationBuilder.Sql("""
                ALTER TABLE public.routine_trackings
                    ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
                    ADD COLUMN IF NOT EXISTS "RoutineTime" character varying(20),
                    ADD COLUMN IF NOT EXISTS "TrackingDate" date,
                    ADD COLUMN IF NOT EXISTS "UpdatedAt" timestamp with time zone;

                ALTER TABLE public.daily_logs
                    ADD COLUMN IF NOT EXISTS "AcneLevel" integer,
                    ADD COLUMN IF NOT EXISTS "DrynessLevel" integer,
                    ADD COLUMN IF NOT EXISTS "HydrationLevel" integer,
                    ADD COLUMN IF NOT EXISTS "IrritationLevel" integer,
                    ADD COLUMN IF NOT EXISTS "RednessLevel" integer;
                """);

            migrationBuilder.Sql("""
                UPDATE public.regimen_items
                SET "RoutineTime" = lower(trim("RoutineTime"))
                WHERE "RoutineTime" IS NOT NULL;

                UPDATE public.reminders
                SET "RoutineType" = lower(trim("RoutineType"))
                WHERE "RoutineType" IS NOT NULL;

                UPDATE public.routine_trackings rt
                SET "RoutineTime" = lower(trim(ri."RoutineTime")),
                    "TrackingDate" = COALESCE(rt."TrackingDate", (rt."CompletedAt" AT TIME ZONE 'utc')::date),
                    "CreatedAt" = COALESCE(rt."CompletedAt", rt."CreatedAt")
                FROM public.regimen_items ri
                WHERE rt."StepId" = ri."Id"
                  AND (rt."RoutineTime" IS NULL OR rt."TrackingDate" IS NULL);

                UPDATE public.routine_trackings
                SET "RoutineTime" = COALESCE("RoutineTime", 'morning'),
                    "TrackingDate" = COALESCE("TrackingDate", CURRENT_DATE)
                WHERE "RoutineTime" IS NULL
                   OR "TrackingDate" IS NULL;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "RoutineTime",
                table: "routine_trackings",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "morning",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<DateOnly>(
                name: "TrackingDate",
                table: "routine_trackings",
                type: "date",
                nullable: false,
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.Sql("""
                UPDATE public.skin_progress_reports
                SET "ScoreChanges" = COALESCE("ScoreChanges", '{}'::jsonb),
                    "MainFindings" = COALESCE("MainFindings", '[]'::jsonb),
                    "NextSuggestions" = COALESCE("NextSuggestions", '[]'::jsonb);

                UPDATE public.skin_photo_comparisons
                SET "Improvements" = COALESCE("Improvements", '[]'::jsonb),
                    "WorsenedAreas" = COALESCE("WorsenedAreas", '[]'::jsonb),
                    "StableAreas" = COALESCE("StableAreas", '[]'::jsonb),
                    "ScoreChanges" = COALESCE("ScoreChanges", '{}'::jsonb),
                    "Recommendations" = COALESCE("Recommendations", '[]'::jsonb);
                """);

            migrationBuilder.Sql("""
                DO $$
                DECLARE
                    rec record;
                BEGIN
                    FOR rec IN
                        SELECT indexname
                        FROM pg_indexes
                        WHERE schemaname = 'public'
                          AND tablename = 'ingredient_conflict_rules'
                          AND indexdef ILIKE '%unique index%'
                          AND indexdef ILIKE '%("PrimaryIngredientId", "ConflictingIngredientId")%'
                    LOOP
                        EXECUTE format('DROP INDEX IF EXISTS public.%I', rec.indexname);
                    END LOOP;

                    FOR rec IN
                        SELECT indexname
                        FROM pg_indexes
                        WHERE schemaname = 'public'
                          AND tablename = 'ingredient_conflict_rules'
                          AND indexdef ILIKE '%unique index%'
                          AND indexdef ILIKE '%("PrimaryIngredient", "ConflictingIngredient")%'
                          AND indexdef ILIKE '%WHERE (("PrimaryIngredient" IS NOT NULL) AND ("ConflictingIngredient" IS NOT NULL))%'
                    LOOP
                        EXECUTE format('DROP INDEX IF EXISTS public.%I', rec.indexname);
                    END LOOP;
                END $$;
                """);

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIngredientId",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredientId", "ConflictingIngredientId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngredient",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredient", "ConflictingIngredient" },
                unique: true,
                filter: "\"PrimaryIngredient\" IS NOT NULL AND \"ConflictingIngredient\" IS NOT NULL");

            migrationBuilder.Sql("""
                CREATE INDEX IF NOT EXISTS "IX_skin_progress_reports_RelatedAnalysisId"
                    ON public.skin_progress_reports ("RelatedAnalysisId");

                CREATE UNIQUE INDEX IF NOT EXISTS "IX_skin_progress_reports_UserId_ReportCategory_PeriodType_Peri~"
                    ON public.skin_progress_reports ("UserId", "ReportCategory", "PeriodType", "PeriodStart", "PeriodEnd", "RelatedAnalysisId");

                ALTER TABLE public.skin_progress_reports
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_after_analysis_related_analysis,
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_period_type,
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_progress_timeline_period,
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_report_category,
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_reports_source;

                ALTER TABLE public.skin_progress_reports
                    ADD CONSTRAINT ck_skin_progress_reports_after_analysis_related_analysis
                    CHECK ("ReportCategory" <> 'after_analysis' OR "RelatedAnalysisId" IS NOT NULL),
                    ADD CONSTRAINT ck_skin_progress_reports_period_type
                    CHECK ("PeriodType" IS NULL OR "PeriodType" IN ('weekly', 'monthly', 'yearly')),
                    ADD CONSTRAINT ck_skin_progress_reports_progress_timeline_period
                    CHECK ("ReportCategory" <> 'progress_timeline' OR ("PeriodType" IS NOT NULL AND "PeriodStart" IS NOT NULL AND "PeriodEnd" IS NOT NULL)),
                    ADD CONSTRAINT ck_skin_progress_reports_report_category
                    CHECK ("ReportCategory" IN ('progress_timeline', 'after_analysis', 'routine_feedback', 'product_feedback', 'general_summary')),
                    ADD CONSTRAINT ck_skin_progress_reports_source
                    CHECK ("Source" IN ('dashboard', 'ai_hub', 'progress', 'onboarding', 'system'));

                ALTER TABLE public.skin_progress_photos
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_photos_source;

                ALTER TABLE public.skin_progress_photos
                    ADD CONSTRAINT ck_skin_progress_photos_source
                    CHECK ("Source" IN ('dashboard', 'ai_hub', 'progress', 'onboarding', 'unknown'));

                CREATE INDEX IF NOT EXISTS "IX_skin_progress_analyses_Status"
                    ON public.skin_progress_analyses ("Status");

                ALTER TABLE public.skin_progress_analyses
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_analyses_confidence_score,
                    DROP CONSTRAINT IF EXISTS ck_skin_progress_analyses_status;

                ALTER TABLE public.skin_progress_analyses
                    ADD CONSTRAINT ck_skin_progress_analyses_confidence_score
                    CHECK ("ConfidenceScore" IS NULL OR "ConfidenceScore" BETWEEN 0 AND 1),
                    ADD CONSTRAINT ck_skin_progress_analyses_status
                    CHECK ("Status" IN ('pending', 'processing', 'completed', 'failed', 'discarded'));

                CREATE INDEX IF NOT EXISTS "IX_routine_trackings_UserId_RoutineTime_TrackingDate"
                    ON public.routine_trackings ("UserId", "RoutineTime", "TrackingDate" DESC);

                CREATE UNIQUE INDEX IF NOT EXISTS "IX_routine_trackings_UserId_StepId_TrackingDate"
                    ON public.routine_trackings ("UserId", "StepId", "TrackingDate");

                CREATE INDEX IF NOT EXISTS "IX_routine_trackings_UserId_TrackingDate"
                    ON public.routine_trackings ("UserId", "TrackingDate" DESC);

                ALTER TABLE public.routine_trackings
                    DROP CONSTRAINT IF EXISTS ck_routine_trackings_routine_time;

                ALTER TABLE public.routine_trackings
                    ADD CONSTRAINT ck_routine_trackings_routine_time
                    CHECK ("RoutineTime" IN ('morning', 'evening'));

                ALTER TABLE public.daily_logs
                    DROP CONSTRAINT IF EXISTS ck_daily_logs_acne_level,
                    DROP CONSTRAINT IF EXISTS ck_daily_logs_dryness_level,
                    DROP CONSTRAINT IF EXISTS ck_daily_logs_hydration_level,
                    DROP CONSTRAINT IF EXISTS ck_daily_logs_irritation_level,
                    DROP CONSTRAINT IF EXISTS ck_daily_logs_redness_level;

                ALTER TABLE public.daily_logs
                    ADD CONSTRAINT ck_daily_logs_acne_level
                    CHECK ("AcneLevel" IS NULL OR "AcneLevel" BETWEEN 0 AND 5),
                    ADD CONSTRAINT ck_daily_logs_dryness_level
                    CHECK ("DrynessLevel" IS NULL OR "DrynessLevel" BETWEEN 0 AND 5),
                    ADD CONSTRAINT ck_daily_logs_hydration_level
                    CHECK ("HydrationLevel" IS NULL OR "HydrationLevel" BETWEEN 0 AND 5),
                    ADD CONSTRAINT ck_daily_logs_irritation_level
                    CHECK ("IrritationLevel" IS NULL OR "IrritationLevel" BETWEEN 0 AND 5),
                    ADD CONSTRAINT ck_daily_logs_redness_level
                    CHECK ("RednessLevel" IS NULL OR "RednessLevel" BETWEEN 0 AND 5);

                ALTER TABLE public.skin_progress_reports
                    DROP CONSTRAINT IF EXISTS "FK_skin_progress_reports_skin_progress_analyses_RelatedAnalysi~";

                ALTER TABLE public.user_regimens
                    DROP CONSTRAINT IF EXISTS "FK_user_regimens_skin_progress_analyses_SourceAnalysisId";

                ALTER TABLE public.skin_progress_reports
                    ADD CONSTRAINT "FK_skin_progress_reports_skin_progress_analyses_RelatedAnalysi~"
                    FOREIGN KEY ("RelatedAnalysisId")
                    REFERENCES public.skin_progress_analyses("Id")
                    ON DELETE SET NULL;

                ALTER TABLE public.user_regimens
                    ADD CONSTRAINT "FK_user_regimens_skin_progress_analyses_SourceAnalysisId"
                    FOREIGN KEY ("SourceAnalysisId")
                    REFERENCES public.skin_progress_analyses("Id")
                    ON DELETE SET NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_skin_progress_reports_skin_progress_analyses_RelatedAnalysi~",
                table: "skin_progress_reports");

            migrationBuilder.DropForeignKey(
                name: "FK_user_regimens_skin_progress_analyses_SourceAnalysisId",
                table: "user_regimens");

            migrationBuilder.DropIndex(
                name: "IX_skin_progress_reports_RelatedAnalysisId",
                table: "skin_progress_reports");

            migrationBuilder.DropIndex(
                name: "IX_skin_progress_reports_UserId_ReportCategory_PeriodType_Peri~",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_reports_after_analysis_related_analysis",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_reports_period_type",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_reports_progress_timeline_period",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_reports_report_category",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_reports_source",
                table: "skin_progress_reports");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_photos_source",
                table: "skin_progress_photos");

            migrationBuilder.DropIndex(
                name: "IX_skin_progress_analyses_Status",
                table: "skin_progress_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_analyses_confidence_score",
                table: "skin_progress_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_skin_progress_analyses_status",
                table: "skin_progress_analyses");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_RoutineTime_TrackingDate",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_StepId_TrackingDate",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_TrackingDate",
                table: "routine_trackings");

            migrationBuilder.DropCheckConstraint(
                name: "ck_routine_trackings_routine_time",
                table: "routine_trackings");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_acne_level",
                table: "daily_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_dryness_level",
                table: "daily_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_hydration_level",
                table: "daily_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_irritation_level",
                table: "daily_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_redness_level",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "ProductFeedback",
                table: "skin_progress_reports");

            migrationBuilder.DropColumn(
                name: "RelatedAnalysisId",
                table: "skin_progress_reports");

            migrationBuilder.DropColumn(
                name: "ReportCategory",
                table: "skin_progress_reports");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "skin_progress_reports");

            migrationBuilder.DropColumn(
                name: "ImageMetadataJson",
                table: "skin_progress_photos");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "skin_progress_photos");

            migrationBuilder.DropColumn(
                name: "AiModel",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "ConfidenceScore",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "DiscardedAt",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "ErrorMessage",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "ParsedAiResponse",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "ProductSuggestions",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "RoutineSuggestions",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "SafetyNotes",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "RoutineTime",
                table: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "TrackingDate",
                table: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "AcneLevel",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "DrynessLevel",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "HydrationLevel",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "IrritationLevel",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "RednessLevel",
                table: "daily_logs");

            migrationBuilder.RenameColumn(
                name: "SourceAnalysisId",
                table: "user_regimens",
                newName: "AnalysisId");

            migrationBuilder.RenameIndex(
                name: "IX_user_regimens_SourceAnalysisId",
                table: "user_regimens",
                newName: "IX_user_regimens_AnalysisId");

            migrationBuilder.AlterColumn<string>(
                name: "ScoreChanges",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'{}'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "PeriodType",
                table: "skin_progress_reports",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "monthly",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.AlterColumn<DateOnly>(
                name: "PeriodStart",
                table: "skin_progress_reports",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AlterColumn<DateOnly>(
                name: "PeriodEnd",
                table: "skin_progress_reports",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "NextSuggestions",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "MainFindings",
                table: "skin_progress_reports",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "RiskFlags",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Recommendations",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "DetectedConcerns",
                table: "skin_progress_analyses",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "AiSummary",
                table: "skin_progress_analyses",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");

            migrationBuilder.AlterColumn<string>(
                name: "WorsenedAreas",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "StableAreas",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "ScoreChanges",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'{}'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Recommendations",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<string>(
                name: "Improvements",
                table: "skin_photo_comparisons",
                type: "jsonb",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldDefaultValueSql: "'[]'::jsonb");

            migrationBuilder.AlterColumn<DateTime>(
                name: "CompletedAt",
                table: "routine_trackings",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "timezone('utc', now())",
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);

            migrationBuilder.CreateTable(
                name: "ai_analyses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    AgingRisk = table.Column<int>(type: "integer", nullable: true),
                    AiModel = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    IssuesDetected = table.Column<string>(type: "jsonb", nullable: true),
                    OverallScore = table.Column<int>(type: "integer", nullable: false),
                    RawResponse = table.Column<string>(type: "jsonb", nullable: true),
                    RecoveryCapacity = table.Column<int>(type: "integer", nullable: true),
                    RootCauses = table.Column<string>(type: "jsonb", nullable: true),
                    SkinAge = table.Column<int>(type: "integer", nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "completed"),
                    UvDamage = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_analyses", x => x.Id);
                    table.CheckConstraint("ck_ai_analyses_aging_risk", "aging_risk IS NULL OR aging_risk BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_ai_analyses_overall_score", "overall_score BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_ai_analyses_recovery_capacity", "recovery_capacity IS NULL OR recovery_capacity BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_ai_analyses_status", "status IN ('pending', 'processing', 'completed', 'failed')");
                    table.CheckConstraint("ck_ai_analyses_uv_damage", "uv_damage IS NULL OR uv_damage BETWEEN 0 AND 100");
                    table.ForeignKey(
                        name: "FK_ai_analyses_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ai_reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    MainFindings = table.Column<string>(type: "jsonb", nullable: false),
                    NextPlan = table.Column<string>(type: "jsonb", nullable: false),
                    ProductFeedback = table.Column<string>(type: "text", nullable: true),
                    ProgressEvaluation = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    RawAiResponse = table.Column<string>(type: "jsonb", nullable: true),
                    ReportType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    RoutineFeedback = table.Column<string>(type: "text", nullable: true),
                    Summary = table.Column<string>(type: "text", nullable: false),
                    Warnings = table.Column<string>(type: "jsonb", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_reports", x => x.Id);
                    table.CheckConstraint("ck_ai_reports_progress_evaluation", "\"ProgressEvaluation\" IN ('improved', 'stable', 'worse', 'insufficient_data')");
                    table.CheckConstraint("ck_ai_reports_report_type", "\"ReportType\" IN ('weekly', 'monthly', 'after_analysis')");
                    table.ForeignKey(
                        name: "FK_ai_reports_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ai_analysis_issues",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AnalysisId = table.Column<Guid>(type: "uuid", nullable: false),
                    ConfidenceScore = table.Column<int>(type: "integer", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IssueType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    SeverityScore = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_analysis_issues", x => x.Id);
                    table.CheckConstraint("ck_ai_analysis_issues_confidence_score", "confidence_score IS NULL OR confidence_score BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_ai_analysis_issues_severity_score", "severity_score BETWEEN 0 AND 100");
                    table.ForeignKey(
                        name: "FK_ai_analysis_issues_ai_analyses_AnalysisId",
                        column: x => x.AnalysisId,
                        principalTable: "ai_analyses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ai_recommendations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AnalysisId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    Priority = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    RecommendationType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Title = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_recommendations", x => x.Id);
                    table.CheckConstraint("ck_ai_recommendations_priority", "priority BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_ai_recommendations_type", "recommendation_type IN ('routine', 'product', 'lifestyle', 'warning', 'ingredient')");
                    table.ForeignKey(
                        name: "FK_ai_recommendations_ai_analyses_AnalysisId",
                        column: x => x.AnalysisId,
                        principalTable: "ai_analyses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ai_recommendations_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodE~",
                table: "skin_progress_reports",
                columns: new[] { "UserId", "PeriodType", "PeriodStart", "PeriodEnd" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_skin_progress_reports_period_type",
                table: "skin_progress_reports",
                sql: "\"PeriodType\" IN ('weekly', 'monthly', 'yearly')");

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "CompletedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_StepId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "StepId", "CompletedAt" },
                descending: new[] { false, false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ai_analyses_Status",
                table: "ai_analyses",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_ai_analyses_UserId_CreatedAt",
                table: "ai_analyses",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ai_analysis_issues_AnalysisId",
                table: "ai_analysis_issues",
                column: "AnalysisId");

            migrationBuilder.CreateIndex(
                name: "IX_ai_analysis_issues_AnalysisId_IssueType",
                table: "ai_analysis_issues",
                columns: new[] { "AnalysisId", "IssueType" });

            migrationBuilder.CreateIndex(
                name: "IX_ai_analysis_issues_IssueType",
                table: "ai_analysis_issues",
                column: "IssueType");

            migrationBuilder.CreateIndex(
                name: "IX_ai_recommendations_AnalysisId",
                table: "ai_recommendations",
                column: "AnalysisId");

            migrationBuilder.CreateIndex(
                name: "IX_ai_recommendations_UserId_CreatedAt",
                table: "ai_recommendations",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ai_reports_UserId_CreatedAt",
                table: "ai_reports",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.AddForeignKey(
                name: "FK_user_regimens_ai_analyses_AnalysisId",
                table: "user_regimens",
                column: "AnalysisId",
                principalTable: "ai_analyses",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
