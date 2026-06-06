import 'package:flutter_test/flutter_test.dart';
import 'package:athens/api/lastfm_api.dart';
import 'package:athens/api/musicbrainz_api.dart';
import 'package:athens/features/catalog/catalog_service.dart';

import '../fakes/fakes.dart';

void main() {
  group('CatalogService.search', () {
    test('returns iTunes results', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: FakeLastfmApi(),
        musicBrainzApi: FakeMusicBrainzApi(),
      );

      final results = await svc.search('shoegaze');
      expect(results, isNotEmpty);
      expect(results.first.source, 'itunes');
    });

    test('returns empty list for empty query', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: FakeLastfmApi(),
        musicBrainzApi: FakeMusicBrainzApi(),
      );

      final results = await svc.search('');
      expect(results, isEmpty);
    });
  });

  group('CatalogService.enrichTags', () {
    test('returns combined tags from Last.fm and MusicBrainz', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: FakeLastfmApi(),
        musicBrainzApi: FakeMusicBrainzApi(),
      );

      const item = CatalogItem(
        id: 'test',
        kind: 'track',
        title: 'Only Shallow',
        primaryArtist: 'My Bloody Valentine',
      );

      final tags = await svc.enrichTags(item);
      expect(tags, isNotEmpty);
      expect(tags.any((t) => t.source == 'lastfm'), isTrue);
      expect(tags.any((t) => t.source == 'musicbrainz'), isTrue);
    });

    test('gracefully handles Last.fm failure', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: _ThrowingLastfmApi(),
        musicBrainzApi: FakeMusicBrainzApi(),
      );

      const item = CatalogItem(id: 'test', kind: 'track', title: 'Test');
      final tags = await svc.enrichTags(item);
      // Should still return MusicBrainz tags
      expect(tags.any((t) => t.source == 'musicbrainz'), isTrue);
    });

    test('gracefully handles MusicBrainz failure', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: FakeLastfmApi(),
        musicBrainzApi: _ThrowingMusicBrainzApi(),
      );

      const item = CatalogItem(id: 'test', kind: 'track', title: 'Test');
      final tags = await svc.enrichTags(item);
      // Should still return Last.fm tags
      expect(tags.any((t) => t.source == 'lastfm'), isTrue);
    });

    test('returns empty list when all APIs fail', () async {
      final svc = CatalogService(
        itunesApi: FakeItunesApi(),
        lastfmApi: _ThrowingLastfmApi(),
        musicBrainzApi: _ThrowingMusicBrainzApi(),
      );

      const item = CatalogItem(id: 'test', kind: 'track', title: 'Test');
      final tags = await svc.enrichTags(item);
      expect(tags, isEmpty);
    });
  });
}

class _ThrowingLastfmApi implements LastfmApi {
  @override
  Future<List<String>> getTopTags({required String artist, required String track}) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<List<String>> getArtistTopTags({required String artist}) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<LastfmTrackInfo?> getTrackInfo(
          {required String artist, required String track}) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<LastfmArtistInfo?> getArtistInfo({required String artist}) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<List<String>> getArtistTopTracks({required String artist}) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<List<LastfmRecentTrack>> getRecentTracks({
    required String username,
    int limit = 10,
  }) =>
      Future.error(Exception('Last.fm unavailable'));

  @override
  Future<List<LastfmRecentTrack>> getTagTopTracks({
    required String tag,
    int limit = 30,
  }) =>
      Future.error(Exception('Last.fm unavailable'));
}

class _ThrowingMusicBrainzApi implements MusicBrainzApi {
  @override
  Future<List<String>> getGenres({required String artist, required String title}) =>
      Future.error(Exception('MusicBrainz unavailable'));

  @override
  Future<MbRecordingInfo> getRecordingInfo(
          {required String artist, required String title}) =>
      Future.error(Exception('MusicBrainz unavailable'));
}
