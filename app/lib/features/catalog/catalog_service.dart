import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/spotify_api.dart';
import '../../api/itunes_api.dart';
import '../../api/lastfm_api.dart';
import '../../api/musicbrainz_api.dart';

class CatalogTag {
  const CatalogTag({required this.name, required this.source});
  final String name;
  final String source;
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.kind,
    required this.title,
    this.primaryArtist,
    this.imageUrl,
    this.sourceId,
    this.source,
    this.tags = const [],
  });

  final String id;
  final String kind; // 'track', 'album', 'artist'
  final String title;
  final String? primaryArtist;
  final String? imageUrl;
  final String? sourceId;
  final String? source;
  final List<CatalogTag> tags;

  CatalogItem copyWithTags(List<CatalogTag> tags) => CatalogItem(
        id: id,
        kind: kind,
        title: title,
        primaryArtist: primaryArtist,
        imageUrl: imageUrl,
        sourceId: sourceId,
        source: source,
        tags: tags,
      );
}

class RatedCatalogItem {
  const RatedCatalogItem({
    required this.id,
    required this.kind,
    required this.title,
    this.primaryArtist,
    this.imageUrl,
    required this.elo,
    required this.comparisons,
    required this.tags,
    required this.updatedAt,
  });

  final String id;
  final String kind;
  final String title;
  final String? primaryArtist;
  final String? imageUrl;
  final double elo;
  final int comparisons;
  final List<CatalogTag> tags;
  final DateTime updatedAt;

  RatedCatalogItem copyWith({
    double? elo,
    int? comparisons,
  }) {
    return RatedCatalogItem(
      id: id,
      kind: kind,
      title: title,
      primaryArtist: primaryArtist,
      imageUrl: imageUrl,
      elo: elo ?? this.elo,
      comparisons: comparisons ?? this.comparisons,
      tags: tags,
      updatedAt: updatedAt,
    );
  }
}

class CatalogService {
  CatalogService({
    required SpotifyApi spotifyApi,
    required ItunesApi itunesApi,
    required LastfmApi lastfmApi,
    required MusicBrainzApi musicBrainzApi,
  })  : _spotifyApi = spotifyApi,
        _itunesApi = itunesApi,
        _lastfmApi = lastfmApi,
        _musicBrainzApi = musicBrainzApi;

  final SpotifyApi _spotifyApi;
  final ItunesApi _itunesApi;
  final LastfmApi _lastfmApi;
  final MusicBrainzApi _musicBrainzApi;

  Future<List<CatalogItem>> search(String query) async {
    try {
      final results = await _spotifyApi.search(query);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fall through to iTunes
    }
    return _itunesApi.search(query);
  }

  Future<List<CatalogTag>> enrichTags(CatalogItem item) async {
    final tags = <CatalogTag>[];

    try {
      final lfmTags = await _lastfmApi.getTopTags(
        artist: item.primaryArtist ?? '',
        track: item.title,
      );
      tags.addAll(lfmTags.map((t) => CatalogTag(name: t, source: 'lastfm')));
    } catch (_) {}

    try {
      final mbGenres = await _musicBrainzApi.getGenres(
        artist: item.primaryArtist ?? '',
        title: item.title,
      );
      tags.addAll(mbGenres.map((t) => CatalogTag(name: t, source: 'musicbrainz')));
    } catch (_) {}

    return tags;
  }
}

// Providers — wire the real network implementations. Tests override these with
// test doubles (see test/fakes/); runtime code never imports one.
final spotifyApiProvider = Provider<SpotifyApi>((ref) => SpotifyApiHttp());
final itunesApiProvider = Provider<ItunesApi>((ref) => ItunesApiHttp());
final lastfmApiProvider = Provider<LastfmApi>((ref) => LastfmApiHttp());
final musicBrainzApiProvider =
    Provider<MusicBrainzApi>((ref) => MusicBrainzApiHttp());

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(
    spotifyApi: ref.watch(spotifyApiProvider),
    itunesApi: ref.watch(itunesApiProvider),
    lastfmApi: ref.watch(lastfmApiProvider),
    musicBrainzApi: ref.watch(musicBrainzApiProvider),
  );
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final svc = ref.watch(catalogServiceProvider);
  return svc.search(query);
});

// Recently played (Spotify-enabled users only).
final recentlyPlayedProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final spotify = ref.watch(spotifyApiProvider);
  try {
    return await spotify.getRecentlyPlayed();
  } catch (_) {
    return [];
  }
});
