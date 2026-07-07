class FieldReviewEligibility {
  const FieldReviewEligibility({
    required this.canReview,
    required this.hasBooked,
    this.userRating,
    this.averageRating = 0,
    this.reviewCount = 0,
  });

  final bool canReview;
  final bool hasBooked;
  final int? userRating;
  final double averageRating;
  final int reviewCount;

  factory FieldReviewEligibility.fromJson(Map<String, dynamic> json) => FieldReviewEligibility(
        canReview: json['canReview'] as bool? ?? false,
        hasBooked: json['hasBooked'] as bool? ?? false,
        userRating: json['userRating'] as int?,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['reviewCount'] as int? ?? 0,
      );
}

class FieldReview {
  const FieldReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory FieldReview.fromJson(Map<String, dynamic> json) => FieldReview(
        id: json['id'] as int,
        userId: json['userId'] as int? ?? 0,
        userName: json['userName'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
