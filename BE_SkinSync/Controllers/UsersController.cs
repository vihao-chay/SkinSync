using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
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
    public async Task<ResponseEntity<SurveyResponseDto>> GetSurvey(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<SurveyResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var user = await _userRepository.GetByIdWithProfileAsync(id, cancellationToken);
        if (user?.Profile is null)
        {
            return ResponseEntity<SurveyResponseDto>.Fail("Survey not found.", 404);
        }

        return ResponseEntity<SurveyResponseDto>.Ok(user.Profile.ToSurveyDto(), "Fetched survey successfully.");
    }

    [HttpPut("survey")]
    [HttpPost("survey")]
    public async Task<ResponseEntity<SurveyResponseDto>> SaveSurvey([FromBody] SurveyRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<SurveyResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<SurveyResponseDto>.Fail("User not found.", 404);
        }

        var payload = new UserProfilePayload
        {
            Concerns = request.Concerns.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            Goals = request.Goals.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            Allergies = request.Allergies.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            AvoidIngredients = request.AvoidIngredients.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList()
        };

        var profile = new UserProfile
        {
            UserId = id,
            SkinType = request.SkinType?.Trim().ToLowerInvariant(),
            SkinConcerns = UserProfilePayloadHelper.Serialize(payload),
            MonthlyBudget = request.MonthlyBudget,
            Age = request.Age,
            BirthYear = request.BirthYear,
            Gender = request.Gender?.Trim(),
            SensitivityLevel = request.SensitivityLevel,
            UpdatedAt = DateTime.UtcNow
        };

        await _userRepository.UpsertProfileAsync(profile, cancellationToken);
        return ResponseEntity<SurveyResponseDto>.Ok(profile.ToSurveyDto(), "Saved survey successfully.");
    }
}
