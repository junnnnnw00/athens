import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import 'catalog_service.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final addedIds = ref.watch(ratedItemsProvider).map((e) => e.id).toSet();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: '트랙, 앨범, 아티스트 검색…',
            border: InputBorder.none,
          ),
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
        ),
      ),
      body: query.trim().isEmpty
          ? _Hint(icon: Icons.search_rounded, text: '검색어를 입력하세요')
          : resultsAsync.when(
              loading: () => const _SearchSkeleton(),
              error: (e, _) => _Hint(
                  icon: Icons.cloud_off_rounded,
                  text: '검색에 실패했어요. 네트워크를 확인하세요.'),
              data: (items) => items.isEmpty
                  ? _Hint(
                      icon: Icons.sentiment_dissatisfied_rounded,
                      text: '결과가 없어요')
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: p.line, indent: AppSpacing.xl),
                      itemBuilder: (context, i) => _ResultRow(
                        item: items[i],
                        added: addedIds.contains(items[i].id),
                      ),
                    ),
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
    setState(() => _busy = true);
    final service = ref.read(catalogServiceProvider);
    var item = widget.item;
    try {
      final tags = await service.enrichTags(item);
      item = item.copyWithTags(tags);
    } catch (_) {
      // Enrichment is best-effort; add without tags on failure.
    }
    await ref.read(libraryControllerProvider.notifier).addItem(item);
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.title}" 추가됨')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = widget.added;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          CoverArt(
              title: widget.item.title,
              imageUrl: widget.item.imageUrl,
              size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(widget.item.primaryArtist ?? widget.item.kind,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
