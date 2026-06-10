using Microsoft.EntityFrameworkCore;
using SkinSync.Models.Entities;

namespace SkinSync.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserProfile> UserProfiles => Set<UserProfile>();
    public DbSet<AiAnalysis> AiAnalyses => Set<AiAnalysis>();
    public DbSet<AiAnalysisIssue> AiAnalysisIssues => Set<AiAnalysisIssue>();
    public DbSet<AiRecommendation> AiRecommendations => Set<AiRecommendation>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<Ingredient> Ingredients => Set<Ingredient>();
    public DbSet<ProductIngredient> ProductIngredients => Set<ProductIngredient>();
    public DbSet<IngredientConflictRule> IngredientConflictRules => Set<IngredientConflictRule>();
    public DbSet<UserRegimen> UserRegimens => Set<UserRegimen>();
    public DbSet<RegimenItem> RegimenItems => Set<RegimenItem>();
    public DbSet<DailyLog> DailyLogs => Set<DailyLog>();
    public DbSet<RoutineTracking> RoutineTrackings => Set<RoutineTracking>();
    public DbSet<Reminder> Reminders => Set<Reminder>();
    public DbSet<AiReport> AiReports => Set<AiReport>();
    public DbSet<AiUsageLog> AiUsageLogs => Set<AiUsageLog>();
    public DbSet<AiChatConversation> AiChatConversations => Set<AiChatConversation>();
    public DbSet<AiChatMessage> AiChatMessages => Set<AiChatMessage>();
    public DbSet<SkinProgressPhoto> SkinProgressPhotos => Set<SkinProgressPhoto>();
    public DbSet<SkinProgressAnalysis> SkinProgressAnalyses => Set<SkinProgressAnalysis>();
    public DbSet<SkinPhotoComparison> SkinPhotoComparisons => Set<SkinPhotoComparison>();
    public DbSet<SkinProgressReport> SkinProgressReports => Set<SkinProgressReport>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users", table =>
            {
                table.HasCheckConstraint("ck_users_role", "role IN ('user', 'admin', 'expert')");
                table.HasCheckConstraint("ck_users_status", "status IN ('active', 'inactive', 'banned')");
                table.HasCheckConstraint("ck_users_plan_type", "\"PlanType\" IN ('free', 'premium')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.Email).IsUnique();
            entity.Property(x => x.FullName).HasMaxLength(120).IsRequired();
            entity.Property(x => x.Email).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Phone).HasMaxLength(30);
            entity.Property(x => x.PasswordHash).HasMaxLength(255).IsRequired();
            entity.Property(x => x.AvatarUrl).HasMaxLength(500);
            entity.Property(x => x.Role).HasMaxLength(20).HasDefaultValue("user").IsRequired();
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("active").IsRequired();
            entity.Property(x => x.PlanType).HasMaxLength(20).HasDefaultValue("free").IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
        });

        modelBuilder.Entity<UserProfile>(entity =>
        {
            entity.ToTable("user_profiles", table =>
            {
                table.HasCheckConstraint("ck_user_profiles_skin_type", "skin_type IS NULL OR skin_type IN ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown')");
                table.HasCheckConstraint("ck_user_profiles_monthly_budget", "monthly_budget IS NULL OR monthly_budget >= 0");
                table.HasCheckConstraint("ck_user_profiles_age", "age IS NULL OR age >= 0");
                table.HasCheckConstraint("ck_user_profiles_sensitivity_level", "sensitivity_level IS NULL OR sensitivity_level BETWEEN 1 AND 5");
                table.HasCheckConstraint("ck_user_profiles_routine_preference", "\"RoutinePreference\" IS NULL OR \"RoutinePreference\" IN ('simple', 'balanced', 'advanced')");
            });
            entity.HasKey(x => x.UserId);
            entity.Property(x => x.SkinType).HasMaxLength(30);
            entity.Property(x => x.SkinConcerns).HasColumnType("jsonb");
            entity.Property(x => x.MonthlyBudget).HasPrecision(12, 2);
            entity.Property(x => x.Gender).HasMaxLength(20);
            entity.Property(x => x.Allergies).HasColumnType("jsonb");
            entity.Property(x => x.SensitiveIngredients).HasColumnType("jsonb");
            entity.Property(x => x.SkinGoals).HasColumnType("jsonb");
            entity.Property(x => x.RoutinePreference).HasMaxLength(20);
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
            entity.HasOne(x => x.User)
                .WithOne(x => x.Profile)
                .HasForeignKey<UserProfile>(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiAnalysis>(entity =>
        {
            entity.ToTable("ai_analyses", table =>
            {
                table.HasCheckConstraint("ck_ai_analyses_overall_score", "overall_score BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_ai_analyses_recovery_capacity", "recovery_capacity IS NULL OR recovery_capacity BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_ai_analyses_uv_damage", "uv_damage IS NULL OR uv_damage BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_ai_analyses_aging_risk", "aging_risk IS NULL OR aging_risk BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_ai_analyses_status", "status IN ('pending', 'processing', 'completed', 'failed')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.HasIndex(x => x.Status);
            entity.Property(x => x.ImageUrl).HasMaxLength(500).IsRequired();
            entity.Property(x => x.IssuesDetected).HasColumnType("jsonb");
            entity.Property(x => x.RootCauses).HasColumnType("jsonb");
            entity.Property(x => x.AiModel).HasMaxLength(100);
            entity.Property(x => x.RawResponse).HasColumnType("jsonb");
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("completed").IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.Analyses)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiAnalysisIssue>(entity =>
        {
            entity.ToTable("ai_analysis_issues", table =>
            {
                table.HasCheckConstraint("ck_ai_analysis_issues_severity_score", "severity_score BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_ai_analysis_issues_confidence_score", "confidence_score IS NULL OR confidence_score BETWEEN 0 AND 100");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.AnalysisId);
            entity.HasIndex(x => x.IssueType);
            entity.HasIndex(x => new { x.AnalysisId, x.IssueType });
            entity.Property(x => x.IssueType).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Description).HasColumnType("text");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.Analysis)
                .WithMany(x => x.AnalysisIssues)
                .HasForeignKey(x => x.AnalysisId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiRecommendation>(entity =>
        {
            entity.ToTable("ai_recommendations", table =>
            {
                table.HasCheckConstraint("ck_ai_recommendations_type", "recommendation_type IN ('routine', 'product', 'lifestyle', 'warning', 'ingredient')");
                table.HasCheckConstraint("ck_ai_recommendations_priority", "priority BETWEEN 1 AND 5");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.HasIndex(x => x.AnalysisId);
            entity.Property(x => x.RecommendationType).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Title).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Content).HasColumnType("text").IsRequired();
            entity.Property(x => x.Priority).HasDefaultValue(1).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.Analysis)
                .WithMany(x => x.Recommendations)
                .HasForeignKey(x => x.AnalysisId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.User)
                .WithMany(x => x.Recommendations)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("products", table =>
            {
                table.HasCheckConstraint("ck_products_price", "price >= 0");
                table.HasCheckConstraint("ck_products_rating", "rating IS NULL OR rating BETWEEN 0 AND 5");
                table.HasCheckConstraint("ck_products_status", "status IN ('active', 'out_of_stock', 'inactive')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.Status, x.Category });
            entity.HasIndex(x => x.Brand);
            entity.HasIndex(x => x.Price);
            entity.Property(x => x.Name).HasMaxLength(255).IsRequired();
            entity.Property(x => x.Brand).HasMaxLength(150).IsRequired();
            entity.Property(x => x.Category).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Description).HasColumnType("text");
            entity.Property(x => x.Ingredient).HasColumnType("jsonb");
            entity.Property(x => x.KeyIngredients).HasColumnType("jsonb");
            entity.Property(x => x.TargetConcerns).HasColumnType("jsonb");
            entity.Property(x => x.AvoidForConcerns).HasColumnType("jsonb");
            entity.Property(x => x.UsageGuide).HasColumnType("text");
            entity.Property(x => x.Price).HasPrecision(12, 2).IsRequired();
            entity.Property(x => x.Currency).HasMaxLength(10).HasDefaultValue("VND").IsRequired();
            entity.Property(x => x.SuitableSkinTypes).HasColumnType("jsonb");
            entity.Property(x => x.ImageUrl).HasMaxLength(500);
            entity.Property(x => x.Rating).HasPrecision(3, 2);
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("active").IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
        });

        modelBuilder.Entity<Ingredient>(entity =>
        {
            entity.ToTable("ingredients", table =>
            {
                table.HasCheckConstraint("ck_ingredients_risk_level", "risk_level IN ('low', 'medium', 'high')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => x.Name).IsUnique();
            entity.Property(x => x.Name).HasMaxLength(120).IsRequired();
            entity.Property(x => x.Description).HasColumnType("text");
            entity.Property(x => x.Benefit).HasColumnType("text");
            entity.Property(x => x.RiskLevel).HasMaxLength(20).HasDefaultValue("low").IsRequired();
            entity.Property(x => x.SuitableSkinTypes).HasColumnType("jsonb");
            entity.Property(x => x.NotSuitableFor).HasColumnType("jsonb");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
        });

        modelBuilder.Entity<ProductIngredient>(entity =>
        {
            entity.ToTable("product_ingredients");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.ProductId, x.IngredientId }).IsUnique();
            entity.HasIndex(x => x.ProductId);
            entity.HasIndex(x => x.IngredientId);
            entity.Property(x => x.Concentration).HasMaxLength(50);
            entity.Property(x => x.Note).HasColumnType("text");
            entity.HasOne(x => x.Product)
                .WithMany(x => x.ProductIngredients)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Ingredient)
                .WithMany(x => x.ProductIngredients)
                .HasForeignKey(x => x.IngredientId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<IngredientConflictRule>(entity =>
        {
            entity.ToTable("ingredient_conflict_rules", table =>
            {
                table.HasCheckConstraint("ck_ingredient_conflict_rules_severity", "severity IN ('low', 'medium', 'high')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.PrimaryIngredientId, x.ConflictingIngredientId }).IsUnique();
            entity.HasIndex(x => new { x.PrimaryIngredient, x.ConflictingIngredient }).IsUnique()
                .HasFilter("\"PrimaryIngredient\" IS NOT NULL AND \"ConflictingIngredient\" IS NOT NULL");
            entity.Property(x => x.PrimaryIngredient).HasMaxLength(120);
            entity.Property(x => x.ConflictingIngredient).HasMaxLength(120);
            entity.Property(x => x.Severity).HasMaxLength(20).HasDefaultValue("medium").IsRequired();
            entity.Property(x => x.Message).HasColumnType("text").HasDefaultValue(string.Empty).IsRequired();
            entity.Property(x => x.Recommendation).HasColumnType("text").HasDefaultValue(string.Empty).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.PrimaryIngredientEntity)
                .WithMany(x => x.PrimaryConflictRules)
                .HasForeignKey(x => x.PrimaryIngredientId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ConflictingIngredientEntity)
                .WithMany(x => x.ConflictingConflictRules)
                .HasForeignKey(x => x.ConflictingIngredientId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<UserRegimen>(entity =>
        {
            entity.ToTable("user_regimens", table =>
            {
                table.HasCheckConstraint("ck_user_regimens_source", "source IN ('ai', 'user', 'expert', 'system')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.IsActive });
            entity.HasIndex(x => x.AnalysisId);
            entity.Property(x => x.Name).HasMaxLength(120).HasDefaultValue("Skin care routine").IsRequired();
            entity.Property(x => x.IsActive).HasDefaultValue(true);
            entity.Property(x => x.IsCustom).HasDefaultValue(false);
            entity.Property(x => x.Source).HasMaxLength(20).HasDefaultValue("ai").IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
            entity.HasOne(x => x.User)
                .WithMany(x => x.Regimens)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Analysis)
                .WithMany(x => x.Regimens)
                .HasForeignKey(x => x.AnalysisId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<RegimenItem>(entity =>
        {
            entity.ToTable("regimen_items", table =>
            {
                table.HasCheckConstraint("ck_regimen_items_routine_time", "routine_time IN ('Morning', 'Evening')");
                table.HasCheckConstraint("ck_regimen_items_step_order", "step_order > 0");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.RegimenId, x.RoutineTime, x.StepOrder }).IsUnique();
            entity.HasIndex(x => x.ProductId);
            entity.Property(x => x.RoutineTime).HasMaxLength(20).IsRequired();
            entity.Property(x => x.Instruction).HasColumnType("text");
            entity.Property(x => x.Frequency).HasMaxLength(50);
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.Regimen)
                .WithMany(x => x.Items)
                .HasForeignKey(x => x.RegimenId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Product)
                .WithMany(x => x.RegimenItems)
                .HasForeignKey(x => x.ProductId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<RoutineTracking>(entity =>
        {
            entity.ToTable("routine_trackings", table =>
            {
                table.HasCheckConstraint("ck_routine_trackings_status", "status IN ('completed', 'skipped', 'missed')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CompletedAt }).IsDescending(false, true);
            entity.HasIndex(x => new { x.UserId, x.StepId, x.CompletedAt }).IsDescending(false, false, true);
            entity.Property(x => x.Status).HasMaxLength(20).HasDefaultValue("completed").IsRequired();
            entity.Property(x => x.Note).HasColumnType("text");
            entity.Property(x => x.CompletedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.RoutineTrackings)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Step)
                .WithMany(x => x.Trackings)
                .HasForeignKey(x => x.StepId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Reminder>(entity =>
        {
            entity.ToTable("reminders", table =>
            {
                table.HasCheckConstraint("ck_reminders_routine_type", "routine_type IN ('Morning', 'Evening')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.RoutineType }).IsUnique();
            entity.Property(x => x.Time).HasColumnType("time without time zone");
            entity.Property(x => x.RoutineType).HasMaxLength(20).IsRequired();
            entity.Property(x => x.IsEnabled).HasDefaultValue(true);
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
            entity.HasOne(x => x.User)
                .WithMany(x => x.Reminders)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DailyLog>(entity =>
        {
            entity.ToTable("daily_logs", table =>
            {
                table.HasCheckConstraint("ck_daily_logs_skin_feeling", "skin_feeling IS NULL OR skin_feeling IN ('good', 'normal', 'dry', 'oily', 'irritated', 'acne_flare', 'sensitive')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.Date }).IsUnique().IsDescending(false, true);
            entity.Property(x => x.MorningCompleted).HasDefaultValue(false);
            entity.Property(x => x.EveningCompleted).HasDefaultValue(false);
            entity.Property(x => x.SkinFeeling).HasMaxLength(30);
            entity.Property(x => x.IsIrritated).HasDefaultValue(false);
            entity.Property(x => x.Notes).HasColumnType("text");
            entity.Property(x => x.DailyImageUrl).HasMaxLength(500);
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone");
            entity.HasOne(x => x.User)
                .WithMany(x => x.DailyLogs)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SkinProgressPhoto>(entity =>
        {
            entity.ToTable("skin_progress_photos", table =>
            {
                table.HasCheckConstraint("ck_skin_progress_photos_time_of_day", "\"TimeOfDay\" IN ('morning', 'afternoon', 'night', 'unknown')");
                table.HasCheckConstraint("ck_skin_progress_photos_lighting_condition", "\"LightingCondition\" IN ('good', 'medium', 'poor', 'unknown')");
                table.HasCheckConstraint("ck_skin_progress_photos_face_angle", "\"FaceAngle\" IN ('front', 'left', 'right', 'unknown')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.PhotoDate }).IsDescending(false, true);
            entity.Property(x => x.ImageUrl).HasMaxLength(500).IsRequired();
            entity.Property(x => x.ThumbnailUrl).HasMaxLength(500);
            entity.Property(x => x.TimeOfDay).HasMaxLength(20).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.LightingCondition).HasMaxLength(20).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.FaceAngle).HasMaxLength(20).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.Note).HasColumnType("text");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.SkinProgressPhotos)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SkinProgressAnalysis>(entity =>
        {
            entity.ToTable("skin_progress_analyses", table =>
            {
                table.HasCheckConstraint("ck_skin_progress_analyses_skin_type", "\"SkinTypeEstimate\" IN ('oily', 'dry', 'combination', 'normal', 'sensitive', 'unknown')");
                table.HasCheckConstraint("ck_skin_progress_analyses_hydration", "\"HydrationLevel\" IN ('low', 'balanced', 'high', 'unknown')");
                table.HasCheckConstraint("ck_skin_progress_analyses_oiliness", "\"OilinessLevel\" IN ('low', 'medium', 'high', 'only_t_zone', 'unknown')");
                table.HasCheckConstraint("ck_skin_progress_analyses_acne_score", "\"AcneScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_redness_score", "\"RednessScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_dark_spot_score", "\"DarkSpotScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_oiliness_score", "\"OilinessScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_dryness_score", "\"DrynessScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_texture_score", "\"TextureScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_sensitivity_score", "\"SensitivityScore\" BETWEEN 0 AND 100");
                table.HasCheckConstraint("ck_skin_progress_analyses_overall_score", "\"OverallScore\" BETWEEN 0 AND 100");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.HasIndex(x => x.PhotoId).IsUnique();
            entity.Property(x => x.SkinTypeEstimate).HasMaxLength(30).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.HydrationLevel).HasMaxLength(20).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.OilinessLevel).HasMaxLength(20).HasDefaultValue("unknown").IsRequired();
            entity.Property(x => x.DetectedConcerns).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.AiSummary).HasColumnType("text").IsRequired();
            entity.Property(x => x.Recommendations).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RiskFlags).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RawAiResponse).HasColumnType("jsonb");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.SkinProgressAnalyses)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Photo)
                .WithMany(x => x.Analyses)
                .HasForeignKey(x => x.PhotoId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<SkinPhotoComparison>(entity =>
        {
            entity.ToTable("skin_photo_comparisons", table =>
            {
                table.HasCheckConstraint("ck_skin_photo_comparisons_progress_status", "\"ProgressStatus\" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.HasIndex(x => new { x.BeforePhotoId, x.AfterPhotoId }).IsUnique();
            entity.Property(x => x.ProgressStatus).HasMaxLength(30).HasDefaultValue("insufficient_data").IsRequired();
            entity.Property(x => x.ComparisonSummary).HasColumnType("text").IsRequired();
            entity.Property(x => x.Improvements).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.WorsenedAreas).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.StableAreas).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.ScoreChanges).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.Recommendations).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.ConfidenceNote).HasColumnType("text");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.SkinPhotoComparisons)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.BeforePhoto)
                .WithMany()
                .HasForeignKey(x => x.BeforePhotoId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.AfterPhoto)
                .WithMany()
                .HasForeignKey(x => x.AfterPhotoId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.BeforeAnalysis)
                .WithMany()
                .HasForeignKey(x => x.BeforeAnalysisId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.AfterAnalysis)
                .WithMany()
                .HasForeignKey(x => x.AfterAnalysisId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<SkinProgressReport>(entity =>
        {
            entity.ToTable("skin_progress_reports", table =>
            {
                table.HasCheckConstraint("ck_skin_progress_reports_period_type", "\"PeriodType\" IN ('weekly', 'monthly', 'yearly')");
                table.HasCheckConstraint("ck_skin_progress_reports_progress_status", "\"ProgressStatus\" IN ('improved', 'stable', 'worse', 'mixed', 'insufficient_data')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.PeriodType, x.PeriodStart, x.PeriodEnd }).IsUnique();
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.Property(x => x.PeriodType).HasMaxLength(20).HasDefaultValue("monthly").IsRequired();
            entity.Property(x => x.ProgressStatus).HasMaxLength(30).HasDefaultValue("insufficient_data").IsRequired();
            entity.Property(x => x.Summary).HasColumnType("text").IsRequired();
            entity.Property(x => x.ScoreChanges).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.MainFindings).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RoutineFeedback).HasColumnType("text");
            entity.Property(x => x.NextSuggestions).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RawAiResponse).HasColumnType("jsonb");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.SkinProgressReports)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiReport>(entity =>
        {
            entity.ToTable("ai_reports", table =>
            {
                table.HasCheckConstraint("ck_ai_reports_report_type", "\"ReportType\" IN ('weekly', 'monthly', 'after_analysis')");
                table.HasCheckConstraint("ck_ai_reports_progress_evaluation", "\"ProgressEvaluation\" IN ('improved', 'stable', 'worse', 'insufficient_data')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            entity.Property(x => x.ReportType).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Summary).HasColumnType("text").IsRequired();
            entity.Property(x => x.ProgressEvaluation).HasMaxLength(30).IsRequired();
            entity.Property(x => x.MainFindings).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RoutineFeedback).HasColumnType("text");
            entity.Property(x => x.ProductFeedback).HasColumnType("text");
            entity.Property(x => x.NextPlan).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.Warnings).HasColumnType("jsonb").IsRequired();
            entity.Property(x => x.RawAiResponse).HasColumnType("jsonb");
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.AiReports)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiUsageLog>(entity =>
        {
            entity.ToTable("ai_usage_logs", table =>
            {
                table.HasCheckConstraint("ck_ai_usage_logs_feature_name", "\"FeatureName\" IN ('skin_analysis', 'skin_progress_analysis', 'skin_progress_compare', 'skin_progress_report', 'ai_chat', 'routine_generation', 'product_recommendation', 'ingredient_check', 'report_generation', 'conflict_check')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.FeatureName, x.UsedAt }).IsDescending(false, false, true);
            entity.Property(x => x.FeatureName).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Model).HasMaxLength(100);
            entity.Property(x => x.CostEstimate).HasPrecision(12, 4);
            entity.Property(x => x.UsedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.AiUsageLogs)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiChatConversation>(entity =>
        {
            entity.ToTable("ai_chat_conversations");
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.UserId, x.LastMessageAt }).IsDescending(false, true);
            entity.Property(x => x.Title).HasMaxLength(120).IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.UpdatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.Property(x => x.LastMessageAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.User)
                .WithMany(x => x.AiChatConversations)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AiChatMessage>(entity =>
        {
            entity.ToTable("ai_chat_messages", table =>
            {
                table.HasCheckConstraint("ck_ai_chat_messages_role", "\"Role\" IN ('user', 'assistant', 'system')");
            });
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.ConversationId, x.CreatedAt });
            entity.Property(x => x.Role).HasMaxLength(20).IsRequired();
            entity.Property(x => x.Content).HasColumnType("text").IsRequired();
            entity.Property(x => x.CreatedAt).HasColumnType("timestamp with time zone").HasDefaultValueSql("timezone('utc', now())");
            entity.HasOne(x => x.Conversation)
                .WithMany(x => x.Messages)
                .HasForeignKey(x => x.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
