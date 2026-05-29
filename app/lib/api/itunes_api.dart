import '../features/catalog/catalog_service.dart';

abstract class ItunesApi {
  Future<List<CatalogItem>> search(String query);
}

class FakeItunesApi implements ItunesApi {
  @override
  Future<List<CatalogItem>> search(String query) async {
    if (query.isEmpty) return [];
    return [
      CatalogItem(
        id: 'fake-itunes-1',
        kind: 'track',
        title: 'iTunes Fallback: $query',
        primaryArtist: 'iTunes Artist',
        imageUrl: null,
        source: 'itunes',
        sourceId: 'itunes-fake-1',
      ),
    ];
  }
}
