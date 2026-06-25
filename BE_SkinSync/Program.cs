using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Repositories;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(10),
                errorCodesToAdd: null);
            npgsqlOptions.CommandTimeout(30);
        }));

var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "SkinSync";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "SkinSync.Client";
var jwtSigningKey = builder.Configuration["Jwt:SigningKey"];

if (string.IsNullOrWhiteSpace(jwtSigningKey))
{
    throw new InvalidOperationException("Missing Jwt:SigningKey configuration.");
}

if (!builder.Environment.IsDevelopment() && jwtSigningKey.Contains("ChangeMe", StringComparison.OrdinalIgnoreCase))
{
    throw new InvalidOperationException("Jwt:SigningKey must be replaced with a secure value in non-development environments.");
}

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? (builder.Environment.IsDevelopment()
        ? ["http://localhost:5173", "http://localhost:3000"]
        : []);

if (!builder.Environment.IsDevelopment() && allowedOrigins.Length == 0)
{
    throw new InvalidOperationException("Configure at least one CORS origin in Cors:AllowedOrigins for non-development environments.");
}

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSigningKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.DefaultPolicy = new AuthorizationPolicyBuilder(JwtBearerDefaults.AuthenticationScheme)
        .RequireAuthenticatedUser()
        .Build();
});

builder.Services.AddScoped<IJwtAuthService, JwtService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IRegimenRepository, RegimenRepository>();
builder.Services.AddScoped<IDiaryRepository, DiaryRepository>();
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.Configure<ProductImportOptions>(builder.Configuration.GetSection("SeedData"));
builder.Services.AddScoped<IProductImportService, ProductImportService>();

builder.Services.AddScoped<IRegimenBuilderService, RegimenBuilderService>();
builder.Services.AddScoped<IIngredientConflictService, IngredientConflictService>();
builder.Services.AddScoped<ISubscriptionPlanService, SubscriptionPlanService>();
builder.Services.AddScoped<IReportPdfService, ReportPdfService>();
builder.Services.AddHttpClient<ISupabaseAuthService, SupabaseAuthService>();

// AI Integration Registrations
builder.Services.Configure<SkinSync.Services.AI.AiSettings>(builder.Configuration.GetSection("AiSettings"));
builder.Services.AddScoped<SkinSync.Services.AI.IAiService, SkinSync.Services.AI.AiService>();
builder.Services.AddScoped<ISkinService, SkinService>();
builder.Services.AddScoped<IOpenAiService, OpenAiService>();
builder.Services.AddScoped<IAiUsageService, AiUsageService>();
builder.Services.AddScoped<IImageStorageService, ImageStorageService>();
builder.Services.AddScoped<ISkinAnalysisService, SkinAnalysisService>();
builder.Services.AddScoped<IRoutineGenerationService, RoutineGenerationService>();
builder.Services.AddScoped<IProductRecommendationService, ProductRecommendationService>();
builder.Services.AddScoped<IIngredientCheckService, IngredientCheckService>();
builder.Services.AddScoped<IConflictCheckService, ConflictCheckService>();
builder.Services.AddScoped<IAiChatService, AiChatService>();
builder.Services.AddScoped<IAiReportService, AiReportService>();
builder.Services.AddScoped<IAiSmartReminderService, AiSmartReminderService>();
builder.Services.AddScoped<IProductRoutineService, ProductRoutineService>();
builder.Services.AddScoped<ISkinProgressService, SkinProgressService>();
builder.Services.AddScoped<ISkinProgressAnalysisService, SkinProgressAnalysisService>();
builder.Services.AddScoped<ISkinProgressComparisonService, SkinProgressComparisonService>();
builder.Services.AddScoped<ISkinProgressReportService, SkinProgressReportService>();

builder.Services.AddHttpClient("OpenAiClient", (sp, client) =>
{
    var settings = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<SkinSync.Services.AI.AiSettings>>().Value;
    var url = string.IsNullOrWhiteSpace(settings.OpenAi.BaseUrl) ? "https://api.openai.com/v1/" : settings.OpenAi.BaseUrl;
    if (!url.EndsWith('/')) url += "/";
    client.BaseAddress = new Uri(url);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
    if (!string.IsNullOrWhiteSpace(settings.OpenAi.ApiKey))
    {
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", settings.OpenAi.ApiKey);
    }
});
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            policy.SetIsOriginAllowed(origin =>
                  {
                      if (!Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                      {
                          return false;
                      }

                      return uri.Scheme is "http" or "https"
                          && (string.Equals(uri.Host, "localhost", StringComparison.OrdinalIgnoreCase)
                              || string.Equals(uri.Host, "127.0.0.1", StringComparison.OrdinalIgnoreCase));
                  })
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
            return;
        }

        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo()
    {
        Title = "SkinSync API",
        Version = "v1",
        Description = "API documentation for the SkinSync backend."
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhap token theo dinh dang: Bearer {access_token}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

var app = builder.Build();

var shouldSeedOnStartup = builder.Configuration.GetValue<bool>("Startup:SeedOnStartup");
var shouldSeedDemoData = builder.Configuration.GetValue<bool>("Startup:SeedDemoData");
var shouldEnableSwagger = builder.Configuration.GetValue<bool>("Swagger:Enabled");
var shouldImportProductsOnStartup = builder.Configuration.GetValue<bool>("SeedData:ImportProductsOnStartup");
var aspNetCoreUrls = builder.Configuration["ASPNETCORE_URLS"] ?? Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? string.Empty;
var shouldUseHttpsRedirection = aspNetCoreUrls
    .Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    .Any(url => url.StartsWith("https://", StringComparison.OrdinalIgnoreCase));
if (app.Environment.IsDevelopment() || shouldSeedOnStartup)
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await DbSeeder.EnsureDatabaseAsync(dbContext);
    if (shouldSeedDemoData)
    {
        await DbSeeder.SeedDemoDataAsync(dbContext);
    }

    if (shouldImportProductsOnStartup)
    {
        var productImportOptions = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Options.IOptions<ProductImportOptions>>().Value;
        var productImportService = scope.ServiceProvider.GetRequiredService<IProductImportService>();
        await productImportService.ImportFromCsvAsync(productImportOptions.ProductCsvPath, CancellationToken.None);
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || shouldEnableSwagger)
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowFrontend");
app.UseForwardedHeaders();
if (shouldUseHttpsRedirection)
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
