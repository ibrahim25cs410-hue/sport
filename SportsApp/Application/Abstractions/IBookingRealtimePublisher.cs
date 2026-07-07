using Riyada.Application.DTOs;

namespace Riyada.Application.Abstractions;

public interface IBookingRealtimePublisher
{
    Task PublishBookingUpdatedAsync(int targetUserId, BookingUpdatedEvent payload);
    Task PublishFieldBookingUpdatedAsync(int fieldId, BookingUpdatedEvent payload);
    Task PublishSlotSelectionAsync(int fieldId, SlotSelectionEvent payload);
    Task PublishSlotReleaseAsync(int fieldId, SlotReleaseEvent payload);
}
