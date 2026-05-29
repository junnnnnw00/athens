import '../features/catalog/catalog_service.dart';

abstract class SpotifyApi {
  Future<List<CatalogItem>> search(String query);
  Future<List<CatalogItem>> getRecentlyPlayed();
}

class FakeSpotifyApi implements SpotifyApi {
  @override
  Future<List<CatalogItem>> search(String query) async {
    if (query.isEmpty) return [];
    return [
      CatalogItem(
        id: 'fake-spotify-1',
        kind: 'track',
        title: 'Fake Track: $query',
        primaryArtist: 'Fake Artist',
        imageUrl: null,
        source: 'spotify',
        sourceId: 'fake-1',
      ),
      CatalogItem(
        id: 'fake-spotify-2',
        kind: 'track',
        title: 'Another Fake Track',
        primaryArtist: 'Other Fake Artist',
        imageUrl: null,
        source: 'spotify',
        sourceId: 'fake-2',
      ),
    ];
  }

  @override
  Future<List<CatalogItem>> getRecentlyPlayed() async {
    // Spotify-disabled by default in tests/sandbox.
    return [];
  }
}
