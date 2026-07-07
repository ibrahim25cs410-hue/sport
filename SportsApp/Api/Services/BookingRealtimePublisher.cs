using Microsoft.AspNetCore.SignalR;
using Riyada.Api.Hubs;
using Riyada.Application.Abstractions;
using Riyada.Application.DTOs;

namespace Riyada.Api.Services;

public sealed class BookingRealtimePublisher(IHubContext<BookingHub> hub) : IBookingRealtimePublisher
{
    public Task PublishBookingUpdatedAsync(int targetUserId, BookingUpdatedEvent payload) =>
        hub.Clients.Group($"user_{targetUserId}").SendAsync("BookingUpdated", payload);

    public Task PublishFieldBookingUpdatedAsync(int fieldId, BookingUpdatedEvent payload) =>
        hub.Clients.Group(BookingHub.FieldGroup(fieldId)).SendAsync("BookingUpdated", payload);

    public Task PublishSlotSelectionAsync(int fieldId, SlotSelectionEvent payload) =>
        hub.Clients.Group(BookingHub.FieldGroup(fieldId)).SendAsync("NotifySlotSelection", payload);

    public Task PublishSlotReleaseAsync(int fieldId, SlotReleaseEvent payload) =>
        hub.Clients.Group(BookingHub.FieldGroup(fieldId)).SendAsync("ReleaseSlot", payload);
}
