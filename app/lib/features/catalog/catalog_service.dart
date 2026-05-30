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

  /// [kind] is one of 'all', 'track', 'album', 'artist'. A specific kind sends
  /// the whole result limit to that type, so e.g. an artist's tracks aren't
  /// crowded out by albums/artists.
  Future<List<CatalogItem>> search(String query,
      {String kind = 'all', int offset = 0}) async {
    final (spotifyTypes, itunesEntity) = _kindToFilters(kind);
    try {
      final results = await _spotifyApi.search(query,
          types: spotifyTypes, offset: offset);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Fall through to iTunes
    }
    return _itunesApi.search(query, entity: itunesEntity, offset: offset);
  }

  static (String, String) _kindToFilters(String kind) => switch (kind) {
        'track' => ('track', 'song'),
        'album' => ('album', 'album'),
        'artist' => ('artist', 'musicArtist'),
        _ => ('track,album,artist', 'song,album,musicArtist'),
      };

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

/// Active search-kind filter: 'all' | 'track' | 'album' | 'artist'.
final searchKindProvider = StateProvider<String>((ref) => 'all');

/// Page size per request (mirrors the API limit).
const int kSearchPageSize = 50;

/// Accumulated, paginated search results for the current query + kind.
class SearchState {
  const SearchState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error = false,
    this.hasMore = false,
  });

  final List<CatalogItem> items;
  final bool loading; // first page
  final bool loadingMore; // subsequent pages
  final bool error;
  final bool hasMore;

  SearchState copyWith({
    List<CatalogItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? error,
    bool? hasMore,
  }) =>
      SearchState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error ?? this.error,
        hasMore: hasMore ?? this.hasMore,
      );
}

class SearchController extends Notifier<SearchState> {
  int _offset = 0;
  int _generation = 0; // bumped each build; guards stale async writes
  final _seen = <String>{};

  @override
  SearchState build() {
    // Re-run the first page whenever the query or kind changes.
    final query = ref.watch(searchQueryProvider).trim();
    final kind = ref.watch(searchKindProvider);
    _offset = 0;
    _seen.clear();
    final gen = ++_generation;
    if (query.isEmpty) {
      return const SearchState();
    }
    _load(query, kind, first: true, gen: gen);
    return const SearchState(loading: true);
  }

  Future<void> _load(String query, String kind,
      {required bool first, required int gen}) async {
    final svc = ref.read(catalogServiceProvider);
    try {
      final page = await svc.search(query, kind: kind, offset: _offset);
      if (gen != _generation) return; // a newer query/kind superseded this
      final fresh = page.where((i) => _seen.add(i.id)).toList();
      _offset += kSearchPageSize;
      state = state.copyWith(
        items: first ? fresh : [...state.items, ...fresh],
        loading: false,
        loadingMore: false,
        error: false,
        // If the API returned a full page, assume there may be more.
        hasMore: page.length >= kSearchPageSize,
      );
    } catch (_) {
      if (gen != _generation) return;
      state = state.copyWith(
          loading: false, loadingMore: false, error: first ? true : false);
    }
  }

  /// Loads the next page (appends).
  void loadMore() {
    if (state.loadingMore || !state.hasMore) return;
    final query = ref.read(searchQueryProvider).trim();
    final kind = ref.read(searchKindProvider);
    if (query.isEmpty) return;
    state = state.copyWith(loadingMore: true);
    _load(query, kind, first: false, gen: _generation);
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

// Recently played (Spotify-enabled users only).
final recentlyPlayedProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final spotify = ref.watch(spotifyApiProvider);
  try {
    return await spotify.getRecentlyPlayed();
  } catch (_) {
    return [];
  }
});
