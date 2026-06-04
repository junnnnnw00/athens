import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/catalog/catalog_service.dart';

/// iTunes Search API — no auth, has artwork. Used as the catalog fallback when
/// Spotify is unavailable or returns nothing.
abstract class ItunesApi {
  /// [entity] is the iTunes entity filter (song,album,musicArtist by default).
  /// [offset] paginates: the implementation fetches `offset + limit` results
  /// (iTunes has no native offset param) and returns the slice past [offset].
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist', int offset = 0, int limit = 20});
}

class ItunesApiHttp implements ItunesApi {
  ItunesApiHttp({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist',
      int offset = 0,
      int limit = 20}) async {
    // iTunes has no offset param, so fetch a window covering [offset, offset+limit)
    // (capped at the API's 200 max) and return the slice past [offset]. Results
    // are stably ordered, so paging by re-fetching a larger window is consistent.
    final fetchLimit = (offset + limit).clamp(1, 200);
    final res = await _http.get(Uri.https('itunes.apple.com', '/search', {
      'term': query,
      'media': 'music',
      'entity': entity,
      'limit': '$fetchLimit',
    }));
    if (res.statusCode != 200) {
      throw StateError('iTunes search failed: ${res.statusCode}');
    }
    final all = parseSearch(res.body);
    if (offset >= all.length) return const [];
    final end = (offset + limit) > all.length ? all.length : offset + limit;
    return all.sublist(offset, end);
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
