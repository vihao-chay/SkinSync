using SkinSync.Models.Dtos.Skin;

namespace SkinSync.Services;

public interface ISkinService
{
    Task<SkinAnalyzeResponseDto> AnalyzeSkinSync(SkinAnalyzeRequestDto request, CancellationToken cancellationToken);
    Task<SkinChatResponseDto> GetSkincareAdviceAsync(SkinChatRequestDto request, CancellationToken cancellationToken);
    Task<SkinRoutineResponseDto> BuildRoutineAsync(SkinRoutineRequestDto request, CancellationToken cancellationToken);
}
