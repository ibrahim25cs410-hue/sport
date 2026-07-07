using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Riyada.Application.Common;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

/// <summary>Initializes Firebase Admin SDK once at application startup.</summary>
public static class FirebaseAppInitializer
{
    private static readonly object Gate = new();
    private static bool _initialized;

    public static void Initialize(IConfiguration config, ILogger logger)
    {
        if (_initialized) return;

        lock (Gate)
        {
            if (_initialized) return;
            if (FirebaseApp.DefaultInstance is not null)
            {
                _initialized = true;
                return;
            }

            try
            {
                var credential = ResolveCredential(config);
                if (credential is null)
                {
                    logger.LogWarning("FCM credentials not configured — push notifications disabled");
                    return;
                }

                FirebaseApp.Create(new AppOptions { Credential = credential });
                _initialized = true;
                logger.LogInformation("Firebase Admin SDK initialized for push notifications");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to initialize Firebase Admin SDK");
            }
        }
    }

    public static bool IsReady => FirebaseApp.DefaultInstance is not null;

    private static GoogleCredential? ResolveCredential(IConfiguration config)
    {
        var json = config["Fcm:CredentialsJson"];
        if (!string.IsNullOrWhiteSpace(json))
            return GoogleCredential.FromJson(json);

        var path = config["Fcm:CredentialsPath"]
            ?? Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");

        if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
            return GoogleCredential.FromFile(path);

        return null;
    }
}

/// <summary>FCM delivery, in-app notifications, device tokens, and push audit logs.</summary>
public sealed class NotificationService
{
    private readonly AppDbContext _db;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(AppDbContext db, ILogger<NotificationService> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task RegisterDeviceTokenAsync(int userId, string token, string? platform = null, CancellationToken ct = default)
    {
        token = token.Trim();
        if (string.IsNullOrWhiteSpace(token))
            throw new ArgumentException("Device token is required", nameof(token));

        var existing = await _db.DeviceTokens.FirstOrDefaultAsync(t => t.Token == token, ct);
        if (existing is not null)
        {
            existing.UserId = userId;
            existing.Platform = platform;
            existing.LastUpdated = DateTime.UtcNow;
        }
        else
        {
            _db.DeviceTokens.Add(new DeviceToken
            {
                UserId = userId,
                Token = token,
                Platform = platform,
                LastUpdated = DateTime.UtcNow
            });
        }

        var user = await _db.Users.FindAsync([userId], ct);
        if (user is not null)
            user.FcmToken = token;

        await _db.SaveChangesAsync(ct);
    }

    public Task NotifyOwnerAsync(int ownerId, string title, string body, string eventType, CancellationToken ct = default)
        => NotifyUserAsync(ownerId, title, body, eventType, ct);

    public async Task NotifyUserAsync(
        int userId, string title, string body, string eventType, CancellationToken ct = default)
    {
        await BookingService.NotifyAsync(_db, userId, title, body);

        var tokens = await ResolveDeviceTokensAsync(userId, ct);
        if (tokens.Count == 0)
        {
            _logger.LogDebug("No device tokens for user {UserId}", userId);
            return;
        }

        foreach (var token in tokens)
            await SendPushNotificationAsync(token, title, body, userId, eventType, ct);
    }

    /// <summary>Sends a single FCM message and records the outcome in <see cref="PushNotificationLog"/>.</summary>
    public async Task<bool> SendPushNotificationAsync(
        string deviceToken,
        string title,
        string body,
        int? userId = null,
        string? eventType = null,
        CancellationToken ct = default)
    {
        deviceToken = deviceToken.Trim();
        var log = new PushNotificationLog
        {
            UserId = userId,
            DeviceTokenPreview = MaskToken(deviceToken),
            Title = title,
            Body = body,
            EventType = eventType ?? string.Empty,
            Status = "pending",
            CreatedAt = DateTime.UtcNow
        };
        _db.PushNotificationLogs.Add(log);
        await _db.SaveChangesAsync(ct);

        if (!FirebaseAppInitializer.IsReady)
        {
            log.Status = "skipped";
            log.Error = "Firebase not initialized";
            await _db.SaveChangesAsync(ct);
            return false;
        }

        var message = new Message
        {
            Token = deviceToken,
            Notification = new FirebaseAdmin.Messaging.Notification { Title = title, Body = body },
            Data = new Dictionary<string, string>
            {
                ["title"] = title,
                ["body"] = body,
                ["type"] = eventType ?? "general"
            },
            Android = new AndroidConfig { Priority = Priority.High },
            Apns = new ApnsConfig
            {
                Aps = new Aps { Sound = "default", ContentAvailable = true }
            }
        };

        try
        {
            var messageId = await FirebaseMessaging.DefaultInstance.SendAsync(message, ct);
            log.Status = "sent";
            log.ProviderMessageId = messageId;
            await _db.SaveChangesAsync(ct);
            return true;
        }
        catch (FirebaseMessagingException ex) when (
            ex.MessagingErrorCode is MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument)
        {
            log.Status = "failed";
            log.Error = ex.MessagingErrorCode.ToString();
            await _db.SaveChangesAsync(ct);
            if (userId is not null && ex.MessagingErrorCode is { } code)
                await PruneTokenIfInvalidAsync(userId.Value, deviceToken, code, ct);
            return false;
        }
        catch (Exception ex)
        {
            log.Status = "failed";
            log.Error = ex.Message;
            await _db.SaveChangesAsync(ct);
            _logger.LogWarning(ex, "FCM send failed for user {UserId}", userId);
            return false;
        }
    }

    private async Task<List<string>> ResolveDeviceTokensAsync(int userId, CancellationToken ct)
    {
        var tokens = await _db.DeviceTokens.AsNoTracking()
            .Where(t => t.UserId == userId)
            .Select(t => t.Token)
            .ToListAsync(ct);

        var legacy = await _db.Users.AsNoTracking()
            .Where(u => u.Id == userId && u.FcmToken != null && u.FcmToken != "")
            .Select(u => u.FcmToken!)
            .FirstOrDefaultAsync(ct);

        if (legacy is not null && !tokens.Contains(legacy))
            tokens.Add(legacy);

        return tokens;
    }

    private async Task PruneTokenIfInvalidAsync(
        int userId, string token, MessagingErrorCode code, CancellationToken ct)
    {
        if (code is not (MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument))
            return;

        var rows = await _db.DeviceTokens
            .Where(t => t.UserId == userId && t.Token == token)
            .ToListAsync(ct);
        if (rows.Count > 0)
            _db.DeviceTokens.RemoveRange(rows);

        var user = await _db.Users.FindAsync([userId], ct);
        if (user?.FcmToken == token)
            user.FcmToken = null;

        await _db.SaveChangesAsync(ct);
    }

    private static string MaskToken(string token)
    {
        if (token.Length <= 8) return "****";
        return $"…{token[^8..]}";
    }
}
