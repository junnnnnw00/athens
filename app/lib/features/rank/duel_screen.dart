import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pair_selector.dart';
import '../../domain/elo.dart';
import '../catalog/catalog_service.dart';

final duelProvider = StateNotifierProvider<DuelNotifier, DuelState>((ref) {
  return DuelNotifier(ref.watch(ratedItemsProvider));
});

class DuelState {
  const DuelState({
    required this.items,
    this.pair,
    this.isLoading = false,
  });
  final List<RatedCatalogItem> items;
  final (RatedCatalogItem, RatedCatalogItem)? pair;
  final bool isLoading;
}

class DuelNotifier extends StateNotifier<DuelState> {
  DuelNotifier(List<RatedCatalogItem> items)
      : _selector = PairSelector(),
        super(DuelState(items: items)) {
    _pickNext();
  }

  final PairSelector _selector;

  void _pickNext() {
    final ratedItems = state.items
        .map((i) => RatedItem(id: i.id, elo: i.elo, comparisons: i.comparisons))
        .toList();
    final pair = _selector.selectPair(ratedItems);
    if (pair == null) {
      state = DuelState(items: state.items);
      return;
    }
    final a = state.items.firstWhere((i) => i.id == pair.$1.id);
    final b = state.items.firstWhere((i) => i.id == pair.$2.id);
    state = DuelState(items: state.items, pair: (a, b));
  }

  void pick(String winnerId) {
    final pair = state.pair;
    if (pair == null) return;
    final (a, b) = pair;
    final winner = winnerId == a.id ? a : b;
    final loser = winnerId == a.id ? b : a;
    final (wElo, lElo) = Elo.update(winner.elo, loser.elo);
    final updated = state.items.map((item) {
      if (item.id == winner.id) {
        return item.copyWith(
          elo: wElo,
          comparisons: item.comparisons + 1,
        );
      } else if (item.id == loser.id) {
        return item.copyWith(
          elo: lElo,
          comparisons: item.comparisons + 1,
        );
      }
      return item;
    }).toList();
    state = DuelState(items: updated);
    _pickNext();
  }
}

class DuelScreen extends ConsumerWidget {
  const DuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelState = ref.watch(duelProvider);
    final pair = duelState.pair;

    if (pair == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.music_note, size: 64),
              const SizedBox(height: 16),
              const Text('Add at least 2 items to start rating.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                child: const Text('Search music'),
              ),
            ],
          ),
        ),
      );
    }

    final (a, b) = pair;
    return Scaffold(
      appBar: AppBar(title: const Text('Which do you prefer?')),
      body: Column(
        children: [
          Expanded(child: _ItemCard(item: a, onTap: () {
            ref.read(duelProvider.notifier).pick(a.id);
          })),
          const Divider(height: 1),
          Expanded(child: _ItemCard(item: b, onTap: () {
            ref.read(duelProvider.notifier).pick(b.id);
          })),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onTap});
  final RatedCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (item.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.album, size: 120),
                ),
              )
            else
              const Icon(Icons.album, size: 120),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (item.primaryArtist != null) ...[
              const SizedBox(height: 4),
              Text(item.primaryArtist!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
