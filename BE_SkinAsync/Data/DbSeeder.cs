using Microsoft.EntityFrameworkCore;
using SkinAsync.Models.Entities;

namespace SkinAsync.Data;

public static class DbSeeder
{
    public static readonly Guid DemoUserId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid AdminUserId = Guid.Parse("22222222-2222-2222-2222-222222222222");

    public static async Task SeedAsync(AppDbContext dbContext, CancellationToken cancellationToken = default)
    {
        await dbContext.Database.MigrateAsync(cancellationToken);

        var demoUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == DemoUserId, cancellationToken);
        if (demoUser is null)
        {
            demoUser = new User
            {
                Id = DemoUserId,
                FullName = "Demo User",
                Email = "demo@skinsync.local",
                Phone = "0900000000",
                PasswordHash = "demo_hash",
                Role = "user",
                Status = "active",
                CreatedAt = DateTime.UtcNow
            };

            dbContext.Users.Add(demoUser);
        }

        var adminUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Id == AdminUserId, cancellationToken);
        if (adminUser is null)
        {
            adminUser = new User
            {
                Id = AdminUserId,
                FullName = "System Admin",
                Email = "admin@skinsync.local",
                Phone = "0911111111",
                PasswordHash = "admin_hash",
                Role = "admin",
                Status = "active",
                CreatedAt = DateTime.UtcNow
            };

            dbContext.Users.Add(adminUser);
        }

        var demoProfile = await dbContext.UserProfiles.FirstOrDefaultAsync(p => p.UserId == DemoUserId, cancellationToken);
        if (demoProfile is null)
        {
            dbContext.UserProfiles.Add(new UserProfile
            {
                UserId = DemoUserId,
                SkinType = "Combination",
                SkinConcerns = new[] { "Acne", "Pores" },
                MonthlyBudget = "Mid-range",
                Age = 22
            });
        }

        var adminProfile = await dbContext.UserProfiles.FirstOrDefaultAsync(p => p.UserId == AdminUserId, cancellationToken);
        if (adminProfile is null)
        {
            dbContext.UserProfiles.Add(new UserProfile
            {
                UserId = AdminUserId,
                SkinType = "Normal",
                SkinConcerns = new[] { "Aging" },
                MonthlyBudget = "Premium",
                Age = 30
            });
        }

        if (!await dbContext.Products.AnyAsync(cancellationToken))
        {
            var now = DateTime.UtcNow;
            var all = new[] { "All" };

            dbContext.Products.AddRange(
                new Product { Id = Guid.NewGuid(), Name = "Gentle Cleanser", Brand = "SkinSync", Category = "Cleanser", Description = "Sữa rửa mặt dịu nhẹ cho routine hằng ngày.", Ingredient = "Glycerin, amino acid surfactants, panthenol", UsageGuide = "Massage trên da ẩm 60 giây rồi rửa sạch.", Price = 8.99m, SuitableSkinTypes = all, Status = "active", Rating = 4.6m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Hydrating Toner", Brand = "SkinSync", Category = "Toner", Description = "Toner cấp ẩm giúp cân bằng bề mặt da.", Ingredient = "Hyaluronic acid, beta-glucan, allantoin", UsageGuide = "Vỗ nhẹ 1 đến 2 lớp sau bước làm sạch.", Price = 9.99m, SuitableSkinTypes = all, Status = "active", Rating = 4.4m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Niacinamide Serum", Brand = "SkinSync", Category = "Serum", Description = "Serum hỗ trợ kiểm soát dầu và làm đều màu da.", Ingredient = "Niacinamide, zinc PCA, panthenol", UsageGuide = "Dùng 2 đến 3 giọt trước kem dưỡng.", Price = 14.50m, SuitableSkinTypes = all, Status = "active", Rating = 4.7m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Daily SPF 50", Brand = "SkinSync", Category = "Sunscreen", Description = "Kem chống nắng phổ rộng cho ban ngày.", Ingredient = "Modern UV filters, vitamin E, silica", UsageGuide = "Thoa lượng 2 ngón tay vào cuối routine buổi sáng.", Price = 12.25m, SuitableSkinTypes = all, Status = "active", Rating = 4.8m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Barrier Moisturizer", Brand = "SkinSync", Category = "Moisturizer", Description = "Kem dưỡng hỗ trợ phục hồi hàng rào bảo vệ da.", Ingredient = "Ceramide, cholesterol, fatty acids", UsageGuide = "Thoa đều sau serum, dùng sáng hoặc tối.", Price = 11.40m, SuitableSkinTypes = all, Status = "active", Rating = 4.5m, CreatedAt = now }
            );
        }

        var hasDemoDailyLogs = await dbContext.DailyLogs.AnyAsync(l => l.UserId == DemoUserId, cancellationToken);
        if (!hasDemoDailyLogs)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
            dbContext.DailyLogs.AddRange(
                new DailyLog
                {
                    Id = Guid.NewGuid(),
                    UserId = DemoUserId,
                    Date = today.AddDays(-2),
                    MorningCompleted = true,
                    EveningCompleted = false,
                    SkinFeeling = "Normal",
                    IsIrritated = false,
                    Notes = "Skipped evening due to late work."
                },
                new DailyLog
                {
                    Id = Guid.NewGuid(),
                    UserId = DemoUserId,
                    Date = today.AddDays(-1),
                    MorningCompleted = true,
                    EveningCompleted = true,
                    SkinFeeling = "Better",
                    IsIrritated = false,
                    Notes = "Routine complete, skin felt hydrated."
                },
                new DailyLog
                {
                    Id = Guid.NewGuid(),
                    UserId = DemoUserId,
                    Date = today,
                    MorningCompleted = true,
                    EveningCompleted = false,
                    SkinFeeling = "Normal",
                    IsIrritated = false,
                    Notes = "Morning done, waiting for evening check-in."
                }
            );
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
