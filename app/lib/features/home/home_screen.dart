import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../catalog/catalog_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentlyPlayedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate something',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => context.go('/duel'),
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Start a duel'),
                  ),
                ],
              ),
            ),
          ),
          recentAsync.when(
            data: (items) => items.isEmpty
                ? const SliverToBoxAdapter(
                    child: _EmptyRecentState(),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _RecentTrackCard(item: items[i]),
                      childCount: items.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentState extends StatelessWidget {
  const _EmptyRecentState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Search for music to rate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect Spotify to see tracks you\'ve recently listened to.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Learn about Spotify connect'),
          ),
        ],
      ),
    );
  }
}

class _RecentTrackCard extends StatelessWidget {
  const _RecentTrackCard({required this.item});
  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  item.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.music_note, size: 48),
                ),
              )
            : const Icon(Icons.music_note, size: 48),
        title: Text(item.title),
        subtitle: Text(item.primaryArtist ?? ''),
        trailing: FilledButton.tonal(
          onPressed: () {},
          child: const Text('Rate'),
        ),
      ),
    );
  }
}
