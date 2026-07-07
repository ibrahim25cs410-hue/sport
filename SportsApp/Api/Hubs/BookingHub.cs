using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Riyada.Api.Hubs;

[Authorize]
public class BookingHub : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(userId))
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrEmpty(userId))
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>الانضمام لغرفة الملعب لمتابعة اختيار الأوقات.</summary>
    public Task JoinField(int fieldId) =>
        Groups.AddToGroupAsync(Context.ConnectionId, FieldGroup(fieldId));

    /// <summary>مغادرة غرفة الملعب.</summary>
    public Task LeaveField(int fieldId) =>
        Groups.RemoveFromGroupAsync(Context.ConnectionId, FieldGroup(fieldId));

    internal static string FieldGroup(int fieldId) => $"field_{fieldId}";
}
