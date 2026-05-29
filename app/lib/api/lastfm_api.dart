import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Last.fm crowd tags (≈ RYM descriptors). Reached through the `lastfm-proxy`
/// edge function so the API key never ships in the client.
abstract class LastfmApi {
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  });
  Future<List<String>> getArtistTopTags({required String artist});
}

class LastfmApiHttp implements LastfmApi {
  LastfmApiHttp({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<String>> _invoke(Map<String, String> query) async {
    final res = await _client.functions.invoke(
      'lastfm-proxy',
      queryParameters: query,
      method: HttpMethod.get,
    );
    return parseTags(res.data);
  }

  @override
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  }) {
    return _invoke({
      'method': 'track.getTopTags',
      'artist': artist,
      'track': track,
    });
  }

  @override
  Future<List<String>> getArtistTopTags({required String artist}) {
    return _invoke({'method': 'artist.getTopTags', 'artist': artist});
  }

  /// Parses a Last.fm `*.getTopTags` payload (already-decoded map or a string).
  static List<String> parseTags(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    if (json is! Map) return [];
    final toptags = json['toptags'];
    final tagList = toptags is Map ? toptags['tag'] : null;
    if (tagList is! List) return [];
    return tagList
        .whereType<Map>()
        .map((t) => t['name'] as String?)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
