import 'dart:convert';

import 'package:http/http.dart' as http;

/// MusicBrainz genres/tags. Public API, no key, but requires a meaningful
/// User-Agent and ≤ 1 req/sec (callers should debounce).
abstract class MusicBrainzApi {
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  });
}

class MusicBrainzApiHttp implements MusicBrainzApi {
  MusicBrainzApiHttp({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _userAgent = 'Athens/0.1 (https://github.com/athens-app)';

  @override
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  }) async {
    final query = title.isNotEmpty
        ? 'recording:"$title" AND artist:"$artist"'
        : 'artist:"$artist"';
    final res = await _http.get(
      Uri.https('musicbrainz.org', '/ws/2/recording', {
        'query': query,
        'fmt': 'json',
        'limit': '1',
      }),
      headers: {'User-Agent': _userAgent},
    );
    if (res.statusCode != 200) {
      throw StateError('MusicBrainz failed: ${res.statusCode}');
    }
    return parseGenres(res.body);
  }

  /// Parses MusicBrainz recording search JSON into a flat list of tag names.
  static List<String> parseGenres(String body) {
    if (body.isEmpty) return [];
    final json = jsonDecode(body);
    if (json is! Map) return [];
    final recordings = json['recordings'];
    if (recordings is! List || recordings.isEmpty) return [];
    final first = recordings.first;
    if (first is! Map) return [];
    final out = <String>{};
    for (final key in ['tags', 'genres']) {
      final list = first[key];
      if (list is List) {
        for (final t in list.whereType<Map>()) {
          final name = t['name'] as String?;
          if (name != null && name.isNotEmpty) out.add(name);
        }
      }
    }
    return out.toList();
  }
}
