using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Helpers;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos;
using SkinAsync.Models.Dtos.Regimens;
using SkinAsync.Models.Entities;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

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
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var regimen = await _regimenRepository.GetCurrentByUserIdAsync(userId, cancellationToken);

        if (regimen is null)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Chưa có lộ trình đang hoạt động.", 404);
        }

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Lấy lộ trình hiện tại thành công.");
    }

    [HttpPost("custom")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> CreateCustom(
        [FromBody] RegimenUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
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

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Tạo lộ trình tùy chỉnh thành công.");
    }

    [HttpPut("current")]
    public async Task<ResponseEntity<CurrentRegimenResponseDto>> UpdateCurrent(
        [FromBody] RegimenUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
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
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var regimen = await _regimenRepository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (regimen is null)
        {
            return ResponseEntity<CurrentRegimenResponseDto>.Fail("Không tìm thấy lộ trình.", 404);
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

        return ResponseEntity<CurrentRegimenResponseDto>.Ok(regimen.ToCurrentRegimenDto(), "Cập nhật lộ trình thành công.");
    }

    [HttpDelete("{id:guid}")]
    public async Task<ResponseEntity<object>> Delete(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<object>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var regimen = await _regimenRepository.GetByIdForUserAsync(id, userId, cancellationToken);
        if (regimen is null)
        {
            return ResponseEntity<object>.Fail("Không tìm thấy lộ trình.", 404);
        }

        await _regimenRepository.DeleteAsync(regimen, cancellationToken);
        return ResponseEntity<object>.Ok(new { }, "Xóa lộ trình thành công.");
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
            return BuildItemsResult.Fail("Vui lòng thêm ít nhất một bước trong lộ trình.");
        }

        if (steps.Any(x => x.RoutineTime is null))
        {
            return BuildItemsResult.Fail("RoutineTime chỉ nhận Morning hoặc Evening.");
        }

        var productIds = steps.Select(x => x.ProductId).Distinct().ToList();
        var products = await _dbContext.Products
            .Where(x => productIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, cancellationToken);

        if (products.Count != productIds.Count)
        {
            return BuildItemsResult.Fail("Có sản phẩm không tồn tại trong lộ trình.");
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
        return string.IsNullOrWhiteSpace(trimmed) ? "Lộ trình chăm sóc da" : trimmed;
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
