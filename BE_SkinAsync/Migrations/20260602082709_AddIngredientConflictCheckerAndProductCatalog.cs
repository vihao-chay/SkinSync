using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SkinAsync.Migrations
{
    /// <inheritdoc />
    public partial class AddIngredientConflictCheckerAndProductCatalog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ingredient_conflict_rules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    PrimaryIngredient = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    ConflictingIngredient = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Severity = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "warning"),
                    Message = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    Recommendation = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "timezone('utc', now())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ingredient_conflict_rules", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ingredient_conflict_rules_PrimaryIngredient_ConflictingIngr~",
                table: "ingredient_conflict_rules",
                columns: new[] { "PrimaryIngredient", "ConflictingIngredient" },
                unique: true);

            migrationBuilder.Sql("""
INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333301'::uuid, 'CeraVe Hydrating Cleanser', 'CeraVe', 'Cleanser',
       'Sữa rửa mặt dịu nhẹ hỗ trợ làm sạch mà không làm khô căng hàng rào da.',
       'Glycerin, Ceramide NP, Hyaluronic Acid',
       'Massage trên da ẩm 60 giây rồi rửa sạch. Dùng sáng và tối.',
       320000, ARRAY['All','Dry','Sensitive','Normal']::text[],
       'https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.7, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'CeraVe Hydrating Cleanser' AND "Brand" = 'CeraVe');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333302'::uuid, 'Supple Preparation Unscented Toner', 'Dear Klairs', 'Toner',
       'Toner cấp ẩm giúp làm dịu và chuẩn bị da cho các bước serum.',
       'Centella Asiatica, Beta-Glucan, Hyaluronic Acid, Panthenol',
       'Vỗ nhẹ 1 đến 2 lớp sau bước làm sạch.',
       360000, ARRAY['All','Dry','Sensitive','Combination']::text[],
       'https://images.unsplash.com/photo-1664165786318-9af861f2a9c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.6, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Supple Preparation Unscented Toner' AND "Brand" = 'Dear Klairs');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333303'::uuid, 'Niacinamide 10% + Zinc 1%', 'The Ordinary', 'Serum',
       'Serum hỗ trợ kiểm soát dầu, giảm bóng nhờn và làm đều màu da.',
       'Niacinamide, Zinc PCA, Panthenol',
       'Dùng 2 đến 3 giọt sau toner, trước kem dưỡng. Có thể dùng sáng hoặc tối.',
       290000, ARRAY['All','Oily','Combination','Normal']::text[],
       'https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.7, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Niacinamide 10% + Zinc 1%' AND "Brand" = 'The Ordinary');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333304'::uuid, 'Melano CC Vitamin C Essence', 'Rohto Melano CC', 'Serum',
       'Tinh chất vitamin C hỗ trợ làm sáng vùng thâm và cải thiện sắc tố không đều.',
       'Vitamin C, Ascorbic Acid, Tocopherol',
       'Dùng buổi sáng sau toner, luôn kết thúc bằng kem chống nắng.',
       260000, ARRAY['Normal','Oily','Combination']::text[],
       'https://images.unsplash.com/photo-1612532275214-e4ca76d0e4d1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.5, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Melano CC Vitamin C Essence' AND "Brand" = 'Rohto Melano CC');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333305'::uuid, 'Retinol 0.2% in Squalane', 'The Ordinary', 'Serum',
       'Serum retinol nồng độ thấp hỗ trợ cải thiện kết cấu da và dấu hiệu lão hóa sớm.',
       'Retinol, Squalane',
       'Dùng buổi tối 2 đến 3 lần mỗi tuần. Không dùng cùng đêm với acid tẩy da chết.',
       330000, ARRAY['Normal','Dry','Mature']::text[],
       'https://images.unsplash.com/photo-1620916297397-a4a5402a3c6c?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.4, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Retinol 0.2% in Squalane' AND "Brand" = 'The Ordinary');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333306'::uuid, 'Skin Perfecting 2% BHA Liquid', 'Paula''s Choice', 'Exfoliant',
       'Dung dịch BHA hỗ trợ làm sạch lỗ chân lông và cải thiện mụn đầu đen.',
       'BHA, Salicylic Acid, Green Tea',
       'Dùng buổi tối 2 đến 3 lần mỗi tuần sau làm sạch. Tăng tần suất từ từ.',
       790000, ARRAY['Oily','Combination']::text[],
       'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.8, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Skin Perfecting 2% BHA Liquid' AND "Brand" = 'Paula''s Choice');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333307'::uuid, 'Cicaplast Baume B5', 'La Roche-Posay', 'Moisturizer',
       'Kem dưỡng phục hồi giúp làm dịu da khô căng, yếu hàng rào bảo vệ.',
       'Panthenol, Madecassoside, Glycerin, Shea Butter',
       'Thoa một lớp mỏng sau serum, dùng sáng hoặc tối.',
       350000, ARRAY['All','Dry','Sensitive','Normal']::text[],
       'https://images.unsplash.com/photo-1767360963892-3353defd6584?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.7, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Cicaplast Baume B5' AND "Brand" = 'La Roche-Posay');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333308'::uuid, 'Relief Sun SPF50+', 'Beauty of Joseon', 'Sunscreen',
       'Kem chống nắng phổ rộng có finish ẩm nhẹ, phù hợp dùng hằng ngày.',
       'Niacinamide, Rice Extract, UV Filters, Green Tea',
       'Thoa lượng 2 ngón tay vào cuối routine buổi sáng và thoa lại khi cần.',
       330000, ARRAY['All','Normal','Dry','Combination']::text[],
       'https://images.unsplash.com/photo-1594332322527-08753d4473c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.8, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Relief Sun SPF50+' AND "Brand" = 'Beauty of Joseon');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333309'::uuid, 'Barrier Cream', 'SkinSync', 'Moisturizer',
       'Kem dưỡng cân bằng lipid giúp khóa ẩm và hỗ trợ hàng rào da.',
       'Ceramide, Cholesterol, Fatty Acids, Panthenol',
       'Thoa đều sau serum, ưu tiên vùng da khô căng.',
       280000, ARRAY['All','Dry','Sensitive','Combination']::text[],
       'https://images.unsplash.com/photo-1631730359585-38a4935cbec4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.5, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Barrier Cream' AND "Brand" = 'SkinSync');

INSERT INTO products ("Id", "Name", "Brand", "Category", "Description", "Ingredient", "UsageGuide", "Price", "SuitableSkinTypes", "ImageUrl", "Rating", "Status", "CreatedAt")
SELECT '33333333-3333-3333-3333-333333333310'::uuid, 'Benzac AC 2.5%', 'Galderma', 'Spot Treatment',
       'Gel chấm mụn benzoyl peroxide hỗ trợ xử lý nốt mụn viêm.',
       'Benzoyl Peroxide, Glycerin',
       'Chấm mỏng lên nốt mụn vào buổi tối. Tránh dùng cùng retinol hoặc vitamin C trong cùng routine.',
       180000, ARRAY['Oily','Combination']::text[],
       'https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=500',
       4.3, 'active', timezone('utc', now())
WHERE NOT EXISTS (SELECT 1 FROM products WHERE "Name" = 'Benzac AC 2.5%' AND "Brand" = 'Galderma');
""");

            migrationBuilder.Sql("""
INSERT INTO ingredient_conflict_rules ("Id", "PrimaryIngredient", "ConflictingIngredient", "Severity", "Message", "Recommendation")
VALUES
('44444444-4444-4444-4444-444444444401'::uuid, 'Retinol', 'AHA', 'danger', 'Retinol dùng cùng AHA dễ làm da khô rát, bong tróc và tăng nguy cơ kích ứng.', 'Tách sang các buổi tối khác nhau và phục hồi da bằng kem dưỡng barrier.'),
('44444444-4444-4444-4444-444444444402'::uuid, 'Retinol', 'BHA', 'danger', 'Retinol dùng cùng BHA có thể làm hàng rào da quá tải, nhất là da nhạy cảm hoặc đang mụn viêm.', 'Dùng BHA vào tối riêng, retinol vào tối riêng; luôn chống nắng ban ngày.'),
('44444444-4444-4444-4444-444444444403'::uuid, 'Retinol', 'Benzoyl Peroxide', 'danger', 'Retinol và benzoyl peroxide dễ gây khô rát khi layer cùng routine.', 'Ưu tiên benzoyl peroxide để chấm mụn, retinol dùng vào ngày khác.'),
('44444444-4444-4444-4444-444444444404'::uuid, 'Vitamin C', 'AHA', 'warning', 'Vitamin C và AHA đều có tính acid, dùng cùng lúc có thể gây châm chích trên da yếu.', 'Dùng vitamin C buổi sáng, AHA buổi tối hoặc giảm tần suất.'),
('44444444-4444-4444-4444-444444444405'::uuid, 'Vitamin C', 'BHA', 'warning', 'Vitamin C và BHA có thể làm da nhạy cảm hơn nếu kết hợp quá dày.', 'Tách thời điểm sử dụng và theo dõi phản ứng da trong 24 giờ.'),
('44444444-4444-4444-4444-444444444406'::uuid, 'Vitamin C', 'Retinol', 'warning', 'Vitamin C và retinol đều là hoạt chất mạnh, dùng chung routine dễ gây khô và kích ứng.', 'Dùng vitamin C buổi sáng, retinol buổi tối.'),
('44444444-4444-4444-4444-444444444407'::uuid, 'Copper Peptide', 'Vitamin C', 'warning', 'Copper peptide và vitamin C có thể làm giảm độ ổn định khi layer cùng lúc.', 'Tách copper peptide sang buổi tối hoặc ngày không dùng vitamin C.'),
('44444444-4444-4444-4444-444444444408'::uuid, 'Benzoyl Peroxide', 'Vitamin C', 'warning', 'Benzoyl peroxide có thể oxy hóa vitamin C và làm tăng khô rát.', 'Chấm mụn vào buổi tối, dùng vitamin C vào buổi sáng.')
ON CONFLICT ("PrimaryIngredient", "ConflictingIngredient") DO NOTHING;
""");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ingredient_conflict_rules");
        }
    }
}
