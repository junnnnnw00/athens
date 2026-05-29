import 'package:flutter_test/flutter_test.dart';
import 'package:athens/domain/stats_engine.dart';

void main() {
  const engine = StatsEngine();
  final now = DateTime(2026, 1, 15);

  LibraryItem makeItem({
    required String id,
    required ItemKind kind,
    double elo = 1000,
    int comparisons = 10,
    List<TagEntry> tags = const [],
    DateTime? updatedAt,
  }) {
    return LibraryItem(
      id: id,
      kind: kind,
      elo: elo,
      comparisons: comparisons,
      tags: tags,
      updatedAt: updatedAt ?? now,
    );
  }

  group('StatsEngine.compute — empty', () {
    test('returns empty stats for empty list', () {
      final stats = engine.compute([]);
      expect(stats.totalByKind, isEmpty);
      expect(stats.averageScore, 0);
      expect(stats.topItems, isEmpty);
      expect(stats.topGenres, isEmpty);
      expect(stats.topMoods, isEmpty);
      expect(stats.activityOverTime, isEmpty);
    });
  });

  group('StatsEngine.compute — totalByKind', () {
    test('counts items by kind correctly', () {
      final items = [
        makeItem(id: '1', kind: ItemKind.track),
        makeItem(id: '2', kind: ItemKind.track),
        makeItem(id: '3', kind: ItemKind.album),
        makeItem(id: '4', kind: ItemKind.artist),
      ];
      final stats = engine.compute(items);
      expect(stats.totalByKind[ItemKind.track], 2);
      expect(stats.totalByKind[ItemKind.album], 1);
      expect(stats.totalByKind[ItemKind.artist], 1);
    });
  });

  group('StatsEngine.compute — averageScore', () {
    test('average score at elo 1000 = 5.0', () {
      final items = [
        makeItem(id: '1', kind: ItemKind.track, elo: 1000),
        makeItem(id: '2', kind: ItemKind.track, elo: 1000),
      ];
      final stats = engine.compute(items);
      expect(stats.averageScore, closeTo(5.0, 0.01));
    });

    test('average score increases with higher elos', () {
      final lowItems = [makeItem(id: '1', kind: ItemKind.track, elo: 800)];
      final highItems = [makeItem(id: '2', kind: ItemKind.track, elo: 1200)];
      expect(
        engine.compute(highItems).averageScore,
        greaterThan(engine.compute(lowItems).averageScore),
      );
    });
  });

  group('StatsEngine.compute — scoreBuckets', () {
    test('always produces 10 buckets', () {
      final items = [makeItem(id: '1', kind: ItemKind.track)];
      final stats = engine.compute(items);
      expect(stats.scoreBuckets.length, 10);
    });

    test('bucket labels are 0-1 through 9-10', () {
      final items = [makeItem(id: '1', kind: ItemKind.track)];
      final buckets = engine.compute(items).scoreBuckets;
      expect(buckets.first.label, '0-1');
      expect(buckets.last.label, '9-10');
    });

    test('total items in buckets equals list length', () {
      final items = [
        makeItem(id: '1', kind: ItemKind.track, elo: 800),
        makeItem(id: '2', kind: ItemKind.track, elo: 1000),
        makeItem(id: '3', kind: ItemKind.track, elo: 1200),
      ];
      final stats = engine.compute(items);
      final total = stats.scoreBuckets.fold<int>(0, (sum, b) => sum + b.count);
      expect(total, items.length);
    });
  });

  group('StatsEngine.compute — topItems', () {
    test('top items ordered by elo descending', () {
      final items = [
        makeItem(id: 'low', kind: ItemKind.track, elo: 800),
        makeItem(id: 'high', kind: ItemKind.track, elo: 1400),
        makeItem(id: 'mid', kind: ItemKind.track, elo: 1000),
      ];
      final top = engine.compute(items).topItems;
      expect(top.first.id, 'high');
      expect(top.last.id, 'low');
    });

    test('returns at most 10 items', () {
      final items = List.generate(
        20,
        (i) => makeItem(id: '$i', kind: ItemKind.track, elo: 1000 + i * 10),
      );
      expect(engine.compute(items).topItems.length, 10);
    });
  });

  group('StatsEngine.compute — topGenres and topMoods', () {
    test('counts genre tags across items', () {
      final items = [
        makeItem(
          id: '1',
          kind: ItemKind.track,
          tags: const [
            TagEntry(name: 'shoegaze', source: 'lastfm'),
            TagEntry(name: 'indie rock', source: 'lastfm'),
          ],
        ),
        makeItem(
          id: '2',
          kind: ItemKind.track,
          tags: const [TagEntry(name: 'shoegaze', source: 'lastfm')],
        ),
      ];
      final stats = engine.compute(items);
      final genreNames = stats.topGenres.map((t) => t.name).toList();
      expect(genreNames, contains('shoegaze'));
    });

    test('mood tags separated from genre tags', () {
      final items = [
        makeItem(
          id: '1',
          kind: ItemKind.track,
          tags: const [
            TagEntry(name: 'melancholic', source: 'lastfm'),
            TagEntry(name: 'shoegaze', source: 'lastfm'),
          ],
        ),
      ];
      final stats = engine.compute(items);
      final moodNames = stats.topMoods.map((t) => t.name).toList();
      final genreNames = stats.topGenres.map((t) => t.name).toList();
      expect(moodNames, contains('melancholic'));
      expect(genreNames, contains('shoegaze'));
    });
  });

  group('StatsEngine.compute — activityOverTime', () {
    test('groups comparisons by day', () {
      final items = [
        makeItem(
          id: '1',
          kind: ItemKind.track,
          comparisons: 5,
          updatedAt: DateTime(2026, 1, 10),
        ),
        makeItem(
          id: '2',
          kind: ItemKind.track,
          comparisons: 3,
          updatedAt: DateTime(2026, 1, 10),
        ),
        makeItem(
          id: '3',
          kind: ItemKind.track,
          comparisons: 7,
          updatedAt: DateTime(2026, 1, 11),
        ),
      ];
      final activity = engine.compute(items).activityOverTime;
      expect(activity.length, 2);
      expect(
        activity.firstWhere((a) => a.date == DateTime(2026, 1, 10)).comparisons,
        8,
      );
      expect(
        activity.firstWhere((a) => a.date == DateTime(2026, 1, 11)).comparisons,
        7,
      );
    });

    test('activity is sorted chronologically', () {
      final items = [
        makeItem(
          id: '1',
          kind: ItemKind.track,
          updatedAt: DateTime(2026, 1, 15),
        ),
        makeItem(
          id: '2',
          kind: ItemKind.track,
          updatedAt: DateTime(2026, 1, 10),
        ),
      ];
      final activity = engine.compute(items).activityOverTime;
      expect(activity.first.date.isBefore(activity.last.date), isTrue);
    });
  });
}
