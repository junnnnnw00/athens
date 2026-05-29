import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/score.dart';
import '../catalog/catalog_service.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(ratedItemsProvider);

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Library')),
        body: const Center(
          child: Text('No ratings yet. Start a duel to rate music!'),
        ),
      );
    }

    final sorted = List<RatedCatalogItem>.from(items)
      ..sort((a, b) => b.elo.compareTo(a.elo));

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final item = sorted[i];
          final score = scoreFromElo(item.elo);
          return ListTile(
            leading: Text(
              '#${i + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            title: Text(item.title),
            subtitle: Text(item.primaryArtist ?? item.kind),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                Text(
                  '${item.comparisons} duels',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
