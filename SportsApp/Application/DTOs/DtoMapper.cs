using Riyada.Domain.Entities;

namespace Riyada.Application.DTOs;

public static class DtoMapper
{
    public static UserDto ToDto(User u) =>
        new(u.Id, u.Name, u.Email, u.Phone, u.Province, u.Image, u.Role, u.LoyaltyPoints);

    public static FieldDto ToDto(Field f, double averageRating = 0, int reviewCount = 0) =>
        new(f.Id, f.Name, f.Address, f.Phone, f.Image, f.PricePerHour, f.OwnerId, averageRating, reviewCount, f.Latitude, f.Longitude);
}
