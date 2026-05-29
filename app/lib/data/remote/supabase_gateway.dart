abstract class SupabaseGateway {
  Future<List<Map<String, dynamic>>> getRatings(String userId);
  Future<void> upsertRating(Map<String, dynamic> rating);
  Future<void> insertComparison(Map<String, dynamic> comparison);
  Future<List<Map<String, dynamic>>> getReviews(String userId);
  Future<void> upsertReview(Map<String, dynamic> review);
  Future<Map<String, dynamic>?> getProfile(String userId);
  Future<void> upsertProfile(Map<String, dynamic> profile);
}

class FakeSupabaseGateway implements SupabaseGateway {
  final Map<String, Map<String, dynamic>> _ratings = {};
  final List<Map<String, dynamic>> _comparisons = [];
  final Map<String, Map<String, dynamic>> _reviews = {};
  final Map<String, Map<String, dynamic>> _profiles = {};

  @override
  Future<List<Map<String, dynamic>>> getRatings(String userId) async =>
      _ratings.values.where((r) => r['user_id'] == userId).toList();

  @override
  Future<void> upsertRating(Map<String, dynamic> rating) async {
    final key = '${rating['user_id']}_${rating['item_id']}';
    _ratings[key] = rating;
  }

  @override
  Future<void> insertComparison(Map<String, dynamic> comparison) async {
    _comparisons.add(comparison);
  }

  @override
  Future<List<Map<String, dynamic>>> getReviews(String userId) async =>
      _reviews.values.where((r) => r['user_id'] == userId).toList();

  @override
  Future<void> upsertReview(Map<String, dynamic> review) async {
    final key = '${review['user_id']}_${review['item_id']}';
    _reviews[key] = review;
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async =>
      _profiles[userId];

  @override
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    _profiles[profile['id'] as String] = profile;
  }
}
