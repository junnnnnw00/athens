import 'package:athens/api/spotify_api.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fakes.dart';

/// Spotify fake that returns full pages so pagination kicks in.
class _PagingSpotify implements SpotifyApi {
  @override
  Future<List<CatalogItem>> search(String query,
      {String types = 'track,album,artist', int offset = 0}) async {
    // Two full pages (>= kSearchPageSize), then a short final page.
    if (offset >= kSearchPageSize * 2) {
      return [_item(offset)]; // short page → hasMore false
    }
    return List.generate(kSearchPageSize, (i) => _item(offset + i));
  }

  CatalogItem _item(int n) => CatalogItem(
        id: 'spotify:$n',
        kind: 'track',
        title: 'Track $n',
        primaryArtist: 'Artist',
        source: 'spotify',
        sourceId: '$n',
      );

  @override
  Future<List<CatalogItem>> getRecentlyPlayed() async => [];
}

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer(overrides: [
      spotifyApiProvider.overrideWithValue(_PagingSpotify()),
      itunesApiProvider.overrideWithValue(FakeItunesApi()),
      lastfmApiProvider.overrideWithValue(FakeLastfmApi()),
      musicBrainzApiProvider.overrideWithValue(FakeMusicBrainzApi()),
    ]);
    // Keep the controller subscribed so it rebuilds eagerly on query/kind change.
    c.listen(searchControllerProvider, (_, __) {});
    return c;
  }

  test('first page loads and reports hasMore', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(searchQueryProvider.notifier).state = 'radiohead';
    // build() kicks off the async first page.
    c.read(searchControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final s = c.read(searchControllerProvider);
    expect(s.items.length, kSearchPageSize);
    expect(s.hasMore, isTrue);
    expect(s.loading, isFalse);
  });

  test('loadMore appends a second page and de-dupes', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(searchQueryProvider.notifier).state = 'radiohead';
    c.read(searchControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    c.read(searchControllerProvider.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final s = c.read(searchControllerProvider);
    expect(s.items.length, kSearchPageSize * 2);
    // Unique ids only.
    expect(s.items.map((e) => e.id).toSet().length, s.items.length);
  });

  test('reaching a short final page clears hasMore', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(searchQueryProvider.notifier).state = 'radiohead';
    c.read(searchControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    c.read(searchControllerProvider.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    c.read(searchControllerProvider.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final s = c.read(searchControllerProvider);
    expect(s.hasMore, isFalse);
  });

  test('changing the query resets results', () async {
    final c = makeContainer();
    addTearDown(c.dispose);
    c.read(searchQueryProvider.notifier).state = 'a';
    c.read(searchControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    c.read(searchControllerProvider.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.read(searchControllerProvider).items.length, kSearchPageSize * 2);

    c.read(searchQueryProvider.notifier).state = 'b';
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.read(searchControllerProvider).items.length, kSearchPageSize);
  });
}
