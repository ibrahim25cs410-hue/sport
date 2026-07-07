namespace Riyada.Domain.Entities;

public static class PaymentMethods
{
    public const string Cash = "cash";
    public const string Online = "online";

    public static bool IsValid(string? value) =>
        string.Equals(value, Cash, StringComparison.OrdinalIgnoreCase) ||
        string.Equals(value, Online, StringComparison.OrdinalIgnoreCase);

    public static string Normalize(string? value) =>
        string.Equals(value, Cash, StringComparison.OrdinalIgnoreCase) ? Cash : Online;
}
