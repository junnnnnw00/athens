import '../../data/remote/supabase_gateway.dart';

class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.body,
    this.ratingSnapshot,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String itemId;
  final String body;
  final double? ratingSnapshot;
  final DateTime updatedAt;
}

class ReviewsService {
  ReviewsService({required SupabaseGateway gateway}) : _gateway = gateway;

  final SupabaseGateway _gateway;

  Future<List<Review>> getReviewsForUser(String userId) async {
    final data = await _gateway.getReviews(userId);
    return data.map((r) => Review(
      id: r['id'] as String? ?? '',
      userId: r['user_id'] as String,
      itemId: r['item_id'] as String,
      body: r['body'] as String,
      ratingSnapshot: (r['rating_snapshot'] as num?)?.toDouble(),
      updatedAt: r['updated_at'] != null
          ? DateTime.parse(r['updated_at'] as String)
          : DateTime.now(),
    )).toList();
  }

  Future<void> upsertReview({
    required String userId,
    required String itemId,
    required String body,
    double? ratingSnapshot,
  }) async {
    await _gateway.upsertReview({
      'id': '${userId}_$itemId',
      'user_id': userId,
      'item_id': itemId,
      'body': body,
      if (ratingSnapshot != null) 'rating_snapshot': ratingSnapshot,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteReview({
    required String userId,
    required String itemId,
  }) async {
    await _gateway.upsertReview({
      'id': '${userId}_$itemId',
      'user_id': userId,
      'item_id': itemId,
      'body': '',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
