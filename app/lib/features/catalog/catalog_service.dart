import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/itunes_api.dart';
import '../../api/lastfm_api.dart';
import '../../api/musicbrainz_api.dart';
import '../profile/profile_service.dart';

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
    this.playedAtUts,
  });

  final String id;
  final String kind; // 'track', 'album', 'artist'
  final String title;
  final String? primaryArtist;
  final String? imageUrl;
  final String? sourceId;
  final String? source;
  final List<CatalogTag> tags;
  final int? playedAtUts;

  CatalogItem copyWithTags(List<CatalogTag> tags) => CatalogItem(
        id: id,
        kind: kind,
        title: title,
        primaryArtist: primaryArtist,
        imageUrl: imageUrl,
        sourceId: sourceId,
        source: source,
        tags: tags,
        playedAtUts: playedAtUts,
      );

  CatalogItem copyWithImage(String? imageUrl) => CatalogItem(
        id: id,
        kind: kind,
        title: title,
        primaryArtist: primaryArtist,
        imageUrl: imageUrl,
        sourceId: sourceId,
        source: source,
        tags: tags,
        playedAtUts: playedAtUts,
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

  Map<String, dynamic> toJson() => {
        'album': album,
        'durationMs': durationMs,
        'year': year,
        'listeners': listeners,
        'playcount': playcount,
        'summary': summary,
        'genres': genres,
        'topTracks': topTracks,
      };

  factory ItemInfo.fromJson(Map<String, dynamic> j) => ItemInfo(
        album: j['album'] as String?,
        durationMs: (j['durationMs'] as num?)?.toInt(),
        year: j['year'] as String?,
        listeners: (j['listeners'] as num?)?.toInt(),
        playcount: (j['playcount'] as num?)?.toInt(),
        summary: j['summary'] as String?,
        genres: (j['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        topTracks: (j['topTracks'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class CatalogService {
  CatalogService({
    required ItunesApi itunesApi,
    required LastfmApi lastfmApi,
    required MusicBrainzApi musicBrainzApi,
  })  : _itunesApi = itunesApi,
        _lastfmApi = lastfmApi,
        _musicBrainzApi = musicBrainzApi;

  final ItunesApi _itunesApi;
  final LastfmApi _lastfmApi;
  final MusicBrainzApi _musicBrainzApi;

  /// [kind] is one of 'all', 'track', 'album', 'artist'. A specific kind sends
  /// the whole result limit to that type, so e.g. an artist's tracks aren't
  /// crowded out by albums/artists.
  Future<List<CatalogItem>> search(String query,
      {String kind = 'all', int offset = 0, int limit = kSearchPageSize}) async {
    final itunesEntity = _kindToItunesEntity(kind);
    return _itunesApi.search(query, entity: itunesEntity, offset: offset, limit: limit);
  }

  static String _kindToItunesEntity(String kind) => switch (kind) {
        'track' => 'song',
        'album' => 'album',
        'artist' => 'musicArtist',
        _ => 'song,album,musicArtist',
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

  /// Best-effort lookup of real cover art for an item that has none (or only a
  /// Last.fm placeholder). Searches the catalog and returns the first result's
  /// artwork, or null when nothing usable is found / offline.
  Future<String?> findArtworkUrl({
    required String kind,
    required String artist,
    required String title,
  }) async {
    final query = kind == 'artist' ? artist : '$artist $title'.trim();
    if (query.isEmpty) return null;
    try {
      final results = await search(query, kind: kind, limit: 5);
      for (final r in results) {
        final url = r.imageUrl;
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {
      // Offline / transient — leave the item art-less for now.
    }
    return null;
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
final itunesApiProvider = Provider<ItunesApi>((ref) => ItunesApiHttp());
final lastfmApiProvider = Provider<LastfmApi>((ref) => LastfmApiHttp());
final musicBrainzApiProvider =
    Provider<MusicBrainzApi>((ref) => MusicBrainzApiHttp());

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService(
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

/// Lazily fetches cover-art URL from iTunes for items that have no usable art
/// (Last.fm often returns missing or placeholder images). Keyed by (kind,
/// artist, title) so results are cached for the lifetime of the provider.
final artworkUrlProvider = FutureProvider.family<String?,
    ({String kind, String artist, String title})>((ref, args) async {
  final svc = ref.read(catalogServiceProvider);
  return svc.findArtworkUrl(
      kind: args.kind, artist: args.artist, title: args.title);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active search-kind filter: 'all' | 'track' | 'album' | 'artist'.
final searchKindProvider = StateProvider<String>((ref) => 'all');

/// Page size per search request.
const int kSearchPageSize = 10;

/// Aliases kept for call sites/tests; all equal [kSearchPageSize].
const int kSearchPageSizeSingle = kSearchPageSize;
const int kSearchPageSizeAll = kSearchPageSize;

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
      // More pages exist when a full page came back.
      final hasMore = page.isNotEmpty && page.length >= pageLimit;
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

// Recently played via Last.fm.
/// Normalizes a track/artist string for matching across sources, so the same
/// song scrobbled as "Idioteque", "Idioteque (Remastered)" or "Idioteque - 2011
/// Remaster" collapses to one identity. Used to (1) dedup repeated Last.fm
/// scrobbles and (2) hide already-rated tracks from the recent list.
String normalizeMatchText(String s) {
  var t = s.toLowerCase().trim();
  // Drop trailing qualifier in parens/brackets: (Remastered 2011), [Live], etc.
  t = t.replaceAll(
      RegExp(r'\s*[\(\[][^\)\]]*\b(remaster|remastered|live|version|edit|mix|deluxe|mono|stereo|feat|featuring|bonus|demo|acoustic|radio)\b[^\)\]]*[\)\]]'),
      '');
  // Drop trailing " - 2011 Remaster" / " - Live" style suffixes.
  t = t.replaceAll(
      RegExp(r'\s*-\s*[^-]*\b(remaster|remastered|live|version|edit|mix|deluxe|mono|stereo|anniversary)\b.*$'),
      '');
  // Drop "feat. X" / "featuring X" tails.
  t = t.replaceAll(RegExp(r'\s*(feat\.?|featuring|ft\.?)\s.*$'), '');
  // Strip punctuation/symbols while keeping all Unicode letters and digits
  // (Korean, Japanese, etc.). \w only covers ASCII so use \p{L}\p{N}.
  t = t.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t;
}

/// Cross-source identity key for a catalog item (kind + normalized title/artist).
String catalogMatchKey({required String kind, required String title, String? artist}) =>
    '${kind}_${normalizeMatchText(title)}_${normalizeMatchText(artist ?? '')}';

final recentlyPlayedProvider = FutureProvider<List<CatalogItem>>((ref) async {
  final profile = ref.watch(myProfileProvider).valueOrNull;
  if (profile == null) return [];

  final username = profile.lastfmUsername?.trim();
  if (username == null || username.isEmpty) return [];

  final lastfm = ref.watch(lastfmApiProvider);
  try {
    // Fetch more than shown — dedup collapses repeated scrobbles so we need headroom.
    final tracks = await lastfm.getRecentTracks(username: username, limit: 50);
    final seen = <String>{};
    final out = <CatalogItem>[];
    for (final t in tracks) {
      final artist = t.artist;
      final title = t.title;
      // Collapse repeated scrobbles of the same song (already sorted
      // now-playing/recent-first, so the first occurrence is the freshest).
      final dedupKey = catalogMatchKey(kind: 'track', title: title, artist: artist);
      if (!seen.add(dedupKey)) continue;

      final mbid = t.mbid;
      final sourceId = mbid ?? '${artist}_$title';
      // Keep the id as `source:sourceId` so a later remote sync (which rebuilds
      // ids that way) reconciles to the same row instead of duplicating it.
      out.add(CatalogItem(
        id: 'lastfm:$sourceId',
        kind: 'track',
        title: title,
        primaryArtist: artist,
        imageUrl: t.imageUrl,
        source: 'lastfm',
        sourceId: sourceId,
        playedAtUts: t.playedAtUts,
      ));
    }
    return out;
  } catch (e, st) {
    debugPrint('[lastfm] recentlyPlayedProvider error: $e\n$st');
    return [];
  }
});
