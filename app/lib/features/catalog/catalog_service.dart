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

/// Rich, on-demand detail info shown on the item detail screen. Not persisted.
class ItemInfo {
  const ItemInfo({
    this.album,
    this.durationMs,
    this.year,
    this.listeners,
    this.playcount,
    this.summary,
    this.genres = const [],
    this.topTracks = const [],
  });

  final String? album;
  final int? durationMs;
  final String? year;
  final int? listeners;
  final int? playcount;
  final String? summary;
  final List<String> genres;
  final List<String> topTracks;

  bool get isEmpty =>
      album == null &&
      durationMs == null &&
      year == null &&
      listeners == null &&
      playcount == null &&
      (summary == null || summary!.isEmpty) &&
      genres.isEmpty &&
      topTracks.isEmpty;
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
      {String kind = 'all', int offset = 0, int limit = 20}) async {
    final (spotifyTypes, itunesEntity) = _kindToFilters(kind);
    // 'all' mode asks Spotify for all three types in ONE request (not three
    // parallel calls) — Spotify's `/search` accepts a combined `type` filter,
    // and a single call costs 1/3 of the rate-limit budget. Artist images come
    // straight from the search payload, so no follow-up enrichment call.
    try {
      final results = await _spotifyApi.search(query,
          types: spotifyTypes, offset: offset, limit: limit);
      if (results.isNotEmpty) return results;
    } catch (_) {
      // Rate-limited or unavailable → fall through to iTunes.
    }
    return _itunesApi.search(query, entity: itunesEntity, limit: limit);
  }

  static (String, String) _kindToFilters(String kind) => switch (kind) {
        'track' => ('track', 'song'),
        'album' => ('album', 'album'),
        'artist' => ('artist', 'musicArtist'),
        _ => ('track,album,artist', 'song,album,musicArtist'),
      };

  /// Rich, on-demand detail info (not persisted) for the item detail screen:
  /// album/duration/year, Last.fm listener+play stats, a short summary/bio, extra
  /// genres, and — for artists — their top tracks. Every source is best-effort.
  Future<ItemInfo> fetchItemInfo({
    required String kind,
    required String artist,
    required String title,
  }) async {
    if (kind == 'artist') {
      LastfmArtistInfo? ai;
      var tops = const <String>[];
      try {
        ai = await _lastfmApi.getArtistInfo(artist: title);
      } catch (_) {}
      try {
        tops = await _lastfmApi.getArtistTopTracks(artist: title);
      } catch (_) {}
      return ItemInfo(
        listeners: ai?.listeners,
        playcount: ai?.playcount,
        summary: ai?.summary,
        topTracks: tops.take(8).toList(),
      );
    }

    LastfmTrackInfo? ti;
    var mb = const MbRecordingInfo();
    try {
      ti = await _lastfmApi.getTrackInfo(artist: artist, track: title);
    } catch (_) {}
    try {
      mb = await _musicBrainzApi.getRecordingInfo(artist: artist, title: title);
    } catch (_) {}
    return ItemInfo(
      album: ti?.album,
      durationMs: ti?.durationMs,
      year: mb.year,
      listeners: ti?.listeners,
      playcount: ti?.playcount,
      summary: ti?.summary,
      genres: mb.genres,
    );
  }

  Future<List<CatalogTag>> enrichTags(CatalogItem item) async {
    final tags = <CatalogTag>[];
    // For an artist item the name lives in `title`; otherwise it's the performer.
    final artist =
        (item.kind == 'artist' ? item.title : item.primaryArtist) ?? '';

    try {
      List<String> lfm;
      if (item.kind == 'artist') {
        lfm = await _lastfmApi.getArtistTopTags(artist: artist);
      } else {
        lfm = await _lastfmApi.getTopTags(artist: artist, track: item.title);
        // Obscure tracks have no track-level tags on Last.fm, but the artist
        // usually does — fall back so the item still gets genre/mood tags.
        if (lfm.isEmpty && artist.isNotEmpty) {
          lfm = await _lastfmApi.getArtistTopTags(artist: artist);
        }
      }
      tags.addAll(lfm.map((t) => CatalogTag(name: t, source: 'lastfm')));
    } catch (_) {}

    try {
      final mbGenres = await _musicBrainzApi.getGenres(
        artist: artist,
        title: item.title,
      );
      tags.addAll(mbGenres.map((t) => CatalogTag(name: t, source: 'musicbrainz')));
    } catch (_) {}

    // De-dupe by lowercased name (Last.fm + MusicBrainz overlap), cap the count.
    final seen = <String>{};
    return tags
        .where((t) => t.name.isNotEmpty && seen.add(t.name.toLowerCase()))
        .take(20)
        .toList();
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

/// On-demand rich info for an item, keyed by (kind, artist, title).
final itemInfoProvider = FutureProvider.family<ItemInfo,
    ({String kind, String artist, String title})>((ref, args) async {
  final svc = ref.watch(catalogServiceProvider);
  return svc.fetchItemInfo(
      kind: args.kind, artist: args.artist, title: args.title);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active search-kind filter: 'all' | 'track' | 'album' | 'artist'.
final searchKindProvider = StateProvider<String>((ref) => 'all');

/// Page size per request for single-kind (track/album/artist) searches.
const int kSearchPageSizeSingle = 20;

/// Per-type page size used when fetching 'all' results (one call per type).
const int kSearchPageSizeAll = 10;

/// Kept for backwards compatibility — equals the single-kind page size.
const int kSearchPageSize = kSearchPageSizeSingle;

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
    // Every mode paginates the same way now: ask for [kSearchPageSize] per
    // Spotify object type at the current offset and append. In 'all' mode the
    // single combined call returns that many of *each* type (up to 3×), so a
    // page is "full" whenever at least one type came back full.
    const pageLimit = kSearchPageSize;
    try {
      final page = await svc.search(query,
          kind: kind, offset: _offset, limit: pageLimit);
      if (gen != _generation) return; // a newer query/kind superseded this
      final fresh = page.where((i) => _seen.add(i.id)).toList();
      _offset += pageLimit;
      // More pages exist when the results came from Spotify (iTunes has no
      // reliable pagination) and a full page worth came back.
      final hasMore = page.isNotEmpty &&
          page.first.source != 'itunes' &&
          page.length >= pageLimit;
      state = state.copyWith(
        items: first ? fresh : [...state.items, ...fresh],
        loading: false,
        loadingMore: false,
        error: false,
        hasMore: hasMore,
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

/// Seed queries that drive the home recommendations. These are search *inputs*
/// (not displayed data) — the cards shown come from the real catalog API.
const _recommendSeeds = [
  'Radiohead',
  'Frank Ocean',
  'My Bloody Valentine',
  'Beach House',
  'King Krule',
  'Tyler, The Creator',
  '검정치마',
  'Slowdive',
];

/// A rotating set of albums to rate, fetched live and filtered to unrated items.
final recommendationsProvider =
    FutureProvider<List<CatalogItem>>((ref) async {
  final svc = ref.watch(catalogServiceProvider);
  // Rotate the seed daily so the home feed isn't identical every open.
  final seed = _recommendSeeds[
      DateTime.now().day % _recommendSeeds.length];
  try {
    final results = await svc.search(seed, kind: 'album');
    return results.take(12).toList();
  } catch (_) {
    return [];
  }
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
