import 'dart:async';
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
    await _syncComparisons();
  }

  /// Two-way sync of the duel log so the per-item "내 Elo 변화" trend has the same
  /// events on every device. Push first (backfills rows recorded before sync
  /// existed, or while offline), then pull anything this device is missing. Both
  /// directions are keyed by the local comparison id (`client_id`) so they're
  /// idempotent. Best-effort; failures leave local data untouched.
  Future<void> _syncComparisons() async {
    if (!_syncEnabled) return;
    try {
      final local = await _db.getComparisonsForUser(userId);
      final localIds = {for (final c in local) c.id};
      final remote = await _remote!.getComparisons(userId);
      final remoteIds = {
        for (final r in remote)
          if (r['client_id'] != null) r['client_id'] as String
      };

      // Push: local rows the server hasn't got yet (legacy/offline backfill),
      // batched into a single upsert.
      final toPush = <Map<String, dynamic>>[];
      for (final c in local) {
        if (remoteIds.contains(c.id)) continue;
        final wUuid = await _remoteItemId(c.winnerItemId);
        final lUuid = await _remoteItemId(c.loserItemId);
        if (wUuid == null || lUuid == null) continue;
        toPush.add({
          'client_id': c.id,
          'user_id': userId,
          'winner_item_id': wUuid,
          'loser_item_id': lUuid,
          'created_at': c.createdAt.toIso8601String(),
        });
      }
      await _remote.insertComparisons(toPush);

      // Pull: server rows this device is missing → insert locally.
      for (final r in remote) {
        final clientId = r['client_id'] as String?;
        if (clientId == null || localIds.contains(clientId)) continue;
        final w = r['winner'] as Map<String, dynamic>?;
        final l = r['loser'] as Map<String, dynamic>?;
        if (w == null || l == null) continue;
        final winnerLocal = '${w['source']}:${w['source_id']}';
        final loserLocal = '${l['source']}:${l['source_id']}';
        final createdAt =
            DateTime.tryParse((r['created_at'] as String?) ?? '') ??
                DateTime.now();
        await _db.insertComparison(LocalComparisonsCompanion(
          id: Value(clientId),
          userId: Value(userId),
          winnerItemId: Value(winnerLocal),
          loserItemId: Value(loserLocal),
          createdAt: Value(createdAt),
        ));
      }
    } catch (_) {
      // Offline / RLS / transient — trend just stays as sparse as local data.
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
        storedCanonicalKey: item.canonicalKey,
      ));
    }
    // Collapse duplicates that refer to the same logical item — e.g. a track
    // added from search (`itunes:..`) and the same track later synced from the
    // Last.fm feed (`lastfm:..`), which carry different ids, or the same song
    // listed under translated/transliterated titles. `canonicalKey` is the
    // ISRC-based identity when known (collapses cross-language dupes), else the
    // normalized text key. Keep the most-dueled (then highest-Elo) copy so
    // ranking history isn't lost.
    final byKey = <String, RatedCatalogItem>{};
    for (final r in result) {
      final key = r.canonicalKey;
      final existing = byKey[key];
      if (existing == null ||
          r.comparisons > existing.comparisons ||
          (r.comparisons == existing.comparisons && r.elo > existing.elo)) {
        byKey[key] = r;
      }
    }
    final deduped = byKey.values.toList()
      ..sort((a, b) => b.elo.compareTo(a.elo));
    return deduped;
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
    unawaited(() async {
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
    }());
  }

  /// Replaces the cached cover art for an item (used by the art backfill) and
  /// pushes the updated catalog row to Supabase. Best-effort remote.
  Future<void> updateItemImage(String localId, String imageUrl) async {
    final item = await _db.getItemById(localId);
    if (item == null) return;
    await _db.upsertItem(LocalItemsCompanion(
      id: Value(item.id),
      kind: Value(item.kind),
      source: Value(item.source),
      sourceId: Value(item.sourceId),
      title: Value(item.title),
      primaryArtist: Value(item.primaryArtist),
      imageUrl: Value(imageUrl),
      tags: Value(item.tags),
    ));
    if (!_syncEnabled) return;
    unawaited(() async {
      try {
        await _remote!.upsertItemReturningId({
          'kind': item.kind,
          'source': item.source,
          'source_id': item.sourceId,
          'title': item.title,
          'primary_artist': item.primaryArtist,
          'image_url': imageUrl,
          'tags': jsonDecode(item.tags),
        });
      } catch (_) {
        // Best-effort — local cache already holds the art.
      }
    }());
  }

  /// Persists a resolved canonical (dedup) key for an item. Used by the backfill
  /// pass to upgrade text keys to ISRC, and by the manual "merge as same track"
  /// action. Local-only — the key is a per-user view concern (see DECISIONS.md).
  Future<void> setItemCanonicalKey(String localId, String canonicalKey) async {
    await _db.setItemCanonicalKey(localId, canonicalKey);
  }

  Future<RatedCatalogItem?> getItem(String itemId) async {
    final all = await loadLibrary();
    for (final i in all) {
      if (i.id == itemId) return i;
    }
    return null;
  }

  /// Adds a catalog item to the library (idempotent) at the starting Elo.
  Future<void> addItem(CatalogItem item, {double startingElo = Elo.startingElo}) async {
    await _db.upsertItem(LocalItemsCompanion(
      id: Value(item.id),
      kind: Value(item.kind),
      source: Value(item.source ?? 'unknown'),
      sourceId: Value(item.sourceId ?? item.id),
      title: Value(item.title),
      primaryArtist: Value(item.primaryArtist),
      imageUrl: Value(item.imageUrl),
      tags: Value(_encodeTags(item.tags)),
      // ISRC-based canonical key when the item carries an ISRC (iTunes song
      // results do); otherwise the text key. The backfill pass upgrades text
      // keys to ISRC for items that can resolve one.
      canonicalKey: Value(item.canonicalKey),
    ));
    final existing = await _db.getRatingsForUser(userId);
    if (existing.any((r) => r.itemId == item.id)) return;
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(item.id)),
      userId: Value(userId),
      itemId: Value(item.id),
      elo: Value(startingElo),
      comparisons: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
    unawaited(_pushRating(item.id, startingElo, 0));
  }

  /// Removes an item from the user's library: deletes their rating, comparisons
  /// and review (the shared catalog row stays cached). Pushed to Supabase too.
  Future<void> removeItem(String localId) async {
    await _db.deleteComparisonsForItem(userId, localId);
    await _db.deleteRatingForItem(userId, localId);
    await _db.deleteReviewForItem(userId, localId);
    if (!_syncEnabled) return;
    unawaited(() async {
      try {
        final uuid = await _remoteItemId(localId);
        if (uuid == null) return;
        await _remote!.deleteComparisonsForItem(userId, uuid);
        await _remote.deleteRating(userId, uuid);
      } catch (_) {
        // Best-effort — local removal already succeeded.
      }
    }());
  }

  /// Returns the current streak for an item. A positive number indicates a win streak,
  /// and a negative number indicates a loss streak.
  Future<int> getItemStreak(String itemId) async {
    final comps = await _db.getComparisonsForItem(userId, itemId);
    if (comps.isEmpty) return 0;
    
    final firstIsWin = comps.first.winnerItemId == itemId;
    int count = 0;
    for (final c in comps) {
      final isWin = c.winnerItemId == itemId;
      if (isWin == firstIsWin) {
        count++;
      } else {
        break;
      }
    }
    return firstIsWin ? count : -count;
  }

  /// Resets an item to the starting Elo and clears its past comparisons so it can
  /// be placed again from scratch (re-run the placement flow against same-kind).
  Future<void> resetForPlacement(String localId, {double startingElo = Elo.startingElo}) async {
    if (await _db.getItemById(localId) == null) return;
    await _db.deleteComparisonsForItem(userId, localId);
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(localId)),
      userId: Value(userId),
      itemId: Value(localId),
      elo: Value(startingElo),
      comparisons: const Value(0),
      updatedAt: Value(DateTime.now()),
    ));
    unawaited(_pushRating(localId, startingElo, 0));
    if (!_syncEnabled) return;
    unawaited(() async {
      try {
        final uuid = await _remoteItemId(localId);
        if (uuid != null) await _remote!.deleteComparisonsForItem(userId, uuid);
      } catch (_) {
        // Best-effort.
      }
    }());
  }

  /// Records a duel result: updates both Elos and stores the comparison.
  /// Returns the new comparison's id (for undo), or null when it was a no-op.
  Future<String?> recordComparison({
    required String winnerId,
    required String loserId,
  }) async {
    final ratings = {
      for (final r in await _db.getRatingsForUser(userId)) r.itemId: r
    };
    final winner = ratings[winnerId];
    final loser = ratings[loserId];
    if (winner == null || loser == null) return null;

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
    final compId = '${userId}_${now.microsecondsSinceEpoch}';
    await _db.insertComparison(LocalComparisonsCompanion(
      id: Value(compId),
      userId: Value(userId),
      winnerItemId: Value(winnerId),
      loserItemId: Value(loserId),
      createdAt: Value(now),
    ));
    // Remote sync is best-effort and MUST NOT block the local write — an offline
    // duel would otherwise hang on a network / token-refresh timeout. Detached.
    unawaited(() async {
      await _pushRating(winnerId, wElo, winner.comparisons + 1);
      await _pushRating(loserId, lElo, loser.comparisons + 1);
      await _pushComparison(compId, winnerId, loserId, now);
    }());
    return compId;
  }

  /// Undoes a single duel: restores both items to their pre-duel Elo and
  /// comparison counts and removes the comparison row (local + best-effort
  /// remote). Caller supplies the snapshot captured before the duel.
  Future<void> revertComparison({
    required String comparisonId,
    required String winnerId,
    required double winnerElo,
    required int winnerComparisons,
    required String loserId,
    required double loserElo,
    required int loserComparisons,
  }) async {
    final now = DateTime.now();
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(winnerId)),
      userId: Value(userId),
      itemId: Value(winnerId),
      elo: Value(winnerElo),
      comparisons: Value(winnerComparisons),
      updatedAt: Value(now),
    ));
    await _db.upsertRating(LocalRatingsCompanion(
      id: Value(_ratingId(loserId)),
      userId: Value(userId),
      itemId: Value(loserId),
      elo: Value(loserElo),
      comparisons: Value(loserComparisons),
      updatedAt: Value(now),
    ));
    await _db.deleteComparisonById(comparisonId);
    unawaited(() async {
      await _pushRating(winnerId, winnerElo, winnerComparisons);
      await _pushRating(loserId, loserElo, loserComparisons);
      if (!_syncEnabled) return;
      try {
        await _remote!.deleteComparison(userId, comparisonId);
      } catch (_) {
        // Best-effort — local undo already succeeded.
      }
    }());
  }

  /// Pushes one duel event to Supabase, keyed by its local id (`client_id`) so
  /// the upsert is idempotent. Best-effort; offline rows are backfilled later by
  /// [pullRemote].
  Future<void> _pushComparison(
      String compId, String winnerId, String loserId, DateTime createdAt) async {
    if (!_syncEnabled) return;
    try {
      final wUuid = await _remoteItemId(winnerId);
      final lUuid = await _remoteItemId(loserId);
      if (wUuid == null || lUuid == null) return;
      await _remote!.insertComparison({
        'client_id': compId,
        'user_id': userId,
        'winner_item_id': wUuid,
        'loser_item_id': lUuid,
        'created_at': createdAt.toIso8601String(),
      });
    } catch (_) {
      // Offline / transient — pullRemote backfills this row next time.
    }
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

  Future<List<DateTime>> getComparisonDates() async {
    final list = await _db.getComparisonsForUser(userId);
    return list.map((c) => c.createdAt).toList();
  }

  // --------------------------------------------------------------------------
  // Community stats helpers
  // --------------------------------------------------------------------------

  /// Resolves (and caches/creates) the shared-catalog uuid for a local item id,
  /// so the per-item community stats RPCs can be called. Returns null offline /
  /// when signed out.
  Future<String?> resolveRemoteItemId(String localItemId) async {
    if (!_syncEnabled) return null;
    try {
      return await _remoteItemId(localItemId);
    } catch (_) {
      return null;
    }
  }

  /// Reconstructs the user's own **Elo** history for one item by replaying their
  /// local duel log: every comparison is re-applied in chronological order from
  /// the shared starting Elo, capturing this item's Elo **after each duel it took
  /// part in**. One point per duel — the point count matches the item's
  /// `comparisons`. The series is shifted so its final point matches the item's
  /// current Elo (exact placement seeds aren't logged), preserving the trend's
  /// shape. Elo (not the 0–10 score) is used so movement stays visible even when
  /// the compressed score barely changes. Returns `[]` when the item has no
  /// duels.
  Future<List<({DateTime t, double elo})>> getOwnRatingTrend(
      String localItemId) async {
    final ratings = await _db.getRatingsForUser(userId);
    final current = ratings.where((r) => r.itemId == localItemId).firstOrNull;
    if (current == null) return const [];

    final comps = await _db.getComparisonsForUser(userId)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final elo = <String, double>{};
    final raw = <({DateTime t, double elo})>[];
    for (final c in comps) {
      final involves =
          c.winnerItemId == localItemId || c.loserItemId == localItemId;
      elo.putIfAbsent(c.winnerItemId, () => Elo.startingElo);
      elo.putIfAbsent(c.loserItemId, () => Elo.startingElo);
      final (wE, lE) = Elo.update(elo[c.winnerItemId]!, elo[c.loserItemId]!);
      elo[c.winnerItemId] = wE;
      elo[c.loserItemId] = lE;
      if (involves) {
        raw.add((t: c.createdAt, elo: elo[localItemId]!));
      }
    }
    if (raw.isEmpty) return const [];

    final shift = current.elo - raw.last.elo;
    return raw.map((p) => (t: p.t, elo: p.elo + shift)).toList();
  }
}
