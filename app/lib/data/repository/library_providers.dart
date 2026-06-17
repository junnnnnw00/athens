import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../api/supabase.dart';
import '../../domain/elo.dart';
import '../../features/catalog/catalog_service.dart';
import '../connectivity_providers.dart';
import '../local/app_database.dart';
import '../remote/supabase_gateway.dart';
import 'library_repository.dart';

/// True when an immediately-preceding free-play duel can still be undone.
final canUndoDuelProvider = StateProvider<bool>((ref) => false);

/// Count of local changes made while offline that still need to reach the
/// server. Shown in the offline/sync indicator; reset after a successful sync.
final pendingSyncProvider = StateProvider<int>((ref) => 0);

/// Snapshot of the two items' pre-duel state, kept in memory so the last duel
/// can be reverted.
class _LastDuel {
  const _LastDuel({
    required this.comparisonId,
    required this.winnerId,
    required this.winnerElo,
    required this.winnerComparisons,
    required this.loserId,
    required this.loserElo,
    required this.loserComparisons,
  });
  final String comparisonId;
  final String winnerId;
  final double winnerElo;
  final int winnerComparisons;
  final String loserId;
  final double loserElo;
  final int loserComparisons;
}

/// The local database. Overridden in tests with an in-memory instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// A stream of Supabase AuthState changes to trigger reactivity on login/logout.
final authStateProvider = StreamProvider<AuthState>((ref) {
  if (isSupabaseInitialized) {
    return Supabase.instance.client.auth.onAuthStateChange;
  }
  return const Stream.empty();
});

/// The last signed-in user id, cached locally so a returning user can open the
/// app fully offline (even if the auth token has lapsed) and still load their
/// own local library. Seeded at startup from PlatformStorage (see main()) and
/// kept current by [offlineSupportProvider].
final lastKnownUserIdProvider = StateProvider<String?>((ref) => null);

/// The active user id. Prefers the live session, then the cached last-known id
/// (so a returning user keeps their library cold-starting offline), and finally
/// a stable local id when nobody has ever signed in.
final currentUserIdProvider = Provider<String>((ref) {
  if (isSupabaseInitialized) {
    try {
      // Listen to auth state changes to force re-evaluation
      ref.watch(authStateProvider);

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.id;
    } catch (_) {
      // Supabase not initialised (e.g. tests) — use the local id.
    }
  }
  // Offline / lapsed token: fall back to the last user we saw signed in, so the
  // local library keyed by that uuid still loads.
  final cached = ref.watch(lastKnownUserIdProvider);
  if (cached != null && cached.isNotEmpty) return cached;
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

  _LastDuel? _lastDuel;

  @override
  Future<List<RatedCatalogItem>> build() async {
    final repo = ref.watch(libraryRepositoryProvider);
    // Local-first: surface the cached library immediately so already-saved items
    // can be browsed and re-rated (duels) instantly — fully offline. Then
    // reconcile with the remote in the background (no-op signed out / offline).
    final local = await repo.loadLibrary();
    if (local.isEmpty) {
      // Possibly a fresh browser/device — hydrate from the remote so the user
      // sees the library other devices created. Best-effort (no-op offline).
      await repo.pullRemote();
      final pulled = await repo.loadLibrary();
      unawaited(_hydrate(pulled));
      return pulled;
    }
    // Backfill missing tags/art, pull remote, and warm the art cache — all
    // detached so they never block (or fail) the offline-available local library.
    unawaited(_syncRemote());
    unawaited(_hydrate(local));
    return local;
  }

  /// Online-only, detached: fill missing tags/art, then download every item's
  /// cover into the shared image cache so the artwork is available offline in
  /// the library AND the duel (which shows items the user may never have
  /// scrolled past online).
  Future<void> _hydrate(List<RatedCatalogItem> lib) async {
    await _backfill(lib);
    await _warmArtCache(state.valueOrNull ?? lib);
  }

  /// Best-effort: pull each cover into the disk cache (no-op if already cached
  /// or offline). Uses the same DefaultCacheManager that CachedNetworkImage
  /// reads, so warmed art renders without a network round-trip.
  Future<void> _warmArtCache(List<RatedCatalogItem> lib) async {
    final urls = lib
        .map((i) => i.imageUrl)
        .whereType<String>()
        .where((u) => !_needsArt(u))
        .toSet();
    if (urls.isEmpty) return;
    final cm = DefaultCacheManager();
    for (final url in urls) {
      try {
        await cm.getSingleFile(url);
      } catch (_) {
        // Offline / transient — skip; next online pass warms it.
      }
    }
  }

  /// Background remote pull + local reload. Best-effort: failures (offline /
  /// disposed) leave the local cache authoritative.
  Future<void> _syncRemote() async {
    try {
      await _repo.pullRemote();
      state = AsyncData(await _repo.loadLibrary());
      if (!ref.read(isOfflineProvider)) {
        ref.read(pendingSyncProvider.notifier).state = 0;
      }
    } catch (_) {
      // Offline / provider disposed mid-sync — keep the local library.
    }
  }

  /// Forces a remote pull + local reload. Wired to the library's pull-to-refresh
  /// and the offline→online reload. Also warms the art cache for offline use.
  Future<void> refresh() async {
    await _repo.pullRemote();
    final lib = await _repo.loadLibrary();
    state = AsyncData(lib);
    if (!ref.read(isOfflineProvider)) {
      ref.read(pendingSyncProvider.notifier).state = 0;
    }
    unawaited(_warmArtCache(lib));
  }

  static bool _needsArt(String? url) =>
      url == null ||
      url.isEmpty ||
      url.contains('2a96cbd8b46e442fc41c2b86b821562f'); // Last.fm blank art

  /// Best-effort: re-enrich items missing tags and/or cover art (e.g. tracks
  /// rated from the Last.fm feed that came without artwork) and persist them,
  /// then refresh. Online-only; offline iterations simply no-op per item.
  Future<void> _backfill(List<RatedCatalogItem> lib) async {
    final svc = ref.read(catalogServiceProvider);
    final itunes = ref.read(itunesApiProvider);
    var changed = false;
    for (final item in lib) {
      final artist =
          item.kind == 'artist' ? item.title : (item.primaryArtist ?? '');

      // Canonical-key backfill: tracks whose stored key isn't yet ISRC-based
      // (legacy items, Last.fm scrobbles) — resolve their ISRC so cross-language
      // duplicates collapse. Best-effort; a miss leaves the text key in place.
      if (item.kind == 'track' && !item.canonicalKey.startsWith('isrc:')) {
        try {
          final isrc = await itunes.lookupIsrc(artist: artist, title: item.title);
          if (isrc != null && isrc.isNotEmpty) {
            await _repo.setItemCanonicalKey(item.id, 'isrc:${isrc.toUpperCase()}');
            changed = true;
          }
        } catch (_) {
          // Skip; try the rest.
        }
      }

      final needTags = item.tags.length < 15;
      final needArt = _needsArt(item.imageUrl);
      if (!needTags && !needArt) continue;

      if (needArt) {
        try {
          final url = await svc.findArtworkUrl(
              kind: item.kind, artist: artist, title: item.title);
          if (url != null) {
            await _repo.updateItemImage(item.id, url);
            changed = true;
          }
        } catch (_) {
          // Skip; try the rest.
        }
      }
      if (needTags) {
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
    // Capture pre-duel state (for undo) before the elos change.
    final before = state.valueOrNull ?? const <RatedCatalogItem>[];
    RatedCatalogItem? w, l;
    for (final i in before) {
      if (i.id == winnerId) w = i;
      if (i.id == loserId) l = i;
    }
    final compId =
        await _repo.recordComparison(winnerId: winnerId, loserId: loserId);
    await _reload();
    if (compId != null && w != null && l != null) {
      _lastDuel = _LastDuel(
        comparisonId: compId,
        winnerId: w.id,
        winnerElo: w.elo,
        winnerComparisons: w.comparisons,
        loserId: l.id,
        loserElo: l.elo,
        loserComparisons: l.comparisons,
      );
      ref.read(canUndoDuelProvider.notifier).state = true;
      if (ref.read(isOfflineProvider)) {
        ref.read(pendingSyncProvider.notifier).state++;
      }
    }
  }

  /// Reverts the most recent free-play duel (restores both elos + counts and
  /// removes the comparison). No-op when there's nothing to undo.
  Future<void> undoLastDuel() async {
    final d = _lastDuel;
    if (d == null) return;
    await _repo.revertComparison(
      comparisonId: d.comparisonId,
      winnerId: d.winnerId,
      winnerElo: d.winnerElo,
      winnerComparisons: d.winnerComparisons,
      loserId: d.loserId,
      loserElo: d.loserElo,
      loserComparisons: d.loserComparisons,
    );
    _lastDuel = null;
    ref.read(canUndoDuelProvider.notifier).state = false;
    await _reload();
  }

  /// Forgets the undo target (e.g. after a skip or leaving the duel).
  void clearUndo() {
    _lastDuel = null;
    ref.read(canUndoDuelProvider.notifier).state = false;
  }

  Future<void> deleteItem(String itemId) async {
    await _repo.removeItem(itemId);
    await _reload();
  }

  /// Manually merges [duplicateId] into [primaryId] (same logical track/album
  /// the auto ISRC dedup missed). They collapse into one in the library.
  Future<void> mergeWith({
    required String primaryId,
    required String duplicateId,
  }) async {
    await _repo.mergeItems(primaryId: primaryId, duplicateId: duplicateId);
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
