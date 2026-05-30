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
  const DuelScreen({super.key});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  final _selector = PairSelector();
  (RatedCatalogItem, RatedCatalogItem)? _pair;
  String? _picked;

  /// Active duel kind — only items of this kind are paired against each other
  /// (artists vs artists, albums vs albums, tracks vs tracks).
  String? _kind;

  static const _kindOrder = ['track', 'album', 'artist'];

  /// Kinds that have at least 2 rated items (a duel needs two).
  List<String> _availableKinds(List<RatedCatalogItem> items) {
    return _kindOrder
        .where((k) => items.where((i) => i.kind == k).length >= 2)
        .toList();
  }

  void _ensurePair(List<RatedCatalogItem> items) {
    final kinds = _availableKinds(items);
    // Keep _kind valid; default to the first available.
    if (_kind == null || !kinds.contains(_kind)) {
      _kind = kinds.isEmpty ? null : kinds.first;
      _pair = _select(items);
      return;
    }
    if (_pair != null) {
      final ids = items
          .where((i) => i.kind == _kind)
          .map((e) => e.id)
          .toSet();
      if (ids.contains(_pair!.$1.id) && ids.contains(_pair!.$2.id)) return;
    }
    _pair = _select(items);
  }

  (RatedCatalogItem, RatedCatalogItem)? _select(List<RatedCatalogItem> items) {
    final pool = items.where((i) => i.kind == _kind).toList();
    final rated = pool
        .map((i) =>
            RatedItem(id: i.id, elo: i.elo, comparisons: i.comparisons))
        .toList();
    final pair = _selector.selectPair(rated);
    if (pair == null) return null;
    final a = pool.firstWhere((i) => i.id == pair.$1.id);
    final b = pool.firstWhere((i) => i.id == pair.$2.id);
    return (a, b);
  }

  Future<void> _pick(String winnerId, List<RatedCatalogItem> items) async {
    if (_picked != null || _pair == null) return;
    final (a, b) = _pair!;
    setState(() => _picked = winnerId);
    final loserId = winnerId == a.id ? b.id : a.id;
    await ref
        .read(libraryControllerProvider.notifier)
        .recordComparison(winnerId: winnerId, loserId: loserId);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final fresh = ref.read(ratedItemsProvider);
    setState(() {
      _picked = null;
      _pair = _select(fresh);
    });
  }

  void _next(List<RatedCatalogItem> items) {
    setState(() => _pair = _select(items));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = ref.watch(ratedItemsProvider);
    _ensurePair(items);
    final pair = _pair;
    final kinds = _availableKinds(items);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Rate')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kinds.length > 1) ...[
                FilterChips(
                  options: [for (final k in kinds) _kindLabel(k)],
                  selected: _kindLabel(_kind!),
                  onSelect: (label) => setState(() {
                    _kind = _kindFromLabel(label);
                    _picked = null;
                    _pair = _select(items);
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('어떤 ${_kindLabel(_kind!)}이 더 좋아요?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _DuelCard(
                        item: a,
                        dim: _picked != null && _picked != a.id,
                        win: _picked == a.id,
                        onTap: () => _pick(a.id, items),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DuelCard(
                        item: b,
                        dim: _picked != null && _picked != b.id,
                        win: _picked == b.id,
                        onTap: () => _pick(b.id, items),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _picked == null ? () => _next(items) : null,
                      child: const Text('건너뛰기'),
                    ),
                    Text('•', style: TextStyle(color: p.faint)),
                    TextButton(
                      onPressed: _picked == null ? () => _next(items) : null,
                      child: const Text('너무 어려워요'),
                    ),
                  ],
                ),
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
