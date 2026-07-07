using Microsoft.AspNetCore.Identity;
using Riyada.Domain.Entities;

namespace Riyada.Infrastructure.Services;

public static class PasswordService
{
    private static readonly PasswordHasher<User> Hasher = new();

    public static string Hash(User user, string password) =>
        Hasher.HashPassword(user, password);

    public static bool Verify(User user, string password) =>
        Hasher.VerifyHashedPassword(user, user.PasswordHash, password)
            != PasswordVerificationResult.Failed;
}
