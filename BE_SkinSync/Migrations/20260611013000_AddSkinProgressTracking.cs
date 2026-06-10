using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    public partial class AddSkinProgressTracking : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs",
                sql: "\"FeatureName\" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check')");

            migrationBuilder.CreateTable(
                name: "skin_progress_photos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    ImageUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    ThumbnailUrl = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    PhotoDate = table.Column<DateOnly>(type: "date", nullable: false),
                    TimeOfDay = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "unknown"),
                    LightingCondition = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "unknown"),
                    FaceAngle = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "unknown"),
                    Note = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_skin_progress_photos", x => x.Id);
                    table.CheckConstraint("ck_skin_progress_photos_face_angle", "\"FaceAngle\" IN ('front', 'left', 'right', 'unknown')");
                    table.CheckConstraint("ck_skin_progress_photos_lighting_condition", "\"LightingCondition\" IN ('good', 'medium', 'poor', 'unknown')");
                    table.CheckConstraint("ck_skin_progress_photos_time_of_day", "\"TimeOfDay\" IN ('morning', 'afternoon', 'night', 'unknown')");
                    table.ForeignKey(
                        name: "FK_skin_progress_photos_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "skin_progress_reports",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PeriodType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "monthly"),
                    PeriodStart = table.Column<DateOnly>(type: "date", nullable: false),
                    PeriodEnd = table.Column<DateOnly>(type: "date", nullable: false),
                    ProgressStatus = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "insufficient_data"),
                    Summary = table.Column<string>(type: "text", nullable: false),
                    ScoreChanges = table.Column<string>(type: "jsonb", nullable: false),
                    MainFindings = table.Column<string>(type: "jsonb", nullable: false),
                    RoutineFeedback = table.Column<string>(type: "text", nullable: true),
                    NextSuggestions = table.Column<string>(type: "jsonb", nullable: false),
                    RawAiResponse = table.Column<string>(type: "jsonb", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_skin_progress_reports", x => x.Id);
                    table.CheckConstraint("ck_skin_progress_reports_period_type", "\"PeriodType\" IN ('weekly', 'monthly', 'yearly')");
                    table.CheckConstraint("ck_skin_progress_reports_progress_status", "\"ProgressStatus\" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data')");
                    table.ForeignKey(
                        name: "FK_skin_progress_reports_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "skin_progress_analyses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    SkinTypeEstimate = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "unknown"),
                    HydrationLevel = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "unknown"),
                    OilinessLevel = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "unknown"),
                    AcneScore = table.Column<int>(type: "integer", nullable: false),
                    RednessScore = table.Column<int>(type: "integer", nullable: false),
                    DarkSpotScore = table.Column<int>(type: "integer", nullable: false),
                    OilinessScore = table.Column<int>(type: "integer", nullable: false),
                    DrynessScore = table.Column<int>(type: "integer", nullable: false),
                    TextureScore = table.Column<int>(type: "integer", nullable: false),
                    SensitivityScore = table.Column<int>(type: "integer", nullable: false),
                    OverallScore = table.Column<int>(type: "integer", nullable: false),
                    DetectedConcerns = table.Column<string>(type: "jsonb", nullable: false),
                    AiSummary = table.Column<string>(type: "text", nullable: false),
                    Recommendations = table.Column<string>(type: "jsonb", nullable: false),
                    RiskFlags = table.Column<string>(type: "jsonb", nullable: false),
                    RawAiResponse = table.Column<string>(type: "jsonb", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_skin_progress_analyses", x => x.Id);
                    table.CheckConstraint("ck_skin_progress_analyses_acne_score", "\"AcneScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_dark_spot_score", "\"DarkSpotScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_dryness_score", "\"DrynessScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_hydration", "\"HydrationLevel\" IN ('low', 'balanced', 'high', 'unknown')");
                    table.CheckConstraint("ck_skin_progress_analyses_oiliness", "\"OilinessLevel\" IN ('low', 'medium', 'high', 'only_t_zone', 'unknown')");
                    table.CheckConstraint("ck_skin_progress_analyses_oiliness_score", "\"OilinessScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_overall_score", "\"OverallScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_redness_score", "\"RednessScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_sensitivity_score", "\"SensitivityScore\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_skin_progress_analyses_skin_type", "\"SkinTypeEstimate\" IN ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown')");
                    table.CheckConstraint("ck_skin_progress_analyses_texture_score", "\"TextureScore\" BETWEEN 0 AND 100");
                    table.ForeignKey(
                        name: "FK_skin_progress_analyses_skin_progress_photos_PhotoId",
                        column: x => x.PhotoId,
                        principalTable: "skin_progress_photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_skin_progress_analyses_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "skin_photo_comparisons",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    BeforePhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    AfterPhotoId = table.Column<Guid>(type: "uuid", nullable: false),
                    BeforeAnalysisId = table.Column<Guid>(type: "uuid", nullable: false),
                    AfterAnalysisId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProgressStatus = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "insufficient_data"),
                    ComparisonSummary = table.Column<string>(type: "text", nullable: false),
                    Improvements = table.Column<string>(type: "jsonb", nullable: false),
                    WorsenedAreas = table.Column<string>(type: "jsonb", nullable: false),
                    StableAreas = table.Column<string>(type: "jsonb", nullable: false),
                    ScoreChanges = table.Column<string>(type: "jsonb", nullable: false),
                    Recommendations = table.Column<string>(type: "jsonb", nullable: false),
                    ConfidenceNote = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_skin_photo_comparisons", x => x.Id);
                    table.CheckConstraint("ck_skin_photo_comparisons_progress_status", "\"ProgressStatus\" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data')");
                    table.ForeignKey(
                        name: "FK_skin_photo_comparisons_skin_progress_analyses_AfterAnalysisId",
                        column: x => x.AfterAnalysisId,
                        principalTable: "skin_progress_analyses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_skin_photo_comparisons_skin_progress_analyses_BeforeAnalysisId",
                        column: x => x.BeforeAnalysisId,
                        principalTable: "skin_progress_analyses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_skin_photo_comparisons_skin_progress_photos_AfterPhotoId",
                        column: x => x.AfterPhotoId,
                        principalTable: "skin_progress_photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_skin_photo_comparisons_skin_progress_photos_BeforePhotoId",
                        column: x => x.BeforePhotoId,
                        principalTable: "skin_progress_photos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_skin_photo_comparisons_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_skin_photo_comparisons_AfterAnalysisId",
                table: "skin_photo_comparisons",
                column: "AfterAnalysisId");

            migrationBuilder.CreateIndex(
                name: "IX_skin_photo_comparisons_AfterPhotoId",
                table: "skin_photo_comparisons",
                column: "AfterPhotoId");

            migrationBuilder.CreateIndex(
                name: "IX_skin_photo_comparisons_BeforeAnalysisId",
                table: "skin_photo_comparisons",
                column: "BeforeAnalysisId");

            migrationBuilder.CreateIndex(
                name: "IX_skin_photo_comparisons_BeforePhotoId_AfterPhotoId",
                table: "skin_photo_comparisons",
                columns: new[] { "BeforePhotoId", "AfterPhotoId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_skin_photo_comparisons_UserId_CreatedAt",
                table: "skin_photo_comparisons",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_analyses_PhotoId",
                table: "skin_progress_analyses",
                column: "PhotoId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_analyses_UserId_CreatedAt",
                table: "skin_progress_analyses",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_photos_UserId_PhotoDate",
                table: "skin_progress_photos",
                columns: new[] { "UserId", "PhotoDate" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_reports_UserId_CreatedAt",
                table: "skin_progress_reports",
                columns: new[] { "UserId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_skin_progress_reports_UserId_PeriodType_PeriodStart_PeriodEnd",
                table: "skin_progress_reports",
                columns: new[] { "UserId", "PeriodType", "PeriodStart", "PeriodEnd" },
                unique: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "skin_photo_comparisons");

            migrationBuilder.DropTable(
                name: "skin_progress_reports");

            migrationBuilder.DropTable(
                name: "skin_progress_analyses");

            migrationBuilder.DropTable(
                name: "skin_progress_photos");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs",
                sql: "\"FeatureName\" IN ('skin_analysis', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check')");
        }
    }
}
