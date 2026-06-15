using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddProductRecommendationSessions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "product_recommendation_sessions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    SourceAnalysisId = table.Column<Guid>(type: "uuid", nullable: true),
                    GeneratedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "completed"),
                    Summary = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_product_recommendation_sessions", x => x.Id);
                    table.CheckConstraint("ck_product_recommendation_sessions_status", "\"Status\" IN ('completed', 'partial', 'failed', 'expired')");
                    table.ForeignKey(
                        name: "FK_product_recommendation_sessions_skin_progress_analyses_Sour~",
                        column: x => x.SourceAnalysisId,
                        principalTable: "skin_progress_analyses",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_product_recommendation_sessions_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "product_recommendation_items",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SessionId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Category = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    MatchPercent = table.Column<int>(type: "integer", nullable: false),
                    WhyRecommended = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    Cautions = table.Column<string>(type: "jsonb", nullable: false, defaultValueSql: "'[]'::jsonb"),
                    Rank = table.Column<int>(type: "integer", nullable: false),
                    AlreadyInRoutine = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_product_recommendation_items", x => x.Id);
                    table.CheckConstraint("ck_product_recommendation_items_match_percent", "\"MatchPercent\" BETWEEN 0 AND 100");
                    table.CheckConstraint("ck_product_recommendation_items_rank", "\"Rank\" > 0");
                    table.ForeignKey(
                        name: "FK_product_recommendation_items_product_recommendation_session~",
                        column: x => x.SessionId,
                        principalTable: "product_recommendation_sessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_product_recommendation_items_products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_product_recommendation_items_ProductId",
                table: "product_recommendation_items",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_product_recommendation_items_SessionId_Category_Rank",
                table: "product_recommendation_items",
                columns: new[] { "SessionId", "Category", "Rank" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_product_recommendation_items_SessionId_ProductId",
                table: "product_recommendation_items",
                columns: new[] { "SessionId", "ProductId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_product_recommendation_sessions_SourceAnalysisId",
                table: "product_recommendation_sessions",
                column: "SourceAnalysisId");

            migrationBuilder.CreateIndex(
                name: "IX_product_recommendation_sessions_UserId_GeneratedAt",
                table: "product_recommendation_sessions",
                columns: new[] { "UserId", "GeneratedAt" },
                descending: new[] { false, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "product_recommendation_items");

            migrationBuilder.DropTable(
                name: "product_recommendation_sessions");
        }
    }
}
