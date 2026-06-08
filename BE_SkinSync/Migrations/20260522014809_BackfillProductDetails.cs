using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinSync.Migrations
{
    /// <inheritdoc />
    public partial class BackfillProductDetails : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE products
                SET
                    "Description" = CASE
                        WHEN lower("Category") LIKE '%cleanser%' THEN 'Sữa rửa mặt giúp làm sạch bụi bẩn, dầu thừa và chuẩn bị da cho các bước tiếp theo.'
                        WHEN lower("Category") LIKE '%toner%' THEN 'Toner giúp cân bằng bề mặt da và tăng khả năng hấp thụ dưỡng chất.'
                        WHEN lower("Category") LIKE '%serum%' THEN 'Serum chứa hoạt chất cô đặc để xử lý nhu cầu chăm sóc da chính.'
                        WHEN lower("Category") LIKE '%sunscreen%' THEN 'Kem chống nắng bảo vệ da trước tia UV và giảm nguy cơ thâm sạm.'
                        WHEN lower("Category") LIKE '%moisturizer%' THEN 'Kem dưỡng giúp khóa ẩm và hỗ trợ hàng rào bảo vệ da.'
                        ELSE 'Sản phẩm chăm sóc da được dùng trong routine cá nhân hóa.'
                    END,
                    "Ingredient" = CASE
                        WHEN lower("Category") LIKE '%cleanser%' THEN 'Glycerin, surfactant dịu nhẹ, panthenol'
                        WHEN lower("Category") LIKE '%toner%' THEN 'Hyaluronic acid, beta-glucan, allantoin'
                        WHEN lower("Category") LIKE '%serum%' THEN 'Niacinamide, peptide, chất chống oxy hóa'
                        WHEN lower("Category") LIKE '%sunscreen%' THEN 'Bộ lọc UV, vitamin E, silica'
                        WHEN lower("Category") LIKE '%moisturizer%' THEN 'Ceramide, cholesterol, fatty acids'
                        ELSE 'Thành phần chăm sóc da cơ bản'
                    END,
                    "UsageGuide" = CASE
                        WHEN lower("Category") LIKE '%cleanser%' THEN 'Massage trên da ẩm khoảng 60 giây rồi rửa sạch.'
                        WHEN lower("Category") LIKE '%toner%' THEN 'Vỗ nhẹ lên da sau bước làm sạch, dùng 1 đến 2 lớp.'
                        WHEN lower("Category") LIKE '%serum%' THEN 'Dùng 2 đến 3 giọt trước kem dưỡng, tránh vùng mắt nếu da nhạy cảm.'
                        WHEN lower("Category") LIKE '%sunscreen%' THEN 'Thoa lượng 2 ngón tay ở cuối routine buổi sáng và thoa lại khi cần.'
                        WHEN lower("Category") LIKE '%moisturizer%' THEN 'Thoa đều sau serum để khóa ẩm, dùng sáng hoặc tối.'
                        ELSE 'Sử dụng theo hướng dẫn trên bao bì sản phẩm.'
                    END
                WHERE COALESCE("Description", '') = ''
                   OR COALESCE("Ingredient", '') = ''
                   OR COALESCE("UsageGuide", '') = '';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
