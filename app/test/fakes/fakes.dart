import 'package:athens/api/spotify_api.dart';
import 'package:athens/api/itunes_api.dart';
import 'package:athens/api/lastfm_api.dart';
import 'package:athens/api/musicbrainz_api.dart';
import 'package:athens/data/remote/supabase_gateway.dart';
import 'package:athens/features/catalog/catalog_service.dart';

/// Test doubles for the network boundary. These live ONLY under test/ and are
/// never imported by lib/ runtime code (ACCEPTANCE A4).

class FakeSpotifyApi implements SpotifyApi {
  FakeSpotifyApi({this.recentlyPlayed = const []});

  final List<CatalogItem> recentlyPlayed;

  @override
  Future<List<CatalogItem>> search(String query,
      {String types = 'track,album,artist', int offset = 0}) async {
    if (query.trim().isEmpty) return [];
    return [
      CatalogItem(
        id: 'spotify:loveless',
        kind: 'album',
        title: 'Loveless',
        primaryArtist: 'My Bloody Valentine',
        imageUrl: 'https://example.test/loveless.jpg',
        source: 'spotify',
        sourceId: 'loveless',
      ),
      CatalogItem(
        id: 'spotify:souvlaki',
        kind: 'album',
        title: 'Souvlaki',
        primaryArtist: 'Slowdive',
        imageUrl: 'https://example.test/souvlaki.jpg',
        source: 'spotify',
        sourceId: 'souvlaki',
      ),
    ];
  }

  @override
  Future<List<CatalogItem>> getRecentlyPlayed() async => recentlyPlayed;
}

class FakeItunesApi implements ItunesApi {
  @override
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist', int offset = 0}) async {
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
  @override
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  }) async =>
      ['shoegaze', 'dreamy', 'noise pop', 'melancholic', 'atmospheric'];

  @override
  Future<List<String>> getArtistTopTags({required String artist}) async =>
      ['shoegaze', 'dream pop', 'alternative'];
}

class FakeMusicBrainzApi implements MusicBrainzApi {
  @override
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  }) async =>
      ['shoegaze', 'dream pop'];
}

class FakeSupabaseGateway implements SupabaseGateway {
  final Map<String, Map<String, dynamic>> _ratings = {};
  final List<Map<String, dynamic>> comparisons = [];
  final Map<String, Map<String, dynamic>> _reviews = {};
  final Map<String, Map<String, dynamic>> _profiles = {};

  @override
  Future<List<Map<String, dynamic>>> getRatings(String userId) async =>
      _ratings.values.where((r) => r['user_id'] == userId).toList();

  @override
  Future<void> upsertRating(Map<String, dynamic> rating) async {
    _ratings['${rating['user_id']}_${rating['item_id']}'] = rating;
  }

  @override
  Future<void> insertComparison(Map<String, dynamic> comparison) async {
    comparisons.add(comparison);
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
}
