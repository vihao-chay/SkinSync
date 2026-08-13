using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddAppInstallEvents : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "app_install_events",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    InstallationId = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    Platform = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false, defaultValue: "unknown"),
                    AppVersion = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: true),
                    FirstSeenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())"),
                    LastSeenAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_app_install_events", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_app_install_events_FirstSeenAt",
                table: "app_install_events",
                column: "FirstSeenAt");

            migrationBuilder.CreateIndex(
                name: "IX_app_install_events_InstallationId",
                table: "app_install_events",
                column: "InstallationId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "app_install_events");
        }
    }
}
