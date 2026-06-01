import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/supabase.dart';
import 'data/local/app_database.dart';
import 'data/repository/library_providers.dart';
import 'domain/elo.dart';
import 'features/catalog/catalog_service.dart';

/// Dev-only seed flag. `false` in release builds. When enabled, real sample data
/// is written into the actual Drift layer and flows through the same providers
/// as production data — it never short-circuits the UI.
const bool kDevSeed = bool.fromEnvironment('DEV_SEED', defaultValue: false);

CatalogItem _item(
  String id,
  String kind,
  String title,
  String artist,
  List<String> genres,
  List<String> moods,
) {
  return CatalogItem(
    id: 'seed:$id',
    kind: kind,
    title: title,
    primaryArtist: artist,
    source: 'seed',
    sourceId: id,
    tags: [
      ...genres.map((g) => CatalogTag(name: g, source: 'genre')),
      ...moods.map((m) => CatalogTag(name: m, source: 'mood')),
    ],
  );
}

/// Sample library mirroring the design prototype (Korean/JP titles included).
List<CatalogItem> devSeedItems() => [
      _item('loveless', 'album', 'Loveless', 'My Bloody Valentine',
          ['shoegaze', 'noise pop'], ['dreamy', 'melancholic']),
      _item('머리에꽃을', 'album', '머리에 꽃을', '실리카겔',
          ['indie rock', 'psychedelic'], ['energetic', 'dreamy']),
      _item('souvlaki', 'album', 'Souvlaki', 'Slowdive',
          ['shoegaze', 'dream pop'], ['dreamy', 'melancholic']),
      _item('heaven', 'album', 'Heaven or Las Vegas', 'Cocteau Twins',
          ['dream pop', 'ethereal wave'], ['atmospheric', 'dreamy']),
      _item('새로운과실', 'album', '新しい果実', '長谷川白紙',
          ['experimental', 'electronic'], ['intense', 'energetic']),
      _item('비행운', 'track', '비행운', '새소년',
          ['indie rock', 'alternative'], ['nostalgic', 'calm']),
      _item('vivid', 'album', 'VIVID', 'ADOY',
          ['synth-pop', 'indie pop'], ['dreamy', 'uplifting']),
      _item('inrainbows', 'album', 'In Rainbows', 'Radiohead',
          ['art rock', 'alternative'], ['melancholic', 'atmospheric']),
      // New Items for rich stats
      _item('okcomputer', 'album', 'OK Computer', 'Radiohead',
          ['alternative rock', 'art rock'], ['melancholic', 'intense']),
      _item('dummy', 'album', 'Dummy', 'Portishead',
          ['trip hop', 'electronic'], ['dark', 'melancholic']),
      _item('blond', 'album', 'Blonde', 'Frank Ocean',
          ['rnb', 'avant-garde'], ['melancholic', 'warm']),
      _item('vespertine', 'album', 'Vespertine', 'Björk',
          ['art pop', 'electronic'], ['dreamy', 'atmospheric']),
      _item('madvillainy', 'album', 'Madvillainy', 'Madvillain',
          ['hip hop', 'experimental'], ['energetic', 'dark']),
      _item('pinkmoon', 'album', 'Pink Moon', 'Nick Drake',
          ['folk', 'acoustic'], ['calm', 'melancholic']),
      _item('velocity', 'album', 'Velocity : Design : Comfort', 'Sweet Trip',
          ['glitch pop', 'shoegaze'], ['dreamy', 'energetic']),
      _item('glowpt2', 'album', 'The Glow Pt. 2', 'The Microphones',
          ['indie folk', 'lo-fi'], ['raw', 'melancholic']),
      _item('hollow', 'album', '201', 'The Black Skirts',
          ['indie pop', 'synth-pop'], ['nostalgic', 'calm']),
      _item('parannoul', 'album', 'To See the Next Part of the Dream', 'Parannoul',
          ['shoegaze', 'emo'], ['melancholic', 'intense']),
    ];

/// Clear local tables for this user, calculate rankings in memory, and insert in a single Drift transaction.
Future<void> seedDatabaseHelper({
  required AppDatabase db,
  required String userId,
  required List<CatalogItem> items,
}) async {
  await db.transaction(() async {
    await (db.delete(db.localRatings)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.localComparisons)..where((t) => t.userId.equals(userId))).go();
  });

  final elos = {for (final item in items) item.id: Elo.startingEloGood};
  final compsCount = {for (final item in items) item.id: 0};
  final comparisonsToInsert = <LocalComparisonsCompanion>[];
  int compIndex = 0;

  for (var i = 0; i < items.length - 1; i++) {
    for (var j = i + 1; j < items.length; j++) {
      final winnerId = items[i].id;
      final loserId = items[j].id;
      
      final winnerElo = elos[winnerId]!;
      final loserElo = elos[loserId]!;
      final (wElo, lElo) = Elo.update(winnerElo, loserElo);
      elos[winnerId] = wElo;
      elos[loserId] = lElo;
      
      compsCount[winnerId] = compsCount[winnerId]! + 1;
      compsCount[loserId] = compsCount[loserId]! + 1;
      
      final offsetDays = (compIndex % 14);
      final backdate = DateTime.now().subtract(Duration(days: offsetDays, hours: compIndex % 24, minutes: compIndex % 60));
      final compId = '${userId}_${backdate.microsecondsSinceEpoch}_$compIndex';
      
      comparisonsToInsert.add(LocalComparisonsCompanion(
        id: Value(compId),
        userId: Value(userId),
        winnerItemId: Value(winnerId),
        loserItemId: Value(loserId),
        createdAt: Value(backdate),
      ));

      compIndex++;
    }
  }

  final ratingsToInsert = <LocalRatingsCompanion>[];
  final now = DateTime.now();
  for (final item in items) {
    final ratingId = '${userId}_${item.id}';
    ratingsToInsert.add(LocalRatingsCompanion(
      id: Value(ratingId),
      userId: Value(userId),
      itemId: Value(item.id),
      elo: Value(elos[item.id]!),
      comparisons: Value(compsCount[item.id]!),
      updatedAt: Value(now),
    ));
  }

  await db.transaction(() async {
    for (final item in items) {
      await db.upsertItem(LocalItemsCompanion(
        id: Value(item.id),
        kind: Value(item.kind),
        source: Value(item.source ?? 'unknown'),
        sourceId: Value(item.sourceId ?? item.id),
        title: Value(item.title),
        primaryArtist: Value(item.primaryArtist),
        imageUrl: Value(item.imageUrl),
        tags: Value(jsonEncode(item.tags.map((t) => {'name': t.name, 'source': t.source}).toList())),
      ));
    }
    for (final rating in ratingsToInsert) {
      await db.upsertRating(rating);
    }
    for (final comp in comparisonsToInsert) {
      await db.insertComparison(comp);
    }
  });
}

/// Seeds the database and runs a handful of duels so ranking/stats have data.
Future<void> seedDevData(ProviderContainer container) async {
  final db = container.read(appDatabaseProvider);
  final items = devSeedItems();
  await seedDatabaseHelper(db: db, userId: 'local-user', items: items);
}

/// Clears all existing data for the active user locally and remotely, then seeds a rich data set.
Future<void> forceReSeed(WidgetRef ref) async {
  final db = ref.read(appDatabaseProvider);
  final client = Supabase.instance.client;
  final userId = ref.read(currentUserIdProvider);
  final items = devSeedItems();

  // 1. Clear remote ratings & comparisons in Supabase for this user (if signed in)
  if (isSupabaseInitialized && client.auth.currentUser != null) {
    try {
      await client.from('ratings').delete().eq('user_id', userId);
      await client.from('comparisons').delete().eq('user_id', userId);
    } catch (_) {}
  }

  // 2. Perform fast local seed
  await seedDatabaseHelper(db: db, userId: userId, items: items);

  // 3. Sync to Supabase in bulk
  if (isSupabaseInitialized && client.auth.currentUser != null) {
    try {
      final elos = {for (final item in items) item.id: Elo.startingEloGood};
      final compsCount = {for (final item in items) item.id: 0};
      final localComps = await db.getComparisonsForUser(userId);

      for (var i = 0; i < items.length - 1; i++) {
        for (var j = i + 1; j < items.length; j++) {
          final wId = items[i].id;
          final lId = items[j].id;
          final (wElo, lElo) = Elo.update(elos[wId]!, elos[lId]!);
          elos[wId] = wElo;
          elos[lId] = lElo;
          compsCount[wId] = compsCount[wId]! + 1;
          compsCount[lId] = compsCount[lId]! + 1;
        }
      }

      final itemRecords = items.map((item) => {
        'kind': item.kind,
        'source': item.source ?? 'unknown',
        'source_id': item.sourceId ?? item.id,
        'title': item.title,
        'primary_artist': item.primaryArtist,
        'image_url': item.imageUrl,
        'tags': item.tags.map((t) => {'name': t.name, 'source': t.source}).toList(),
      }).toList();

      final response = await client
          .from('items')
          .upsert(itemRecords, onConflict: 'source,source_id')
          .select('id, source_id');
      
      final uuidMap = <String, String>{};
      for (final row in response) {
        final sourceId = row['source_id'] as String;
        final id = row['id'] as String;
        uuidMap['seed:$sourceId'] = id;
      }

      final now = DateTime.now();
      final supabaseRatings = items.map((item) {
        final uuid = uuidMap[item.id];
        return {
          'user_id': userId,
          'item_id': uuid,
          'elo': elos[item.id],
          'comparisons': compsCount[item.id],
          'updated_at': now.toIso8601String(),
        };
      }).where((r) => r['item_id'] != null).toList();

      final supabaseComparisons = localComps.map((comp) {
        final wUuid = uuidMap[comp.winnerItemId];
        final lUuid = uuidMap[comp.loserItemId];
        return {
          'user_id': userId,
          'winner_item_id': wUuid,
          'loser_item_id': lUuid,
          'created_at': comp.createdAt.toIso8601String(),
        };
      }).where((c) => c['winner_item_id'] != null && c['loser_item_id'] != null).toList();

      if (supabaseRatings.isNotEmpty) {
        await client.from('ratings').upsert(supabaseRatings, onConflict: 'user_id,item_id');
      }
      if (supabaseComparisons.isNotEmpty) {
        await client.from('comparisons').insert(supabaseComparisons);
      }
    } catch (e) {
      debugPrint('Supabase batch seed error: $e');
    }
  }
}

