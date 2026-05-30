import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/pair_selector.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chips.dart';
import '../catalog/catalog_service.dart';

const _kindLabels = {'track': '곡', 'album': '앨범', 'artist': '아티스트'};
String _kindLabel(String k) => _kindLabels[k] ?? k;
String _kindFromLabel(String label) =>
    _kindLabels.entries.firstWhere((e) => e.value == label).key;

class DuelScreen extends ConsumerStatefulWidget {
  const DuelScreen({super.key, this.focusId});

  /// When set, runs *placement*: this newly added item duels existing same-kind
  /// items to find its rank, then finishes. When null, free-play duels.
  final String? focusId;

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  final _selector = PairSelector();
  (RatedCatalogItem, RatedCatalogItem)? _pair;
  String? _picked;

  /// Active duel kind (free mode only). Placement uses the focus item's kind.
  String? _kind;

  // Placement state.
  bool get _placement => widget.focusId != null;
  final _faced = <String>{};
  int _rounds = 0;
  int _target = 0;
  bool _done = false;

  static const _kindOrder = ['track', 'album', 'artist'];

  List<String> _availableKinds(List<RatedCatalogItem> items) => _kindOrder
      .where((k) => items.where((i) => i.kind == k).length >= 2)
      .toList();

  RatedItem _toRated(RatedCatalogItem i) =>
      RatedItem(id: i.id, elo: i.elo, comparisons: i.comparisons);

  // -------- placement --------
  void _ensurePlacementPair(List<RatedCatalogItem> items) {
    if (_done) return;
    final focus = items.where((i) => i.id == widget.focusId).firstOrNull;
    if (focus == null) {
      _done = true;
      return;
    }
    final candidates =
        items.where((i) => i.kind == focus.kind && i.id != focus.id).toList();
    if (candidates.isEmpty) {
      _done = true;
      return;
    }
    if (_target == 0) _target = PairSelector.placementRounds(candidates.length);
    if (_rounds >= _target) {
      _done = true;
      return;
    }
    final opp = PairSelector.nextPlacementOpponent(
      focus: _toRated(focus),
      candidates: candidates.map(_toRated).toList(),
      faced: _faced,
    );
    if (opp == null) {
      _done = true;
      return;
    }
    final oppItem = candidates.firstWhere((i) => i.id == opp.id);
    // Randomise sides so the new item isn't always on the left.
    _pair = _rounds.isEven ? (focus, oppItem) : (oppItem, focus);
  }

  // -------- free play --------
  void _ensureFreePair(List<RatedCatalogItem> items) {
    final kinds = _availableKinds(items);
    if (_kind == null || !kinds.contains(_kind)) {
      _kind = kinds.isEmpty ? null : kinds.first;
      _pair = _selectFree(items);
      return;
    }
    if (_pair != null) {
      final ids =
          items.where((i) => i.kind == _kind).map((e) => e.id).toSet();
      if (ids.contains(_pair!.$1.id) && ids.contains(_pair!.$2.id)) return;
    }
    _pair = _selectFree(items);
  }

  (RatedCatalogItem, RatedCatalogItem)? _selectFree(
      List<RatedCatalogItem> items) {
    final pool = items.where((i) => i.kind == _kind).toList();
    final pair = _selector.selectPair(pool.map(_toRated).toList());
    if (pair == null) return null;
    return (
      pool.firstWhere((i) => i.id == pair.$1.id),
      pool.firstWhere((i) => i.id == pair.$2.id),
    );
  }

  Future<void> _pick(String winnerId) async {
    if (_picked != null || _pair == null) return;
    final (a, b) = _pair!;
    final loserId = winnerId == a.id ? b.id : a.id;
    setState(() => _picked = winnerId);
    await ref
        .read(libraryControllerProvider.notifier)
        .recordComparison(winnerId: winnerId, loserId: loserId);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final fresh = ref.read(ratedItemsProvider);
    setState(() {
      _picked = null;
      if (_placement) {
        // The opponent this round was whichever card wasn't the focus.
        final oppId = a.id == widget.focusId ? b.id : a.id;
        _faced.add(oppId);
        _rounds++;
        _pair = null;
        _ensurePlacementPair(fresh);
      } else {
        _pair = _selectFree(fresh);
      }
    });
  }

  void _skip(List<RatedCatalogItem> items) {
    setState(() {
      if (_placement) {
        final (a, b) = _pair!;
        final oppId = a.id == widget.focusId ? b.id : a.id;
        _faced.add(oppId);
        _rounds++;
        _pair = null;
        _ensurePlacementPair(items);
      } else {
        _pair = _selectFree(items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = ref.watch(ratedItemsProvider);

    if (_placement) {
      _ensurePlacementPair(items);
    } else {
      _ensureFreePair(items);
    }
    final pair = _pair;
    final kinds = _availableKinds(items);

    // Placement finished → confirmation with the item's new rank.
    if (_placement && _done) {
      return _PlacementDone(focusId: widget.focusId!);
    }

    if (pair == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.compare_arrows_rounded, size: 56, color: p.faint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                    items.isEmpty
                        ? '듀얼을 시작하려면 음악을 추가하세요'
                        : '같은 종류끼리 겨뤄요 — 한 종류에 2개 이상 추가하면 시작돼요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go('/search'),
                  child: const Text('음악 검색'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final (a, b) = pair;
    final title = _placement
        ? '새로 추가한 ${_kindLabel(a.kind)}, 어느 쪽이 더 좋아요?'
        : '어떤 ${_kindLabel(_kind!)}이 더 좋아요?';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate'),
        leading: _placement
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/library'),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_placement) ...[
                _PlacementProgress(round: _rounds, target: _target),
                const SizedBox(height: AppSpacing.lg),
              ] else if (kinds.length > 1) ...[
                FilterChips(
                  options: [for (final k in kinds) _kindLabel(k)],
                  selected: _kindLabel(_kind!),
                  onSelect: (label) => setState(() {
                    _kind = _kindFromLabel(label);
                    _picked = null;
                    _pair = _selectFree(items);
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _DuelCard(
                        item: a,
                        dim: _picked != null && _picked != a.id,
                        win: _picked == a.id,
                        onTap: () => _pick(a.id),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DuelCard(
                        item: b,
                        dim: _picked != null && _picked != b.id,
                        win: _picked == b.id,
                        onTap: () => _pick(b.id),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  onPressed: _picked == null ? () => _skip(items) : null,
                  child: Text(_placement ? '잘 모르겠어요' : '건너뛰기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacementProgress extends StatelessWidget {
  const _PlacementProgress({required this.round, required this.target});
  final int round;
  final int target;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = target == 0 ? 0.0 : (round / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('순위 정하는 중 · ${round + 1}/$target',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: p.muted)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: value, minHeight: 6, backgroundColor: p.line),
        ),
      ],
    );
  }
}

class _PlacementDone extends ConsumerWidget {
  const _PlacementDone({required this.focusId});
  final String focusId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final items = ref.watch(ratedItemsProvider);
    final item = items.where((i) => i.id == focusId).firstOrNull;
    final sameKind = item == null
        ? <RatedCatalogItem>[]
        : (items.where((i) => i.kind == item.kind).toList()
          ..sort((a, b) => b.elo.compareTo(a.elo)));
    final rank = item == null
        ? 0
        : sameKind.indexWhere((i) => i.id == focusId) + 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 56, color: p.accent),
              const SizedBox(height: AppSpacing.lg),
              Text('순위가 정해졌어요',
                  style: Theme.of(context).textTheme.titleLarge),
              if (item != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '"${item.title}" — ${_kindLabel(item.kind)} ${sameKind.length}개 중 $rank위',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go('/library'),
                child: const Text('라이브러리 보기'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go('/search'),
                child: const Text('더 추가하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuelCard extends StatelessWidget {
  const _DuelCard({
    required this.item,
    required this.dim,
    required this.win,
    required this.onTap,
  });

  final RatedCatalogItem item;
  final bool dim;
  final bool win;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: dim ? 0.4 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, win ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: win ? p.accent : p.line, width: win ? 2 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BlurredArt(imageUrl: item.imageUrl, fallback: p.surface2),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        p.surface.withValues(alpha: 0.2),
                        p.surface.withValues(alpha: 0.87),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(item.primaryArtist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurredArt extends StatelessWidget {
  const _BlurredArt({required this.imageUrl, required this.fallback});
  final String? imageUrl;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return ColoredBox(color: fallback);
    }
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Transform.scale(
        scale: 1.25,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(color: fallback),
          loadingBuilder: (c, child, prog) =>
              prog == null ? child : ColoredBox(color: fallback),
        ),
      ),
    );
  }
}
