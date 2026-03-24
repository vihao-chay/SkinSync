using Microsoft.AspNetCore.Mvc;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RegimensController : ControllerBase
{
    private readonly IRegimenRepository _regimenRepository;

    public RegimensController(IRegimenRepository regimenRepository)
    {
        _regimenRepository = regimenRepository;
    }

    [HttpGet("current")]
    public async Task<IActionResult> GetCurrent([FromHeader(Name = "Id")] Guid userId, CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest("Missing Id header.");
        }

        var regimen = await _regimenRepository.GetCurrentByUserIdAsync(userId, cancellationToken);

        if (regimen is null)
        {
            return NotFound("No active regimen found.");
        }

        return Ok(regimen.ToCurrentRegimenDto());
    }
}
