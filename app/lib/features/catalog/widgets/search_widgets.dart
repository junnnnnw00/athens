part of '../search_screen.dart';

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
    final addedToast = context.t('home_added_toast', args: [widget.item.title], ref: ref);
    final dialogTitle = context.t('rate_prompt_${widget.item.kind}', ref: ref);
    final score = await showDialog<double>(
      context: context,
      builder: (c) => InitialScoreDialog(
        title: dialogTitle,
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
      router.push('/duel/${Uri.encodeComponent(item.id)}');
    } else {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(addedToast)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = widget.added;
    final item = widget.item;

    final String? resolvedUrl;
    if (hasUsableArt(item.imageUrl)) {
      resolvedUrl = item.imageUrl;
    } else {
      resolvedUrl = ref.watch(artworkUrlProvider((
        kind: item.kind,
        artist: item.primaryArtist ?? '',
        title: item.title,
      ))).valueOrNull;
    }

    return InkWell(
      onTap: () {
        context.push('/search/item/${Uri.encodeComponent(item.id)}',
            extra: item);
      },
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          children: [
            CoverArt(
                title: item.title,
                imageUrl: resolvedUrl,
                size: 48,
                radius: item.kind == 'artist' ? 24 : AppRadii.cover),
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
                          ? context.t('search_artist', ref: ref)
                          : '${context.t('search_${widget.item.kind}', ref: ref)} · ${widget.item.primaryArtist ?? ''}',
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
                    : Text(context.t('search_add', ref: ref)),
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
      padding: EdgeInsets.only(
          top: AppSpacing.sm, bottom: AppLayout.scrollBottomInset(context)),
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

class _SearchRecommendations extends ConsumerWidget {
  const _SearchRecommendations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final recsAsync = ref.watch(genreRecommendationsProvider);
    final addedIds = ref.watch(ratedItemsProvider).map((e) => e.id).toSet();
    final statsAsync = ref.watch(statsProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);

    return ListView(
      padding: EdgeInsets.only(
          top: AppSpacing.lg, bottom: AppLayout.scrollBottomInset(context)),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: statsAsync.when(
            loading: () => Container(
              height: 120,
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) {
              final isDefault = stats.genrePreferences.isEmpty;
              if (isDefault) {
                return Card(
                  color: p.surface2,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    side: BorderSide(color: p.line),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: p.accent, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.t('search_taste_engine_title', ref: ref),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: p.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.t('search_taste_engine_desc', ref: ref),
                          style: TextStyle(
                            fontSize: 12,
                            color: p.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              context.push('/duel');
                            },
                            icon: const Icon(Icons.bolt_rounded, size: 16),
                            label: Text(context.t('search_go_analyze', ref: ref)),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Has ratings and preferences
              final activeGenre = selectedGenre ?? recsAsync.valueOrNull?.genre ?? stats.genrePreferences.firstOrNull?.name ?? 'Indie';
              return Card(
                color: p.surface2,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  side: BorderSide(color: p.line),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.query_stats_rounded, color: p.accent, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            context.t('search_realtime_genres', ref: ref),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: p.text,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: p.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.t('search_updating_live', ref: ref),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: p.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.t('search_genre_desc', ref: ref),
                        style: TextStyle(
                          fontSize: 12,
                          color: p.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: stats.genrePreferences.take(3).map((pref) {
                          final isTop = pref.name == activeGenre;
                          return InkWell(
                            onTap: () {
                              ref.read(selectedGenreProvider.notifier).state = pref.name;
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isTop ? p.accent.withValues(alpha: 0.12) : p.chip,
                                border: Border.all(
                                  color: isTop ? p.accent : p.line,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isTop) ...[
                                    Icon(Icons.check_circle_rounded, color: p.accent, size: 12),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '#${pref.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                                      color: isTop ? p.accentText : p.text,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pref.averageScore.toStringAsFixed(1)}★',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isTop ? p.accentText.withValues(alpha: 0.8) : p.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        recsAsync.when(
          loading: () => const _RecommendationsSkeleton(),
          error: (e, _) => const SizedBox.shrink(),
          data: (data) {
            if (data.items.isEmpty) return const SizedBox.shrink();
            
            final isDefault = ref.read(statsProvider).valueOrNull?.genrePreferences.isEmpty ?? true;
            final activeGenre = ref.watch(selectedGenreProvider) ?? data.genre;
            final title = isDefault 
                ? context.t('home_recs_hot', args: [data.genre], ref: ref)
                : context.t('home_recs_personalized', args: [activeGenre], ref: ref);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...data.items.map((item) => Column(
                  children: [
                    _ResultRow(item: item, added: addedIds.contains(item.id)),
                    Divider(height: 1, color: p.line, indent: AppSpacing.xl),
                  ],
                )),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RecommendationsSkeleton extends StatelessWidget {
  const _RecommendationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 16,
            width: 180,
            decoration: BoxDecoration(
              color: p.surface2,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(AppRadii.cover),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
