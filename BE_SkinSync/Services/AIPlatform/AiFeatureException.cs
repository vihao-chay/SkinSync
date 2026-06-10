namespace SkinSync.Services.AIPlatform;

public class AiFeatureException : Exception
{
    public AiFeatureException(string code, string message, int statusCode = 400, Exception? innerException = null)
        : base(message, innerException)
    {
        Code = code;
        StatusCode = statusCode;
    }

    public string Code { get; }
    public int StatusCode { get; }
}
