using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Models.Dtos.Ingredients;
using SkinSync.Services;

namespace SkinSync.Controllers;

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
            "Láº¥y danh sÃ¡ch quy táº¯c xung Ä‘á»™t thÃ nh pháº§n thÃ nh cÃ´ng.");
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
                ? "PhÃ¡t hiá»‡n thÃ nh pháº§n cáº§n lÆ°u Ã½ trong routine."
                : "Routine hiá»‡n táº¡i chÆ°a cÃ³ cáº£nh bÃ¡o xung Ä‘á»™t thÃ nh pháº§n.");
    }
}
