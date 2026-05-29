import 'score.dart';

enum ItemKind { track, album, artist }

class TagEntry {
  const TagEntry({required this.name, required this.source});
  final String name;
  final String source;
}

class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.kind,
    required this.elo,
    required this.comparisons,
    required this.tags,
    required this.updatedAt,
  });

  final String id;
  final ItemKind kind;
  final double elo;
  final int comparisons;
  final List<TagEntry> tags;
  final DateTime updatedAt;

  double get score => scoreFromElo(elo);
}

class ScoreBucket {
  const ScoreBucket({required this.label, required this.count});
  final String label; // e.g. "0-1", "1-2", ...
  final int count;
}

class TagCount {
  const TagCount({required this.name, required this.count});
  final String name;
  final int count;
}

class ActivityPoint {
  const ActivityPoint({required this.date, required this.comparisons});
  final DateTime date;
  final int comparisons;
}

class LibraryStats {
  const LibraryStats({
    required this.totalByKind,
    required this.averageScore,
    required this.scoreBuckets,
    required this.topItems,
    required this.topGenres,
    required this.topMoods,
    required this.activityOverTime,
  });

  final Map<ItemKind, int> totalByKind;
  final double averageScore;
  final List<ScoreBucket> scoreBuckets;
  final List<LibraryItem> topItems;
  final List<TagCount> topGenres;
  final List<TagCount> topMoods;
  final List<ActivityPoint> activityOverTime;
}

class StatsEngine {
  const StatsEngine();

  LibraryStats compute(List<LibraryItem> items) {
    if (items.isEmpty) {
      return LibraryStats(
        totalByKind: {},
        averageScore: 0,
        scoreBuckets: _emptyBuckets(),
        topItems: [],
        topGenres: [],
        topMoods: [],
        activityOverTime: [],
      );
    }

    return LibraryStats(
      totalByKind: _totalByKind(items),
      averageScore: _averageScore(items),
      scoreBuckets: _scoreBuckets(items),
      topItems: _topN(items, 10),
      topGenres: _topTags(items, 'genre', 10),
      topMoods: _topTags(items, 'mood', 10),
      activityOverTime: _activity(items),
    );
  }

  Map<ItemKind, int> _totalByKind(List<LibraryItem> items) {
    final counts = <ItemKind, int>{};
    for (final item in items) {
      counts[item.kind] = (counts[item.kind] ?? 0) + 1;
    }
    return counts;
  }

  double _averageScore(List<LibraryItem> items) {
    if (items.isEmpty) return 0;
    final sum = items.fold<double>(0, (acc, i) => acc + i.score);
    return sum / items.length;
  }

  List<ScoreBucket> _scoreBuckets(List<LibraryItem> items) {
    final buckets = List<int>.filled(10, 0);
    for (final item in items) {
      final idx = item.score.floor().clamp(0, 9);
      buckets[idx]++;
    }
    return List.generate(
      10,
      (i) => ScoreBucket(label: '$i-${i + 1}', count: buckets[i]),
    );
  }

  List<LibraryItem> _topN(List<LibraryItem> items, int n) {
    final sorted = List<LibraryItem>.from(items)
      ..sort((a, b) => b.elo.compareTo(a.elo));
    return sorted.take(n).toList();
  }

  List<TagCount> _topTags(List<LibraryItem> items, String category, int n) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final tag in item.tags) {
        if (tag.source == category ||
            (category == 'genre' && !_isMoodTag(tag.name)) ||
            (category == 'mood' && _isMoodTag(tag.name))) {
          counts[tag.name] = (counts[tag.name] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).map((e) => TagCount(name: e.key, count: e.value)).toList();
  }

  List<ActivityPoint> _activity(List<LibraryItem> items) {
    final byDate = <DateTime, int>{};
    for (final item in items) {
      final day = DateTime(
        item.updatedAt.year,
        item.updatedAt.month,
        item.updatedAt.day,
      );
      byDate[day] = (byDate[day] ?? 0) + item.comparisons;
    }
    final sorted = byDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted
        .map((e) => ActivityPoint(date: e.key, comparisons: e.value))
        .toList();
  }

  List<ScoreBucket> _emptyBuckets() {
    return List.generate(
      10,
      (i) => ScoreBucket(label: '$i-${i + 1}', count: 0),
    );
  }

  static const _moodKeywords = {
    'melancholic', 'dreamy', 'energetic', 'calm', 'dark', 'uplifting',
    'romantic', 'aggressive', 'peaceful', 'sad', 'happy', 'intense',
    'relaxing', 'atmospheric', 'emotional', 'powerful', 'mellow', 'epic',
    'haunting', 'nostalgic', 'mysterious', 'cathartic',
  };

  bool _isMoodTag(String tag) => _moodKeywords.contains(tag.toLowerCase());
}
