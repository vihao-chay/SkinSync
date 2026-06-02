using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinAsync.Base;
using SkinAsync.Models.Dtos.Ingredients;
using SkinAsync.Services;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/ingredient-conflicts")]
[Authorize]
public class IngredientConflictsController : ControllerBase
{
    private readonly IIngredientConflictService _ingredientConflictService;

    public IngredientConflictsController(IIngredientConflictService ingredientConflictService)
    {
        _ingredientConflictService = ingredientConflictService;
    }

    [HttpGet("rules")]
    public async Task<ResponseEntity<IEnumerable<IngredientConflictRuleDto>>> GetRules(CancellationToken cancellationToken)
    {
        var rules = await _ingredientConflictService.GetRulesAsync(cancellationToken);
        return ResponseEntity<IEnumerable<IngredientConflictRuleDto>>.Ok(
            rules,
            "Lấy danh sách quy tắc xung đột thành phần thành công.");
    }

    [HttpPost("check")]
    public async Task<ResponseEntity<IngredientConflictCheckResponseDto>> Check(
        [FromBody] IngredientConflictCheckRequestDto? request,
        CancellationToken cancellationToken)
    {
        var response = await _ingredientConflictService.CheckAsync(
            request?.ProductIds ?? Array.Empty<Guid>(),
            cancellationToken);
        return ResponseEntity<IngredientConflictCheckResponseDto>.Ok(
            response,
            response.WarningCount > 0
                ? "Phát hiện thành phần cần lưu ý trong routine."
                : "Routine hiện tại chưa có cảnh báo xung đột thành phần.");
    }
}
