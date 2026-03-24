using Microsoft.EntityFrameworkCore;
using SkinAsync.Models.Entities;

namespace SkinAsync.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<AiAnalysis> AiAnalyses => Set<AiAnalysis>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<UserRegimen> UserRegimens => Set<UserRegimen>();
    public DbSet<RegimenItem> RegimenItems => Set<RegimenItem>();
    public DbSet<DailyLog> DailyLogs => Set<DailyLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.Property(x => x.FullName).HasMaxLength(120).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Phone).HasMaxLength(30);
            entity.Property(x => x.PasswordHash).HasMaxLength(255).IsRequired();
            entity.Property(x => x.AvatarUrl).HasMaxLength(500);
            entity.Property(x => x.Role).HasMaxLength(20).HasDefaultValue("user");
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("active");
            entity.Property(x => x.CreatedAt).HasDefaultValueSql("timezone('utc', now())");
        });

        modelBuilder.Entity<UserProfile>(entity =>
        {
            entity.ToTable("user_profiles");
            entity.HasKey(x => x.UserId);
            entity.Property(x => x.SkinType).HasMaxLength(30).IsRequired();
            entity.Property(x => x.SkinConcerns).HasColumnType("text[]").IsRequired();
            entity.Property(x => x.MonthlyBudget).HasMaxLength(30).IsRequired();
            entity.HasOne(x => x.User)
                .WithOne(x => x.Profile)
                .HasForeignKey<UserProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiAnalysis>(entity =>
        {
            entity.ToTable("ai_analyses");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt });
            entity.Property(x => x.ImageUrl).HasMaxLength(500).IsRequired();
            entity.Property(x => x.IssuesDetected).HasColumnType("jsonb");
            entity.Property(x => x.RootCauses).HasColumnType("text");
            entity.Property(x => x.CreatedAt).HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.Analyses)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("products");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.Status, x.Category });
            entity.Property(x => x.Name).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Brand).HasMaxLength(150).IsRequired();
            entity.Property(x => x.Category).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Price).HasPrecision(12, 2).IsRequired();
            entity.Property(x => x.SuitableSkinTypes).HasColumnType("text[]").IsRequired();
            entity.Property(x => x.ImageUrl).HasMaxLength(500);
            entity.Property(x => x.Rating).HasPrecision(3, 2).HasDefaultValue(0m);
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("active");
            entity.Property(x => x.CreatedAt).HasDefaultValueSql("timezone('utc', now())");
        });

        modelBuilder.Entity<UserRegimen>(entity =>
        {
            entity.ToTable("user_regimens");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.IsActive });
            entity.HasOne(x => x.User)
                .WithMany(x => x.Regimens)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Analysis)
                .WithMany(x => x.Regimens)
                .HasForeignKey(x => x.AnalysisId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RegimenItem>(entity =>
        {
            entity.ToTable("regimen_items");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.RegimenId, x.RoutineTime, x.StepOrder });
            entity.Property(x => x.RoutineTime).HasMaxLength(20).IsRequired();
            entity.HasOne(x => x.Regimen)
                .WithMany(x => x.Items)
                .HasForeignKey(x => x.RegimenId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Product)
                .WithMany(x => x.RegimenItems)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<DailyLog>(entity =>
        {
            entity.ToTable("daily_logs");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.Date }).IsUnique();
            entity.Property(x => x.SkinFeeling).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Notes).HasColumnType("text");
            entity.Property(x => x.DailyImageUrl).HasMaxLength(500);
            entity.HasOne(x => x.User)
                .WithMany(x => x.DailyLogs)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
