import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/score.dart';
import '../catalog/catalog_service.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  final _reviewController = TextEditingController();
  bool _editingReview = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ratedItemsProvider);
    final item = items.where((i) => i.id == widget.itemId).firstOrNull;

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item')),
        body: const Center(child: Text('Item not found.')),
      );
    }

    final score = scoreFromElo(item.elo);

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (item.imageUrl != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.album, size: 200),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          if (item.primaryArtist != null)
            Text(item.primaryArtist!,
                style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'Score',
                value: score.toStringAsFixed(1),
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Duels',
                value: '${item.comparisons}',
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Elo',
                value: item.elo.toStringAsFixed(0),
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags
                  .map((t) => Chip(
                        label: Text(t.name),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Text('Review', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_editingReview)
            Column(
              children: [
                TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Write your thoughts…',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _editingReview = false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _editingReview = false),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            )
          else
            InkWell(
              onTap: () => setState(() => _editingReview = true),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _reviewController.text.isEmpty
                      ? 'Tap to add a review…'
                      : _reviewController.text,
                  style: _reviewController.text.isEmpty
                      ? TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha:0.5))
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 18)),
          Text(label,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha:0.8))),
        ],
      ),
    );
  }
}
