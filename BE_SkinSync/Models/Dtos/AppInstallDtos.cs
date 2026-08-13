namespace SkinSync.Models.Dtos;

public class AppInstallRecordRequestDto
{
    public string InstallationId { get; set; } = string.Empty;
    public string? Platform { get; set; }
    public string? AppVersion { get; set; }
}

public class AppInstallRecordResponseDto
{
    public bool Recorded { get; set; }
    public int TotalDownloads { get; set; }
}

public class AppInstallSummaryResponseDto
{
    public int TotalDownloads { get; set; }
}
