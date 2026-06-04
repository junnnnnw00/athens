import 'package:athens/api/itunes_api.dart';
import 'package:athens/api/lastfm_api.dart';
import 'package:athens/api/musicbrainz_api.dart';
import 'package:athens/data/remote/supabase_gateway.dart';
import 'package:athens/features/catalog/catalog_service.dart';

/// Test doubles for the network boundary. These live ONLY under test/ and are
/// never imported by lib/ runtime code (ACCEPTANCE A4).

class FakeItunesApi implements ItunesApi {
  @override
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist', int offset = 0, int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    return [
      CatalogItem(
        id: 'itunes:1',
        kind: 'track',
        title: 'iTunes Fallback: $query',
        primaryArtist: 'Fallback Artist',
        imageUrl: 'https://example.test/itunes.jpg',
        source: 'itunes',
        sourceId: '1',
      ),
    ];
  }
}

class FakeLastfmApi implements LastfmApi {
  FakeLastfmApi({this.recentlyPlayed = const []});
  final List<CatalogItem> recentlyPlayed;
  @override
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  }) async =>
      ['shoegaze', 'dreamy', 'noise pop', 'melancholic', 'atmospheric'];

  @override
  Future<List<String>> getArtistTopTags({required String artist}) async =>
      ['shoegaze', 'dream pop', 'alternative'];

  @override
  Future<LastfmTrackInfo?> getTrackInfo({
    required String artist,
    required String track,
  }) async =>
      const LastfmTrackInfo(
          listeners: 12000,
          playcount: 45000,
          durationMs: 222000,
          album: 'Fake Album',
          summary: 'A fake summary.');

  @override
  Future<LastfmArtistInfo?> getArtistInfo({required String artist}) async =>
      const LastfmArtistInfo(
          listeners: 99000, playcount: 500000, summary: 'A fake bio.');

  @override
  Future<List<String>> getArtistTopTracks({required String artist}) async =>
      ['Track One', 'Track Two', 'Track Three'];

  @override
  Future<List<LastfmRecentTrack>> getRecentTracks({
    required String username,
    int limit = 10,
  }) async {
    if (recentlyPlayed.isNotEmpty) {
      return recentlyPlayed
          .map((item) => LastfmRecentTrack(
                title: item.title,
                artist: item.primaryArtist ?? '',
                imageUrl: item.imageUrl,
                mbid: item.sourceId,
              ))
          .toList();
    }
    return [
      const LastfmRecentTrack(
        title: 'Fake Recent Track 1',
        artist: 'Fake Artist',
        imageUrl: 'https://placekitten.com/200/200',
      ),
      const LastfmRecentTrack(
        title: 'Fake Recent Track 2',
        artist: 'Fake Artist',
      ),
    ];
  }
}

class FakeMusicBrainzApi implements MusicBrainzApi {
  @override
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  }) async =>
      ['shoegaze', 'dream pop'];

  @override
  Future<MbRecordingInfo> getRecordingInfo({
    required String artist,
    required String title,
  }) async =>
      const MbRecordingInfo(genres: ['shoegaze', 'dream pop'], year: '1991');
}

class FakeSupabaseGateway implements SupabaseGateway {
  final Map<String, Map<String, dynamic>> _ratings = {};
  final List<Map<String, dynamic>> comparisons = [];
  final Map<String, Map<String, dynamic>> _reviews = {};
  final Map<String, Map<String, dynamic>> _profiles = {};
  final Map<String, Map<String, dynamic>> items = {};
  int _itemSeq = 0;

  @override
  Future<String?> upsertItemReturningId(Map<String, dynamic> item) async {
    final key = '${item['source']}:${item['source_id']}';
    final existing = items[key];
    if (existing != null) return existing['id'] as String;
    final id = 'uuid-${_itemSeq++}';
    items[key] = {...item, 'id': id};
    return id;
  }

  @override
  Future<List<Map<String, dynamic>>> getRatings(String userId) async =>
      _ratings.values.where((r) => r['user_id'] == userId).toList();

  @override
  Future<List<Map<String, dynamic>>> getRatingsWithItems(String userId) async {
    final itemsById = {for (final i in items.values) i['id'] as String: i};
    return _ratings.values.where((r) => r['user_id'] == userId).map((r) {
      return {
        'elo': r['elo'],
        'comparisons': r['comparisons'],
        'updated_at': r['updated_at'],
        'item': itemsById[r['item_id']],
      };
    }).toList();
  }

  @override
  Future<void> upsertRating(Map<String, dynamic> rating) async {
    _ratings['${rating['user_id']}_${rating['item_id']}'] = rating;
  }

  @override
  Future<void> deleteRating(String userId, String remoteItemId) async {
    _ratings.remove('${userId}_$remoteItemId');
  }

  @override
  Future<void> insertComparison(Map<String, dynamic> comparison) async {
    final clientId = comparison['client_id'];
    if (clientId != null) {
      comparisons.removeWhere((c) => c['client_id'] == clientId);
    }
    comparisons.add(comparison);
  }

  @override
  Future<void> insertComparisons(List<Map<String, dynamic>> rows) async {
    for (final r in rows) {
      await insertComparison(r);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getComparisons(String userId) async {
    final byId = {for (final i in items.values) i['id'] as String: i};
    Map<String, dynamic>? src(dynamic uuid) {
      final i = byId[uuid];
      return i == null
          ? null
          : {'source': i['source'], 'source_id': i['source_id']};
    }

    return comparisons.where((c) => c['user_id'] == userId).map((c) {
      return {
        'client_id': c['client_id'],
        'created_at': c['created_at'],
        'winner': src(c['winner_item_id']),
        'loser': src(c['loser_item_id']),
      };
    }).toList();
  }

  @override
  Future<void> deleteComparisonsForItem(
      String userId, String remoteItemId) async {
    comparisons.removeWhere((c) =>
        c['user_id'] == userId &&
        (c['winner_item_id'] == remoteItemId ||
            c['loser_item_id'] == remoteItemId));
  }

  @override
  Future<void> deleteComparison(String userId, String clientId) async {
    comparisons.removeWhere(
        (c) => c['user_id'] == userId && c['client_id'] == clientId);
  }

  @override
  Future<List<Map<String, dynamic>>> getReviews(String userId) async =>
      _reviews.values.where((r) => r['user_id'] == userId).toList();

  @override
  Future<void> upsertReview(Map<String, dynamic> review) async {
    _reviews['${review['user_id']}_${review['item_id']}'] = review;
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async =>
      _profiles[userId];

  @override
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    _profiles[profile['id'] as String] = profile;
  }

  @override
  Future<Map<String, dynamic>?> getItemRatingStats(String itemUuid) async =>
      null;

  @override
  Future<List<Map<String, dynamic>>> getItemRatingTrend(String itemUuid) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> getItemPublicReviews(
          String itemUuid) async =>
      const [];
}
