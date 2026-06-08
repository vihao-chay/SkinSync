using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Models.Dtos.Skin;
using SkinSync.Services;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/[controller]")]
[AllowAnonymous]
public class SkinController : ControllerBase
{
    private readonly ISkinService _skinService;

    public SkinController(ISkinService skinService)
    {
        _skinService = skinService;
    }

    /// <summary>
    /// Vision-based skin analysis from an image URL (remote or local path).
    /// </summary>
    [HttpPost("analyze")]
    [ProducesResponseType(typeof(SkinAnalyzeResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Analyze([FromBody] SkinAnalyzeRequestDto request, CancellationToken cancellationToken)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest("Image URL is required.");
        }

        try
        {
            var result = await _skinService.AnalyzeSkinSync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (FileNotFoundException ex)
        {
            return NotFound(ex.Message);
        }
        catch (HttpRequestException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, $"Failed to retrieve the image: {ex.Message}");
        }
        catch (Exception ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, $"An error occurred during analysis: {ex.Message}");
        }
    }

    /// <summary>
    /// Skincare chat assistant providing safe skincare advice.
    /// </summary>
    [HttpPost("chat")]
    [ProducesResponseType(typeof(SkinChatResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Chat([FromBody] SkinChatRequestDto request, CancellationToken cancellationToken)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest("Message is required.");
        }

        try
        {
            var result = await _skinService.GetSkincareAdviceAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, $"An error occurred during chat: {ex.Message}");
        }
    }

    /// <summary>
    /// Routine builder that generates AM/PM skincare routines avoiding ingredient conflicts.
    /// </summary>
    [HttpPost("routine")]
    [ProducesResponseType(typeof(SkinRoutineResponseDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> Routine([FromBody] SkinRoutineRequestDto request, CancellationToken cancellationToken)
    {
        if (request == null)
        {
            return BadRequest("Routine parameters are required.");
        }

        if (string.IsNullOrWhiteSpace(request.SkinType))
        {
            return BadRequest("SkinType is required.");
        }

        try
        {
            var result = await _skinService.BuildRoutineAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, $"An error occurred during routine building: {ex.Message}");
        }
    }
}
