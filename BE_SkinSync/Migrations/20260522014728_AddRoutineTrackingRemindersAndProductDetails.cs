using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddRoutineTrackingRemindersAndProductDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_user_regimens_ai_analyses_AnalysisId",
                table: "user_regimens");

            migrationBuilder.AlterColumn<Guid>(
                name: "AnalysisId",
                table: "user_regimens",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<bool>(
                name: "IsCustom",
                table: "user_regimens",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Name",
                table: "user_regimens",
                type: "character varying(120)",
                maxLength: 120,
                nullable: false,
                defaultValue: "Lộ trình chăm sóc da");

            migrationBuilder.AddColumn<string>(
                name: "Instruction",
                table: "regimen_items",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Ingredient",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "UsageGuide",
                table: "products",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateTable(
                name: "reminders",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Time = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    RoutineType = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    IsEnabled = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_reminders", x => x.Id);
                    table.ForeignKey(
                        name: "FK_reminders_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "routine_trackings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    StepId = table.Column<Guid>(type: "uuid", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "completed")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_routine_trackings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_routine_trackings_regimen_items_StepId",
                        column: x => x.StepId,
                        principalTable: "regimen_items",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_routine_trackings_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_reminders_UserId_RoutineType",
                table: "reminders",
                columns: new[] { "UserId", "RoutineType" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_StepId",
                table: "routine_trackings",
                column: "StepId");

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "CompletedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_routine_trackings_UserId_StepId_CompletedAt",
                table: "routine_trackings",
                columns: new[] { "UserId", "StepId", "CompletedAt" });

            migrationBuilder.AddForeignKey(
                name: "FK_user_regimens_ai_analyses_AnalysisId",
                table: "user_regimens",
                column: "AnalysisId",
                principalTable: "ai_analyses",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_user_regimens_ai_analyses_AnalysisId",
                table: "user_regimens");

            migrationBuilder.DropTable(
                name: "reminders");

            migrationBuilder.DropTable(
                name: "routine_trackings");

            migrationBuilder.DropColumn(
                name: "IsCustom",
                table: "user_regimens");

            migrationBuilder.DropColumn(
                name: "Name",
                table: "user_regimens");

            migrationBuilder.DropColumn(
                name: "Instruction",
                table: "regimen_items");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "products");

            migrationBuilder.DropColumn(
                name: "Ingredient",
                table: "products");

            migrationBuilder.DropColumn(
                name: "UsageGuide",
                table: "products");

            migrationBuilder.AlterColumn<Guid>(
                name: "AnalysisId",
                table: "user_regimens",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_user_regimens_ai_analyses_AnalysisId",
                table: "user_regimens",
                column: "AnalysisId",
                principalTable: "ai_analyses",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
