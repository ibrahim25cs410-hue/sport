namespace Riyada.Application.DTOs;

/// <summary>حملة حدث لحظي — المفاتيح تُترجم في العميل (i18n).</summary>
public record BookingUpdatedEvent(
    int BookingId,
    string Status,
    string TitleKey,
    string MessageKey,
    Dictionary<string, string> MessageArgs);

public record SlotSelectionEvent(
    int FieldId,
    DateTime StartTime,
    int Hours,
    int UserId,
    DateTime ExpiresAt);

public record SlotReleaseEvent(
    int FieldId,
    DateTime StartTime,
    int Hours);
