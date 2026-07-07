import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  ReviewService(this._client);
  final ApiClient _client;

  Future<FieldReviewEligibility> getEligibility(int fieldId) async {
    final res = await _client.dio.get('/fields/$fieldId/review-eligibility');
    return FieldReviewEligibility.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<FieldReview>> getReviews(int fieldId) async {
    final res = await _client.dio.get('/fields/$fieldId/reviews');
    return (res.data as List).map((e) => FieldReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitReview({required int fieldId, required int rating, String? comment}) async {
    await _client.dio.post('/fields/$fieldId/reviews', data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}
