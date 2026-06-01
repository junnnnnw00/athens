import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../catalog/catalog_service.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/score_ring.dart';
import '../../widgets/initial_score_dialog.dart';

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
            ? '이 곡은 어땠나요?'
            : item.kind == 'album'
                ? '이 앨범은 어땠나요?'
                : '이 아티스트는 어땠나요?',
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
      context.go('/duel/${Uri.encodeComponent(widget.itemId)}');
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('라이브러리에서 삭제할까요?'),
        content: const Text('이 항목의 평가와 비교 기록이 모두 사라져요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(libraryControllerProvider.notifier).deleteItem(widget.itemId);
    if (mounted) context.go('/library');
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
            ? '이 곡은 어땠나요?'
            : item.kind == 'album'
                ? '이 앨범은 어땠나요?'
                : '이 아티스트는 어땠나요?',
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
      router.go('/duel/${Uri.encodeComponent(enrichedItem.id)}');
    } else {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('"${enrichedItem.title}" 추가됨 — 같은 종류를 더 추가하면 순위를 매겨요')),
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
        body: const Center(child: Text('항목을 찾을 수 없어요.')),
      );
    }

    if (!isUnrated && !_loadedReview) {
      _loadedReview = true;
      _loadReview();
    }

    final String title = item == null ? widget.catalogItem!.title : item.title;
    final String? primaryArtist = item == null ? widget.catalogItem!.primaryArtist : item.primaryArtist;
    final String? imageUrl = item == null ? widget.catalogItem!.imageUrl : item.imageUrl;
    final String kind = item == null ? widget.catalogItem!.kind : item.kind;

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
                    const PopupMenuItem(
                      value: 'replace',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.refresh_rounded),
                        title: Text('재배치고사'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('삭제'),
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, 110),
        children: [
          Center(
            child: CoverArt(
                title: title,
                imageUrl: imageUrl,
                size: 200,
                radius: kind == 'artist' ? 100 : AppRadii.card),
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
                IconButton.filled(
                  onPressed: _busy ? null : _addFromUnrated,
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(64, 64),
                    backgroundColor: p.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!isUnrated)
            Row(
              children: [
                _Stat(label: '듀얼', value: '${item.comparisons}'),
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
                '아직 라이브러리에 추가되지 않은 항목입니다.',
                style: TextStyle(color: p.muted, fontSize: 13),
              ),
            ),
          if (!isUnrated && item.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('태그', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.map((t) => _TagChip(t.name)).toList(),
            ),
          ],
          _InfoSection(
            kind: kind,
            artist: primaryArtist ?? '',
            title: title,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (!isUnrated) ...[
            Text('리뷰', style: Theme.of(context).textTheme.titleMedium),
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
                      hintText: '이 음악에 대한 생각을 적어보세요…',
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
                        child: const Text('취소'),
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
                            : const Text('저장'),
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
                        ? '탭해서 리뷰 작성…'
                        : _reviewController.text,
                    style: TextStyle(
                      color: _reviewController.text.isEmpty ? p.faint : p.text,
                    ),
                  ),
                ),
              ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy ? null : _addFromUnrated,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('라이브러리에 추가하여 평가하기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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

class _TagChip extends StatelessWidget {
  const _TagChip(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: p.line),
      ),
      child: Text(name,
          style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w500)),
    );
  }
}

class _InfoSection extends ConsumerWidget {
  const _InfoSection({
    required this.kind,
    required this.artist,
    required this.title,
  });
  final String kind;
  final String artist;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final infoAsync = ref.watch(itemInfoProvider((
      kind: kind,
      artist: artist,
      title: title,
    )));

    return infoAsync.when(
      data: (info) {
        if (info.isEmpty) return const SizedBox.shrink();

        final facts = <String>[];
        if (info.year != null && info.year!.isNotEmpty) {
          facts.add(info.year!);
        }
        if (info.album != null && info.album!.isNotEmpty) {
          facts.add(info.album!);
        }
        if (info.durationMs != null && info.durationMs! > 0) {
          final minutes = info.durationMs! ~/ 60000;
          final seconds = (info.durationMs! % 60000) ~/ 1000;
          facts.add('$minutes:${seconds.toString().padLeft(2, '0')}');
        }

        final stats = <String>[];
        if (info.listeners != null) {
          stats.add('청취자 ${_formatNumber(info.listeners!)}');
        }
        if (info.playcount != null) {
          stats.add('재생수 ${_formatNumber(info.playcount!)}');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info genres (especially useful for unrated items without DB tags)
            if (info.genres.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('장르', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: info.genres.map((g) => _TagChip(g)).toList(),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            
            // Facts row: year · album · duration
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
              Text('인기 트랙', style: Theme.of(context).textTheme.titleSmall),
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
