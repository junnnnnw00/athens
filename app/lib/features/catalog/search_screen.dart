import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../api/lastfm_api.dart' show LastfmRecentTrack;
import '../../widgets/cover_art.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/initial_score_dialog.dart';
import '../stats/stats_screen.dart';
import 'catalog_service.dart';
import '../../i18n.dart';

part 'widgets/search_widgets.dart';



final selectedGenreProvider = StateProvider<String?>((ref) => null);

final genreRecommendationsProvider = FutureProvider.autoDispose<({String genre, List<CatalogItem> items})>((ref) async {
  final statsAsync = await ref.watch(statsProvider.future);
  final selectedGenre = ref.watch(selectedGenreProvider);
  final defaultGenre = statsAsync.genrePreferences.firstOrNull?.name ?? 'Indie';
  final candidateGenres = <String>{
    if (selectedGenre != null && selectedGenre.trim().isNotEmpty) selectedGenre.trim(),
    if (defaultGenre.trim().isNotEmpty) defaultGenre.trim(),
    ...statsAsync.genrePreferences.map((pref) => pref.name.trim()).where((name) => name.isNotEmpty),
    'Indie',
  }.toList();
  
  final lastfm = ref.watch(lastfmApiProvider);
  final service = ref.watch(catalogServiceProvider);

  final ratedItems = ref.watch(ratedItemsProvider);
  final ratedIds = ratedItems.map((e) => e.id).toSet();
  final ratedKeys = ratedItems
      .map((r) => catalogMatchKey(kind: r.kind, title: r.title, artist: r.primaryArtist))
      .toSet();

  // Recommend tracks that are ACTUALLY tagged with the genre/mood via Last.fm
  // `tag.getTopTracks` — NOT a catalog text-search for the tag word, which only
  // returns songs that happen to contain the word in their title/artist (the
  // source of the "doesn't match the tag" recommendations). Walk the candidate
  // genres until one yields unrated picks.
  var genre = candidateGenres.first;
  List<CatalogItem> picks = const [];
  for (final candidate in candidateGenres) {
    List<LastfmRecentTrack> tagged;
    try {
      tagged = await lastfm.getTagTopTracks(tag: candidate, limit: 100);
    } catch (_) {
      tagged = const [];
    }
    if (tagged.isEmpty) continue;

    final seen = <String>{};
    final mapped = <CatalogItem>[];
    for (final t in tagged) {
      final key = catalogMatchKey(kind: 'track', title: t.title, artist: t.artist);
      if (!seen.add(key)) continue; // dedup repeated entries
      if (ratedKeys.contains(key)) continue; // skip already-rated
      final sourceId = t.mbid ?? '${t.artist}_${t.title}';
      final item = CatalogItem(
        id: 'lastfm:$sourceId',
        kind: 'track',
        title: t.title,
        primaryArtist: t.artist,
        imageUrl: t.imageUrl,
        source: 'lastfm',
        sourceId: sourceId,
      );
      if (ratedIds.contains(item.id)) continue;
      mapped.add(item);
      if (mapped.length >= 15) break;
    }
    if (mapped.isNotEmpty) {
      picks = mapped;
      genre = candidate;
      break;
    }
  }

  if (picks.isEmpty) {
    return (genre: genre, items: const <CatalogItem>[]);
  }

  // tag.getTopTracks usually omits artwork — enrich the final picks with a
  // targeted catalog lookup so rows show real covers, not initials tiles. The
  // Last.fm id is preserved (only the image is adopted) so a later sync still
  // reconciles correctly.
  final enriched = await Future.wait(picks.map((it) async {
    if (it.imageUrl != null && it.imageUrl!.isNotEmpty) return it;
    try {
      final hits = await service.search(
          '${it.primaryArtist ?? ''} ${it.title}'.trim(),
          kind: 'track',
          limit: 1);
      final img = hits.isNotEmpty ? hits.first.imageUrl : null;
      if (img != null && img.isNotEmpty) return it.copyWithImage(img);
    } catch (_) {}
    return it;
  }));

  return (genre: genre, items: enriched);
});

class SearchScreen extends ConsumerStatefulWidget {
  /// When [debounceDuration] is [Duration.zero] (the default) searches fire
  /// immediately on every keystroke — useful for tests and direct construction.
  /// Pass a non-zero duration (e.g. 400 ms) to debounce API calls in production.
  const SearchScreen(
      {super.key, this.debounceDuration = Duration.zero});

  /// The debounce delay before a search fires.
  final Duration debounceDuration;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    ref.read(selectedGenreProvider.notifier).state = null;
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (widget.debounceDuration == Duration.zero) {
      ref.read(searchQueryProvider.notifier).state = value;
      return;
    }
    _debounce = Timer(widget.debounceDuration, () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final kind = ref.watch(searchKindProvider);
    
    final kindLabels = {
      context.t('search_all', ref: ref): 'all',
      context.t('search_track', ref: ref): 'track',
      context.t('search_album', ref: ref): 'album',
      context.t('search_artist', ref: ref): 'artist',
    };
    final selectedLabel =
        kindLabels.entries.firstWhere((e) => e.value == kind).key;

    return Scaffold(
      appBar: AppBar(
        // Search is usually entered via `go('/search')` (no back stack), so the
        // automatic leading is absent — add an explicit back that pops when it
        // can and otherwise returns to Home.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: context.t('search_back_tooltip', ref: ref),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: context.t('search_hint', ref: ref),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
            child: FilterChips(
              options: kindLabels.keys.toList(),
              selected: selectedLabel,
              onSelect: (label) => ref
                  .read(searchKindProvider.notifier)
                  .state = kindLabels[label]!,
            ),
          ),
        ),
      ),
      body: query.trim().isEmpty
          ? const _SearchRecommendations()
          : const _SearchBody(),
    );
  }
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(searchControllerProvider);
    final kind = ref.watch(searchKindProvider);
    final addedIds = ref.watch(ratedItemsProvider).map((e) => e.id).toSet();

    if (s.loading) return const _SearchSkeleton();
    if (s.error) {
      return _Hint(
          icon: Icons.cloud_off_rounded, text: context.t('search_error', ref: ref));
    }
    if (s.items.isEmpty) {
      return _Hint(
          icon: Icons.sentiment_dissatisfied_rounded, text: context.t('search_no_results', ref: ref));
    }

    // Group by kind, ordered 곡 → 앨범 → 아티스트, with section headers.
    const order = ['track', 'album', 'artist'];
    final rows = <Widget>[];
    for (final k in order) {
      final group = s.items.where((i) => i.kind == k).toList();
      if (group.isEmpty) continue;
      rows.add(_SectionHeader(label: context.t('search_$k', ref: ref), count: group.length));
      for (final item in group) {
        rows.add(_ResultRow(item: item, added: addedIds.contains(item.id)));
        rows.add(Divider(height: 1, color: p.line, indent: AppSpacing.xl));
      }
      if (kind == 'all' && group.length >= kSearchPageSizeAll) {
        rows.add(
          InkWell(
            onTap: () {
              ref.read(searchKindProvider.notifier).state = k;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xl,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.t('search_category_more', args: [context.t('search_$k', ref: ref)], ref: ref),
                    style: TextStyle(
                      color: p.accentText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: p.accentText,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
        rows.add(Divider(height: 1, color: p.line, indent: AppSpacing.xl));
      }
    }
    if (s.hasMore) {
      rows.add(
        s.loadingMore
            ? const _LoadMoreShimmer()
            : Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(searchControllerProvider.notifier).loadMore(),
                    child: Text(context.t('search_more', ref: ref)),
                  ),
                ),
              ),
      );
    }
    return ListView(
      padding: EdgeInsets.only(bottom: AppLayout.scrollBottomInset(context)),
      children: rows,
    );
  }
}

