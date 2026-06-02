import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Last.fm crowd tags (≈ RYM descriptors). Reached through the `lastfm-proxy`
/// edge function so the API key never ships in the client.
/// Extended track facts + stats from `track.getInfo`.
class LastfmTrackInfo {
  const LastfmTrackInfo(
      {this.listeners, this.playcount, this.durationMs, this.album, this.summary});
  final int? listeners;
  final int? playcount;
  final int? durationMs;
  final String? album;
  final String? summary;
}

/// Artist stats + bio from `artist.getInfo`.
class LastfmArtistInfo {
  const LastfmArtistInfo({this.listeners, this.playcount, this.summary});
  final int? listeners;
  final int? playcount;
  final String? summary;
}

class LastfmRecentTrack {
  const LastfmRecentTrack({
    required this.title,
    required this.artist,
    this.imageUrl,
    this.mbid,
  });
  final String title;
  final String artist;
  final String? imageUrl;
  final String? mbid;
}

abstract class LastfmApi {
  Future<List<String>> getTopTags({
    required String artist,
    required String track,
  });
  Future<List<String>> getArtistTopTags({required String artist});
  Future<LastfmTrackInfo?> getTrackInfo({
    required String artist,
    required String track,
  });
  Future<LastfmArtistInfo?> getArtistInfo({required String artist});
  Future<List<String>> getArtistTopTracks({required String artist});
  Future<List<LastfmRecentTrack>> getRecentTracks({
    required String username,
    int limit = 10,
  });
}

class LastfmApiHttp implements LastfmApi {
  LastfmApiHttp({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  Future<dynamic> _raw(Map<String, String> query) async {
    if (!isSupabaseInitialized) return null;
    final res = await _client.functions.invoke(
      'lastfm-proxy',
      queryParameters: query,
      method: HttpMethod.get,
    );
    return res.data;
  }

  Future<List<String>> _invoke(Map<String, String> query) async =>
      parseTags(await _raw(query));

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

  @override
  Future<LastfmTrackInfo?> getTrackInfo({
    required String artist,
    required String track,
  }) async =>
      parseTrackInfo(await _raw(
          {'method': 'track.getInfo', 'artist': artist, 'track': track}));

  @override
  Future<LastfmArtistInfo?> getArtistInfo({required String artist}) async =>
      parseArtistInfo(
          await _raw({'method': 'artist.getInfo', 'artist': artist}));

  @override
  Future<List<String>> getArtistTopTracks({required String artist}) async =>
      parseTopTracks(
          await _raw({'method': 'artist.getTopTracks', 'artist': artist}));

  @override
  Future<List<LastfmRecentTrack>> getRecentTracks({
    required String username,
    int limit = 10,
  }) async {
    final data = await _raw({
      'method': 'user.getRecentTracks',
      'user': username,
      'limit': limit.toString(),
    });
    return parseRecentTracks(data);
  }

  static int? _toInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  /// Last.fm wiki/bio summaries end with an HTML "Read more" link — strip tags.
  static String? _cleanSummary(dynamic wiki) {
    if (wiki is! Map) return null;
    final summary = wiki['summary'] as String?;
    if (summary == null || summary.trim().isEmpty) return null;
    var text = summary.replaceAll(RegExp(r'<a[^>]*>.*?</a>', dotAll: true), '');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    return text.isEmpty ? null : text;
  }

  static LastfmTrackInfo? parseTrackInfo(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    final track = (json is Map) ? json['track'] : null;
    if (track is! Map) return null;
    final album = track['album'];
    return LastfmTrackInfo(
      listeners: _toInt(track['listeners']),
      playcount: _toInt(track['playcount']),
      durationMs: _toInt(track['duration']),
      album: album is Map ? album['title'] as String? : null,
      summary: _cleanSummary(track['wiki']),
    );
  }

  static LastfmArtistInfo? parseArtistInfo(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    final artist = (json is Map) ? json['artist'] : null;
    if (artist is! Map) return null;
    final stats = artist['stats'];
    return LastfmArtistInfo(
      listeners: stats is Map ? _toInt(stats['listeners']) : null,
      playcount: stats is Map ? _toInt(stats['playcount']) : null,
      summary: _cleanSummary(artist['bio']),
    );
  }

  static List<String> parseTopTracks(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    final top = (json is Map) ? json['toptracks'] : null;
    final list = (top is Map) ? top['track'] : null;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((t) => t['name'] as String?)
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
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

  static List<LastfmRecentTrack> parseRecentTracks(dynamic data) {
    final json = data is String ? jsonDecode(data) : data;
    if (json is! Map) return [];
    final recent = json['recenttracks'];
    final list = recent is Map ? recent['track'] : null;
    if (list is! List) return [];
    
    final items = <LastfmRecentTrack>[];
    for (final t in list) {
      if (t is! Map) continue;
      final name = t['name'] as String? ?? '';
      final artistMap = t['artist'];
      final artistName = artistMap is Map ? artistMap['#text'] as String? ?? '' : '';
      
      if (name.isEmpty || artistName.isEmpty) continue;
      
      String? imageUrl;
      final images = t['image'];
      if (images is List) {
        final largeImg = images.firstWhere(
          (img) => img is Map && img['size'] == 'large',
          orElse: () => images.firstWhere(
            (img) => img is Map && img['size'] == 'medium',
            orElse: () => images.firstOrNull,
          ),
        );
        if (largeImg is Map) {
          imageUrl = largeImg['#text'] as String?;
          if (imageUrl?.isEmpty ?? true) imageUrl = null;
        }
      }
      
      final mbid = t['mbid'] as String? ?? '';
      items.add(LastfmRecentTrack(
        title: name,
        artist: artistName,
        imageUrl: imageUrl,
        mbid: mbid.isNotEmpty ? mbid : null,
      ));
    }
    return items;
  }
}
