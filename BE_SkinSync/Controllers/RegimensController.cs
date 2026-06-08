using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.Regimens;
using SkinSync.Models.Entities;
using SkinSync.Repositories;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RegimensController : ControllerBase
{
    private readonly AppDbContext _dbContext;
    private readonly IRegimenRepository _regimenRepository;

    public RegimensController(AppDbContext dbContext, IRegimenRepository regimenRepository)
    {
        _dbContext = dbContext;
        _regimenRepository = regimenRepository;
    }

    [HttpGet("current")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> GetCurrent(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var regimen = await _regimenRepository.GetCurrentByUserIdAsync(userId, cancellationToken);

        if (regimen is null)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("ChÆ°a cÃ³ lá»™ trÃ¬nh Ä‘ang hoáº¡t Ä‘á»™ng.", 404);
        }

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Láº¥y lá»™ trÃ¬nh hiá»‡n táº¡i thÃ nh cÃ´ng.");
    }

    [HttpPost("custom")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> CreateCustom(
        [FromBody] RegimenUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var regimenId = Guid.NewGuid();
        var buildResult = await BuildItemsAsync(regimenId, request.Steps, cancellationToken);
        if (!buildResult.Success)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail(buildResult.Message);
        }

        await _regimenRepository.DeactivateAllByUserIdAsync(userId, cancellationToken);

        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var regimen = new UserRegimen
        {
            Id = regimenId,
            UserId = userId,
            Name = NormalizeName(request.Name),
            StartDate = today,
            EndDate = today.AddDays(30),
            IsActive = true,
            IsCustom = true,
            Items = buildResult.Items
        };

        await _regimenRepository.AddAsync(regimen, cancellationToken);

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Táº¡o lá»™ trÃ¬nh tÃ¹y chá»‰nh thÃ nh cÃ´ng.");
    }

    [HttpPut("current")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> UpdateCurrent(
        [FromBody] RegimenUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var current = await _regimenRepository.GetCurrentByUserIdAsync(userId, cancellationToken);
        if (current is null)
        {
            return await CreateCustom(request, cancellationToken);
        }

        return await UpdateById(current.Id, request, cancellationToken);
    }

    [HttpPut("{id:guid}")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> UpdateById(
        Guid id,
        [FromBody] RegimenUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var regimen = await _regimenRepository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (regimen is null)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y lá»™ trÃ¬nh.", 404);
        }

        var buildResult = await BuildItemsAsync(regimen.Id, request.Steps, cancellationToken);
        if (!buildResult.Success)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail(buildResult.Message);
        }

        _dbContext.RegimenItems.RemoveRange(regimen.Items);
        regimen.Items = buildResult.Items;
        regimen.Name = NormalizeName(request.Name);
        regimen.IsCustom = true;
        _dbContext.RegimenItems.AddRange(buildResult.Items);

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Cáº­p nháº­t lá»™ trÃ¬nh thÃ nh cÃ´ng.");
    }

    [HttpDelete("{id:guid}")]
    public async Task<ResponseEntity<object>> Delete(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<object>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var regimen = await _regimenRepository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (regimen is null)
        {
            return ResponseEntity<object>.Fail("KhÃ´ng tÃ¬m tháº¥y lá»™ trÃ¬nh.", 404);
        }

        await _regimenRepository.DeleteAsync(regimen, cancellationToken);
        return ResponseEntity<object>.Ok(new { }, "XÃ³a lá»™ trÃ¬nh thÃ nh cÃ´ng.");
    }

    private async Task<BuildItemsResult> BuildItemsAsync(
        Guid regimenId,
        IEnumerable<RegimenStepUpsertDto> requestSteps,
        CancellationToken cancellationToken)
    {
        var steps = requestSteps
            .Select(x => new
            {
                x.ProductId,
                RoutineTime = NormalizeRoutineTime(x.RoutineTime),
                x.StepOrder,
                Instruction = x.Instruction.Trim()
            })
            .ToList();

        if (steps.Count == 0)
        {
            return BuildItemsResult.Fail("Vui lÃ²ng thÃªm Ã­t nháº¥t má»™t bÆ°á»›c trong lá»™ trÃ¬nh.");
        }

        if (steps.Any(x => x.RoutineTime is null))
        {
            return BuildItemsResult.Fail("RoutineTime chá»‰ nháº­n Morning hoáº·c Evening.");
        }

        var productIds = steps.Select(x => x.ProductId).Distinct().ToList();
        var products = await _dbContext.Products
            .Where(x => productIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, cancellationToken);

        if (products.Count != productIds.Count)
        {
            return BuildItemsResult.Fail("CÃ³ sáº£n pháº©m khÃ´ng tá»“n táº¡i trong lá»™ trÃ¬nh.");
        }

        var items = steps
            .GroupBy(x => x.RoutineTime!)
            .SelectMany(group => group
                .OrderBy(x => x.StepOrder)
                .Select((step, index) =>
                {
                    var product = products[step.ProductId];
                    return new RegimenItem
                    {
                        Id = Guid.NewGuid(),
                        RegimenId = regimenId,
                        ProductId = step.ProductId,
                        Product = product,
                        RoutineTime = group.Key,
                        StepOrder = index + 1,
                        Instruction = string.IsNullOrWhiteSpace(step.Instruction)
                            ? product.UsageGuide
                            : step.Instruction
                    };
                }))
            .ToList();

        return BuildItemsResult.Ok(items);
    }

    private static string NormalizeName(string name)
    {
        var trimmed = name.Trim();
        return string.IsNullOrWhiteSpace(trimmed) ? "Lá»™ trÃ¬nh chÄƒm sÃ³c da" : trimmed;
    }

    private static string? NormalizeRoutineTime(string routineTime)
    {
        var value = routineTime.Trim();
        if (value.Equals("Morning", StringComparison.OrdinalIgnoreCase))
        {
            return "Morning";
        }

        if (value.Equals("Evening", StringComparison.OrdinalIgnoreCase))
        {
            return "Evening";
        }

        return null;
    }

    private sealed class BuildItemsResult
    {
        public bool Success { get; private init; }
        public string Message { get; private init; } = string.Empty;
        public List<RegimenItem> Items { get; private init; } = [];

        public static BuildItemsResult Ok(List<RegimenItem> items)
        {
            return new BuildItemsResult { Success = true, Items = items };
        }

        public static BuildItemsResult Fail(string message)
        {
            return new BuildItemsResult { Success = false, Message = message };
        }
    }
}
