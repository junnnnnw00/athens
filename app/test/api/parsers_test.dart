import 'package:athens/api/itunes_api.dart';
import 'package:athens/api/lastfm_api.dart';
import 'package:athens/api/musicbrainz_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

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
      final genres = MusicBrainzApiHttp.parseRecording(body).genres;
      expect(genres, containsAll(['shoegaze', 'dream pop']));
    });

    test('returns empty when there are no recordings', () {
      expect(
          MusicBrainzApiHttp.parseRecording('{"recordings": []}').genres, isEmpty);
    });
  });

  group('LastfmApiHttp.parseTrackInfo', () {
    test('parses track details with stats and wiki summary', () {
      const body = '''
      {
        "track": {
          "name": "Only Shallow",
          "duration": "222000",
          "listeners": "12000",
          "playcount": "45000",
          "album": {
            "title": "Loveless"
          },
          "wiki": {
            "summary": "Only Shallow is the opening track... <a href=\\"https://last.fm\\">Read more on Last.fm</a>"
          }
        }
      }''';
      final info = LastfmApiHttp.parseTrackInfo(body);
      expect(info, isNotNull);
      expect(info!.album, 'Loveless');
      expect(info.durationMs, 222000);
      expect(info.listeners, 12000);
      expect(info.playcount, 45000);
      expect(info.summary, 'Only Shallow is the opening track...');
    });

    test('returns null for invalid structure', () {
      expect(LastfmApiHttp.parseTrackInfo('{}'), isNull);
    });
  });

  group('LastfmApiHttp.parseArtistInfo', () {
    test('parses artist stats and bio', () {
      const body = '''
      {
        "artist": {
          "name": "Slowdive",
          "stats": {
            "listeners": "99000",
            "playcount": "500000"
          },
          "bio": {
            "summary": "Slowdive are an English shoegaze band... <a href=\\"https://last.fm\\">Read more</a>"
          }
        }
      }''';
      final info = LastfmApiHttp.parseArtistInfo(body);
      expect(info, isNotNull);
      expect(info!.listeners, 99000);
      expect(info.playcount, 500000);
      expect(info.summary, 'Slowdive are an English shoegaze band...');
    });

    test('returns null for invalid structure', () {
      expect(LastfmApiHttp.parseArtistInfo('{}'), isNull);
    });
  });

  group('LastfmApiHttp.parseTopTracks', () {
    test('parses top track names', () {
      const body = '''
      {
        "toptracks": {
          "track": [
            {"name": "Alison"},
            {"name": "When the Sun Hits"},
            {"name": "Machine Gun"}
          ]
        }
      }''';
      final tracks = LastfmApiHttp.parseTopTracks(body);
      expect(tracks, ['Alison', 'When the Sun Hits', 'Machine Gun']);
    });

    test('returns empty for invalid structure', () {
      expect(LastfmApiHttp.parseTopTracks('{}'), isEmpty);
    });
  });

  group('MusicBrainzApiHttp.parseRecording (extended)', () {
    test('parses first-release-date to extract year', () {
      const body = '''
      {"recordings": [
        {"title": "Only Shallow",
         "first-release-date": "1991-11-04",
         "tags": [{"name": "shoegaze"}]}
      ]}''';
      final info = MusicBrainzApiHttp.parseRecording(body);
      expect(info.year, '1991');
      expect(info.genres, ['shoegaze']);
    });

    test('handles missing or short date', () {
      const body1 = '{"recordings": [{"title": "Only Shallow", "first-release-date": "199"}]}';
      const body2 = '{"recordings": [{"title": "Only Shallow"}]}';
      expect(MusicBrainzApiHttp.parseRecording(body1).year, isNull);
      expect(MusicBrainzApiHttp.parseRecording(body2).year, isNull);
    });
  });
}
