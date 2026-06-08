using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Users;
using SkinSync.Models.Entities;
using SkinSync.Repositories;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _userRepository;

    public UsersController(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    [HttpGet("survey")]
    public async Task<IActionResult> GetSurvey(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return Unauthorized("Missing authenticated user.");
        }

        var user = await _userRepository.GetByIdWithProfileAsync(id, cancellationToken);
        if (user?.Profile is null)
        {
            return NotFound("Survey not found.");
        }

        return Ok(user.Profile.ToSurveyDto());
    }

    [HttpPost("survey")]
    public async Task<IActionResult> SaveSurvey([FromBody] SurveyRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return Unauthorized("Missing authenticated user.");
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return NotFound("User not found.");
        }

        var profile = new UserProfile
        {
            UserId = id,
            SkinType = request.SkinType?.Trim().ToLowerInvariant(),
            SkinConcerns = request.SkinConcerns,
            MonthlyBudget = request.MonthlyBudget,
            Age = request.Age,
            BirthYear = request.BirthYear,
            Gender = request.Gender?.Trim(),
            SensitivityLevel = request.SensitivityLevel,
            UpdatedAt = DateTime.UtcNow
        };

        await _userRepository.UpsertProfileAsync(profile, cancellationToken);
        return Ok(profile.ToSurveyDto());
    }
}
