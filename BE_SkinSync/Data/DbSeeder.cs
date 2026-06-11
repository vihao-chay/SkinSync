using Microsoft.EntityFrameworkCore;
using SkinSync.Models.Entities;

namespace SkinSync.Data;

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
                SkinType = "combination",
                SkinConcerns = """["acne","pores"]""",
                MonthlyBudget = 500000m,
                Age = 22,
                CreatedAt = DateTime.UtcNow
            });
        }

        var adminProfile = await dbContext.UserProfiles.FirstOrDefaultAsync(p => p.UserId == AdminUserId, cancellationToken);
        if (adminProfile is null)
        {
            dbContext.UserProfiles.Add(new UserProfile
            {
                UserId = AdminUserId,
                SkinType = "normal",
                SkinConcerns = """["aging"]""",
                MonthlyBudget = 1000000m,
                Age = 30,
                CreatedAt = DateTime.UtcNow
            });
        }

        if (!await dbContext.Products.AnyAsync(cancellationToken))
        {
            var now = DateTime.UtcNow;
            const string allSkinTypes = """["All"]""";

            dbContext.Products.AddRange(
                new Product { Id = Guid.NewGuid(), Name = "Gentle Cleanser", Brand = "SkinSync", Category = "Cleanser", Description = "Gentle cleanser for daily use.", Ingredient = """["Glycerin","Amino Acid Surfactants","Panthenol"]""", UsageGuide = "Massage on damp skin for 60 seconds, then rinse.", Price = 8.99m, SuitableSkinTypes = allSkinTypes, Status = "active", Rating = 4.6m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Hydrating Toner", Brand = "SkinSync", Category = "Toner", Description = "Hydrating toner that helps balance skin.", Ingredient = """["Hyaluronic Acid","Beta-Glucan","Allantoin"]""", UsageGuide = "Pat 1 to 2 layers onto skin after cleansing.", Price = 9.99m, SuitableSkinTypes = allSkinTypes, Status = "active", Rating = 4.4m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Niacinamide Serum", Brand = "SkinSync", Category = "Serum", Description = "Serum that supports oil control and tone balance.", Ingredient = """["Niacinamide","Zinc PCA","Panthenol"]""", UsageGuide = "Apply 2 to 3 drops before moisturizer.", Price = 14.50m, SuitableSkinTypes = allSkinTypes, Status = "active", Rating = 4.7m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Daily SPF 50", Brand = "SkinSync", Category = "Sunscreen", Description = "Broad-spectrum sunscreen for daytime use.", Ingredient = """["UV Filters","Vitamin E","Silica"]""", UsageGuide = "Apply two-finger amount at the end of the morning routine.", Price = 12.25m, SuitableSkinTypes = allSkinTypes, Status = "active", Rating = 4.8m, CreatedAt = now },
                new Product { Id = Guid.NewGuid(), Name = "Barrier Moisturizer", Brand = "SkinSync", Category = "Moisturizer", Description = "Moisturizer that supports barrier recovery.", Ingredient = """["Ceramide","Cholesterol","Fatty Acids"]""", UsageGuide = "Apply evenly after serum, morning or evening.", Price = 11.40m, SuitableSkinTypes = allSkinTypes, Status = "active", Rating = 4.5m, CreatedAt = now }
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
                    SkinFeeling = "normal",
                    IsIrritated = false,
                    Notes = "Skipped evening due to late work.",
                    CreatedAt = DateTime.UtcNow
                },
                new DailyLog
                {
                    Id = Guid.NewGuid(),
                    UserId = DemoUserId,
                    Date = today.AddDays(-1),
                    MorningCompleted = true,
                    EveningCompleted = true,
                    SkinFeeling = "good",
                    IsIrritated = false,
                    Notes = "Routine complete, skin felt hydrated.",
                    CreatedAt = DateTime.UtcNow
                },
                new DailyLog
                {
                    Id = Guid.NewGuid(),
                    UserId = DemoUserId,
                    Date = today,
                    MorningCompleted = true,
                    EveningCompleted = false,
                    SkinFeeling = "normal",
                    IsIrritated = false,
                    Notes = "Morning done, waiting for evening check-in.",
                    CreatedAt = DateTime.UtcNow
                }
            );
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
