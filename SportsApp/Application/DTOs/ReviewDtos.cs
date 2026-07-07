namespace Riyada.Application.DTOs;

public record SubmitReviewRequest(int Rating, string? Comment);

public record ReviewDto(int Id, int UserId, string UserName, int Rating, string? Comment, DateTime CreatedAt);

public record FieldReviewEligibilityDto(bool CanReview, bool HasBooked, int? UserRating, double AverageRating, int ReviewCount);
