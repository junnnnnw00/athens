import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_service.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tracks, albums, artists…',
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
        ),
      ),
      body: query.isEmpty
          ? const Center(child: Text('Type to search music'))
          : resultsAsync.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          leading: item.imageUrl != null
                              ? Image.network(item.imageUrl!,
                                  width: 48, height: 48, fit: BoxFit.cover)
                              : const Icon(Icons.music_note),
                          title: Text(item.title),
                          subtitle: Text(item.primaryArtist ?? item.kind),
                          trailing: FilledButton.tonal(
                            onPressed: () => _addToLibrary(ref, item),
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }

  void _addToLibrary(WidgetRef ref, CatalogItem item) {
    final existing = ref.read(ratedItemsProvider);
    if (existing.any((r) => r.id == item.id)) return;
    ref.read(ratedItemsProvider.notifier).state = [
      ...existing,
      RatedCatalogItem(
        id: item.id,
        kind: item.kind,
        title: item.title,
        primaryArtist: item.primaryArtist,
        imageUrl: item.imageUrl,
        elo: 1000,
        comparisons: 0,
        tags: item.tags,
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
