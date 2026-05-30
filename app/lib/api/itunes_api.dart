import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/catalog/catalog_service.dart';

/// iTunes Search API — no auth, has artwork. Used as the catalog fallback when
/// Spotify is unavailable or returns nothing.
abstract class ItunesApi {
  /// [entity] is the iTunes entity filter (song,album,musicArtist by default).
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist'});
}

class ItunesApiHttp implements ItunesApi {
  ItunesApiHttp({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist'}) async {
    if (query.trim().isEmpty) return [];
    final res = await _http.get(Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'media': 'music',
      'entity': entity,
      'limit': '50',
    }));
    if (res.statusCode != 200) {
      throw StateError('iTunes search failed: ${res.statusCode}');
    }
    return parseSearch(res.body);
  }

  /// Parses the iTunes Search response into catalog items.
  static List<CatalogItem> parseSearch(String body) {
    if (body.isEmpty) return [];
    final json = jsonDecode(body);
    if (json is! Map || json['results'] is! List) return [];
    final out = <CatalogItem>[];
    for (final r in (json['results'] as List).whereType<Map>()) {
      final wrapper = r['wrapperType'] as String?;
      final kind = switch (wrapper) {
        'collection' => 'album',
        'artist' => 'artist',
        _ => 'track',
      };
      final id = (r['trackId'] ?? r['collectionId'] ?? r['artistId'])
          ?.toString();
      if (id == null) continue;
      final title = (r['trackName'] ?? r['collectionName'] ?? r['artistName'])
          as String?;
      if (title == null) continue;
      out.add(CatalogItem(
        id: 'itunes:$id',
        kind: kind,
        title: title,
        primaryArtist: r['artistName'] as String?,
        imageUrl: (r['artworkUrl100'] as String?)
            ?.replaceAll('100x100bb', '600x600bb'),
        source: 'itunes',
        sourceId: id,
      ));
    }
    return out;
  }
}
