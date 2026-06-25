using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class AddProductCatalogImportFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_products_price",
                table: "products");

            migrationBuilder.AlterColumn<decimal>(
                name: "Price",
                table: "products",
                type: "numeric(12,2)",
                precision: 12,
                scale: 2,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(12,2)",
                oldPrecision: 12,
                oldScale: 2);

            migrationBuilder.AlterColumn<string>(
                name: "Currency",
                table: "products",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "character varying(10)",
                oldMaxLength: 10,
                oldDefaultValue: "VND");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                table: "products",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsVerified",
                table: "products",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Source",
                table: "products",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "SourceUrl",
                table: "products",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "UsageTime",
                table: "products",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_products_Category",
                table: "products",
                column: "Category");

            migrationBuilder.CreateIndex(
                name: "IX_products_IsActive",
                table: "products",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_products_IsVerified",
                table: "products",
                column: "IsVerified");

            migrationBuilder.CreateIndex(
                name: "IX_products_Name",
                table: "products",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_products_Source",
                table: "products",
                column: "Source");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_price",
                table: "products",
                sql: "\"Price\" IS NULL OR \"Price\" >= 0");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_usage_time",
                table: "products",
                sql: "\"UsageTime\" IS NULL OR \"UsageTime\" IN ('Morning', 'Night', 'Both')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_products_Category",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_IsActive",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_IsVerified",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_Name",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_Source",
                table: "products");

            migrationBuilder.DropCheckConstraint(
                name: "ck_products_price",
                table: "products");

            migrationBuilder.DropCheckConstraint(
                name: "ck_products_usage_time",
                table: "products");

            migrationBuilder.DropColumn(
                name: "IsActive",
                table: "products");

            migrationBuilder.DropColumn(
                name: "IsVerified",
                table: "products");

            migrationBuilder.DropColumn(
                name: "Source",
                table: "products");

            migrationBuilder.DropColumn(
                name: "SourceUrl",
                table: "products");

            migrationBuilder.DropColumn(
                name: "UsageTime",
                table: "products");

            migrationBuilder.AlterColumn<decimal>(
                name: "Price",
                table: "products",
                type: "numeric(12,2)",
                precision: 12,
                scale: 2,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(12,2)",
                oldPrecision: 12,
                oldScale: 2,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Currency",
                table: "products",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "VND",
                oldClrType: typeof(string),
                oldType: "character varying(10)",
                oldMaxLength: 10,
                oldDefaultValue: "");

            migrationBuilder.AddCheckConstraint(
                name: "ck_products_price",
                table: "products",
                sql: "\"Price\" >= 0");
        }
    }
}
