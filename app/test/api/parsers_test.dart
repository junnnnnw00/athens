import 'package:athens/api/itunes_api.dart';
import 'package:athens/api/lastfm_api.dart';
import 'package:athens/api/musicbrainz_api.dart';
import 'package:athens/api/spotify_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotifyApiHttp.parseSearch', () {
    test('parses tracks/albums/artists with cover art', () {
      const body = '''
      {
        "tracks": {"items": [
          {"id": "t1", "name": "Only Shallow",
           "artists": [{"name": "My Bloody Valentine"}],
           "album": {"images": [{"url": "https://img/loveless.jpg"}]}}
        ]},
        "albums": {"items": [
          {"id": "al1", "name": "Souvlaki",
           "artists": [{"name": "Slowdive"}],
           "images": [{"url": "https://img/souvlaki.jpg"}]}
        ]},
        "artists": {"items": [
          {"id": "ar1", "name": "Cocteau Twins",
           "images": [{"url": "https://img/ct.jpg"}]}
        ]}
      }''';
      final items = SpotifyApiHttp.parseSearch(body);
      expect(items.length, 3);
      final track = items.firstWhere((i) => i.kind == 'track');
      expect(track.title, 'Only Shallow');
      expect(track.primaryArtist, 'My Bloody Valentine');
      expect(track.imageUrl, 'https://img/loveless.jpg');
      expect(track.source, 'spotify');
      expect(items.any((i) => i.kind == 'album' && i.title == 'Souvlaki'), isTrue);
      expect(items.any((i) => i.kind == 'artist'), isTrue);
    });

    test('parseRecentlyPlayed de-duplicates repeated tracks', () {
      const body = '''
      {"items": [
        {"track": {"id": "t1", "name": "Sometimes",
          "artists": [{"name": "MBV"}], "album": {"images": []}}},
        {"track": {"id": "t1", "name": "Sometimes",
          "artists": [{"name": "MBV"}], "album": {"images": []}}},
        {"track": {"id": "t2", "name": "Blown a Wish",
          "artists": [{"name": "MBV"}], "album": {"images": []}}}
      ]}''';
      final items = SpotifyApiHttp.parseRecentlyPlayed(body);
      expect(items.length, 2);
    });

    test('tolerates empty / malformed bodies', () {
      expect(SpotifyApiHttp.parseSearch(''), isEmpty);
      expect(SpotifyApiHttp.parseSearch('null'), isEmpty);
    });
  });

  group('ItunesApiHttp.parseSearch', () {
    test('maps wrapperType and upgrades artwork resolution', () {
      const body = '''
      {"resultCount": 2, "results": [
        {"wrapperType": "track", "trackId": 1, "trackName": "Souvlaki Space Station",
         "artistName": "Slowdive", "artworkUrl100": "https://itu/100x100bb.jpg"},
        {"wrapperType": "collection", "collectionId": 2,
         "collectionName": "Souvlaki", "artistName": "Slowdive",
         "artworkUrl100": "https://itu/a-100x100bb.jpg"}
      ]}''';
      final items = ItunesApiHttp.parseSearch(body);
      expect(items.length, 2);
      expect(items[0].kind, 'track');
      expect(items[0].imageUrl, 'https://itu/600x600bb.jpg');
      expect(items[1].kind, 'album');
      expect(items[1].source, 'itunes');
    });

    test('returns empty for no results', () {
      expect(ItunesApiHttp.parseSearch('{"results": []}'), isEmpty);
    });
  });

  group('LastfmApiHttp.parseTags', () {
    test('extracts tag names from a getTopTags payload', () {
      final tags = LastfmApiHttp.parseTags({
        'toptags': {
          'tag': [
            {'name': 'shoegaze', 'count': 100},
            {'name': 'dream pop', 'count': 80},
          ]
        }
      });
      expect(tags, ['shoegaze', 'dream pop']);
    });

    test('returns empty on unexpected shape', () {
      expect(LastfmApiHttp.parseTags({'error': 6}), isEmpty);
    });
  });

  group('MusicBrainzApiHttp.parseGenres', () {
    test('flattens tags and genres from the first recording', () {
      const body = '''
      {"recordings": [
        {"title": "Only Shallow",
         "tags": [{"name": "shoegaze"}],
         "genres": [{"name": "dream pop"}]}
      ]}''';
      final genres = MusicBrainzApiHttp.parseGenres(body);
      expect(genres, containsAll(['shoegaze', 'dream pop']));
    });

    test('returns empty when there are no recordings', () {
      expect(MusicBrainzApiHttp.parseGenres('{"recordings": []}'), isEmpty);
    });
  });
}
