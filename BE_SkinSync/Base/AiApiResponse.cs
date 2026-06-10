using Microsoft.AspNetCore.Mvc;

namespace SkinSync.Base;

public class AiApiResponse<T> : IActionResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public IReadOnlyCollection<AiApiError> Errors { get; set; } = Array.Empty<AiApiError>();
    public string RequestId { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public int StatusCode { get; set; } = 200;

    public static AiApiResponse<T> Ok(T data, string message, string requestId)
    {
        return new AiApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            RequestId = requestId,
            Timestamp = DateTime.UtcNow,
            StatusCode = 200
        };
    }

    public static AiApiResponse<T> Fail(
        string message,
        string requestId,
        int statusCode,
        params AiApiError[] errors)
    {
        return new AiApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = default,
            Errors = errors,
            RequestId = requestId,
            Timestamp = DateTime.UtcNow,
            StatusCode = statusCode
        };
    }

    public async Task ExecuteResultAsync(ActionContext context)
    {
        var objectResult = new ObjectResult(this)
        {
            StatusCode = StatusCode
        };

        await objectResult.ExecuteResultAsync(context);
    }
}

public class AiApiError
{
    public string Code { get; set; } = string.Empty;
    public string Detail { get; set; } = string.Empty;
}
