import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/initial_score_dialog.dart';
import '../stats/stats_screen.dart';
import 'catalog_service.dart';

part 'widgets/search_widgets.dart';

const _kindLabels = {
  '전체': 'all',
  '곡': 'track',
  '앨범': 'album',
  '아티스트': 'artist',
};
const _kindHeaders = {'track': '곡', 'album': '앨범', 'artist': '아티스트'};

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
  
  final service = ref.watch(catalogServiceProvider);
  
  final ratedItems = ref.watch(ratedItemsProvider);
  final ratedIds = ratedItems.map((e) => e.id).toSet();
  final ratedKeys = ratedItems.map((r) {
    final title = r.title.toLowerCase().trim();
    final artist = (r.primaryArtist ?? '').toLowerCase().trim();
    return '${r.kind}_${title}_$artist';
  }).toSet();

  List<CatalogItem> candidates = const [];
  var genre = candidateGenres.first;
  for (final candidateGenre in candidateGenres) {
    final rawResults = await service.search(candidateGenre, kind: 'track', limit: 30);
    final results = rawResults.where((item) {
      final title = item.title.toLowerCase().trim();
      final g = candidateGenre.toLowerCase().trim();
      // Filter out low-quality songs where the title is exactly the genre name or
      // starts with the genre name followed by common punctuation (e.g. "Shoegaze (Edit)", "Shoegaze - Mix")
      if (title == g) return false;
      if (title.startsWith('$g (') || title.startsWith('$g -')) return false;
      return true;
    }).toList();

    if (results.isNotEmpty) {
      candidates = results;
      genre = candidateGenre;
      break;
    }
  }

  if (candidates.isEmpty) {
    return (genre: genre, items: const <CatalogItem>[]);
  }

  // Filter out already rated items, but fall back to the raw candidate list if
  // everything in the current genre has already been rated.
  final unrated = candidates.where((it) {
    final key = '${it.kind}_${it.title.toLowerCase().trim()}_${(it.primaryArtist ?? '').toLowerCase().trim()}';
    return !ratedKeys.contains(key) && !ratedIds.contains(it.id);
  }).toList();

  return (genre: genre, items: (unrated.isNotEmpty ? unrated : candidates).take(5).toList());
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
    final selectedLabel =
        _kindLabels.entries.firstWhere((e) => e.value == kind).key;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: '트랙, 앨범, 아티스트 검색…',
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
              options: _kindLabels.keys.toList(),
              selected: selectedLabel,
              onSelect: (label) => ref
                  .read(searchKindProvider.notifier)
                  .state = _kindLabels[label]!,
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
          icon: Icons.cloud_off_rounded, text: '검색에 실패했어요. 네트워크를 확인하세요.');
    }
    if (s.items.isEmpty) {
      return _Hint(
          icon: Icons.sentiment_dissatisfied_rounded, text: '결과가 없어요');
    }

    // Group by kind, ordered 곡 → 앨범 → 아티스트, with section headers.
    const order = ['track', 'album', 'artist'];
    final rows = <Widget>[];
    for (final k in order) {
      final group = s.items.where((i) => i.kind == k).toList();
      if (group.isEmpty) continue;
      rows.add(_SectionHeader(label: _kindHeaders[k]!, count: group.length));
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
                    '${_kindHeaders[k]} 카테고리에서 더보기',
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
                    child: const Text('더 보기'),
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

