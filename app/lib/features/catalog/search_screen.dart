import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/filter_chips.dart';
import 'catalog_service.dart';

const _kindLabels = {
  '전체': 'all',
  '곡': 'track',
  '앨범': 'album',
  '아티스트': 'artist',
};
const _kindHeaders = {'track': '곡', 'album': '앨범', 'artist': '아티스트'};

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
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
    final resultsAsync = ref.watch(searchResultsProvider);
    final addedIds = ref.watch(ratedItemsProvider).map((e) => e.id).toSet();

    return resultsAsync.when(
      loading: () => const _SearchSkeleton(),
      error: (e, _) => _Hint(
          icon: Icons.cloud_off_rounded, text: '검색에 실패했어요. 네트워크를 확인하세요.'),
      data: (items) {
        if (items.isEmpty) {
          return _Hint(
              icon: Icons.sentiment_dissatisfied_rounded, text: '결과가 없어요');
        }
        // Group by kind, ordered 곡 → 앨범 → 아티스트, with section headers.
        const order = ['track', 'album', 'artist'];
        final rows = <Widget>[];
        for (final k in order) {
          final group = items.where((i) => i.kind == k).toList();
          if (group.isEmpty) continue;
          rows.add(_SectionHeader(
              label: _kindHeaders[k]!, count: group.length));
          for (final item in group) {
            rows.add(_ResultRow(
                item: item, added: addedIds.contains(item.id)));
            rows.add(Divider(
                height: 1, color: p.line, indent: AppSpacing.xl));
          }
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: rows,
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
