import '../../models/review.dart';
import '../../services/api_client.dart';
import '../../services/review_service.dart';

class ReviewRepository {
  ReviewRepository(ApiClient client) : _remote = ReviewService(client);

  final ReviewService _remote;

  Future<FieldReviewEligibility> getEligibility(int fieldId) => _remote.getEligibility(fieldId);

  Future<List<FieldReview>> getReviews(int fieldId) => _remote.getReviews(fieldId);

  Future<void> submitReview({required int fieldId, required int rating, String? comment}) =>
      _remote.submitReview(fieldId: fieldId, rating: rating, comment: comment);
}
