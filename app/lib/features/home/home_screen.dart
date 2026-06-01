import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../catalog/catalog_service.dart';
import '../friends/friends_service.dart';
import '../../i18n.dart';
import '../../widgets/update_banner.dart';
import '../../widgets/initial_score_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final recentAsync = ref.watch(recentlyPlayedProvider);
    final friendsRecentAsync = ref.watch(friendsRecentRatingsProvider);
    final ratedItems = ref.watch(ratedItemsProvider);
    final ratedIds = ratedItems.map((e) => e.id).toSet();
    final ratedKeys = ratedItems.map((r) {
      final title = r.title.toLowerCase().trim();
      final artist = (r.primaryArtist ?? '').toLowerCase().trim();
      return '${r.kind}_${title}_$artist';
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(friendsRecentRatingsProvider);
                try {
                  await ref.read(recentlyPlayedProvider.future);
                } catch (_) {}
                try {
                  await ref.read(friendsRecentRatingsProvider.future);
                } catch (_) {}
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
                children: [
                  Text(context.t('home_title', ref: ref),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  const _DuelCallout(onTap: null), // Tap behavior is embedded inside _DuelCallout or can be passed
                  
                  // Recommended Friend Ratings Section
                  friendsRecentAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) {
                      final unrated = items.where((it) {
                        final key = '${it.kind}_${it.title.toLowerCase().trim()}_${(it.primaryArtist ?? '').toLowerCase().trim()}';
                        return !ratedKeys.contains(key) && !ratedIds.contains(it.id);
                      }).toList();
                      if (unrated.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          const Text('친구들이 평가한 음악', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            children: unrated
                                .take(5)
                                .map((it) => _RecentCard(item: it))
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Text(context.t('home_recent', ref: ref),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  recentAsync.when(
                    loading: () => _skeletonList(p),
                    error: (e, _) => _RecentEmpty(message: context.t('home_recent_error', ref: ref)),
                    data: (items) {
                      // Surface only tracks the user hasn't rated yet (match by ID or normalized title/artist/kind).
                      final unrated = items.where((it) {
                        final key = '${it.kind}_${it.title.toLowerCase().trim()}_${(it.primaryArtist ?? '').toLowerCase().trim()}';
                        return !ratedKeys.contains(key) && !ratedIds.contains(it.id);
                      }).toList();
                      return unrated.isEmpty
                          ? const _RecentEmpty()
                          : Column(
                              children: unrated
                                  .take(10)
                                  .map((it) => _RecentCard(item: it))
                                  .toList(),
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonList(AppPalette p) => Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 72,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: p.line),
            ),
          ),
        ),
      );
}

class _DuelCallout extends ConsumerWidget {
  const _DuelCallout({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap ?? () => context.go('/duel'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Icon(Icons.compare_arrows_rounded, color: p.accentText, size: 28),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('home_start_duel', ref: ref),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.accentText)),
                  const SizedBox(height: 2),
                  Text(context.t('home_start_duel_sub', ref: ref),
                      style: TextStyle(color: p.accentText, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: p.accentText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends ConsumerStatefulWidget {
  const _RecentCard({required this.item});
  final CatalogItem item;

  @override
  ConsumerState<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends ConsumerState<_RecentCard> {
  bool _busy = false;

  Future<void> _rate() async {
    if (_busy) return;
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
    // Mirror the search-screen add flow: enrich tags, then run *placement*
    // (duel against existing same-kind items) instead of a plain free duel.
    final item = widget.item;
    final service = ref.read(catalogServiceProvider);
    final controller = ref.read(libraryControllerProvider.notifier);
    final hasOpponents = ref
        .read(ratedItemsProvider)
        .any((i) => i.kind == item.kind && i.id != item.id);

    var enriched = item;
    try {
      enriched = item.copyWithTags(await service.enrichTags(item));
    } catch (_) {
      // Enrichment is best-effort; add without tags on failure.
    }
    await controller.addItem(enriched, startingElo: startingElo);
    ref.invalidate(recentlyPlayedProvider);

    if (!mounted) return;
    if (hasOpponents) {
      router.go('/duel/${Uri.encodeComponent(enriched.id)}');
    } else {
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('"${enriched.title}" 추가됨 — 같은 종류를 더 추가하면 순위를 매겨요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          CoverArt(title: item.title, imageUrl: item.imageUrl, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(item.primaryArtist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _busy ? null : _rate,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(context.t('home_rate', ref: ref)),
          ),
        ],
      ),
    );
  }
}

class _RecentEmpty extends ConsumerWidget {
  const _RecentEmpty({this.message});
  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Icon(Icons.headphones_rounded, size: 40, color: p.faint),
          const SizedBox(height: AppSpacing.md),
          Text(message ?? context.t('home_spotify_connect_desc', ref: ref),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted)),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.go('/spotify-connect'),
            child: Text(context.t('home_spotify_connect', ref: ref)),
          ),
        ],
      ),
    );
  }
}
