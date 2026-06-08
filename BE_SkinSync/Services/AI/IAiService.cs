using SkinSync.Models.Dtos.Skin;

namespace SkinSync.Services.AI;

public interface IAiService
{
    Task<SkinAnalyzeResponseDto> AnalyzeSkinSync(byte[] imageBytes, string contentType, CancellationToken cancellationToken);
    Task<SkinChatResponseDto> GetSkincareAdviceAsync(string message, UserSkinProfileDto? userProfile, CancellationToken cancellationToken);
    Task<SkinRoutineResponseDto> BuildRoutineAsync(SkinRoutineRequestDto request, string systemInstructions, CancellationToken cancellationToken);
}
