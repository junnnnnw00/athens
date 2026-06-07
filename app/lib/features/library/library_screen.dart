import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/score_ring.dart';
import '../catalog/catalog_service.dart';
import '../../i18n.dart';

final _libraryFilterProvider = StateProvider<String>((ref) => 'All');
final _lastLibraryOrderProvider = StateProvider<Map<String, List<String>>>((ref) => {});

/// How the library list is ordered.
enum LibrarySort { rank, recent, alpha, mostDueled }

final _librarySortProvider = StateProvider<LibrarySort>((ref) => LibrarySort.rank);
final _librarySearchProvider = StateProvider<String>((ref) => '');

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  static const _kinds = {'Albums': 'album', 'Tracks': 'track', 'Artists': 'artist'};

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<RatedCatalogItem>? _animatedItems;
  String? _lastFilter;
  bool _animating = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchOpen = ref.read(_librarySearchProvider).isNotEmpty;
    _searchController.text = ref.read(_librarySearchProvider);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    // Focus after the field is mounted so the keyboard rises on intent only.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchController.clear();
    ref.read(_librarySearchProvider.notifier).state = '';
    setState(() => _searchOpen = false);
  }

  Future<void> _refresh() =>
      ref.read(libraryControllerProvider.notifier).refresh();

  List<RatedCatalogItem> _sorted(List<RatedCatalogItem> list, LibrarySort sort) {
    final out = List<RatedCatalogItem>.from(list);
    switch (sort) {
      case LibrarySort.rank:
        out.sort((a, b) => b.elo.compareTo(a.elo));
      case LibrarySort.recent:
        out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case LibrarySort.alpha:
        out.sort((a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case LibrarySort.mostDueled:
        out.sort((a, b) => b.comparisons.compareTo(a.comparisons));
    }
    return out;
  }

  Widget _sortAction(LibrarySort sort, AppLanguage lang) {
    return PopupMenuButton<LibrarySort>(
      icon: Icon(Icons.sort_rounded,
          color: sort == LibrarySort.rank ? null : context.palette.accent),
      tooltip: context.t('lib_sort_tooltip', ref: ref),
      initialValue: sort,
      onSelected: (s) => ref.read(_librarySortProvider.notifier).state = s,
      itemBuilder: (c) => [
        _sortMenuItem(LibrarySort.rank, context.t('lib_sort_rank', ref: ref), sort),
        _sortMenuItem(
            LibrarySort.recent, context.t('lib_sort_recent', ref: ref), sort),
        _sortMenuItem(LibrarySort.alpha, context.t('lib_sort_alpha', ref: ref), sort),
        _sortMenuItem(
            LibrarySort.mostDueled, context.t('lib_sort_most_dueled', ref: ref), sort),
      ],
    );
  }

  PopupMenuItem<LibrarySort> _sortMenuItem(
      LibrarySort value, String label, LibrarySort current) {
    final selected = value == current;
    return PopupMenuItem<LibrarySort>(
      value: value,
      child: Row(
        children: [
          Icon(Icons.check_rounded,
              size: 16,
              color: selected ? context.palette.accent : Colors.transparent),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }

  /// The default (rank, no-search) view, with the smooth post-duel reorder
  /// animation. Returns the list to display.
  List<RatedCatalogItem> _resolveDefaultView(
      String filter, List<RatedCatalogItem> filtered) {
    if (_lastFilter != filter || _animatedItems == null) {
      _lastFilter = filter;
      final lastOrderMap = ref.read(_lastLibraryOrderProvider);
      final lastIds = lastOrderMap[filter];

      if (lastIds != null && lastIds.isNotEmpty) {
        final Map<String, int> orderMap = {
          for (int i = 0; i < lastIds.length; i++) lastIds[i]: i
        };
        final sortedToMatchLast = List<RatedCatalogItem>.from(filtered)
          ..sort((a, b) {
            final indexA = orderMap[a.id];
            final indexB = orderMap[b.id];
            if (indexA != null && indexB != null) {
              return indexA.compareTo(indexB);
            }
            if (indexA != null) return -1;
            if (indexB != null) return 1;
            return b.elo.compareTo(a.elo);
          });
        _animatedItems = sortedToMatchLast;

        if (!_animating) {
          _animating = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) {
                  setState(() {
                    _animatedItems = filtered;
                    _animating = false;
                  });
                  final newIds = filtered.map((i) => i.id).toList();
                  ref.read(_lastLibraryOrderProvider.notifier).update((state) => {
                        ...state,
                        filter: newIds,
                      });
                }
              });
            }
          });
        }
      } else {
        _animatedItems = filtered;
        final newIds = filtered.map((i) => i.id).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(_lastLibraryOrderProvider.notifier).update((state) => {
                  ...state,
                  filter: newIds,
                });
          }
        });
      }
    } else {
      if (!_animating) {
        _animatedItems = filtered;
        final newIds = filtered.map((i) => i.id).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(_lastLibraryOrderProvider.notifier).update((state) => {
                  ...state,
                  filter: newIds,
                });
          }
        });
      }
    }
    return _animatedItems ?? filtered;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(libraryControllerProvider);
    final filter = ref.watch(_libraryFilterProvider);
    final lang = ref.watch(localeProvider);

    final options = ['All', 'Albums', 'Tracks', 'Artists'];
    String getOptionLabel(String opt) {
      if (lang == AppLanguage.ko) {
        switch (opt) {
          case 'All': return '전체';
          case 'Albums': return '앨범';
          case 'Tracks': return '곡';
          case 'Artists': return '아티스트';
        }
      }
      return opt;
    }

    final sort = ref.watch(_librarySortProvider);
    final pending = ref.watch(pendingSyncProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _searchOpen
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: context.t('lib_close_tooltip', ref: ref),
                onPressed: _closeSearch,
              )
            : null,
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) =>
                    ref.read(_librarySearchProvider.notifier).state = v,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  isCollapsed: true,
                  hintText: context.t('lib_search_hint', ref: ref),
                  border: InputBorder.none,
                ),
              )
            : Text(context.t('profile_library', ref: ref)),
        actions: _searchOpen
            ? [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: context.t('lib_clear_tooltip', ref: ref),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(_librarySearchProvider.notifier).state = '';
                      setState(() {});
                    },
                  ),
                _sortAction(sort, lang),
              ]
            : [
                IconButton(
                  tooltip: context.t('lib_search_tooltip', ref: ref),
                  icon: const Icon(Icons.search_rounded),
                  onPressed: _openSearch,
                ),
                _sortAction(sort, lang),
                if (pending > 0)
                  IconButton(
                    tooltip: context.t('lib_sync_tooltip', args: ['$pending'], ref: ref),
                    icon: Badge(
                      label: Text('$pending'),
                      child: const Icon(Icons.cloud_upload_outlined),
                    ),
                    onPressed: _refresh,
                  ),
                IconButton(
                  tooltip: context.t('profile_stats', ref: ref),
                  icon: const Icon(Icons.bar_chart_rounded),
                  onPressed: () => context.push('/stats'),
                ),
                IconButton(
                  tooltip: context.t('profile_me', ref: ref),
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: () => context.push('/profile'),
                ),
              ],
      ),
      body: async.when(
        loading: () => const _LibrarySkeleton(),
        error: (e, _) => _LibraryError(message: '$e'),
        data: (items) {
          if (items.isEmpty) return const _LibraryEmpty();
          final kindFiltered = filter == 'All'
              ? items
              : items.where((i) => i.kind == LibraryScreen._kinds[filter]).toList();

          final query = ref.watch(_librarySearchProvider).trim().toLowerCase();
          final sort = ref.watch(_librarySortProvider);
          final searched = query.isEmpty
              ? kindFiltered
              : kindFiltered
                  .where((i) =>
                      i.title.toLowerCase().contains(query) ||
                      (i.primaryArtist ?? '').toLowerCase().contains(query) ||
                      i.tags.any((t) => t.name.toLowerCase().contains(query)))
                  .toList();

          // Default view keeps the post-duel reorder animation; search/sort show
          // the computed order directly (and reset the animation state).
          final isDefaultView = sort == LibrarySort.rank && query.isEmpty;
          final List<RatedCatalogItem> displayItems;
          if (isDefaultView) {
            displayItems = _resolveDefaultView(filter, searched);
          } else {
            _animatedItems = null;
            _lastFilter = null;
            displayItems = _sorted(searched, sort);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
                child: FilterChips(
                  options: options.map(getOptionLabel).toList(),
                  selected: getOptionLabel(filter),
                  onSelect: (v) {
                    final originalKey = options.firstWhere((opt) => getOptionLabel(opt) == v);
                    ref.read(_libraryFilterProvider.notifier).state = originalKey;
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: displayItems.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3),
                            Center(
                                child: Text(
                                    context.t('lib_empty_filter', ref: ref),
                                    style: TextStyle(color: p.muted))),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                              bottom: AppLayout.scrollBottomInset(context)),
                          itemCount: displayItems.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: p.line,
                            indent: AppSpacing.xl,
                          ),
                          itemBuilder: (context, index) {
                            return Material(
                              color: Colors.transparent,
                              child: _LibraryRow(
                                rank: index + 1,
                                item: displayItems[index],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LibraryRow extends ConsumerWidget {
  const _LibraryRow({required this.rank, required this.item});
  final int rank;
  final RatedCatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final score = scoreFromElo(item.elo);
    return InkWell(
      onTap: () => context.push('/library/item/${Uri.encodeComponent(item.id)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text('$rank',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(width: AppSpacing.md),
            CoverArt(title: item.title, imageUrl: item.imageUrl, size: 56),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${context.t('search_${item.kind}', ref: ref)} · ${item.primaryArtist ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if (rank == 1) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.workspace_premium_rounded,
                            size: 13, color: p.accentText),
                      ],
                    ],
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: item.tags
                          .take(3)
                          .map((t) => _MiniTag(t.name))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ScoreRing(score: score),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ConstrainedBox(
      // Cap width so a long tag name ellipsizes instead of spilling past the card.
      constraints: const BoxConstraints(maxWidth: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: p.chip,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: p.line),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style:
              TextStyle(color: p.muted, fontSize: 10.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LibraryEmpty extends ConsumerWidget {
  const _LibraryEmpty();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music_outlined, size: 56, color: p.faint),
            const SizedBox(height: AppSpacing.lg),
            Text(context.t('lib_no_rated_title', ref: ref),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(context.t('lib_no_rated_desc', ref: ref),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.go('/search'),
              child: Text(context.t('lib_search_music', ref: ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends ConsumerWidget {
  const _LibraryError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text(context.t('lib_load_error', ref: ref),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            _box(p.surface2, 56, 56, AppRadii.cover),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(p.surface2, 160, 14, 6),
                  const SizedBox(height: 8),
                  _box(p.surface, 100, 12, 6),
                ],
              ),
            ),
            _box(p.surface2, 48, 48, 24),
          ],
        ),
      ),
    );
  }

  Widget _box(Color c, double w, double h, double r) => Container(
        width: w,
        height: h,
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
      );
}
