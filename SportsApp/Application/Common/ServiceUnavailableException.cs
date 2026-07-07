namespace Riyada.Application.Common;

public sealed class ServiceUnavailableException : Exception
{
    public const string ErrorCode = "SERVICE_UNAVAILABLE";

    public ServiceUnavailableException(string message = "Service temporarily unavailable. Please try again.")
        : base(message)
    {
    }
}
