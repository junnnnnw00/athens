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

  group('catalogCanonicalKey', () {
    test('track with ISRC keys on the ISRC (uppercased), title-independent', () {
      // Same recording listed under original + romanized titles → same key.
      final ja = catalogCanonicalKey(
          kind: 'track', title: '夜に駆ける', artist: 'YOASOBI', isrc: 'jpu902000123');
      final romaji = catalogCanonicalKey(
          kind: 'track', title: 'Yoru ni Kakeru', artist: 'YOASOBI', isrc: 'JPU902000123');
      expect(ja, 'isrc:JPU902000123');
      expect(ja, romaji);
    });

    test('track without ISRC falls back to the normalized text key', () {
      final key = catalogCanonicalKey(
          kind: 'track', title: 'Idioteque (Remastered)', artist: 'Radiohead');
      expect(key, catalogMatchKey(kind: 'track', title: 'Idioteque', artist: 'Radiohead'));
      expect(key.startsWith('isrc:'), isFalse);
    });

    test('album ignores ISRC and uses the text key', () {
      final key = catalogCanonicalKey(
          kind: 'album', title: 'Kid A', artist: 'Radiohead', isrc: 'SHOULDIGNORE');
      expect(key, catalogMatchKey(kind: 'album', title: 'Kid A', artist: 'Radiohead'));
    });

    test('CatalogItem.canonicalKey uses its ISRC', () {
      const item = CatalogItem(
          id: 'itunes:1', kind: 'track', title: 'X', primaryArtist: 'Y', isrc: 'us1234567890');
      expect(item.canonicalKey, 'isrc:US1234567890');
    });
  });

  group('resolveCanonicalKey + naturalKeysFor (manual merge)', () {
    test('with no aliases returns the natural key', () {
      final key = resolveCanonicalKey(
          kind: 'track', title: 'Into the Night', artist: 'YOASOBI', isrc: 'US111');
      expect(key, 'isrc:US111');
    });

    test('alias maps a searched item onto a merged target canonical key', () {
      // English release (different ISRC) merged onto the Japanese rating.
      const target = 'isrc:JPU902000123';
      final aliases = {
        for (final k in naturalKeysFor(
            kind: 'track', title: 'Into the Night', artist: 'YOASOBI', isrc: 'USABC1234567'))
          k: target,
      };
      // The searched English item now resolves to the Japanese canonical key.
      final resolved = resolveCanonicalKey(
          kind: 'track',
          title: 'Into the Night',
          artist: 'YOASOBI',
          isrc: 'USABC1234567',
          aliases: aliases);
      expect(resolved, target);
    });

    test('alias also matches by text key when the item carries no ISRC', () {
      const target = 'isrc:JPU902000123';
      final aliases = {
        for (final k in naturalKeysFor(
            kind: 'track', title: 'Into the Night', artist: 'YOASOBI'))
          k: target,
      };
      final resolved = resolveCanonicalKey(
          kind: 'track', title: 'Into the Night', artist: 'YOASOBI', aliases: aliases);
      expect(resolved, target);
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
