using System.Globalization;
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
[Route("api/user-profiles")]
[Authorize]
public class UserProfilesController : ControllerBase
{
    private readonly IUserRepository _userRepository;

    public UserProfilesController(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    [HttpGet("onboarding")]
    public async Task<ResponseEntity<SurveyResponseDto>> GetOnboarding(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<SurveyResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var user = await _userRepository.GetByIdWithProfileAsync(id, cancellationToken);
        if (user?.Profile is null)
        {
            return ResponseEntity<SurveyResponseDto>.Ok(new SurveyResponseDto
            {
                UserId = id,
                DisplayName = user?.FullName ?? string.Empty,
                IsOnboardingCompleted = false
            }, "Onboarding profile not found.");
        }

        return ResponseEntity<SurveyResponseDto>.Ok(user.Profile.ToSurveyDto(), "Fetched onboarding profile successfully.");
    }

    [HttpPost("onboarding")]
    public async Task<ResponseEntity<SurveyResponseDto>> SaveOnboarding([FromBody] SurveyRequestDto request, CancellationToken cancellationToken)
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

        ApplyDisplayName(user, request.DisplayName);

        var payload = BuildPayload(request);
        var profile = new UserProfile
        {
            UserId = id,
            SkinType = request.SkinType?.Trim().ToLowerInvariant(),
            SkinConcerns = UserProfilePayloadHelper.Serialize(payload),
            MonthlyBudget = request.MonthlyBudget,
            Age = request.Age,
            BirthYear = request.BirthYear ?? TryGetBirthYear(request.DateOfBirth),
            Gender = request.Gender?.Trim(),
            SensitivityLevel = request.SensitivityLevel,
            UpdatedAt = DateTime.UtcNow
        };

        await _userRepository.UpsertProfileAsync(profile, cancellationToken);
        await _userRepository.UpdateAsync(user, cancellationToken);

        return ResponseEntity<SurveyResponseDto>.Ok(profile.ToSurveyDto(), "Saved onboarding successfully.");
    }

    private static void ApplyDisplayName(User user, string? displayName)
    {
        var value = displayName?.Trim();
        if (!string.IsNullOrWhiteSpace(value))
        {
            user.FullName = value;
        }
    }

    private static UserProfilePayload BuildPayload(SurveyRequestDto request)
    {
        var healthIssues = request.HealthIssues
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (healthIssues.Any(x => x.Equals("none", StringComparison.OrdinalIgnoreCase)))
        {
            healthIssues = ["none"];
        }

        return new UserProfilePayload
        {
            DisplayName = request.DisplayName?.Trim(),
            DateOfBirth = request.DateOfBirth?.Trim(),
            Gender = request.Gender?.Trim(),
            HealthIssues = healthIssues,
            Concerns = request.Concerns.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            CurrentRoutineLevel = request.CurrentRoutineLevel?.Trim(),
            Goals = request.Goals.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            Allergies = request.Allergies.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            AvoidIngredients = request.AvoidIngredients.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            SkinGoals = request.SkinGoals.Where(x => !string.IsNullOrWhiteSpace(x)).Select(x => x.Trim()).Distinct(StringComparer.OrdinalIgnoreCase).ToList(),
            SkinTypeQuiz = request.SkinType?.Trim().ToLowerInvariant(),
            BudgetLevel = request.BudgetLevel?.Trim(),
            RednessWhenNewProducts = request.RednessWhenNewProducts?.Trim(),
            RednessWhenSunOrExercise = request.RednessWhenSunOrExercise?.Trim(),
            OnboardingCompleted = true
        };
    }

    private static int? TryGetBirthYear(string? dateOfBirth)
    {
        if (string.IsNullOrWhiteSpace(dateOfBirth))
        {
            return null;
        }

        return DateTime.TryParse(dateOfBirth, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var parsed)
            ? parsed.Year
            : null;
    }
}
