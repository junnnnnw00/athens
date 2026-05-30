import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// MusicBrainz recording genres/tags + first-release year.
class MbRecordingInfo {
  const MbRecordingInfo({this.genres = const [], this.year});
  final List<String> genres;
  final String? year;
}

/// Reached through the `musicbrainz-proxy` edge function: MusicBrainz sends no
/// CORS headers, so a direct browser call is blocked. The proxy also carries the
/// required User-Agent server-side.
abstract class MusicBrainzApi {
  Future<List<String>> getGenres({required String artist, required String title});
  Future<MbRecordingInfo> getRecordingInfo({
    required String artist,
    required String title,
  });
}

class MusicBrainzApiHttp implements MusicBrainzApi {
  MusicBrainzApiHttp({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  @override
  Future<List<String>> getGenres({
    required String artist,
    required String title,
  }) async =>
      (await getRecordingInfo(artist: artist, title: title)).genres;

  @override
  Future<MbRecordingInfo> getRecordingInfo({
    required String artist,
    required String title,
  }) async {
    if (!isSupabaseInitialized) return const MbRecordingInfo();
    final query = title.isNotEmpty
        ? 'recording:"$title" AND artist:"$artist"'
        : 'artist:"$artist"';
    final res = await _client.functions.invoke(
      'musicbrainz-proxy',
      queryParameters: {'entity': 'recording', 'query': query, 'limit': '1'},
      method: HttpMethod.get,
    );
    return parseRecording(res.data);
  }

  /// Parses a MusicBrainz recording-search payload (decoded map or string).
  static MbRecordingInfo parseRecording(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    if (json is! Map) return const MbRecordingInfo();
    final recordings = json['recordings'];
    if (recordings is! List || recordings.isEmpty) return const MbRecordingInfo();
    final first = recordings.first;
    if (first is! Map) return const MbRecordingInfo();

    final genres = <String>{};
    for (final key in ['genres', 'tags']) {
      final list = first[key];
      if (list is List) {
        for (final t in list.whereType<Map>()) {
          final name = t['name'] as String?;
          if (name != null && name.isNotEmpty) genres.add(name);
        }
      }
    }
    final date = first['first-release-date'] as String?;
    final year =
        (date != null && date.length >= 4) ? date.substring(0, 4) : null;
    return MbRecordingInfo(genres: genres.toList(), year: year);
  }
}
