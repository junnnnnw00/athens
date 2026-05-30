import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
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
    return _repo.loadLibrary();
  }

  Future<void> addItem(CatalogItem item) async {
    await _repo.addItem(item);
    await _reload();
  }

  Future<void> recordComparison({
    required String winnerId,
    required String loserId,
  }) async {
    await _repo.recordComparison(winnerId: winnerId, loserId: loserId);
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
