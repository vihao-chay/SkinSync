using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    public partial class AddAiSmartReminder : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs");

            migrationBuilder.AddColumn<string>(
                name: "Frequency",
                table: "reminders",
                type: "character varying(30)",
                maxLength: 30,
                nullable: false,
                defaultValue: "daily");

            migrationBuilder.AddColumn<bool>(
                name: "IsAdaptive",
                table: "reminders",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Priority",
                table: "reminders",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "medium");

            migrationBuilder.AddColumn<string>(
                name: "Reason",
                table: "reminders",
                type: "text",
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_reminders_priority",
                table: "reminders",
                sql: "\"Priority\" IN ('low', 'medium', 'high')");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs",
                sql: "\"FeatureName\" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check', 'smart_reminder')");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_reminders_priority",
                table: "reminders");

            migrationBuilder.DropCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs");

            migrationBuilder.DropColumn(
                name: "Frequency",
                table: "reminders");

            migrationBuilder.DropColumn(
                name: "IsAdaptive",
                table: "reminders");

            migrationBuilder.DropColumn(
                name: "Priority",
                table: "reminders");

            migrationBuilder.DropColumn(
                name: "Reason",
                table: "reminders");

            migrationBuilder.AddCheckConstraint(
                name: "ck_ai_usage_logs_feature_name",
                table: "ai_usage_logs",
                sql: "\"FeatureName\" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check')");
        }
    }
}
