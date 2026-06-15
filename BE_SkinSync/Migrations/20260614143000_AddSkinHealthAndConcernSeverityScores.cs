using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    public partial class AddSkinHealthAndConcernSeverityScores : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "OverallConcernSeverity",
                table: "skin_progress_analyses",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SkinHealthScore",
                table: "skin_progress_analyses",
                type: "integer",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE public.skin_progress_analyses
                SET "OverallConcernSeverity" = COALESCE("OverallConcernSeverity", "OverallScore"),
                    "SkinHealthScore" = COALESCE("SkinHealthScore", GREATEST(0, LEAST(100, 100 - "OverallScore")));
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OverallConcernSeverity",
                table: "skin_progress_analyses");

            migrationBuilder.DropColumn(
                name: "SkinHealthScore",
                table: "skin_progress_analyses");
        }
    }
}
