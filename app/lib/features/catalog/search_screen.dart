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
import 'catalog_service.dart';

const _kindLabels = {
  '전체': 'all',
  '곡': 'track',
  '앨범': 'album',
  '아티스트': 'artist',
};
const _kindHeaders = {'track': '곡', 'album': '앨범', 'artist': '아티스트'};

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
          ? _Hint(icon: Icons.search_rounded, text: '검색어를 입력하세요')
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
      padding: const EdgeInsets.only(bottom: 130),
      children: rows,
    );
  }
}

/// Animated shimmer row shown while loading the next page of results.
class _LoadMoreShimmer extends StatefulWidget {
  const _LoadMoreShimmer();

  @override
  State<_LoadMoreShimmer> createState() => _LoadMoreShimmerState();
}

class _LoadMoreShimmerState extends State<_LoadMoreShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.3 + 0.5 * _anim.value;
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            children: [
              Opacity(
                opacity: opacity,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(AppRadii.cover),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: opacity * 0.7,
                      child: Container(
                        height: 10,
                        width: 120,
                        decoration: BoxDecoration(
                          color: p.surface2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: p.muted, letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Text('$count',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: p.faint)),
        ],
      ),
    );
  }
}

class _ResultRow extends ConsumerStatefulWidget {
  const _ResultRow({required this.item, required this.added});
  final CatalogItem item;
  final bool added;

  @override
  ConsumerState<_ResultRow> createState() => _ResultRowState();
}

class _ResultRowState extends ConsumerState<_ResultRow> {
  bool _busy = false;

  Future<void> _add() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final score = await showDialog<double>(
      context: context,
      builder: (c) => InitialScoreDialog(
        title: widget.item.kind == 'track'
            ? '이 곡은 어땠나요?'
            : widget.item.kind == 'album'
                ? '이 앨범은 어땠나요?'
                : '이 아티스트는 어땠나요?',
        itemTitle: widget.item.title,
        itemArtist: widget.item.kind == 'artist' ? null : widget.item.primaryArtist,
        imageUrl: widget.item.imageUrl,
        initialValue: 5.0,
        itemKind: widget.item.kind,
      ),
    );
    if (score == null) return;
    final startingElo = eloFromScore(score);

    if (!mounted) return;
    setState(() => _busy = true);
    // Capture everything that touches ref/context BEFORE any await — the row may
    // be disposed (e.g. by navigation) while the network call is in flight.
    final service = ref.read(catalogServiceProvider);
    final controller = ref.read(libraryControllerProvider.notifier);
    // Are there already-rated items of the same kind to place this against?
    final hasOpponents = ref
        .read(ratedItemsProvider)
        .any((i) => i.kind == widget.item.kind && i.id != widget.item.id);

    var item = widget.item;
    try {
      final tags = await service.enrichTags(item);
      item = item.copyWithTags(tags);
    } catch (_) {
      // Enrichment is best-effort; add without tags on failure.
    }
    await controller.addItem(item, startingElo: startingElo);

    if (hasOpponents) {
      // Place the new item by duelling it against existing same-kind items.
      router.go('/duel/${Uri.encodeComponent(item.id)}');
    } else {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('"${item.title}" 추가됨 — 같은 종류를 더 추가하면 순위를 매겨요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = widget.added;
    return InkWell(
      onTap: () {
        context.push('/item/${widget.item.id}', extra: widget.item);
      },
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            CoverArt(
                title: widget.item.title,
                imageUrl: widget.item.imageUrl,
                size: 48,
                // Artists get a circular avatar, releases a rounded square.
                radius: widget.item.kind == 'artist' ? 24 : AppRadii.cover),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                      widget.item.kind == 'artist'
                          ? '아티스트'
                          : '${_kindHeaders[widget.item.kind] ?? ''} · ${widget.item.primaryArtist ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (added)
              Icon(Icons.check_circle_rounded, color: context.palette.accent)
            else
              FilledButton(
                onPressed: _busy ? null : _add,
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('추가'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: p.faint),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: TextStyle(color: p.muted)),
        ],
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 130),
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: p.surface2,
                    borderRadius: BorderRadius.circular(AppRadii.cover))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(6))),
            ),
          ],
        ),
      ),
    );
  }
}
