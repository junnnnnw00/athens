import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over the Supabase tables used for cross-device sync.
/// Tests use a fake implementation (test/fakes/); runtime uses [SupabaseGatewayImpl].
abstract class SupabaseGateway {
  Future<List<Map<String, dynamic>>> getRatings(String userId);

  /// Ratings joined with their shared catalog item, for pulling a user's whole
  /// library down to a fresh device / browser. Each row carries an `item` map.
  Future<List<Map<String, dynamic>>> getRatingsWithItems(String userId);

  /// Upserts a shared catalog item (by source+source_id) and returns its uuid.
  Future<String?> upsertItemReturningId(Map<String, dynamic> item);
  Future<void> upsertRating(Map<String, dynamic> rating);
  Future<void> deleteRating(String userId, String remoteItemId);
  Future<void> insertComparison(Map<String, dynamic> comparison);

  /// Batch idempotent upsert of duel rows (keyed by client_id) — used to backfill
  /// the whole local log in one call.
  Future<void> insertComparisons(List<Map<String, dynamic>> rows);

  /// The user's duel log joined to each item's source/source_id, so a pulling
  /// device can map remote uuids back to its local item ids.
  Future<List<Map<String, dynamic>>> getComparisons(String userId);
  Future<void> deleteComparisonsForItem(String userId, String remoteItemId);
  Future<List<Map<String, dynamic>>> getReviews(String userId);
  Future<void> upsertReview(Map<String, dynamic> review);
  Future<Map<String, dynamic>?> getProfile(String userId);
  Future<void> upsertProfile(Map<String, dynamic> profile);

  /// Aggregate rating stats for one catalog item across ALL accounts
  /// (public + private). Returns `{count, avg, distribution: [c0..c9]}`; `avg`
  /// and `distribution` are null until a privacy threshold of raters is met.
  Future<Map<String, dynamic>?> getItemRatingStats(String itemUuid);

  /// Daily community-average trend for one item (from item_rating_daily).
  Future<List<Map<String, dynamic>>> getItemRatingTrend(String itemUuid);

  /// Reviews for one item from PUBLIC accounts only, with author profile fields.
  Future<List<Map<String, dynamic>>> getItemPublicReviews(String itemUuid);
}

class SupabaseGatewayImpl implements SupabaseGateway {
  SupabaseGatewayImpl({SupabaseClient? client})
      : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> getRatings(String userId) async {
    final rows = await _client.from('ratings').select().eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> getRatingsWithItems(String userId) async {
    final rows = await _client
        .from('ratings')
        .select('elo, comparisons, updated_at, item:items(*)')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<String?> upsertItemReturningId(Map<String, dynamic> item) async {
    final row = await _client
        .from('items')
        .upsert(item, onConflict: 'source,source_id')
        .select('id')
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<void> upsertRating(Map<String, dynamic> rating) async {
    await _client.from('ratings').upsert(rating, onConflict: 'user_id,item_id');
  }

  @override
  Future<void> deleteRating(String userId, String remoteItemId) async {
    await _client
        .from('ratings')
        .delete()
        .eq('user_id', userId)
        .eq('item_id', remoteItemId);
  }

  @override
  Future<void> insertComparison(Map<String, dynamic> comparison) async {
    // Upsert on client_id so re-pushing the same local row (backfill / retry)
    // is idempotent. Falls back to a plain insert if no client_id is supplied.
    if (comparison['client_id'] != null) {
      await _client
          .from('comparisons')
          .upsert(comparison, onConflict: 'client_id', ignoreDuplicates: true);
    } else {
      await _client.from('comparisons').insert(comparison);
    }
  }

  @override
  Future<void> insertComparisons(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client
        .from('comparisons')
        .upsert(rows, onConflict: 'client_id', ignoreDuplicates: true);
  }

  @override
  Future<List<Map<String, dynamic>>> getComparisons(String userId) async {
    final rows = await _client
        .from('comparisons')
        .select(
            'client_id, created_at, winner:items!winner_item_id(source, source_id), loser:items!loser_item_id(source, source_id)')
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<void> deleteComparisonsForItem(
      String userId, String remoteItemId) async {
    await _client.from('comparisons').delete().eq('user_id', userId).or(
        'winner_item_id.eq.$remoteItemId,loser_item_id.eq.$remoteItemId');
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

  @override
  Future<Map<String, dynamic>?> getItemRatingStats(String itemUuid) async {
    final row = await _client.rpc(
      'item_rating_stats',
      params: {'p_item_id': itemUuid},
    );
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  @override
  Future<List<Map<String, dynamic>>> getItemRatingTrend(String itemUuid) async {
    final rows = await _client.rpc(
      'item_rating_trend',
      params: {'p_item_id': itemUuid},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  @override
  Future<List<Map<String, dynamic>>> getItemPublicReviews(
      String itemUuid) async {
    final rows = await _client.rpc(
      'item_public_reviews',
      params: {'p_item_id': itemUuid},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
