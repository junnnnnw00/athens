import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../catalog/catalog_service.dart';
import '../catalog/search_screen.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/initial_score_dialog.dart';
import 'community_stats_section.dart';
import 'item_info_cache.dart';
import '../share/review_share.dart';
import '../friends/friends_service.dart';
import '../../i18n.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId, this.catalogItem});
  final String itemId;
  final CatalogItem? catalogItem;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _reviewController = TextEditingController();
  bool _editing = false;
  bool _loadedReview = false;
  bool _saving = false;
  bool _busy = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReview() async {
    final body =
        await ref.read(libraryRepositoryProvider).getReview(widget.itemId);
    if (mounted && body != null) {
      _reviewController.text = body;
      setState(() {});
    }
  }

  Future<void> _saveReview(double score) async {
    setState(() => _saving = true);
    await ref.read(libraryRepositoryProvider).upsertReview(
          itemId: widget.itemId,
          body: _reviewController.text.trim(),
          ratingSnapshot: score,
        );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }

  Future<void> _replace() async {
    final items = ref.read(ratedItemsProvider);
    final item = items.firstWhere((i) => i.id == widget.itemId);
    final score = await showDialog<double>(
      context: context,
      builder: (c) => InitialScoreDialog(
        title: item.kind == 'track'
            ? context.t('rate_prompt_track', ref: ref)
            : item.kind == 'album'
                ? context.t('rate_prompt_album', ref: ref)
                : context.t('rate_prompt_artist', ref: ref),
        itemTitle: item.title,
        itemArtist: item.kind == 'artist' ? null : item.primaryArtist,
        imageUrl: item.imageUrl,
        initialValue: scoreFromElo(item.elo),
        itemKind: item.kind,
      ),
    );
    if (score == null) return;
    final startingElo = eloFromScore(score);

    if (!mounted) return;
    await ref
        .read(libraryControllerProvider.notifier)
        .resetForPlacement(widget.itemId, startingElo: startingElo);
    if (mounted) {
      context.push('/duel/${Uri.encodeComponent(widget.itemId)}');
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.t('lib_delete_confirm_title', ref: ref)),
        content: Text(context.t('lib_delete_confirm_desc', ref: ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(context.t('lib_cancel', ref: ref))),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: Text(context.t('lib_delete', ref: ref))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(libraryControllerProvider.notifier).deleteItem(widget.itemId);
    if (!mounted) return;
    // Item is gone — return to wherever we came from (list refreshes). Fall back
    // to the library tab if this was opened via a deep link with no back stack.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/library');
    }
  }

  Future<void> _addFromUnrated() async {
    if (widget.catalogItem == null) return;
    final item = widget.catalogItem!;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    final score = await showDialog<double>(
      context: context,
      builder: (c) => InitialScoreDialog(
        title: item.kind == 'track'
            ? context.t('rate_prompt_track', ref: ref)
            : item.kind == 'album'
                ? context.t('rate_prompt_album', ref: ref)
                : context.t('rate_prompt_artist', ref: ref),
        itemTitle: item.title,
        itemArtist: item.kind == 'artist' ? null : item.primaryArtist,
        imageUrl: item.imageUrl,
        initialValue: 5.0,
        itemKind: item.kind,
      ),
    );
    if (score == null) return;
    final startingElo = eloFromScore(score);

    if (!mounted) return;
    final toastMsg = context.t('home_added_toast', args: [item.title], ref: ref);
    setState(() => _busy = true);

    final service = ref.read(catalogServiceProvider);
    final controller = ref.read(libraryControllerProvider.notifier);
    final hasOpponents = ref
        .read(ratedItemsProvider)
        .any((i) => i.kind == item.kind && i.id != item.id);

    var enrichedItem = item;
    try {
      final tags = await service.enrichTags(item);
      enrichedItem = item.copyWithTags(tags);
    } catch (_) {
      // Enrichment is best-effort
    }
    await controller.addItem(enrichedItem, startingElo: startingElo);

    if (hasOpponents) {
      router.push('/duel/${Uri.encodeComponent(enrichedItem.id)}');
    } else {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(toastMsg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = ref.watch(ratedItemsProvider);
    final item = items.where((i) => i.id == widget.itemId).firstOrNull;

    final isUnrated = item == null;
    if (isUnrated && widget.catalogItem == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.t('lib_item_not_found', ref: ref))),
      );
    }

    final String title = item == null ? widget.catalogItem!.title : item.title;
    final String? primaryArtist = item == null ? widget.catalogItem!.primaryArtist : item.primaryArtist;
    final String? imageUrl = item == null ? widget.catalogItem!.imageUrl : item.imageUrl;
    final String kind = item == null ? widget.catalogItem!.kind : item.kind;

    final storedTags = !isUnrated ? item.tags : widget.catalogItem?.tags ?? [];
    final liveTags = isUnrated && storedTags.isEmpty
        ? ref
            .watch(itemTagsProvider((
              kind: kind,
              artist: primaryArtist ?? '',
              title: title,
            )))
            .valueOrNull ??
            const <CatalogTag>[]
        : const <CatalogTag>[];
    final displayTags = storedTags.isNotEmpty ? storedTags : liveTags;

    if (!isUnrated && !_loadedReview) {
      _loadedReview = true;
      _loadReview();
    }

    final double score = item == null ? 0.0 : scoreFromElo(item.elo);

    return Scaffold(
      appBar: AppBar(
        actions: isUnrated
            ? null
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) {
                    if (v == 'replace') _replace();
                    if (v == 'delete') _confirmDelete();
                  },
                  itemBuilder: (c) => [
                    PopupMenuItem(
                      value: 'replace',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.refresh_rounded),
                        title: Text(context.t('lib_placement_test', ref: ref)),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: Text(context.t('lib_delete', ref: ref)),
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppLayout.scrollBottomInset(context)),
        children: [
          Center(
            child: CoverArt(
                title: title,
                imageUrl: imageUrl,
                size: 200,
                radius: kind == 'artist' ? 100 : AppRadii.card,
                artist: primaryArtist,
                kind: kind),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (primaryArtist != null) ...[
                      const SizedBox(height: 4),
                      Text(primaryArtist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (!isUnrated)
                ScoreRing(score: score, size: 64)
              else
                IconButton(
                  onPressed: _busy ? null : _addFromUnrated,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    backgroundColor: p.surface2,
                    foregroundColor: p.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(color: p.line),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isUnrated)
            Row(
              children: [
                _Stat(label: context.t('lib_duels', ref: ref), value: '${item.comparisons}'),
                const SizedBox(width: AppSpacing.xl),
                _Stat(label: 'Elo', value: item.elo.toStringAsFixed(0)),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Text(
                context.t('lib_unrated_message', ref: ref),
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
          if (displayTags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(context.t('lib_tags', ref: ref), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: displayTags.map((t) => _TagChip(t.name)).toList(),
            ),
          ],
          _InfoSection(
            kind: kind,
            artist: primaryArtist ?? '',
            title: title,
            catalogAlbum: widget.catalogItem?.album,
            catalogAlbumSourceId: widget.catalogItem?.albumSourceId,
            catalogTrackSourceId: widget.catalogItem?.source == 'itunes'
                ? widget.catalogItem?.sourceId
                : null,
          ),
          if (kind == 'album')
            _AlbumTracksSection(
              album: widget.catalogItem ??
                  CatalogItem(
                    id: widget.itemId,
                    kind: kind,
                    title: title,
                    primaryArtist: primaryArtist,
                    imageUrl: imageUrl,
                    source: '',
                    sourceId: null,
                  ),
            ),
          const SizedBox(height: AppSpacing.xxl),
          if (!isUnrated) ...[
            Row(
              children: [
                Expanded(
                  child: Text(context.t('lib_review', ref: ref),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                // Export as a wide score card; the review rides along as a
                // caption when one exists, but score-only sharing works too.
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    tooltip: context.t('lib_share_review', ref: ref),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showReviewShareSheet(
                      context,
                      ref,
                      title: title,
                      artist: primaryArtist,
                      imageUrl: imageUrl,
                      score: score,
                      review: _reviewController.text.trim(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_editing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    autofocus: true,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: context.t('lib_review_hint', ref: ref),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        borderSide: BorderSide(color: p.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        borderSide: BorderSide(color: p.accent, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _saving ? null : () => setState(() => _editing = false),
                        child: Text(context.t('lib_cancel', ref: ref)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _saving ? null : () => _saveReview(score),
                        child: _saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Text(context.t('lib_save', ref: ref)),
                      ),
                    ],
                  ),
                ],
              )
            else
              InkWell(
                onTap: () => setState(() => _editing = true),
                borderRadius: BorderRadius.circular(AppRadii.card),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.line),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Text(
                    _reviewController.text.isEmpty
                        ? context.t('lib_write_review_hint', ref: ref)
                        : _reviewController.text,
                    style: TextStyle(
                      color: _reviewController.text.isEmpty ? p.faint : p.text,
                    ),
                  ),
                ),
              ),
            CommunityStatsSection(itemId: widget.itemId),
          ] else ...[
            Center(
              child: SizedBox(
                width: 200,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _addFromUnrated,
                  icon: _busy
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.accentText,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: Text(context.t('lib_add_to_library', ref: ref)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.accentText,
                    side: BorderSide(color: p.accent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
          _FriendRatingsSection(itemId: widget.itemId),
        ],
      ),
    );
  }
}



class _FriendRatingsSection extends ConsumerWidget {
  const _FriendRatingsSection({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(friendRatingsForItemProvider(itemId));
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ratings) {
        if (ratings.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text(context.t('lib_friend_ratings', ref: ref), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...ratings.map((r) {
              final name = r.profile.displayName?.isNotEmpty == true
                  ? r.profile.displayName!
                  : r.profile.handle;
              return GestureDetector(
                onTap: () => context.push('/friends/compare/${r.profile.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: p.surface2,
                        backgroundImage: r.profile.avatarUrl != null
                            ? NetworkImage(r.profile.avatarUrl!)
                            : null,
                        child: r.profile.avatarUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 13, color: p.text),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          r.score.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.chevron_right_rounded, size: 16, color: p.faint),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
      ],
    );
  }
}

class _TagChip extends ConsumerWidget {
  const _TagChip(this.name);
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return InkWell(
      onTap: () {
        ref.read(searchQueryProvider.notifier).state = '';
        ref.read(selectedGenreProvider.notifier).state = name;
        context.go('/search');
      },
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: p.chip,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: p.line),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: p.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends ConsumerWidget {
  const _InfoSection({
    required this.kind,
    required this.artist,
    required this.title,
    this.catalogAlbum,
    this.catalogAlbumSourceId,
    this.catalogTrackSourceId,
  });
  final String kind;
  final String artist;
  final String title;
  final String? catalogAlbum;
  final String? catalogAlbumSourceId;
  /// iTunes trackId — used for direct collectionId lookup when albumSourceId is unavailable.
  final String? catalogTrackSourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final infoAsync = ref.watch(cachedItemInfoProvider((
      kind: kind,
      artist: artist,
      title: title,
    )));

    return infoAsync.when(
      data: (info) {
        if (info.isEmpty) return const SizedBox.shrink();

        final albumForLink = kind == 'track'
            ? (catalogAlbum?.isNotEmpty == true
                ? catalogAlbum
                : (info.album?.isNotEmpty == true ? info.album : null))
            : null;

        final facts = <String>[];
        if (info.year != null && info.year!.isNotEmpty) {
          facts.add(info.year!);
        }
        if (albumForLink == null && info.album != null && info.album!.isNotEmpty) {
          facts.add(info.album!);
        }
        if (info.durationMs != null && info.durationMs! > 0) {
          final minutes = info.durationMs! ~/ 60000;
          final seconds = (info.durationMs! % 60000) ~/ 1000;
          facts.add('$minutes:${seconds.toString().padLeft(2, '0')}');
        }

        final stats = <String>[];
        if (info.listeners != null) {
          stats.add(context.t('lib_listeners_count', args: [_formatNumber(info.listeners!)], ref: ref));
        }
        if (info.playcount != null) {
          stats.add(context.t('lib_play_count', args: [_formatNumber(info.playcount!)], ref: ref));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info genres (especially useful for unrated items without DB tags)
            if (info.genres.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(context.t('lib_genres_label', ref: ref), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: info.genres.map((g) => _TagChip(g)).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Facts row: year · duration (album shown separately as link for tracks)
            if (facts.isNotEmpty) ...[
              Text(
                facts.join(' · '),
                style: TextStyle(
                  color: p.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Tappable album link for tracks
            if (albumForLink != null) ...[
              GestureDetector(
                onTap: () async {
                  final itunes = ref.read(itunesApiProvider);
                  String? collectionId = catalogAlbumSourceId;
                  String? resolvedAlbumName = albumForLink;

                  // Path 2: direct iTunes track lookup for exact collectionId
                  if (collectionId == null && catalogTrackSourceId != null) {
                    try {
                      collectionId = await itunes.lookupCollectionId(catalogTrackSourceId!);
                    } catch (_) {}
                  }

                  // Path 3: search for track, prefer album-name fuzzy match
                  if (collectionId == null) {
                    try {
                      final hits = await itunes.search(
                          '$artist $title', entity: 'song', limit: 10);
                      String? fallbackId;
                      String? fallbackName;
                      const unwantedKeywords = [
                        'live', 'karaoke', 'tribute', 'cover version', 'covers',
                      ];
                      for (final h in hits) {
                        if (h.albumSourceId == null) continue;
                        final hAlbum = h.album?.toLowerCase().trim() ?? '';
                        final want = albumForLink.toLowerCase().trim();
                        // Skip live/tribute/karaoke unless the target album itself has those keywords
                        final isUnwanted = unwantedKeywords.any(
                            (kw) => hAlbum.contains(kw) && !want.contains(kw));
                        // Exact match first, then fuzzy (handles deluxe/remaster editions)
                        final exactMatch = hAlbum == want;
                        final fuzzyMatch = !isUnwanted &&
                            (hAlbum.contains(want) || want.contains(hAlbum));
                        if (exactMatch || fuzzyMatch) {
                          collectionId = h.albumSourceId;
                          resolvedAlbumName = h.album;
                          break;
                        }
                        if (!isUnwanted) {
                          fallbackId ??= h.albumSourceId;
                          fallbackName ??= h.album;
                        }
                      }
                      collectionId ??= fallbackId;
                      resolvedAlbumName ??= fallbackName ?? albumForLink;
                    } catch (_) {}
                  }

                  if (!context.mounted) return;

                  if (collectionId != null) {
                    final albumItem = CatalogItem(
                      id: 'itunes:$collectionId',
                      kind: 'album',
                      title: resolvedAlbumName ?? albumForLink,
                      primaryArtist: artist.isNotEmpty ? artist : null,
                      source: 'itunes',
                      sourceId: collectionId,
                    );
                    context.push(
                        '/home/item/${Uri.encodeComponent(albumItem.id)}',
                        extra: albumItem);
                    return;
                  }

                  // Fallback: text search
                  try {
                    final service = ref.read(catalogServiceProvider);
                    final results = await service.search(
                        '$artist $albumForLink', kind: 'album');
                    if (results.isEmpty || !context.mounted) return;
                    context.push(
                        '/home/item/${Uri.encodeComponent(results.first.id)}',
                        extra: results.first);
                  } catch (_) {}
                },
                child: Row(
                  children: [
                    Icon(Icons.album_rounded, size: 14, color: p.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        albumForLink,
                        style: TextStyle(color: p.muted, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: p.faint),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Stats row: listeners, playcount
            if (stats.isNotEmpty) ...[
              Text(
                stats.join(' · '),
                style: TextStyle(
                  color: p.faint,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Summary / Bio
            if (info.summary != null && info.summary!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                info.summary!,
                style: TextStyle(
                  color: p.text,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],

            // Artist top tracks
            if (kind == 'artist' && info.topTracks.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(context.t('lib_popular_tracks', ref: ref), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: info.topTracks.length,
                itemBuilder: (context, index) {
                  final trackName = info.topTracks[index];
                  return InkWell(
                    onTap: () {
                      ref.read(searchQueryProvider.notifier).state = trackName;
                      ref.read(searchKindProvider.notifier).state = 'track';
                      context.go('/search');
                    },
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: p.faint,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              trackName,
                              style: TextStyle(
                                color: p.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: p.faint,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}K';
    }
    return number.toString();
  }
}

class _AlbumTracksSection extends ConsumerWidget {
  const _AlbumTracksSection({required this.album});
  final CatalogItem album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tracksAsync = ref.watch(albumTracksProvider(album));

    return tracksAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.faint),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tracks) {
        if (tracks.isEmpty) return const SizedBox.shrink();

        final ratedItems = ref.watch(ratedItemsProvider);
        // Keyed by both the canonical (ISRC) key and the text key, so an
        // album track that was rated under a translated title still shows its
        // score (album tracks from iTunes carry ISRCs).
        final ratedKeys = <String, double>{};
        for (final r in ratedItems) {
          final score = scoreFromElo(r.elo);
          ratedKeys[r.canonicalKey] = score;
          ratedKeys[catalogMatchKey(
              kind: r.kind, title: r.title, artist: r.primaryArtist)] = score;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text(context.t('lib_tracklist', ref: ref),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...tracks.asMap().entries.map((entry) {
              final idx = entry.key;
              final track = entry.value;
              final score = ratedKeys[track.canonicalKey] ??
                  ratedKeys[catalogMatchKey(
                      kind: 'track', title: track.title, artist: track.primaryArtist ?? '')];

              return InkWell(
                onTap: () => context.push(
                  '/home/item/${Uri.encodeComponent(track.id)}',
                  extra: track,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${idx + 1}',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: score != null ? p.accentText : p.text,
                            fontWeight: score != null ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (score != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: p.accentText,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: p.faint),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
