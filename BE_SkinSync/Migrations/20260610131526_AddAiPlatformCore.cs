using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddAiPlatformCore : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PlanType",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "free");

            migrationBuilder.AddColumn<string>(
                name: "Allergies",
                table: "user_profiles",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "RoutinePreference",
                table: "user_profiles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SensitiveIngredients",
                table: "user_profiles",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SkinGoals",
                table: "user_profiles",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AvoidForConcerns",
                table: "products",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Currency",
                table: "products",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "VND");

            migrationBuilder.AddColumn<string>(
                name: "KeyIngredients",
                table: "products",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TargetConcerns",
                table: "products",
                type: "jsonb",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ai_reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReportType = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    Summary = table.Column<string>(type: "text", nullable: false),
                    ProgressEvaluation = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    MainFindings = table.Column<string>(type: "jsonb", nullable: false),
                    RoutineFeedback = table.Column<string>(type: "text", nullable: true),
                    ProductFeedback = table.Column<string>(type: "text", nullable: true),
                    NextPlan = table.Column<string>(type: "jsonb", nullable: false),
                    Warnings = table.Column<string>(type: "jsonb", nullable: false),
                    RawAiResponse = table.Column<string>(type: "jsonb", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
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
                name: "ai_usage_logs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    FeatureName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    UsedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    InputTokens = table.Column<int>(type: "integer", nullable: true),
                    OutputTokens = table.Column<int>(type: "integer", nullable: true),
                    Model = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    CostEstimate = table.Column<decimal>(type: "numeric(12,4)", precision: 12, scale: 4, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ai_usage_logs", x => x.Id);
                    table.CheckConstraint("ck_ai_usage_logs_feature_name", "\"FeatureName\" IN ('skin_analysis', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check')");
                    table.ForeignKey(
                        name: "FK_ai_usage_logs_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.AddCheckConstraint(
                name: "ck_users_plan_type",
                table: "users",
                sql: "\"PlanType\" IN ('free', 'premium')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_user_profiles_routine_preference",
                table: "user_profiles",
                sql: "\"RoutinePreference\" IS NULL OR \"RoutinePreference\" IN ('simple', 'balanced', 'advanced')");

            migrationBuilder.CreateIndex(
                name: "IX_ai_reports_UserId_CreatedAt",
                table: "ai_reports",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ai_usage_logs_UserId_FeatureName_UsedAt",
                table: "ai_usage_logs",
                columns: new[] { "UserId", "FeatureName", "UsedAt" },
                descending: new[] { false, false, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ai_reports");

            migrationBuilder.DropTable(
                name: "ai_usage_logs");

            migrationBuilder.DropCheckConstraint(
                name: "ck_users_plan_type",
                table: "users");

            migrationBuilder.DropCheckConstraint(
                name: "ck_user_profiles_routine_preference",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "PlanType",
                table: "users");

            migrationBuilder.DropColumn(
                name: "Allergies",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "RoutinePreference",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "SensitiveIngredients",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "SkinGoals",
                table: "user_profiles");

            migrationBuilder.DropColumn(
                name: "AvoidForConcerns",
                table: "products");

            migrationBuilder.DropColumn(
                name: "Currency",
                table: "products");

            migrationBuilder.DropColumn(
                name: "KeyIngredients",
                table: "products");

            migrationBuilder.DropColumn(
                name: "TargetConcerns",
                table: "products");
        }
    }
}
