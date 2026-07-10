using System.Security.Claims;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Riyada.Api.Hubs;
using Riyada.Api.Middleware;
using Riyada.Api.Security;
using Riyada.Api.Services;
using Riyada.Application.Abstractions;
using Riyada.Application.Common;
using Riyada.Application.DTOs;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;
using Riyada.Infrastructure.PaymentGateways;
using Riyada.Infrastructure.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRiyadaDatabase(builder.Configuration);

builder.Services.AddSingleton<JwtService>();

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key is required.");
if (!builder.Environment.IsDevelopment())
{
    const string devDefaultKey = "Riyada-Flutter-MVP-Secret-Key-32-Chars-Min!";
    if (jwtKey == devDefaultKey || jwtKey.Length < 32)
        throw new InvalidOperationException(
            "Production requires a strong Jwt:Key (min 32 chars) via environment — not the dev default.");
}
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true, ValidateAudience = true, ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
        opt.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
                    context.Token = accessToken;
                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddSignalR()
    .AddJsonProtocol(o => o.PayloadSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase);
builder.Services.AddSingleton<IBookingRealtimePublisher, BookingRealtimePublisher>();
builder.Services.AddSingleton<SlotLockService>();
builder.Services.AddSingleton<FieldPrefetchCache>();
builder.Services.AddScoped<OwnerPaymentService>();
builder.Services.AddScoped<UserBookingPaymentService>();
builder.Services.AddScoped<WalletService>();
builder.Services.AddScoped<CommissionService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddHttpClient("ZainCash");
builder.Services.AddHttpClient("CardGateway");
builder.Services.AddSingleton<IPaymentGatewayVerifier, ZainCashGatewayVerifier>();
builder.Services.AddSingleton<IPaymentGatewayVerifier, CardGatewayVerifier>();
builder.Services.AddSingleton<IPaymentGatewayVerifierRouter, PaymentGatewayVerifierRouter>();
builder.Services.AddRiyadaRateLimiting(builder.Configuration);
builder.Services.AddHostedService<RiyadaBackgroundService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Riyada API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization", Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }, [] }
    });
});
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
{
    var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    if (builder.Environment.IsDevelopment() && origins.Length == 0)
    {
        p.SetIsOriginAllowed(_ => true)
         .AllowAnyMethod()
         .AllowAnyHeader()
         .AllowCredentials();
        return;
    }

    if (origins.Length == 0)
        origins = ["https://riyada.iq", "https://www.riyada.iq", "https://app.riyada.iq"];

    p.WithOrigins(origins)
     .AllowAnyMethod()
     .AllowAnyHeader()
     .AllowCredentials();
}));

builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    o.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});

var app = builder.Build();

FirebaseAppInitializer.Initialize(app.Configuration, app.Logger);

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    var providerInfo = scope.ServiceProvider.GetRequiredService<DatabaseProviderInfo>();
    await DatabaseInitializer.InitializeAsync(db, logger, providerInfo);
}

app.UseGlobalExceptionHandler();
app.UseRequestLogging();
app.UseCors();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();

app.MapHub<BookingHub>("/hubs/booking");

static int UserId(ClaimsPrincipal u) => int.Parse(u.FindFirstValue(ClaimTypes.NameIdentifier)!);

static bool IsAdmin(ClaimsPrincipal u) =>
    string.Equals(u.FindFirstValue(ClaimTypes.Role), "admin", StringComparison.OrdinalIgnoreCase);

static object BookingActionResult(Booking b) => new
{
    b.Id,
    b.Status,
    b.ReferenceCode,
    b.StartTime,
    b.Hours,
    b.TotalPrice
};

static Task PushBookingEventAsync(
    IBookingRealtimePublisher realtime,
    int targetUserId,
    int bookingId,
    string status,
    string titleKey,
    string messageKey,
    Dictionary<string, string> messageArgs) =>
    realtime.PublishBookingUpdatedAsync(targetUserId, new BookingUpdatedEvent(
        bookingId, status, titleKey, messageKey, messageArgs));

static BookingUpdatedEvent BuildBookingEvent(
    int bookingId,
    string status,
    string titleKey,
    string messageKey,
    Dictionary<string, string> messageArgs) =>
    new(bookingId, status, titleKey, messageKey, messageArgs);

static async Task BroadcastBookingAsync(
    IBookingRealtimePublisher realtime,
    int? targetUserId,
    int? fieldId,
    BookingUpdatedEvent payload)
{
    var tasks = new List<Task>(2);
    if (targetUserId.HasValue)
        tasks.Add(realtime.PublishBookingUpdatedAsync(targetUserId.Value, payload));
    if (fieldId.HasValue)
        tasks.Add(realtime.PublishFieldBookingUpdatedAsync(fieldId.Value, payload));
    if (tasks.Count > 0)
        await Task.WhenAll(tasks);
}

app.MapGet("/api/health", async (AppDbContext db) =>
{
    var dbOk = false;
    try
    {
        dbOk = await db.Database.CanConnectAsync();
    }
    catch { /* ignore */ }

    var payload = new ApiInfoDto(
        "Riyada API", "1.0.0",
        dbOk ? "healthy" : "degraded",
        dbOk,
        DateTime.UtcNow);

    return dbOk
        ? Results.Ok(payload)
        : Results.Json(
            new { message = "Service temporarily unavailable. Please try again.", code = ServiceUnavailableException.ErrorCode, api = payload },
            statusCode: StatusCodes.Status503ServiceUnavailable);
});

// ── Auth ──
app.MapPost("/api/register-user", async (AppDbContext db, JwtService jwt, RegisterUserRequest req) =>
{
    if (!BookingService.IsValidProvince(req.Province))
        return Results.BadRequest(new { message = "المحافظة: نينوى فقط" });
    var email = req.Email.Trim().ToLower();
    if (await db.Users.AnyAsync(u => u.Email == email))
        return Results.BadRequest(new { message = "البريد مستخدم" });

    var user = new User
    {
        Name = req.Name.Trim(), Email = email, Phone = req.Phone.Trim(),
        Province = "نينوى", Image = req.Image, Role = "user"
    };
    user.PasswordHash = PasswordService.Hash(user, req.Password);
    db.Users.Add(user);
    await db.SaveChangesAsync();
    return Results.Ok(new { token = jwt.CreateToken(user), user = DtoMapper.ToDto(user) });
}).RequireRateLimiting(RateLimitingExtensions.AuthPolicy);

app.MapPost("/api/register-owner", async (AppDbContext db, JwtService jwt, RegisterOwnerRequest req) =>
{
    var email = req.Email.Trim().ToLower();
    if (await db.Users.AnyAsync(u => u.Email == email))
        return Results.BadRequest(new { message = "البريد مستخدم" });

    var owner = new User
    {
        Name = req.Name.Trim(), Email = email, Phone = req.Phone.Trim(),
        Province = "نينوى", Role = "owner"
    };
    owner.PasswordHash = PasswordService.Hash(owner, req.Password);
    db.Users.Add(owner);
    await db.SaveChangesAsync();

    var field = new Field
    {
        OwnerId = owner.Id, Name = req.StadiumName.Trim(), Address = req.StadiumAddress.Trim(),
        Phone = req.StadiumPhone.Trim(), Image = req.StadiumImage,
        PricePerHour = req.PricePerHour, BasePrice = req.PricePerHour
    };
    db.Fields.Add(field);
    db.Wallets.Add(new Wallet { OwnerId = owner.Id, Balance = 0, LastUpdated = DateTime.UtcNow });
    await db.SaveChangesAsync();
    var fd = DtoMapper.ToDto(field);
    return Results.Ok(new { token = jwt.CreateToken(owner), user = DtoMapper.ToDto(owner), field = fd, stadium = fd });
}).RequireRateLimiting(RateLimitingExtensions.AuthPolicy);

app.MapPost("/api/login", async (AppDbContext db, JwtService jwt, LoginRequest req) =>
{
    var email = req.Email.Trim().ToLower();
    var user = await db.Users.FirstOrDefaultAsync(u => u.Email == email);
    if (user is null || !PasswordService.Verify(user, req.Password))
        return Results.Json(new { message = "عذراً، المعلومات غير صحيحة" }, statusCode: 401);

    if (CancellationAbuseRules.IsBanned(user))
        return Results.Json(
            new { message = CancellationAbuseRules.BanErrorMessage, code = "account_restricted" },
            statusCode: 403);

    var dto = DtoMapper.ToDto(user);
    var token = jwt.CreateToken(user);
    if (user.Role == "owner")
    {
        var field = await db.Fields.FirstOrDefaultAsync(f => f.OwnerId == user.Id && f.IsActive);
        var fd = field is not null ? DtoMapper.ToDto(field) : null;
        return Results.Ok(new { token, user = dto, field = fd, stadium = fd });
    }
    return Results.Ok(new { token, user = dto });
}).RequireRateLimiting(RateLimitingExtensions.AuthPolicy);

app.MapGet("/api/me", async (ClaimsPrincipal p, AppDbContext db) =>
{
    var uid = UserId(p);
    var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == uid);
    if (user is null) return Results.NotFound();
    var dto = DtoMapper.ToDto(user);
    if (user.Role == "owner")
    {
        var field = await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.OwnerId == user.Id && f.IsActive);
        var fd = field is not null ? DtoMapper.ToDto(field) : null;
        return Results.Ok(new { user = dto, field = fd, stadium = fd });
    }
    return Results.Ok(new { user = dto });
}).RequireAuthorization();

app.MapPut("/api/me", async (ClaimsPrincipal p, AppDbContext db, UpdateProfileRequest req) =>
{
    var uid = UserId(p);
    var user = await db.Users.FindAsync(uid);
    if (user is null) return Results.NotFound();
    user.Name = req.Name.Trim();
    user.Phone = req.Phone.Trim();
    if (req.Image is not null) user.Image = req.Image;
    if (!string.IsNullOrWhiteSpace(req.Password))
        user.PasswordHash = PasswordService.Hash(user, req.Password);
    await db.SaveChangesAsync();
    return Results.Ok(DtoMapper.ToDto(user));
}).RequireAuthorization();

// ── Fields ──
async Task<IResult> ListFields(AppDbContext db, int? page, int? limit)
{
    var (p, l, explicitPaging) = Pagination.Parse(page, limit);
    // Active fields are listed immediately for users — wallet balance only gates bookings.
    var query = db.Fields.AsNoTracking().Where(f => f.IsActive);

    var total = await query.CountAsync();
    var take = explicitPaging ? l : Pagination.LegacyMaxItems;
    var skip = explicitPaging ? (p - 1) * l : 0;

    var list = await query
        .OrderBy(f => f.Name)
        .Skip(skip)
        .Take(take)
        .Select(f => new FieldDto(
            f.Id, f.Name, f.Address, f.Phone, f.Image, f.PricePerHour, f.OwnerId,
            f.Reviews.Any() ? f.Reviews.Average(r => (double)r.Rating) : 0,
            f.Reviews.Count(),
            f.Latitude,
            f.Longitude))
        .ToListAsync();

    if (!explicitPaging) return Results.Ok(list);

    return Results.Ok(new PagedResult<FieldDto>(list, p, l, total, skip + list.Count < total));
}

async Task<IResult> FieldSchedule(AppDbContext db, SlotLockService locks, FieldPrefetchCache prefetch, int id)
{
    prefetch.RecordScheduleRequest(id);
    var field = await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.Id == id);
    if (field is null) return Results.NotFound();
    var (avg, count) = await ReviewService.GetFieldRatingAsync(db, id);
    var bookings = await db.Bookings.AsNoTracking()
        .Where(b => b.FieldId == id && b.Status != "cancelled" && b.Status != "rejected")
        .Where(b => b.StartTime >= DateTime.Today && b.StartTime < DateTime.Today.AddDays(7))
        .ToListAsync();
    return Results.Ok(new
    {
        field.Id,
        field.Name,
        field.PricePerHour,
        field.Address,
        field.Phone,
        field.Latitude,
        field.Longitude,
        averageRating = avg,
        reviewCount = count,
        schedule = BookingService.BuildWeekSchedule(id, bookings, locks)
    });
}

async Task<IResult> GetField(AppDbContext db, int id)
{
    var field = await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.Id == id && f.IsActive);
    if (field is null) return Results.NotFound();
    var (avg, count) = await ReviewService.GetFieldRatingAsync(db, id);
    return Results.Ok(DtoMapper.ToDto(field, avg, count));
}

app.MapGet("/api/fields", ListFields);
app.MapGet("/api/fields/{id:int}", GetField);
app.MapGet("/api/fields/{id:int}/schedule", FieldSchedule);
app.MapGet("/api/stadiums", ListFields);
app.MapGet("/api/stadiums/{id:int}/schedule", FieldSchedule);

app.MapPost("/api/fields", async (ClaimsPrincipal p, AppDbContext db, CreateFieldRequest req) =>
{
    var ownerId = UserId(p);
    var owner = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == ownerId);
    if (owner is null || owner.Role != "owner")
        return Results.Json(new { message = "غير مصرح — لأصحاب الملاعب فقط" }, statusCode: 403);
    if (string.IsNullOrWhiteSpace(req.Name) || string.IsNullOrWhiteSpace(req.Address) || string.IsNullOrWhiteSpace(req.Phone))
        return Results.BadRequest(new { message = "اسم الملعب والعنوان والهاتف مطلوبة" });
    if (req.PricePerHour < 1000) return Results.BadRequest(new { message = "السعر غير صالح" });

    var field = new Field
    {
        OwnerId = ownerId,
        Name = req.Name.Trim(),
        Address = req.Address.Trim(),
        Phone = req.Phone.Trim(),
        Image = req.Image,
        PricePerHour = req.PricePerHour,
        BasePrice = req.PricePerHour,
        IsActive = true,
        Latitude = req.Latitude,
        Longitude = req.Longitude,
    };
    db.Fields.Add(field);

    if (!await db.Wallets.AnyAsync(w => w.OwnerId == ownerId))
        db.Wallets.Add(new Wallet { OwnerId = ownerId, Balance = 0, LastUpdated = DateTime.UtcNow });

    await db.SaveChangesAsync();
    return Results.Ok(DtoMapper.ToDto(field));
}).RequireAuthorization();

app.MapPut("/api/fields/{id:int}", async (ClaimsPrincipal p, AppDbContext db, int id, UpdateFieldRequest req) =>
{
    var field = await db.Fields.FindAsync(id);
    if (field is null) return Results.NotFound();
    if (field.OwnerId != UserId(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    if (req.PricePerHour < 1000) return Results.BadRequest(new { message = "السعر غير صالح" });

    field.Name = req.Name.Trim();
    field.Address = req.Address.Trim();
    field.Phone = req.Phone.Trim();
    if (req.Image is not null) field.Image = req.Image;
    field.PricePerHour = req.PricePerHour;
    field.BasePrice = req.PricePerHour;
    await db.SaveChangesAsync();
    var (avg, count) = await ReviewService.GetFieldRatingAsync(db, id);
    return Results.Ok(DtoMapper.ToDto(field, avg, count));
}).RequireAuthorization();

// ── Slot selection (competitive booking) ──
app.MapPost("/api/slots/select", async (
    ClaimsPrincipal p,
    SlotLockService locks,
    IBookingRealtimePublisher realtime,
    SelectSlotRequest req) =>
{
    var uid = UserId(p);
    if (locks.IsHeldByOther(req.FieldId, req.StartTime, req.Hours, uid))
        return Results.Conflict(new { code = "ConflictError", messageKey = "slotUnderSelection" });

    if (!locks.TryAcquire(req.FieldId, req.StartTime, req.Hours, uid))
        return Results.Conflict(new { code = "ConflictError", messageKey = "slotUnderSelection" });

    var entry = locks.Get(req.FieldId, req.StartTime, req.Hours)!;
    var evt = new SlotSelectionEvent(req.FieldId, req.StartTime, req.Hours, uid, entry.ExpiresAt);
    await realtime.PublishSlotSelectionAsync(req.FieldId, evt);
    return Results.Ok(new { expiresAt = entry.ExpiresAt });
}).RequireAuthorization();

app.MapPost("/api/slots/release", async (
    ClaimsPrincipal p,
    SlotLockService locks,
    IBookingRealtimePublisher realtime,
    ReleaseSlotRequest req) =>
{
    var uid = UserId(p);
    locks.Release(req.FieldId, req.StartTime, req.Hours, uid);
    await realtime.PublishSlotReleaseAsync(req.FieldId, new SlotReleaseEvent(req.FieldId, req.StartTime, req.Hours));
    return Results.Ok();
}).RequireAuthorization();

// ── Bookings ──
app.MapPost("/api/bookings", async (
    ClaimsPrincipal p,
    AppDbContext db,
    SlotLockService locks,
    WalletService wallets,
    IBookingRealtimePublisher realtime,
    IServiceScopeFactory scopeFactory,
    CreateBookingRequest req) =>
{
    var uid = UserId(p);
    var user = await db.Users.FindAsync(uid);
    if (user?.Role != "user") return Results.BadRequest(new { message = "للمستخدمين فقط" });

    var field = await db.Fields.FindAsync(req.FieldId);
    if (field is null) return Results.NotFound();

    if (!await wallets.IsOwnerEligibleForBookingsAsync(db, field.OwnerId))
        return Results.BadRequest(new { code = "OwnerWalletBlocked", message = "الملعب غير متاح — رصيد المالك غير كافٍ" });

    var method = PaymentMethods.IsValid(req.PaymentMethod)
        ? PaymentMethods.Normalize(req.PaymentMethod)
        : PaymentMethods.Online;

    var basePrice = BookingService.ResolveBasePrice(field);
    var quote = BookingService.CalculatePrice(basePrice, req.StartTime, req.Hours, user.LoyaltyPoints);

    var (booking, err, code) = await BookingService.TryCreateBookingWithLockAsync(
        db, locks, uid, req.FieldId, req.StartTime, req.Hours, basePrice, user.LoyaltyPoints, method);
    if (code == "ConflictError")
        return Results.Conflict(new { code = "ConflictError", messageKey = "slotJustBooked" });
    if (err is not null) return Results.BadRequest(new { message = err });

    var refCode = booking!.ReferenceCode ?? "";
    var dateTime = req.StartTime.ToString("yyyy-MM-dd HH:mm");
    var ownerArgs = new Dictionary<string, string>
    {
        ["userName"] = user.Name,
        ["dateTime"] = dateTime,
        ["referenceCode"] = refCode,
        ["fieldName"] = field.Name
    };
    var ownerEvent = BuildBookingEvent(booking.Id, booking.Status, "rtTitleNewBooking", "rtMsgNewBooking", ownerArgs);
    var userEvent = BuildBookingEvent(booking.Id, booking.Status, "rtTitleBookingPending", "rtMsgBookingPending", ownerArgs);

    await Task.WhenAll(
        realtime.PublishSlotReleaseAsync(req.FieldId, new SlotReleaseEvent(req.FieldId, req.StartTime, req.Hours)),
        realtime.PublishBookingUpdatedAsync(field.OwnerId, ownerEvent),
        realtime.PublishFieldBookingUpdatedAsync(req.FieldId, ownerEvent),
        realtime.PublishBookingUpdatedAsync(uid, userEvent));

    BookingService.QueueNotifyOwner(
        scopeFactory,
        field.OwnerId,
        PushNotificationMessages.DefaultTitle,
        PushNotificationMessages.NewBookingForOwner(field.Name),
        PushNotificationEventTypes.BookingPending);

    return Results.Ok(new CreateBookingResponse(
        booking.Id,
        booking.ReferenceCode,
        booking.Status,
        booking.PaymentStatus,
        booking.PaymentMethod,
        booking.StartTime,
        booking.Hours,
        booking.TotalPrice,
        booking.DiscountAmount,
        booking.IsDiscountApplied,
        quote.HourlyRate,
        user.LoyaltyPoints));
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.BookingsWritePolicy);

app.MapPost("/api/bookings/approve", async (
    ClaimsPrincipal p,
    AppDbContext db,
    CommissionService commission,
    IBookingRealtimePublisher realtime,
    IServiceScopeFactory scopeFactory,
    BookingActionRequest req) =>
{
    var oid = UserId(p);
    var b = await db.Bookings.Include(x => x.Field).Include(x => x.User).FirstOrDefaultAsync(x => x.Id == req.BookingId);
    if (b is null) return Results.NotFound();
    if (b.Field?.OwnerId != oid) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var (ok, err, changed) = await BookingService.TryApproveBookingAsync(db, b, commission, oid);
    if (!ok) return Results.BadRequest(new { message = err });
    if (!changed) return Results.Ok(BookingActionResult(b));

    var args = new Dictionary<string, string>
    {
        ["fieldName"] = b.Field?.Name ?? "",
        ["referenceCode"] = b.ReferenceCode ?? "",
        ["dateTime"] = b.StartTime.ToString("yyyy-MM-dd HH:mm")
    };
    var payload = BuildBookingEvent(b.Id, "approved", "rtTitleBookingApproved", "rtMsgBookingApproved", args);
    await BroadcastBookingAsync(realtime, b.UserId, b.FieldId, payload);
    await realtime.PublishSlotReleaseAsync(b.FieldId, new SlotReleaseEvent(b.FieldId, b.StartTime, b.Hours));

    BookingService.QueueNotifyUser(
        scopeFactory,
        b.UserId,
        PushNotificationMessages.BookingApprovedTitle,
        PushNotificationMessages.BookingApprovedBody,
        PushNotificationEventTypes.BookingApproved);

    return Results.Ok(BookingActionResult(b));
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.BookingsWritePolicy);

app.MapPost("/api/bookings/reject", async (
    ClaimsPrincipal p,
    AppDbContext db,
    IBookingRealtimePublisher realtime,
    IServiceScopeFactory scopeFactory,
    BookingActionRequest req) =>
{
    var oid = UserId(p);
    var b = await db.Bookings.Include(x => x.Field).FirstOrDefaultAsync(x => x.Id == req.BookingId);
    if (b is null) return Results.NotFound();
    if (b.Field?.OwnerId != oid) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    if (b.Status == "rejected") return Results.Ok(BookingActionResult(b));
    if (b.Status != "pending") return Results.BadRequest(new { message = "لا يمكن رفض هذا الحجز" });

    b.Status = "rejected";
    await db.SaveChangesAsync();
    var args = new Dictionary<string, string>
    {
        ["fieldName"] = b.Field?.Name ?? "",
        ["referenceCode"] = b.ReferenceCode ?? ""
    };
    var payload = BuildBookingEvent(b.Id, "rejected", "rtTitleBookingRejected", "rtMsgBookingRejected", args);
    await BroadcastBookingAsync(realtime, b.UserId, b.FieldId, payload);
    await realtime.PublishSlotReleaseAsync(b.FieldId, new SlotReleaseEvent(b.FieldId, b.StartTime, b.Hours));

    BookingService.QueueNotifyUser(
        scopeFactory,
        b.UserId,
        PushNotificationMessages.BookingRejectedTitle,
        PushNotificationMessages.BookingRejectedBody,
        PushNotificationEventTypes.BookingRejected);

    return Results.Ok(BookingActionResult(b));
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.BookingsWritePolicy);

app.MapPost("/api/bookings/cancel", async (
    ClaimsPrincipal p,
    AppDbContext db,
    WalletService wallets,
    IBookingRealtimePublisher realtime,
    IServiceScopeFactory scopeFactory,
    CancelBookingRequest req) =>
{
    var uid = UserId(p);
    var b = await db.Bookings.Include(x => x.Field).FirstOrDefaultAsync(x => x.Id == req.BookingId && x.UserId == uid);
    if (b is null) return Results.NotFound();
    if (b.Status is not ("pending" or "approved")) return Results.BadRequest(new { message = "لا يمكن الإلغاء" });

    var user = await db.Users.FirstOrDefaultAsync(x => x.Id == uid);
    if (user is null) return Results.NotFound();

    var (cancelOk, cancelErr, outcome, pushKind) = await BookingService.TryCancelBookingAsync(db, wallets, b, user);
    if (!cancelOk)
    {
        if (pushKind == CancellationPushKind.AccountRestricted)
        {
            BookingService.QueueNotifyUser(
                scopeFactory,
                uid,
                "Account restricted",
                CancellationAbuseRules.BanErrorMessage,
                PushNotificationEventTypes.AccountRestricted);
        }

        var code = cancelErr == CancellationAbuseRules.BanErrorMessage ? "account_restricted" : null;
        return Results.BadRequest(new { message = cancelErr ?? "لا يمكن الإلغاء", code });
    }

    if (pushKind == CancellationPushKind.AbuseWarning)
    {
        BookingService.QueueNotifyUser(
            scopeFactory,
            uid,
            CancellationAbuseRules.WarningTitle,
            CancellationAbuseRules.WarningMessage,
            PushNotificationEventTypes.CancellationAbuseWarning);
    }

    var userArgs = new Dictionary<string, string>
    {
        ["dateTime"] = b.StartTime.ToString("yyyy-MM-dd HH:mm"),
        ["fieldName"] = b.Field?.Name ?? "",
        ["referenceCode"] = b.ReferenceCode ?? ""
    };
    var payload = BuildBookingEvent(b.Id, "cancelled", "rtTitleBookingCancelled", "rtMsgBookingCancelled", userArgs);

    if (b.Field is not null)
    {
        await Task.WhenAll(
            realtime.PublishBookingUpdatedAsync(b.Field.OwnerId, payload),
            realtime.PublishBookingUpdatedAsync(uid, payload),
            realtime.PublishFieldBookingUpdatedAsync(b.FieldId, payload),
            realtime.PublishSlotReleaseAsync(b.FieldId, new SlotReleaseEvent(b.FieldId, b.StartTime, b.Hours)));
        BookingService.QueueNotifyOwner(
            scopeFactory,
            b.Field.OwnerId,
            PushNotificationMessages.BookingCancelledOwnerTitle,
            PushNotificationMessages.BookingCancelledOwnerBody,
            PushNotificationEventTypes.BookingCancelled);
    }
    else
    {
        await PushBookingEventAsync(realtime, uid, b.Id, "cancelled",
            "rtTitleBookingCancelled", "rtMsgBookingCancelled", userArgs);
    }

    var o = outcome!;
    var tier = o.Tier == CancellationTier.LatePenalty ? "late_penalty" : "free";
    var message = o.Tier == CancellationTier.LatePenalty
        ? $"تم الإلغاء — غرامة {o.PenaltyIqd:N0} د.ع"
        : "تم الإلغاء";

    return Results.Ok(new CancelBookingResponse(message, tier, o.PenaltyIqd, o.OwnerShareIqd, o.PlatformShareIqd));
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.BookingsWritePolicy);

app.MapGet("/api/bookings/user/{userId:int}", async (ClaimsPrincipal p, AppDbContext db, int userId, int? page, int? limit) =>
{
    if (UserId(p) != userId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    var (pg, l, explicitPaging) = Pagination.Parse(page, limit);
    var query = db.Bookings.AsNoTracking().Include(b => b.Field)
        .Where(b => b.UserId == userId && b.Status != "cancelled" && b.Status != "rejected")
        .OrderBy(b => b.StartTime);

    var total = await query.CountAsync();
    var take = explicitPaging ? l : Pagination.LegacyMaxItems;
    var skip = explicitPaging ? (pg - 1) * l : 0;
    var list = await query.Skip(skip).Take(take).ToListAsync();

    ActiveBookingDto Map(Booking b) => new(
        b.Id, b.ReferenceCode, b.Field?.Name ?? "", b.Field?.Phone ?? "", b.Field?.Image, b.Field?.Address ?? "",
        b.StartTime, b.EndTime != default ? b.EndTime : BookingService.EndTime(b.StartTime, b.Hours),
        b.Hours, b.TotalPrice, b.Status, b.PaymentStatus,
        BookingService.RemainingHours(b.StartTime, b.EndTime != default ? b.EndTime : BookingService.EndTime(b.StartTime, b.Hours)),
        BookingService.CanCancelBooking(b.Status, b.StartTime));

    if (!explicitPaging) return Results.Ok(list.Select(Map));
    return Results.Ok(new PagedResult<ActiveBookingDto>(list.Select(Map).ToList(), pg, l, total, skip + list.Count < total));
}).RequireAuthorization();

app.MapGet("/api/bookings/user/{userId:int}/history", async (ClaimsPrincipal p, AppDbContext db, int userId, int? page, int? limit) =>
{
    if (UserId(p) != userId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    var (pg, l, explicitPaging) = Pagination.Parse(page, limit);
    var query = db.Bookings.AsNoTracking().Include(b => b.Field)
        .Where(b => b.UserId == userId)
        .OrderByDescending(b => b.StartTime);

    var total = await query.CountAsync();
    var take = explicitPaging ? l : Pagination.LegacyMaxItems;
    var skip = explicitPaging ? (pg - 1) * l : 0;
    var list = await query.Skip(skip).Take(take).ToListAsync();

    ActiveBookingDto Map(Booking b) => new(
        b.Id, b.ReferenceCode, b.Field?.Name ?? "", b.Field?.Phone ?? "", b.Field?.Image, b.Field?.Address ?? "",
        b.StartTime, b.EndTime != default ? b.EndTime : BookingService.EndTime(b.StartTime, b.Hours),
        b.Hours, b.TotalPrice, b.Status, b.PaymentStatus,
        BookingService.RemainingHours(b.StartTime, b.EndTime != default ? b.EndTime : BookingService.EndTime(b.StartTime, b.Hours)),
        BookingService.CanCancelBooking(b.Status, b.StartTime));

    if (!explicitPaging) return Results.Ok(list.Select(Map));
    return Results.Ok(new PagedResult<ActiveBookingDto>(list.Select(Map).ToList(), pg, l, total, skip + list.Count < total));
}).RequireAuthorization();

// ── Reviews ──
app.MapGet("/api/fields/{fieldId:int}/reviews", async (AppDbContext db, int fieldId) =>
{
    if (!await db.Fields.AsNoTracking().AnyAsync(f => f.Id == fieldId && f.IsActive))
        return Results.NotFound();
    var list = await db.Reviews.AsNoTracking().Include(r => r.User)
        .Where(r => r.FieldId == fieldId)
        .OrderByDescending(r => r.CreatedAt)
        .Take(50)
        .Select(r => new ReviewDto(r.Id, r.UserId, r.User!.Name, r.Rating, r.Comment, r.CreatedAt))
        .ToListAsync();
    return Results.Ok(list);
});

app.MapGet("/api/fields/{fieldId:int}/review-eligibility", async (ClaimsPrincipal p, AppDbContext db, int fieldId) =>
{
    var uid = UserId(p);
    if (!await db.Fields.AsNoTracking().AnyAsync(f => f.Id == fieldId && f.IsActive))
        return Results.NotFound();
    var hasBooked = await ReviewService.HasBookedFieldAsync(db, uid, fieldId);
    var userRating = await db.Reviews.AsNoTracking()
        .Where(r => r.FieldId == fieldId && r.UserId == uid)
        .Select(r => (int?)r.Rating)
        .FirstOrDefaultAsync();
    var (avg, count) = await ReviewService.GetFieldRatingAsync(db, fieldId);
    return Results.Ok(new FieldReviewEligibilityDto(hasBooked && userRating is null, hasBooked, userRating, avg, count));
}).RequireAuthorization();

app.MapPost("/api/fields/{fieldId:int}/reviews", async (ClaimsPrincipal p, AppDbContext db, int fieldId, SubmitReviewRequest req) =>
{
    var uid = UserId(p);
    if (!ReviewService.IsValidRating(req.Rating))
        return Results.BadRequest(new { message = "التقييم يجب أن يكون بين 1 و 5" });
    if (!await db.Fields.AsNoTracking().AnyAsync(f => f.Id == fieldId && f.IsActive))
        return Results.NotFound();
    if (!await ReviewService.HasBookedFieldAsync(db, uid, fieldId))
        return Results.Json(new { message = "يمكنك التقييم بعد حجز الملعب والموافقة عليه" }, statusCode: 403);
    if (await db.Reviews.AnyAsync(r => r.FieldId == fieldId && r.UserId == uid))
        return Results.Conflict(new { message = "لقد قيّمت هذا الملعب مسبقاً" });

    var review = new Review
    {
        UserId = uid,
        FieldId = fieldId,
        Rating = req.Rating,
        Comment = string.IsNullOrWhiteSpace(req.Comment) ? null : req.Comment.Trim(),
        CreatedAt = DateTime.UtcNow
    };
    db.Reviews.Add(review);
    await db.SaveChangesAsync();
    var (avg, count) = await ReviewService.GetFieldRatingAsync(db, fieldId);
    return Results.Ok(new { review = new ReviewDto(review.Id, uid, "", review.Rating, review.Comment, review.CreatedAt), averageRating = avg, reviewCount = count });
}).RequireAuthorization();

app.MapGet("/api/bookings/owner/{ownerId:int}", async (ClaimsPrincipal p, AppDbContext db, int ownerId, int? page, int? limit) =>
{
    if (UserId(p) != ownerId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    var fields = await db.Fields.AsNoTracking().Where(f => f.OwnerId == ownerId).OrderBy(f => f.Id).ToListAsync();
    if (fields.Count == 0) return Results.NotFound();
    var fieldIds = fields.Select(f => f.Id).ToList();
    var primary = fields[0];

    var allBookings = await db.Bookings.AsNoTracking().Include(b => b.User)
        .Where(b => fieldIds.Contains(b.FieldId))
        .OrderByDescending(b => b.StartTime)
        .ToListAsync();

    var approved = allBookings.Where(b => b.Status == "approved");
    var (totalRev, comm, net) = BookingService.CalculateOwnerFinancials(approved);
    var pendingCount = allBookings.Count(b => b.Status == "pending");

    var (pg, l, explicitPaging) = Pagination.Parse(page, limit);
    var bookingsPage = explicitPaging
        ? allBookings.Skip((pg - 1) * l).Take(l).ToList()
        : allBookings.Take(Pagination.LegacyMaxItems).ToList();

    OwnerBookingDto Map(Booking b) => new(
        b.Id, b.ReferenceCode, b.User?.Name ?? "", b.User?.Phone ?? "", b.User?.Email ?? "",
        b.StartTime, b.Hours, b.TotalPrice, b.Status);

    return Results.Ok(new OwnerDashboardDto(
        DtoMapper.ToDto(primary),
        bookingsPage.Select(Map).ToList(),
        totalRev, comm, net, pendingCount,
        explicitPaging ? pg : null,
        explicitPaging ? l : null,
        explicitPaging ? allBookings.Count : null,
        explicitPaging ? pg * l < allBookings.Count : null));
}).RequireAuthorization();

app.MapGet("/api/payments/owner/{ownerId:int}/account", async (ClaimsPrincipal p, OwnerPaymentService payments, int ownerId) =>
{
    if (UserId(p) != ownerId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    return Results.Ok(await payments.GetAccountAsync(ownerId));
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.PaymentsPolicy);

app.MapPost("/api/payments/initiate", async (ClaimsPrincipal p, OwnerPaymentService payments, InitiatePaymentRequest req) =>
{
    var ownerId = UserId(p);
    var (result, error) = await payments.InitiateAsync(ownerId, req.InvoiceId, req.Gateway);
    if (error is not null) return Results.BadRequest(new { message = error });
    return Results.Ok(result);
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.PaymentsPolicy);

app.MapPost("/api/payments/verify", async (ClaimsPrincipal p, OwnerPaymentService payments, VerifyPaymentRequest req) =>
{
    var ownerId = UserId(p);
    var (result, error) = await payments.VerifyAsync(ownerId, req.TransactionToken);
    if (error is not null) return Results.BadRequest(new { message = error });
    return Results.Ok(result);
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.PaymentsPolicy);

app.MapGet("/api/notifications/{userId:int}", async (ClaimsPrincipal p, AppDbContext db, int userId, int? page, int? limit) =>
{
    if (UserId(p) != userId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    var (pg, l, explicitPaging) = Pagination.Parse(page, limit);
    var query = db.Notifications.AsNoTracking().Where(n => n.UserId == userId)
        .OrderByDescending(n => n.CreatedAt);

    var total = await query.CountAsync();
    var take = explicitPaging ? l : Pagination.LegacyMaxItems;
    var skip = explicitPaging ? (pg - 1) * l : 0;
    var list = await query.Skip(skip).Take(take).ToListAsync();

    if (!explicitPaging) return Results.Ok(list);

    var items = list.Select(n => new NotificationDto(n.Id, n.UserId, n.Title, n.Message, n.IsRead, n.CreatedAt)).ToList();
    return Results.Ok(new PagedResult<NotificationDto>(items, pg, l, total, skip + list.Count < total));
}).RequireAuthorization();

app.MapPost("/api/notifications/{id:int}/read", async (ClaimsPrincipal p, AppDbContext db, int id) =>
{
    var n = await db.Notifications.FindAsync(id);
    if (n is null) return Results.NotFound();
    if (n.UserId != UserId(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    n.IsRead = true;
    await db.SaveChangesAsync();
    return Results.Ok(n);
}).RequireAuthorization();

app.MapPost("/api/notifications/user/{userId:int}/read-all", async (ClaimsPrincipal p, AppDbContext db, int userId) =>
{
    if (UserId(p) != userId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    await db.Notifications
        .Where(n => n.UserId == userId && !n.IsRead)
        .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
    return Results.Ok(new { message = "تم" });
}).RequireAuthorization();

app.MapGet("/api/stats/user/{userId:int}", async (ClaimsPrincipal p, AppDbContext db, int userId) =>
{
    if (UserId(p) != userId) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);
    var now = BookingClock.UtcNow;
    var upcoming = await db.Bookings.AsNoTracking().CountAsync(b =>
        b.UserId == userId && b.Status == "approved" && b.StartTime > now);
    var pending = await db.Bookings.AsNoTracking().CountAsync(b =>
        b.UserId == userId && b.Status == "pending");
    var unread = await db.Notifications.AsNoTracking().CountAsync(n =>
        n.UserId == userId && !n.IsRead);
    var totalHours = await db.Bookings.AsNoTracking()
        .Where(b => b.UserId == userId && b.Status != "cancelled" && b.Status != "rejected")
        .SumAsync(b => b.Hours);
    return Results.Ok(new UserStatsDto(upcoming, pending, unread, totalHours));
}).RequireAuthorization();

app.MapPost("/api/users/update-token", async (
    ClaimsPrincipal p,
    NotificationService notifications,
    UpdateDeviceTokenRequest req) =>
{
    if (string.IsNullOrWhiteSpace(req.Token))
        return Results.BadRequest(new { message = "رمز الجهاز مطلوب" });
    var uid = UserId(p);
    await notifications.RegisterDeviceTokenAsync(uid, req.Token, req.Platform);
    return Results.Ok(new { registered = true });
}).RequireAuthorization();

app.MapPost("/api/bookings/{bookingId:int}/pay/initiate", async (
    ClaimsPrincipal p,
    AppDbContext db,
    UserBookingPaymentService payments,
    int bookingId,
    InitiateBookingPaymentRequest req) =>
{
    var uid = UserId(p);
    var (result, error) = await payments.InitiateAsync(uid, bookingId, req.Gateway);
    if (error is not null) return Results.BadRequest(new { message = error });
    return Results.Ok(result);
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.PaymentsPolicy);

app.MapPost("/api/bookings/pay/verify", async (
    ClaimsPrincipal p,
    UserBookingPaymentService payments,
    VerifyPaymentRequest req) =>
{
    var uid = UserId(p);
    var (result, error) = await payments.VerifyAsync(uid, req.TransactionToken);
    if (error is not null) return Results.BadRequest(new { message = error });
    return Results.Ok(result);
}).RequireAuthorization().RequireRateLimiting(RateLimitingExtensions.PaymentsPolicy);

app.MapGet("/api/admin/stats", async (ClaimsPrincipal p, AppDbContext db) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var totalUsers = await db.Users.CountAsync(u => u.Role == "user");
    var totalOwners = await db.Users.CountAsync(u => u.Role == "owner");
    var totalFields = await db.Fields.CountAsync(f => f.IsActive);
    var totalBookings = await db.Bookings.CountAsync();
    var paidBookings = await db.Bookings.CountAsync(b => b.PaymentStatus == "paid");
    var totalRevenue = await db.Bookings.Where(b => b.PaymentStatus == "paid").SumAsync(b => b.TotalPrice);
    var commissionBookings = await db.Bookings.AsNoTracking()
        .Where(b => b.PaymentStatus == "paid" && b.Status != "cancelled" && b.Status != "rejected")
        .Select(b => b.TotalPrice)
        .ToListAsync();
    var commission = commissionBookings.Sum(FinancialRules.CalculateCommissionFromTotal);

    return Results.Ok(new AdminStatsDto(
        totalUsers, totalOwners, totalFields, totalBookings, paidBookings, totalRevenue, commission));
}).RequireAuthorization();

app.MapGet("/api/admin/financials", async (ClaimsPrincipal p, AppDbContext db) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var paidBookings = await db.Bookings.CountAsync(b => b.PaymentStatus == "paid");
    var totalRevenue = await db.Bookings.Where(b => b.PaymentStatus == "paid").SumAsync(b => b.TotalPrice);
    var commissionBookings = await db.Bookings.AsNoTracking()
        .Where(b => b.PaymentStatus == "paid" && b.Status != "cancelled" && b.Status != "rejected")
        .Select(b => b.TotalPrice)
        .ToListAsync();
    var commission = commissionBookings.Sum(FinancialRules.CalculateCommissionFromTotal);

    return Results.Ok(new
    {
        paidBookings,
        totalRevenueIqd = totalRevenue,
        platformCommissionIqd = commission,
    });
}).RequireAuthorization();

app.MapGet("/api/admin/owners", async (ClaimsPrincipal p, AppDbContext db) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var owners = await db.Users.AsNoTracking()
        .Where(u => u.Role == "owner")
        .Select(u => new AdminOwnerDto(
            u.Id,
            u.Name,
            u.Email,
            u.Phone,
            u.OwnedFields.Count))
        .ToListAsync();

    return Results.Ok(owners);
}).RequireAuthorization();

app.MapGet("/api/admin/fields", async (ClaimsPrincipal p, AppDbContext db) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var fields = await db.Fields.AsNoTracking()
        .Select(f => new AdminFieldDto(
            f.Id,
            f.Name,
            f.Address,
            f.OwnerId,
            f.Owner!.Name,
            f.IsActive))
        .OrderBy(f => f.Name)
        .ToListAsync();

    return Results.Ok(fields);
}).RequireAuthorization();

app.MapGet("/api/admin/bookings/pending", async (ClaimsPrincipal p, AppDbContext db) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var pending = await db.Bookings.AsNoTracking()
        .Where(b => b.Status == "pending")
        .OrderByDescending(b => b.CreatedAt)
        .Select(b => new AdminPendingBookingDto(
            b.Id,
            b.Field!.Name,
            b.User!.Name,
            b.StartTime,
            b.Hours,
            b.TotalPrice,
            b.Status))
        .Take(100)
        .ToListAsync();

    return Results.Ok(pending);
}).RequireAuthorization();

app.MapPatch("/api/admin/fields/{id:int}/toggle", async (ClaimsPrincipal p, AppDbContext db, int id) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var field = await db.Fields.FindAsync(id);
    if (field is null) return Results.NotFound(new { message = "الملعب غير موجود" });

    field.IsActive = !field.IsActive;
    await db.SaveChangesAsync();

    return Results.Ok(new { field.Id, field.IsActive });
}).RequireAuthorization();

// ── Owner wallet ──
app.MapGet("/api/owner/wallet/status", async (ClaimsPrincipal p, AppDbContext db, WalletService wallets) =>
{
    var oid = UserId(p);
    if (!string.Equals(p.FindFirstValue(ClaimTypes.Role), "owner", StringComparison.OrdinalIgnoreCase))
        return Results.Json(new { message = "للملاك فقط" }, statusCode: 403);

    var status = await wallets.GetStatusAsync(db, oid);
    return Results.Ok(status);
}).RequireAuthorization();

app.MapGet("/api/owner/wallet", async (ClaimsPrincipal p, AppDbContext db, WalletService wallets) =>
{
    var oid = UserId(p);
    if (!string.Equals(p.FindFirstValue(ClaimTypes.Role), "owner", StringComparison.OrdinalIgnoreCase))
        return Results.Json(new { message = "للملاك فقط" }, statusCode: 403);

    var detail = await wallets.GetDetailAsync(db, oid);
    return Results.Ok(detail);
}).RequireAuthorization();

// ── Admin wallet management (sole manual credit path) ──
app.MapPost("/api/admin/wallets/top-up", async (
    ClaimsPrincipal p,
    AppDbContext db,
    WalletService wallets,
    AdminWalletTopUpRequest req) =>
{
    if (!IsAdmin(p)) return Results.Json(new { message = "غير مصرح" }, statusCode: 403);

    var owner = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == req.OwnerId && u.Role == "owner");
    if (owner is null) return Results.NotFound(new { message = "المالك غير موجود" });

    if (req.Amount < 1000)
        return Results.BadRequest(new { message = "الحد الأدنى للشحن 1,000 د.ع" });

    var adminName = p.FindFirstValue(ClaimTypes.Name) ?? "مدير";
    var note = string.IsNullOrWhiteSpace(req.Note)
        ? $"شحن يدوي بواسطة {adminName}"
        : req.Note.Trim();

    var (ok, err) = await wallets.AdminCreditAsync(db, req.OwnerId, req.Amount, note);
    if (!ok) return Results.BadRequest(new { message = err });

    var detail = await wallets.GetDetailAsync(db, req.OwnerId);
    return Results.Ok(detail);
}).RequireAuthorization();

app.Run();

/// <summary>Exposed for WebApplicationFactory integration tests.</summary>
public partial class Program { }
