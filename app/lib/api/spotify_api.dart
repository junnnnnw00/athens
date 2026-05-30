import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';
import '../features/catalog/catalog_service.dart';
import 'spotify_pkce_service.dart';

/// Spotify catalog + listening-history access.
///
/// Catalog search uses an app-level token (Client Credentials) minted by the
/// `spotify-app-token` edge function, so the client never holds the secret.
/// Recently-played uses the per-user PKCE token (allow-listed users only).
abstract class SpotifyApi {
  /// [types] is the Spotify `type` filter, e.g. 'track', 'album', 'artist', or
  /// the combined default. A single type lets the whole limit go to it.
  /// [offset] pages through results (Spotify caps offset+limit at 1000).
  Future<List<CatalogItem>> search(String query,
      {String types = 'track,album,artist', int offset = 0});
  Future<List<CatalogItem>> getRecentlyPlayed();
}

class SpotifyApiHttp implements SpotifyApi {
  SpotifyApiHttp({SupabaseClient? client, http.Client? httpClient})
      : _providedClient = client,
        _http = httpClient ?? http.Client();

  final SupabaseClient? _providedClient;
  final http.Client _http;

  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  Future<String> _appToken() async {
    if (!isSupabaseInitialized) throw StateError('Supabase is not initialized');
    final res = await _client.functions.invoke('spotify-app-token');
    final data = res.data as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw StateError('No Spotify app token');
    return token;
  }

  @override
  Future<List<CatalogItem>> search(String query,
      {String types = 'track,album,artist', int offset = 0}) async {
    if (query.trim().isEmpty) return [];
    final token = await _appToken();
    final limit = types.contains(',') ? '10' : '30';
    final res = await _http.get(
      Uri.https('api.spotify.com', '/v1/search', {
        'q': query,
        'type': types,
        'limit': limit,
        'offset': '$offset',
      }),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw StateError('Spotify search failed: ${res.statusCode}');
    }
    return parseSearch(res.body);
  }

  @override
  Future<List<CatalogItem>> getRecentlyPlayed() async {
    final token = await SpotifyPkceService.getValidAccessToken();
    if (token == null) return [];
    final res = await _http.get(
      Uri.https('api.spotify.com', '/v1/me/player/recently-played',
          {'limit': '20'}),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) return [];
    return parseRecentlyPlayed(res.body);
  }

  /// Parses Spotify's `/search` response into catalog items.
  static List<CatalogItem> parseSearch(String body) {
    final json = _obj(body);
    final items = <CatalogItem>[];
    for (final t in (_list(json['tracks'], 'items'))) {
      items.add(_track(t));
    }
    for (final a in (_list(json['albums'], 'items'))) {
      items.add(_album(a));
    }
    for (final ar in (_list(json['artists'], 'items'))) {
      items.add(_artist(ar));
    }
    return items;
  }

  /// Parses `/me/player/recently-played`, de-duplicating repeated tracks.
  static List<CatalogItem> parseRecentlyPlayed(String body) {
    final json = _obj(body);
    final out = <CatalogItem>[];
    final seen = <String>{};
    for (final entry in (json['items'] as List? ?? const [])) {
      final t = (entry as Map)['track'];
      if (t is! Map) continue;
      final item = _track(Map<String, dynamic>.from(t));
      if (seen.add(item.sourceId ?? item.id)) out.add(item);
    }
    return out;
  }

  static CatalogItem _track(Map<String, dynamic> t) {
    final album = t['album'];
    return CatalogItem(
      id: 'spotify:${t['id']}',
      kind: 'track',
      title: t['name'] as String? ?? 'Unknown',
      primaryArtist: _firstArtist(t['artists']),
      imageUrl: _image(album is Map ? album['images'] : null),
      source: 'spotify',
      sourceId: t['id'] as String?,
    );
  }

  static CatalogItem _album(Map<String, dynamic> a) => CatalogItem(
        id: 'spotify:${a['id']}',
        kind: 'album',
        title: a['name'] as String? ?? 'Unknown',
        primaryArtist: _firstArtist(a['artists']),
        imageUrl: _image(a['images']),
        source: 'spotify',
        sourceId: a['id'] as String?,
      );

  static CatalogItem _artist(Map<String, dynamic> a) => CatalogItem(
        id: 'spotify:${a['id']}',
        kind: 'artist',
        title: a['name'] as String? ?? 'Unknown',
        imageUrl: _image(a['images']),
        source: 'spotify',
        sourceId: a['id'] as String?,
      );

  static String? _firstArtist(dynamic artists) {
    if (artists is List && artists.isNotEmpty) {
      return (artists.first as Map)['name'] as String?;
    }
    return null;
  }

  static String? _image(dynamic images) {
    if (images is List && images.isNotEmpty) {
      return (images.first as Map)['url'] as String?;
    }
    return null;
  }

  static Map<String, dynamic> _obj(String body) {
    if (body.isEmpty) return {};
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static List<Map<String, dynamic>> _list(dynamic parent, String key) {
    if (parent is Map && parent[key] is List) {
      return (parent[key] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
