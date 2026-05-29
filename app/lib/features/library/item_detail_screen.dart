import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/score_ring.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _reviewController = TextEditingController();
  bool _editing = false;
  bool _loadedReview = false;
  bool _saving = false;

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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (!_loadedReview) {
      _loadedReview = true;
      _loadReview();
    }
    final items = ref.watch(ratedItemsProvider);
    final item = items.where((i) => i.id == widget.itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('항목을 찾을 수 없어요.')),
      );
    }

    final score = scoreFromElo(item.elo);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, 110),
        children: [
          Center(
            child: CoverArt(
                title: item.title,
                imageUrl: item.imageUrl,
                size: 200,
                radius: AppRadii.card),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                    if (item.primaryArtist != null) ...[
                      const SizedBox(height: 2),
                      Text(item.primaryArtist!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ScoreRing(score: score, size: 64),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _Stat(label: '듀얼', value: '${item.comparisons}'),
              const SizedBox(width: AppSpacing.xl),
              _Stat(label: 'Elo', value: item.elo.toStringAsFixed(0)),
            ],
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('태그', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.map((t) => _TagChip(t.name)).toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
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
