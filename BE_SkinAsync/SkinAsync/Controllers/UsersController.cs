using Microsoft.AspNetCore.Mvc;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos.Users;
using SkinAsync.Models.Entities;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _userRepository;

    public UsersController(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    [HttpPost("survey")]
    public async Task<IActionResult> SaveSurvey([FromHeader(Name = "Id")] Guid id, [FromBody] SurveyRequestDto request, CancellationToken cancellationToken)
    {
        if (id == Guid.Empty)
        {
            return BadRequest("Missing Id header.");
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return NotFound("User not found.");
        }

        var profile = new UserProfile
        {
            UserId = id,
            SkinType = request.SkinType.Trim(),
            SkinConcerns = request.SkinConcerns,
            MonthlyBudget = request.MonthlyBudget.Trim(),
            Age = request.Age,
            BirthYear = request.BirthYear
        };

        await _userRepository.UpsertProfileAsync(profile, cancellationToken);
        return Ok(profile.ToSurveyDto());
    }
}
