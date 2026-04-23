using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinAsync.Helpers;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class RegimensController : ControllerBase
{
    private readonly IRegimenRepository _regimenRepository;

    public RegimensController(IRegimenRepository regimenRepository)
    {
        _regimenRepository = regimenRepository;
    }

    [HttpGet("current")]
    public async Task<IActionResult> GetCurrent(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return Unauthorized("Missing authenticated user.");
        }

        var regimen = await _regimenRepository.GetCurrentByUserIdAsync(userId, cancellationToken);

        if (regimen is null)
        {
            return NotFound("No active regimen found.");
        }

        return Ok(regimen.ToCurrentRegimenDto());
    }
}
