import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/supabase.dart';
import 'data/local/app_database.dart';
import 'data/repository/library_providers.dart';
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

/// Seeds the database and runs a handful of duels so ranking/stats have data.
Future<void> seedDevData(ProviderContainer container) async {
  await container.read(libraryControllerProvider.future);
  final controller = container.read(libraryControllerProvider.notifier);
  final items = devSeedItems();
  for (final item in items) {
    await controller.addItem(item);
  }
  // Deterministic duels: earlier items beat later ones, building a clear order.
  for (var i = 0; i < items.length - 1; i++) {
    for (var j = i + 1; j < items.length; j++) {
      await controller.recordComparison(
        winnerId: items[i].id,
        loserId: items[j].id,
      );
    }
  }

  // Backdate comparisons to build a beautiful historical activity timeline chart
  final db = container.read(appDatabaseProvider);
  final comps = await db.select(db.localComparisons).get();
  for (var i = 0; i < comps.length; i++) {
    final offsetDays = (i % 14); // Distribute over the past 14 days
    final backdate = DateTime.now().subtract(Duration(days: offsetDays, hours: i % 24, minutes: i % 60));
    await (db.update(db.localComparisons)..where((t) => t.id.equals(comps[i].id)))
        .write(LocalComparisonsCompanion(
      createdAt: Value(backdate),
    ));
  }
}

/// Clears all existing data for the active user locally and remotely, then seeds a rich data set.
Future<void> forceReSeed(WidgetRef ref) async {
  final db = ref.read(appDatabaseProvider);
  final client = Supabase.instance.client;
  final userId = ref.read(currentUserIdProvider);

  // 1. Clear remote ratings & comparisons in Supabase for this user (if signed in)
  if (isSupabaseInitialized && client.auth.currentUser != null) {
    try {
      await client.from('ratings').delete().eq('user_id', userId);
      await client.from('comparisons').delete().eq('user_id', userId);
    } catch (_) {}
  }

  // 2. Clear local Drift database for this user
  await db.transaction(() async {
    await (db.delete(db.localRatings)..where((t) => t.userId.equals(userId))).go();
    await (db.delete(db.localComparisons)..where((t) => t.userId.equals(userId))).go();
  });

  // 3. Seed data
  final controller = ref.read(libraryControllerProvider.notifier);
  final items = devSeedItems();
  for (final item in items) {
    await controller.addItem(item);
  }

  for (var i = 0; i < items.length - 1; i++) {
    for (var j = i + 1; j < items.length; j++) {
      await controller.recordComparison(
        winnerId: items[i].id,
        loserId: items[j].id,
      );
    }
  }

  // 4. Backdate comparisons in SQLite to populate the history chart
  final comps = await db.select(db.localComparisons).get();
  for (var i = 0; i < comps.length; i++) {
    final offsetDays = (i % 14);
    final backdate = DateTime.now().subtract(Duration(days: offsetDays, hours: i % 24, minutes: i % 60));
    await (db.update(db.localComparisons)..where((t) => t.id.equals(comps[i].id)))
        .write(LocalComparisonsCompanion(
      createdAt: Value(backdate),
    ));
  }
}

