import 'package:athens/api/itunes_api.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fakes.dart';

/// iTunes fake that returns deterministic pages based on offset.
class _PagingiTunes implements ItunesApi {
  @override
  Future<List<CatalogItem>> search(String query,
      {String entity = 'song,album,musicArtist',
      int offset = 0,
      int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    // Two full pages then a short page to signal end of results.
    if (offset >= kSearchPageSizeSingle * 2) {
      return [_item(offset)]; // short page → hasMore false
    }
    return List.generate(limit, (i) => _item(offset + i));
  }

  CatalogItem _item(int n) => CatalogItem(
        id: 'itunes:$n',
        kind: 'track',
        title: 'Track $n',
        primaryArtist: 'Artist',
        source: 'itunes',
        sourceId: '$n',
      );

  @override
  Future<List<CatalogItem>> getAlbumTracks(String collectionId) async => const [];
  @override
  Future<String?> lookupCollectionId(String trackId) async => null;
}

void main() {
  group('CatalogService search pagination (via service layer)', () {
    CatalogService makeSvc() => CatalogService(
          itunesApi: _PagingiTunes(),
          lastfmApi: FakeLastfmApi(),
          musicBrainzApi: FakeMusicBrainzApi(),
        );

    test('first page returns a full page', () async {
      final svc = makeSvc();
      final page1 = await svc.search('test', kind: 'track', offset: 0, limit: kSearchPageSizeSingle);
      expect(page1.length, kSearchPageSizeSingle);
    });

    test('second page returns the next kSearchPageSizeSingle items', () async {
      final svc = makeSvc();
      final page2 = await svc.search('test', kind: 'track', offset: kSearchPageSizeSingle, limit: kSearchPageSizeSingle);
      expect(page2.length, kSearchPageSizeSingle);
      // No overlap with first page
      expect(page2.first.id, isNot('itunes:0'));
    });

    test('short final page signals end of results', () async {
      final svc = makeSvc();
      final page3 = await svc.search('test', kind: 'track', offset: kSearchPageSizeSingle * 2, limit: kSearchPageSizeSingle);
      expect(page3.length, lessThan(kSearchPageSizeSingle));
    });

    test('empty query returns empty results', () async {
      final svc = makeSvc();
      final results = await svc.search('', kind: 'track');
      expect(results, isEmpty);
    });
  });
}
