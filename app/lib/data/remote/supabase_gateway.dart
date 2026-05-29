import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase tables used for cross-device sync.
/// Tests use a fake implementation (test/fakes/); runtime uses [SupabaseGatewayImpl].
abstract class SupabaseGateway {
  Future<List<Map<String, dynamic>>> getRatings(String userId);
  Future<void> upsertRating(Map<String, dynamic> rating);
  Future<void> insertComparison(Map<String, dynamic> comparison);
  Future<List<Map<String, dynamic>>> getReviews(String userId);
  Future<void> upsertReview(Map<String, dynamic> review);
  Future<Map<String, dynamic>?> getProfile(String userId);
  Future<void> upsertProfile(Map<String, dynamic> profile);
}

class SupabaseGatewayImpl implements SupabaseGateway {
  SupabaseGatewayImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> getRatings(String userId) async {
    final rows = await _client.from('ratings').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsertRating(Map<String, dynamic> rating) async {
    await _client.from('ratings').upsert(rating, onConflict: 'user_id,item_id');
  }

  @override
  Future<void> insertComparison(Map<String, dynamic> comparison) async {
    await _client.from('comparisons').insert(comparison);
  }

  @override
  Future<List<Map<String, dynamic>>> getReviews(String userId) async {
    final rows = await _client.from('reviews').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> upsertReview(Map<String, dynamic> review) async {
    await _client.from('reviews').upsert(review, onConflict: 'user_id,item_id');
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final row =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return row;
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    await _client.from('profiles').upsert(profile);
  }
}
