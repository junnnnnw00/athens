import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/pair_selector.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chips.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/cover_art.dart';
import '../catalog/catalog_service.dart';
import '../../i18n.dart';

String _localizedKindLabel(String k, AppLanguage lang, {bool plural = false}) {
  if (lang == AppLanguage.ko) {
    switch (k) {
      case 'track': return '곡';
      case 'album': return '앨범';
      case 'artist': return '아티스트';
      default: return k;
    }
  } else {
    switch (k) {
      case 'track': return plural ? 'tracks' : 'track';
      case 'album': return plural ? 'albums' : 'album';
      case 'artist': return plural ? 'artists' : 'artist';
      default: return k;
    }
  }
}

class DuelScreen extends ConsumerStatefulWidget {
  const DuelScreen({super.key, this.focusId, this.selector});

  /// When set, runs *placement*: this newly added item duels existing same-kind
  /// items to find its rank, then finishes. When null, free-play duels.
  final String? focusId;
  final PairSelector? selector;

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  late final PairSelector _selector;

  @override
  void initState() {
    super.initState();
    _selector = widget.selector ?? PairSelector();
  }

  @override
  void dispose() {
    _streakTimer?.cancel();
    super.dispose();
  }

  (RatedCatalogItem, RatedCatalogItem)? _pair;
  String? _picked;

  /// Active duel kind (free mode only). Placement uses the focus item's kind.
  String? _kind;

  bool _showStreakNudge = false;
  String _streakText = '';
  Timer? _streakTimer;

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
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      HapticFeedback.lightImpact();
    }
    final (a, b) = _pair!;
    final loserId = winnerId == a.id ? b.id : a.id;
    final winner = winnerId == a.id ? a : b;
    final loser = winnerId == a.id ? b : a;

    setState(() => _picked = winnerId);
    await ref
        .read(libraryControllerProvider.notifier)
        .recordComparison(winnerId: winnerId, loserId: loserId);

    // Calculate streaks
    final winnerStreak = await ref.read(libraryRepositoryProvider).getItemStreak(winnerId);
    final loserStreak = await ref.read(libraryRepositoryProvider).getItemStreak(loserId);

    final lang = ref.read(localeProvider);
    String streakText = '';
    bool showNudge = false;
    if (winnerStreak >= 2) {
      streakText = I18n.get('duel_win_streak', lang, [winner.title, '$winnerStreak']);
      showNudge = true;
    } else if (loserStreak <= -2) {
      streakText = I18n.get('duel_loss_streak', lang, [loser.title, '${-loserStreak}']);
      showNudge = true;
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    final fresh = ref.read(ratedItemsProvider);
    setState(() {
      _picked = null;
      if (showNudge) {
        _streakText = streakText;
        _showStreakNudge = true;
        _streakTimer?.cancel();
        _streakTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showStreakNudge = false;
            });
          }
        });
      }
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
      _showStreakNudge = false;
      _streakTimer?.cancel();
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

    final lang = ref.watch(localeProvider);

    if (pair == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('home_rate', ref: ref))),
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
                        ? context.t('duel_empty_library', ref: ref)
                        : context.t('duel_empty_sub', ref: ref),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: () => context.go('/search'),
                  child: Text(context.t('lib_search_music', ref: ref)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final (a, b) = pair;
    final title = _placement
        ? (lang == AppLanguage.ko
            ? '새로 추가한 ${_localizedKindLabel(a.kind, lang)}, 어느 쪽이 더 좋아요?'
            : 'Which ${_localizedKindLabel(a.kind, lang)} do you prefer for the new one?')
        : (lang == AppLanguage.ko
            ? '어떤 ${_localizedKindLabel(_kind!, lang)}이 더 좋아요?'
            : 'Which ${_localizedKindLabel(_kind!, lang)} do you prefer?');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home_rate', ref: ref)),
        leading: _placement
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => context.go('/library'),
              )
            : null,
      ),
      body: Stack(
        children: [
          SafeArea(
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
                      options: [for (final k in kinds) _localizedKindLabel(k, lang)],
                      selected: _localizedKindLabel(_kind!, lang),
                      onSelect: (label) => setState(() {
                        final kindKey = kinds.firstWhere((k) => _localizedKindLabel(k, lang) == label);
                        _kind = kindKey;
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
                      child: Text(_placement ? context.t('duel_not_sure', ref: ref) : context.t('duel_skip_btn', ref: ref)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlide(
                offset: _showStreakNudge ? Offset.zero : const Offset(0, -0.5),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _showStreakNudge ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _streakText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final lang = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('home_rate', ref: ref))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 28, color: p.accent),
                  const SizedBox(width: 8),
                  Text(
                    context.t('duel_placement_complete', ref: ref),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (item != null) ...[
                Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      CoverArt(
                        title: item.title,
                        imageUrl: item.imageUrl,
                        size: 110,
                        radius: item.kind == 'artist' ? 55 : AppRadii.card,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.primaryArtist != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.primaryArtist!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScoreRing(
                            score: scoreFromElo(item.elo),
                            size: 64,
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: p.accentSoft.withAlpha(38),
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            child: Text(
                              lang == AppLanguage.ko
                                  ? '${_localizedKindLabel(item.kind, lang)} ${sameKind.length}개 중 $rank위'
                                  : 'Rank $rank of ${sameKind.length} ${_localizedKindLabel(item.kind, lang, plural: true)}',
                              style: TextStyle(
                                color: p.accentText,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 240,
                child: FilledButton(
                  onPressed: () => context.go('/library'),
                  child: Text(context.t('duel_view_library', ref: ref)),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 240,
                child: TextButton(
                  onPressed: () => context.go('/search'),
                  child: Text(context.t('duel_add_more', ref: ref)),
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
                _DuelArt(
                    imageUrl: item.imageUrl,
                    title: item.title,
                    fallback: p.surface2,
                    faint: p.faint),
                // Bottom scrim only — keeps the album art crisp and readable up
                // top while the title/artist stay legible over the artwork.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(item.primaryArtist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70)),
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

class _DuelArt extends StatelessWidget {
  const _DuelArt({
    required this.imageUrl,
    required this.title,
    required this.fallback,
    required this.faint,
  });
  final String? imageUrl;
  final String title;
  final Color fallback;
  final Color faint;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      // No artwork — a clean monogram tile instead of an empty box.
      return ColoredBox(
        color: fallback,
        child: Center(
          child: Text(
            title.isEmpty ? '♪' : title.characters.first.toUpperCase(),
            style: TextStyle(
                color: faint, fontSize: 48, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(color: fallback),
      loadingBuilder: (c, child, prog) =>
          prog == null ? child : ColoredBox(color: fallback),
    );
  }
}
