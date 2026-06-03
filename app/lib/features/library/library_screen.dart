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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('profile_library', ref: ref)),
        actions: [
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
          final filtered = filter == 'All'
              ? items
              : items.where((i) => i.kind == LibraryScreen._kinds[filter]).toList();

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

          final displayItems = _animatedItems ?? filtered;

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
                child: displayItems.isEmpty
                    ? Center(
                        child: Text(context.t('lib_empty_filter', ref: ref),
                            style: TextStyle(color: p.muted)))
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                            bottom: AppLayout.scrollBottomInset(context)),
                        child: Builder(
                          builder: (context) {
                            final tops = <double>[];
                            final heights = <double>[];
                            double currentTop = 0.0;
                            for (final item in displayItems) {
                              final h = item.tags.isNotEmpty ? 126.0 : 86.0;
                              tops.add(currentTop);
                              heights.add(h);
                              currentTop += h;
                            }
                            return SizedBox(
                              height: currentTop,
                              child: Stack(
                                children: [
                                  for (int i = 0; i < displayItems.length; i++)
                                    AnimatedPositioned(
                                      key: ValueKey(displayItems[i].id),
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
                                      top: tops[i],
                                      left: 0,
                                      right: 0,
                                      height: heights[i],
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: _LibraryRow(rank: i + 1, item: displayItems[i]),
                                            ),
                                            Divider(height: 1, color: p.line, indent: AppSpacing.xl),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
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

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.rank, required this.item});
  final int rank;
  final RatedCatalogItem item;

  @override
  Widget build(BuildContext context) {
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
                          '${_kindLabel(item.kind)} · ${item.primaryArtist ?? '—'}',
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

  String _kindLabel(String kind) => switch (kind) {
        'album' => 'Album',
        'artist' => 'Artist',
        _ => 'Track',
      };
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

class _LibraryEmpty extends StatelessWidget {
  const _LibraryEmpty();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music_outlined, size: 56, color: p.faint),
            const SizedBox(height: AppSpacing.lg),
            Text('아직 평가한 음악이 없어요',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('검색해서 음악을 추가하고 듀얼을 시작하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted)),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.go('/search'),
              child: const Text('음악 검색'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryError extends StatelessWidget {
  const _LibraryError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: p.muted),
            const SizedBox(height: AppSpacing.md),
            Text('라이브러리를 불러오지 못했어요',
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
