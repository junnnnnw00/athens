import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/elo.dart';
import '../local/app_database.dart';
import '../../features/catalog/catalog_service.dart';

/// Reads/writes the user's rated library through the local Drift database.
/// This is the single source of truth the UI renders — no in-memory shortcuts.
/// Ratings survive an app restart because every mutation is persisted here.
class LibraryRepository {
  LibraryRepository({required AppDatabase db, required this.userId}) : _db = db;

  final AppDatabase _db;
  final String userId;

  String _ratingId(String itemId) => '${userId}_$itemId';

  List<CatalogTag> _decodeTags(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => CatalogTag(
                name: (e as Map<String, dynamic>)['name'] as String,
                source: e['source'] as String,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  String _encodeTags(List<CatalogTag> tags) => jsonEncode(
      tags.map((t) => {'name': t.name, 'source': t.source}).toList());

  /// Loads the rated library joined with cached item metadata.
  Future<List<RatedCatalogItem>> loadLibrary() async {
    final ratings = await _db.getRatingsForUser(userId);
    final items = {for (final i in await _db.getAllItems()) i.id: i};
    final result = <RatedCatalogItem>[];
    for (final r in ratings) {
      final item = items[r.itemId];
      if (item == null) continue;
      result.add(RatedCatalogItem(
        id: item.id,
        kind: item.kind,
        title: item.title,
        primaryArtist: item.primaryArtist,
        imageUrl: item.imageUrl,
        elo: r.elo,
        comparisons: r.comparisons,
        tags: _decodeTags(item.tags),
        updatedAt: r.updatedAt,
      ));
    }
    result.sort((a, b) => b.elo.compareTo(a.elo));
    return result;
  }

  Future<RatedCatalogItem?> getItem(String itemId) async {
    final all = await loadLibrary();
    for (final i in all) {
      if (i.id == itemId) return i;
    }
    return null;
  }

  /// Adds a catalog item to the library (idempotent) at the starting Elo.
  Future<void> addItem(CatalogItem item) async {
    await _db.upsertItem(LocalItemsCompanion(
      id: Value(item.id),
      kind: Value(item.kind),
      source: Value(item.source ?? 'unknown'),
      sourceId: Value(item.sourceId ?? item.id),
      title: Value(item.title),
      primaryArtist: Value(item.primaryArtist),
      imageUrl: Value(item.imageUrl),
      tags: Value(_encodeTags(item.tags)),
    ));
    final existing = await _db.getRatingsForUser(userId);
    if (existing.any((r) => r.itemId == item.id)) return;
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(item.id)),
      userId: Value(userId),
      itemId: Value(item.id),
      elo: const Value(Elo.startingElo),
      comparisons: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Records a duel result: updates both Elos and stores the comparison.
  Future<void> recordComparison({
    required String winnerId,
    required String loserId,
  }) async {
    final ratings = {
      for (final r in await _db.getRatingsForUser(userId)) r.itemId: r
    };
    final winner = ratings[winnerId];
    final loser = ratings[loserId];
    if (winner == null || loser == null) return;

    final (wElo, lElo) = Elo.update(winner.elo, loser.elo);
    final now = DateTime.now();
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(winnerId)),
      userId: Value(userId),
      itemId: Value(winnerId),
      elo: Value(wElo),
      comparisons: Value(winner.comparisons + 1),
      updatedAt: Value(now),
    ));
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(loserId)),
      userId: Value(userId),
      itemId: Value(loserId),
      elo: Value(lElo),
      comparisons: Value(loser.comparisons + 1),
      updatedAt: Value(now),
    ));
    await _db.insertComparison(LocalComparisonsCompanion(
      id: Value('${userId}_${now.microsecondsSinceEpoch}'),
      userId: Value(userId),
      winnerItemId: Value(winnerId),
      loserItemId: Value(loserId),
      createdAt: Value(now),
    ));
  }

  Future<String?> getReview(String itemId) async {
    final reviews = await _db.getReviewsForUser(userId);
    for (final r in reviews) {
      if (r.itemId == itemId) return r.body;
    }
    return null;
  }

  Future<void> upsertReview({
    required String itemId,
    required String body,
    double? ratingSnapshot,
  }) async {
    await _db.upsertReview(LocalReviewsCompanion(
      id: Value(_ratingId(itemId)),
      userId: Value(userId),
      itemId: Value(itemId),
      body: Value(body),
      ratingSnapshot: Value(ratingSnapshot),
      updatedAt: Value(DateTime.now()),
    ));
  }
}
