import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
import '../../domain/elo.dart';
import '../../features/catalog/catalog_service.dart';
import '../local/app_database.dart';
import '../remote/supabase_gateway.dart';
import 'library_repository.dart';

/// The local database. Overridden in tests with an in-memory instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The active user id. Falls back to a stable local id when not signed in,
/// so the app is fully usable offline / before auth.
final currentUserIdProvider = Provider<String>((ref) {
  if (isSupabaseInitialized) {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {
      // Supabase not initialised (e.g. tests) — use the local id.
    }
  }
  return 'local-user';
});

final supabaseGatewayProvider = Provider<SupabaseGateway?>((ref) {
  if (isSupabaseInitialized) {
    return SupabaseGatewayImpl();
  }
  return null;
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(
    db: ref.watch(appDatabaseProvider),
    userId: ref.watch(currentUserIdProvider),
    remote: ref.watch(supabaseGatewayProvider),
  );
});

/// The rated library, loaded from Drift. Every mutation re-reads from the
/// database so the UI always reflects persisted state (survives restart).
final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, List<RatedCatalogItem>>(
  LibraryController.new,
);

class LibraryController extends AsyncNotifier<List<RatedCatalogItem>> {
  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  @override
  Future<List<RatedCatalogItem>> build() async {
    // Pull remote ratings into the local cache first, so a fresh browser/device
    // shows the library other devices created (no-op when signed out / offline).
    await _repo.pullRemote();
    final lib = await _repo.loadLibrary();
    // Backfill tags for items that have none (e.g. added before the artist-tag
    // fallback existed, or pulled from an older row). Runs detached.
    unawaited(_backfillTags(lib));
    return lib;
  }

  /// Best-effort: re-enrich items missing tags and persist them, then refresh
  Future<void> _backfillTags(List<RatedCatalogItem> lib) async {
    final missing = lib.where((i) => i.tags.length < 15).toList();
    if (missing.isEmpty) return;
    final svc = ref.read(catalogServiceProvider);
    var changed = false;
    for (final item in missing) {
      try {
        final tags = await svc.enrichTags(CatalogItem(
          id: item.id,
          kind: item.kind,
          title: item.title,
          primaryArtist: item.primaryArtist,
          imageUrl: item.imageUrl,
        ));
        if (tags.isNotEmpty) {
          await _repo.updateItemTags(item.id, tags);
          changed = true;
        }
      } catch (_) {
        // Skip this item; try the rest.
      }
    }
    if (!changed) return;
    try {
      state = AsyncData(await _repo.loadLibrary());
    } catch (_) {
      // Provider disposed mid-backfill — nothing to update.
    }
  }

  Future<void> addItem(CatalogItem item, {double startingElo = Elo.startingEloGood}) async {
    await _repo.addItem(item, startingElo: startingElo);
    state = AsyncData(await _repo.loadLibrary());
  }

  Future<void> recordComparison({
    required String winnerId,
    required String loserId,
  }) async {
    await _repo.recordComparison(winnerId: winnerId, loserId: loserId);
    await _reload();
  }

  Future<void> deleteItem(String itemId) async {
    await _repo.removeItem(itemId);
    await _reload();
  }

  Future<void> resetForPlacement(String itemId, {double startingElo = Elo.startingElo}) async {
    await _repo.resetForPlacement(itemId, startingElo: startingElo);
    await _reload();
  }

  Future<void> _reload() async {
    state = AsyncData(await _repo.loadLibrary());
  }
}

/// Convenience: the loaded list (empty while loading / on error).
final ratedItemsProvider = Provider<List<RatedCatalogItem>>((ref) {
  return ref.watch(libraryControllerProvider).valueOrNull ?? const [];
});
