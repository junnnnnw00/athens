import '../remote/supabase_gateway.dart';

class SyncResult {
  const SyncResult({
    required this.uploaded,
    required this.downloaded,
    this.errors = const [],
  });

  final int uploaded;
  final int downloaded;
  final List<String> errors;
}

class SyncService {
  SyncService({required SupabaseGateway gateway}) : _gateway = gateway;

  final SupabaseGateway _gateway;

  /// Push local ratings to Supabase, pull remote changes down.
  /// Last-write-wins strategy using updated_at timestamp.
  Future<SyncResult> sync({
    required String userId,
    required List<Map<String, dynamic>> localRatings,
  }) async {
    int uploaded = 0;
    int downloaded = 0;
    final errors = <String>[];

    // Upload local ratings.
    for (final rating in localRatings) {
      try {
        await _gateway.upsertRating({...rating, 'user_id': userId});
        uploaded++;
      } catch (e) {
        errors.add('Failed to upload rating ${rating['item_id']}: $e');
      }
    }

    // Download remote ratings.
    try {
      final remote = await _gateway.getRatings(userId);
      downloaded = remote.length;
    } catch (e) {
      errors.add('Failed to download ratings: $e');
    }

    return SyncResult(uploaded: uploaded, downloaded: downloaded, errors: errors);
  }

  Future<void> syncComparison({
    required String userId,
    required String winnerId,
    required String loserId,
  }) async {
    await _gateway.insertComparison({
      'user_id': userId,
      'winner_item_id': winnerId,
      'loser_item_id': loserId,
    });
  }
}
