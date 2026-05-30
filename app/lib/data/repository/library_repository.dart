import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/elo.dart';
import '../local/app_database.dart';
import '../remote/supabase_gateway.dart';
import '../../features/catalog/catalog_service.dart';

/// Reads/writes the user's rated library through the local Drift database.
/// This is the single source of truth the UI renders — no in-memory shortcuts.
/// Ratings survive an app restart because every mutation is persisted here.
///
/// When [remote] is provided and [userId] is a real auth user, mutations are
/// also pushed to Supabase (best-effort, non-blocking) so the public web profile
/// reflects them. Local writes never wait on or fail because of the network.
class LibraryRepository {
  LibraryRepository({
    required AppDatabase db,
    required this.userId,
    SupabaseGateway? remote,
  })  : _db = db,
        _remote = remote;

  final AppDatabase _db;
  final SupabaseGateway? _remote;
  final String userId;

  /// Maps a local item id (e.g. 'spotify:abc') to its remote uuid, cached.
  final Map<String, String> _remoteItemIds = {};

  bool get _syncEnabled => _remote != null && userId != 'local-user';

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

  /// Pulls the user's ratings + items from Supabase into the local Drift cache,
  /// so a fresh device / browser shows the library that other devices created.
  /// Best-effort and last-write-wins: a newer local edit is never clobbered.
  Future<void> pullRemote() async {
    if (!_syncEnabled) return;
    try {
      final rows = await _remote!.getRatingsWithItems(userId);
      final localByItem = {
        for (final r in await _db.getRatingsForUser(userId)) r.itemId: r
      };
      for (final row in rows) {
        final item = row['item'] as Map<String, dynamic>?;
        if (item == null) continue;
        final source = (item['source'] as String?) ?? 'unknown';
        final sourceId = (item['source_id'] as String?) ?? '';
        // Mirrors CatalogItem.id ('spotify:xxx' / 'itunes:xxx') so a later local
        // rate of the same item reconciles to the same row (no duplicates).
        final localId = '$source:$sourceId';

        await _db.upsertItem(LocalItemsCompanion(
          id: Value(localId),
          kind: Value((item['kind'] as String?) ?? 'track'),
          source: Value(source),
          sourceId: Value(sourceId),
          title: Value((item['title'] as String?) ?? ''),
          primaryArtist: Value(item['primary_artist'] as String?),
          imageUrl: Value(item['image_url'] as String?),
          tags: Value(_encodeJsonTags(item['tags'])),
        ));
        if (item['id'] != null) {
          _remoteItemIds[localId] = item['id'] as String;
        }

        final remoteUpdated =
            DateTime.tryParse((row['updated_at'] as String?) ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
        final existing = localByItem[localId];
        if (existing != null && existing.updatedAt.isAfter(remoteUpdated)) {
          continue; // local edit is newer — keep it
        }
        await _db.upsertRating(LocalRatingsCompanion(
          id: Value(_ratingId(localId)),
          userId: Value(userId),
          itemId: Value(localId),
          elo: Value((row['elo'] as num?)?.toDouble() ?? Elo.startingElo),
          comparisons: Value((row['comparisons'] as num?)?.toInt() ?? 0),
          updatedAt: Value(remoteUpdated),
        ));
      }
    } catch (_) {
      // Offline / RLS / transient — local cache stays as-is.
    }
  }

  /// Re-encodes a jsonb tag list (already `[{name, source}, …]`) to a string.
  String _encodeJsonTags(dynamic tags) =>
      tags is List ? jsonEncode(tags) : '[]';

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

  /// Replaces the cached tags for an item (used by the tag backfill) and pushes
  /// the updated catalog row to Supabase so the public profile reflects them.
  Future<void> updateItemTags(String localId, List<CatalogTag> tags) async {
    final item = await _db.getItemById(localId);
    if (item == null) return;
    await _db.upsertItem(LocalItemsCompanion(
      id: Value(item.id),
      kind: Value(item.kind),
      source: Value(item.source),
      sourceId: Value(item.sourceId),
      title: Value(item.title),
      primaryArtist: Value(item.primaryArtist),
      imageUrl: Value(item.imageUrl),
      tags: Value(_encodeTags(tags)),
    ));
    if (!_syncEnabled) return;
    try {
      await _remote!.upsertItemReturningId({
        'kind': item.kind,
        'source': item.source,
        'source_id': item.sourceId,
        'title': item.title,
        'primary_artist': item.primaryArtist,
        'image_url': item.imageUrl,
        'tags': tags.map((t) => {'name': t.name, 'source': t.source}).toList(),
      });
    } catch (_) {
      // Best-effort — local cache already holds the tags.
    }
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
    await _pushRating(item.id, Elo.startingElo, 0);
  }

  /// Removes an item from the user's library: deletes their rating, comparisons
  /// and review (the shared catalog row stays cached). Pushed to Supabase too.
  Future<void> removeItem(String localId) async {
    await _db.deleteComparisonsForItem(userId, localId);
    await _db.deleteRatingForItem(userId, localId);
    await _db.deleteReviewForItem(userId, localId);
    if (!_syncEnabled) return;
    try {
      final uuid = await _remoteItemId(localId);
      if (uuid == null) return;
      await _remote!.deleteComparisonsForItem(userId, uuid);
      await _remote.deleteRating(userId, uuid);
    } catch (_) {
      // Best-effort — local removal already succeeded.
    }
  }

  /// Resets an item to the starting Elo and clears its past comparisons so it can
  /// be placed again from scratch (re-run the placement flow against same-kind).
  Future<void> resetForPlacement(String localId) async {
    if (await _db.getItemById(localId) == null) return;
    await _db.deleteComparisonsForItem(userId, localId);
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(localId)),
      userId: Value(userId),
      itemId: Value(localId),
      elo: const Value(Elo.startingElo),
      comparisons: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
    await _pushRating(localId, Elo.startingElo, 0);
    if (!_syncEnabled) return;
    try {
      final uuid = await _remoteItemId(localId);
      if (uuid != null) await _remote!.deleteComparisonsForItem(userId, uuid);
    } catch (_) {
      // Best-effort.
    }
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
    await _pushRating(winnerId, wElo, winner.comparisons + 1);
    await _pushRating(loserId, lElo, loser.comparisons + 1);
  }

  // --------------------------------------------------------------------------
  // Remote sync (best-effort). Errors are swallowed; local data is the source.
  // --------------------------------------------------------------------------

  /// Resolves (and caches) the remote uuid for a local item, upserting the
  /// shared catalog row if needed.
  Future<String?> _remoteItemId(String localItemId) async {
    if (_remoteItemIds.containsKey(localItemId)) {
      return _remoteItemIds[localItemId];
    }
    final item = await _db.getItemById(localItemId);
    if (item == null) return null;
    final uuid = await _remote!.upsertItemReturningId({
      'kind': item.kind,
      'source': item.source,
      'source_id': item.sourceId,
      'title': item.title,
      'primary_artist': item.primaryArtist,
      'image_url': item.imageUrl,
      'tags': jsonDecode(item.tags),
    });
    if (uuid != null) _remoteItemIds[localItemId] = uuid;
    return uuid;
  }

  /// Pushes one rating (item + elo + comparisons) to Supabase.
  Future<void> _pushRating(String localItemId, double elo, int comparisons) async {
    if (!_syncEnabled) return;
    try {
      final uuid = await _remoteItemId(localItemId);
      if (uuid == null) return;
      await _remote!.upsertRating({
        'user_id': userId,
        'item_id': uuid,
        'elo': elo,
        'comparisons': comparisons,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Offline / RLS / transient — ignore; local stays authoritative.
    }
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
