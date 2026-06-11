using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class SyncTargetSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_routine_trackings_regimen_items_StepId",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_CompletedAt",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_StepId_CompletedAt",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_regimen_items_RegimenId_RoutineTime_StepOrder",
                table: "regimen_items");

            migrationBuilder.DropIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngr~",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropIndex(
                name: "IX_daily_logs_UserId_Date",
                table: "daily_logs");

            migrationBuilder.DropIndex(
                name: "IX_ai_analyses_UserId_CreatedAt",
                table: "ai_analyses");

            migrationBuilder.AlterColumn<string>(
                name: "Phone",
                table: "users",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "user_regimens",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                defaultValue: "Skin care routine",
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120,
                oldDefaultValue: "Lộ trình chăm sóc da");

            migrationBuilder.AlterColumn<bool>(
                name: "IsActive",
                table: "user_regimens",
                type: "boolean",
                nullable: false,
                defaultValue: true,
                oldClrType: typeof(bool),
                oldType: "boolean");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "EndDate",
                table: "user_regimens",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "user_regimens",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "timezone('utc', now())");

            migrationBuilder.AddColumn<string>(
                name: "Source",
                table: "user_regimens",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "ai");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "user_regimens",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "SkinType",
                table: "user_profiles",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30);

            migrationBuilder.Sql(
                """
                ALTER TABLE user_profiles
                ALTER COLUMN "SkinConcerns" TYPE jsonb
                USING CASE
                    WHEN "SkinConcerns" IS NULL THEN NULL
                    ELSE to_jsonb("SkinConcerns")
                END;
                ALTER TABLE user_profiles
                ALTER COLUMN "SkinConcerns" DROP NOT NULL;
                """);

            migrationBuilder.Sql(
                """
                ALTER TABLE user_profiles
                ALTER COLUMN "MonthlyBudget" TYPE numeric(12,2)
                USING CASE
                    WHEN "MonthlyBudget" IS NULL OR btrim("MonthlyBudget") = '' THEN 0
                    WHEN regexp_replace("MonthlyBudget", '[^0-9.]', '', 'g') = '' THEN 0
                    ELSE regexp_replace("MonthlyBudget", '[^0-9.]', '', 'g')::numeric(12,2)
                END;
                ALTER TABLE user_profiles
                ALTER COLUMN "MonthlyBudget" DROP NOT NULL;
                """);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "user_profiles",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "timezone('utc', now())");

            migrationBuilder.AddColumn<string>(
                name: "Gender",
                table: "user_profiles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SensitivityLevel",
                table: "user_profiles",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "user_profiles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE user_profiles
                SET "SkinType" = CASE
                    WHEN "SkinType" IS NULL OR btrim("SkinType") = '' THEN NULL
                    ELSE lower(btrim("SkinType"))
                END;
                """);

            migrationBuilder.AddColumn<string>(
                name: "Note",
                table: "routine_trackings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "reminders",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Instruction",
                table: "regimen_items",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "regimen_items",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "timezone('utc', now())");

            migrationBuilder.AddColumn<string>(
                name: "Frequency",
                table: "regimen_items",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "UsageGuide",
                table: "products",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");

            migrationBuilder.Sql("""ALTER TABLE products ALTER COLUMN "Ingredient" DROP DEFAULT;""");

            migrationBuilder.Sql(
                """
                ALTER TABLE products
                ALTER COLUMN "SuitableSkinTypes" TYPE jsonb
                USING CASE
                    WHEN "SuitableSkinTypes" IS NULL THEN NULL
                    ELSE to_jsonb("SuitableSkinTypes")
                END;
                ALTER TABLE products
                ALTER COLUMN "SuitableSkinTypes" DROP NOT NULL;
                """);

            migrationBuilder.AlterColumn<decimal>(
                name: "Rating",
                table: "products",
                type: "numeric(3,2)",
                precision: 3,
                scale: 2,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(3,2)",
                oldPrecision: 3,
                oldScale: 2,
                oldDefaultValue: 0m);

            migrationBuilder.Sql(
                """
                ALTER TABLE products
                ALTER COLUMN "Ingredient" TYPE jsonb
                USING CASE
                    WHEN "Ingredient" IS NULL OR btrim("Ingredient") = '' THEN NULL
                    ELSE to_jsonb(regexp_split_to_array("Ingredient", '\s*,\s*'))
                END;
                ALTER TABLE products
                ALTER COLUMN "Ingredient" DROP NOT NULL;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "products",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "products",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Severity",
                table: "ingredient_conflict_rules",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "medium",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldDefaultValue: "warning");

            migrationBuilder.AlterColumn<string>(
                name: "PrimaryIngredient",
                table: "ingredient_conflict_rules",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120);

            migrationBuilder.AlterColumn<string>(
                name: "ConflictingIngredient",
                table: "ingredient_conflict_rules",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120);

            migrationBuilder.AddColumn<Guid>(
                name: "ConflictingIngredientId",
                table: "ingredient_conflict_rules",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "PrimaryIngredientId",
                table: "ingredient_conflict_rules",
                type: "uuid",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE ingredient_conflict_rules
                SET "Severity" = CASE
                    WHEN lower(btrim("Severity")) = 'warning' THEN 'medium'
                    WHEN lower(btrim("Severity")) IN ('low', 'medium', 'high') THEN lower(btrim("Severity"))
                    ELSE 'medium'
                END;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "SkinFeeling",
                table: "daily_logs",
                type: "character varying(30)",
                maxLength: 30,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30);

            migrationBuilder.AlterColumn<bool>(
                name: "MorningCompleted",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "boolean");

            migrationBuilder.AlterColumn<bool>(
                name: "IsIrritated",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "boolean");

            migrationBuilder.AlterColumn<bool>(
                name: "EveningCompleted",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                defaultValue: false,
                oldClrType: typeof(bool),
                oldType: "boolean");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "daily_logs",
                type: "timestamp with time zone",
                nullable: false,
                defaultValueSql: "timezone('utc', now())");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "daily_logs",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE daily_logs
                SET "SkinFeeling" = CASE
                    WHEN "SkinFeeling" IS NULL OR btrim("SkinFeeling") = '' THEN NULL
                    WHEN lower(btrim("SkinFeeling")) = 'better' THEN 'good'
                    WHEN lower(replace(btrim("SkinFeeling"), ' ', '_')) IN ('good', 'normal', 'dry', 'oily', 'irritated', 'acne_flare', 'sensitive')
                        THEN lower(replace(btrim("SkinFeeling"), ' ', '_'))
                    ELSE 'normal'
                END;
                """);

            migrationBuilder.AlterColumn<int>(
                name: "UvDamage",
                table: "ai_analyses",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<int>(
                name: "SkinAge",
                table: "ai_analyses",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.Sql(
                """
                ALTER TABLE ai_analyses
                ALTER COLUMN "RootCauses" TYPE jsonb
                USING CASE
                    WHEN "RootCauses" IS NULL OR btrim("RootCauses") = '' THEN NULL
                    ELSE jsonb_build_array("RootCauses")
                END;
                ALTER TABLE ai_analyses
                ALTER COLUMN "RootCauses" DROP NOT NULL;
                """);

            migrationBuilder.AlterColumn<int>(
                name: "RecoveryCapacity",
                table: "ai_analyses",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "IssuesDetected",
                table: "ai_analyses",
                type: "jsonb",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "jsonb");

            migrationBuilder.AlterColumn<int>(
                name: "AgingRisk",
                table: "ai_analyses",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<string>(
                name: "AiModel",
                table: "ai_analyses",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RawResponse",
                table: "ai_analyses",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "ai_analyses",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "completed");

            migrationBuilder.CreateTable(
                name: "ai_analysis_issues",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AnalysisId = table.Column<Guid>(type: "uuid", nullable: false),
                    IssueType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    SeverityScore = table.Column<int>(type: "integer", nullable: false),
                    ConfidenceScore = table.Column<int>(type: "integer", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_analysis_issues", x => x.Id);
                    table.CheckConstraint("ck_ai_analysis_issues_confidence_score", "\"ConfidenceScore\" IS NULL OR \"ConfidenceScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_ai_analysis_issues_severity_score", "\"SeverityScore\" BETWEEN 0 AND 100");
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
                    RecommendationType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Title = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    Priority = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_recommendations", x => x.Id);
                    table.CheckConstraint("ck_ai_recommendations_priority", "\"Priority\" BETWEEN 1 AND 5");
                    table.CheckConstraint("ck_ai_recommendations_type", "\"RecommendationType\" IN ('routine', 'product', 'lifestyle', 'warning', 'ingredient')");
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

            migrationBuilder.CreateTable(
                name: "ingredients",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Benefit = table.Column<string>(type: "text", nullable: true),
                    RiskLevel = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "low"),
                    SuitableSkinTypes = table.Column<string>(type: "jsonb", nullable: true),
                    NotSuitableFor = table.Column<string>(type: "jsonb", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ingredients", x => x.Id);
                    table.CheckConstraint("ck_ingredients_risk_level", "\"RiskLevel\" IN ('low', 'medium', 'high')");
                });

            migrationBuilder.CreateTable(
                name: "product_ingredients",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    IngredientId = table.Column<Guid>(type: "uuid", nullable: false),
                    Concentration = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Note = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_product_ingredients", x => x.Id);
                    table.ForeignKey(
                        name: "FK_product_ingredients_ingredients_IngredientId",
                        column: x => x.IngredientId,
                        principalTable: "ingredients",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_product_ingredients_products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_role",
                table: "users",
                sql: "\"Role\" IN ('user', 'admin', 'expert')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_status",
                table: "users",
                sql: "\"Status\" IN ('active', 'inactive', 'banned')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_regimens_source",
                table: "user_regimens",
                sql: "\"Source\" IN ('ai', 'user', 'expert', 'system')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_profiles_age",
                table: "user_profiles",
                sql: "\"Age\" IS NULL OR \"Age\" >= 0");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_profiles_monthly_budget",
                table: "user_profiles",
                sql: "\"MonthlyBudget\" IS NULL OR \"MonthlyBudget\" >= 0");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_profiles_sensitivity_level",
                table: "user_profiles",
                sql: "\"SensitivityLevel\" IS NULL OR \"SensitivityLevel\" BETWEEN 1 AND 5");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_profiles_skin_type",
                table: "user_profiles",
                sql: "\"SkinType\" IS NULL OR \"SkinType\" IN ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown')");

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

            migrationBuilder.AddCheckConstraint(
                name: "ck_routine_trackings_status",
                table: "routine_trackings",
                sql: "\"Status\" IN ('completed', 'skipped', 'missed')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_reminders_routine_type",
                table: "reminders",
                sql: "\"RoutineType\" IN ('Morning', 'Evening')");

            migrationBuilder.CreateIndex(
                name: "IX_regimen_items_RegimenId_RoutineTime_StepOrder",
                table: "regimen_items",
                columns: new[] { "RegimenId", "RoutineTime", "StepOrder" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_regimen_items_routine_time",
                table: "regimen_items",
                sql: "\"RoutineTime\" IN ('Morning', 'Evening')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_regimen_items_step_order",
                table: "regimen_items",
                sql: "\"StepOrder\" > 0");

            migrationBuilder.CreateIndex(
                name: "IX_products_Brand",
                table: "products",
                column: "Brand");

            migrationBuilder.CreateIndex(
                name: "IX_products_Price",
                table: "products",
                column: "Price");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_price",
                table: "products",
                sql: "\"Price\" >= 0");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_rating",
                table: "products",
                sql: "\"Rating\" IS NULL OR \"Rating\" BETWEEN 0 AND 5");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_status",
                table: "products",
                sql: "\"Status\" IN ('active', 'out_of_stock', 'inactive')");

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_ConflictingIngredientId",
                table: "ingredient_conflict_rules",
                column: "ConflictingIngredientId");

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngr~",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredient", "ConflictingIngredient" },
                unique: true,
                filter: "\"PrimaryIngredient\" IS NOT NULL AND \"ConflictingIngredient\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIn~",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredientId", "ConflictingIngredientId" },
                unique: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_ingredient_conflict_rules_severity",
                table: "ingredient_conflict_rules",
                sql: "\"Severity\" IN ('low', 'medium', 'high')");

            migrationBuilder.CreateIndex(
                name: "IX_daily_logs_UserId_Date",
                table: "daily_logs",
                columns: new[] { "UserId", "Date" },
                unique: true,
                descending: new[] { false, true });

            migrationBuilder.AddCheckConstraint(
                name: "ck_daily_logs_skin_feeling",
                table: "daily_logs",
                sql: "\"SkinFeeling\" IS NULL OR \"SkinFeeling\" IN ('good', 'normal', 'dry', 'oily', 'irritated', 'acne_flare', 'sensitive')");

            migrationBuilder.CreateIndex(
                name: "IX_ai_analyses_Status",
                table: "ai_analyses",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_ai_analyses_UserId_CreatedAt",
                table: "ai_analyses",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_analyses_aging_risk",
                table: "ai_analyses",
                sql: "\"AgingRisk\" IS NULL OR \"AgingRisk\" BETWEEN 0 AND 100");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_analyses_overall_score",
                table: "ai_analyses",
                sql: "\"OverallScore\" BETWEEN 0 AND 100");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_analyses_recovery_capacity",
                table: "ai_analyses",
                sql: "\"RecoveryCapacity\" IS NULL OR \"RecoveryCapacity\" BETWEEN 0 AND 100");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_analyses_status",
                table: "ai_analyses",
                sql: "\"Status\" IN ('pending', 'processing', 'completed', 'failed')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_analyses_uv_damage",
                table: "ai_analyses",
                sql: "\"UvDamage\" IS NULL OR \"UvDamage\" BETWEEN 0 AND 100");

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
                name: "IX_ingredients_Name",
                table: "ingredients",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_product_ingredients_IngredientId",
                table: "product_ingredients",
                column: "IngredientId");

            migrationBuilder.CreateIndex(
                name: "IX_product_ingredients_ProductId",
                table: "product_ingredients",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_product_ingredients_ProductId_IngredientId",
                table: "product_ingredients",
                columns: new[] { "ProductId", "IngredientId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_ingredient_conflict_rules_ingredients_ConflictingIngredient~",
                table: "ingredient_conflict_rules",
                column: "ConflictingIngredientId",
                principalTable: "ingredients",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId",
                table: "ingredient_conflict_rules",
                column: "PrimaryIngredientId",
                principalTable: "ingredients",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_routine_trackings_regimen_items_StepId",
                table: "routine_trackings",
                column: "StepId",
                principalTable: "regimen_items",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ingredient_conflict_rules_ingredients_ConflictingIngredient~",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropForeignKey(
                name: "FK_ingredient_conflict_rules_ingredients_PrimaryIngredientId",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropForeignKey(
                name: "FK_routine_trackings_regimen_items_StepId",
                table: "routine_trackings");

            migrationBuilder.DropTable(
                name: "ai_analysis_issues");

            migrationBuilder.DropTable(
                name: "ai_recommendations");

            migrationBuilder.DropTable(
                name: "product_ingredients");

            migrationBuilder.DropTable(
                name: "ingredients");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_role",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_status",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_regimens_source",
                table: "user_regimens");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_profiles_age",
                table: "user_profiles");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_profiles_monthly_budget",
                table: "user_profiles");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_profiles_sensitivity_level",
                table: "user_profiles");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_profiles_skin_type",
                table: "user_profiles");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_CompletedAt",
                table: "routine_trackings");

            migrationBuilder.DropIndex(
                name: "IX_routine_trackings_UserId_StepId_CompletedAt",
                table: "routine_trackings");

            migrationBuilder.DropCheckConstraint(
                name: "ck_routine_trackings_status",
                table: "routine_trackings");

            migrationBuilder.DropCheckConstraint(
                name: "ck_reminders_routine_type",
                table: "reminders");

            migrationBuilder.DropIndex(
                name: "IX_regimen_items_RegimenId_RoutineTime_StepOrder",
                table: "regimen_items");

            migrationBuilder.DropCheckConstraint(
                name: "ck_regimen_items_routine_time",
                table: "regimen_items");

            migrationBuilder.DropCheckConstraint(
                name: "ck_regimen_items_step_order",
                table: "regimen_items");

            migrationBuilder.DropIndex(
                name: "IX_products_Brand",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_Price",
                table: "products");

            migrationBuilder.DropCheckConstraint(
                name: "ck_products_price",
                table: "products");

            migrationBuilder.DropCheckConstraint(
                name: "ck_products_rating",
                table: "products");

            migrationBuilder.DropCheckConstraint(
                name: "ck_products_status",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_ingredient_conflict_rules_ConflictingIngredientId",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngr~",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredientId_ConflictingIn~",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ingredient_conflict_rules_severity",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropIndex(
                name: "IX_daily_logs_UserId_Date",
                table: "daily_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_daily_logs_skin_feeling",
                table: "daily_logs");

            migrationBuilder.DropIndex(
                name: "IX_ai_analyses_Status",
                table: "ai_analyses");

            migrationBuilder.DropIndex(
                name: "IX_ai_analyses_UserId_CreatedAt",
                table: "ai_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_analyses_aging_risk",
                table: "ai_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_analyses_overall_score",
                table: "ai_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_analyses_recovery_capacity",
                table: "ai_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_analyses_status",
                table: "ai_analyses");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_analyses_uv_damage",
                table: "ai_analyses");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "users");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "user_regimens");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "user_regimens");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "user_regimens");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "Gender",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "SensitivityLevel",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "Note",
                table: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "reminders");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "regimen_items");

            migrationBuilder.DropColumn(
                name: "Frequency",
                table: "regimen_items");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "products");

            migrationBuilder.DropColumn(
                name: "ConflictingIngredientId",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropColumn(
                name: "PrimaryIngredientId",
                table: "ingredient_conflict_rules");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "daily_logs");

            migrationBuilder.DropColumn(
                name: "AiModel",
                table: "ai_analyses");

            migrationBuilder.DropColumn(
                name: "RawResponse",
                table: "ai_analyses");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ai_analyses");

            migrationBuilder.AlterColumn<string>(
                name: "Phone",
                table: "users",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "user_regimens",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                defaultValue: "Lộ trình chăm sóc da",
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120,
                oldDefaultValue: "Skin care routine");

            migrationBuilder.AlterColumn<bool>(
                name: "IsActive",
                table: "user_regimens",
                type: "boolean",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "boolean",
                oldDefaultValue: true);

            migrationBuilder.AlterColumn<DateOnly>(
                name: "EndDate",
                table: "user_regimens",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "SkinType",
                table: "user_profiles",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.AlterColumn<string[]>(
                name: "SkinConcerns",
                table: "user_profiles",
                type: "text[]",
                nullable: false,
                defaultValue: new string[0],
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "MonthlyBudget",
                table: "user_profiles",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(decimal),
                oldType: "numeric(12,2)",
                oldPrecision: 12,
                oldScale: 2,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Instruction",
                table: "regimen_items",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "UsageGuide",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string[]>(
                name: "SuitableSkinTypes",
                table: "products",
                type: "text[]",
                nullable: false,
                defaultValue: new string[0],
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<decimal>(
                name: "Rating",
                table: "products",
                type: "numeric(3,2)",
                precision: 3,
                scale: 2,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(3,2)",
                oldPrecision: 3,
                oldScale: 2,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Ingredient",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Description",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Severity",
                table: "ingredient_conflict_rules",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "warning",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldDefaultValue: "medium");

            migrationBuilder.AlterColumn<string>(
                name: "PrimaryIngredient",
                table: "ingredient_conflict_rules",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ConflictingIngredient",
                table: "ingredient_conflict_rules",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(120)",
                oldMaxLength: 120,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "SkinFeeling",
                table: "daily_logs",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(30)",
                oldMaxLength: 30,
                oldNullable: true);

            migrationBuilder.AlterColumn<bool>(
                name: "MorningCompleted",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "boolean",
                oldDefaultValue: false);

            migrationBuilder.AlterColumn<bool>(
                name: "IsIrritated",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "boolean",
                oldDefaultValue: false);

            migrationBuilder.AlterColumn<bool>(
                name: "EveningCompleted",
                table: "daily_logs",
                type: "boolean",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "boolean",
                oldDefaultValue: false);

            migrationBuilder.AlterColumn<int>(
                name: "UvDamage",
                table: "ai_analyses",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "SkinAge",
                table: "ai_analyses",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "RootCauses",
                table: "ai_analyses",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "RecoveryCapacity",
                table: "ai_analyses",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "IssuesDetected",
                table: "ai_analyses",
                type: "jsonb",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "jsonb",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "AgingRisk",
                table: "ai_analyses",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "CompletedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_StepId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "StepId", "CompletedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_regimen_items_RegimenId_RoutineTime_StepOrder",
                table: "regimen_items",
                columns: new[] { "RegimenId", "RoutineTime", "StepOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngr~",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredient", "ConflictingIngredient" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_daily_logs_UserId_Date",
                table: "daily_logs",
                columns: new[] { "UserId", "Date" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ai_analyses_UserId_CreatedAt",
                table: "ai_analyses",
                columns: new[] { "UserId", "CreatedAt" });

            migrationBuilder.AddForeignKey(
                name: "FK_routine_trackings_regimen_items_StepId",
                table: "routine_trackings",
                column: "StepId",
                principalTable: "regimen_items",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
