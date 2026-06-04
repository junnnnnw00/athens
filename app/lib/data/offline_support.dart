import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/platform_storage.dart';
import '../features/catalog/catalog_service.dart';
import '../features/catalog/search_screen.dart' show genreRecommendationsProvider;
import '../features/friends/friends_service.dart' show friendsRecentRatingsProvider;
import '../features/profile/profile_service.dart';
import '../features/stats/stats_screen.dart' show statsProvider;
import 'connectivity_providers.dart';
import 'repository/library_providers.dart';

const String kLastUserIdKey = 'last_user_id';

/// Long-lived wiring that (1) persists the signed-in user id for offline use and
/// (2) reloads all network-backed data when connectivity is restored. Activated
/// by watching it from the app shell.
final offlineSupportProvider = Provider<void>((ref) {
  // Persist / clear the cached user id as auth state changes.
  ref.listen(authStateProvider, (_, next) {
    final state = next.valueOrNull;
    if (state == null) return;
    if (state.event == AuthChangeEvent.signedOut) {
      PlatformStorage.delete(key: kLastUserIdKey);
      ref.read(lastKnownUserIdProvider.notifier).state = null;
      return;
    }
    String? id;
    try {
      id = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {}
    if (id != null) {
      PlatformStorage.write(key: kLastUserIdKey, value: id);
      ref.read(lastKnownUserIdProvider.notifier).state = id;
    }
  });

  // On offline → online, refresh everything that depends on the network.
  ref.listen(connectivityProvider, (prev, next) {
    final cameOnline =
        prev?.valueOrNull == false && next.valueOrNull == true;
    if (!cameOnline) return;
    // Library: real remote pull + local reload.
    ref.read(libraryControllerProvider.notifier).refresh();
    // Profile, recommendations, recent plays, friends, stats.
    ref.invalidate(myProfileProvider);
    ref.invalidate(genreRecommendationsProvider);
    ref.invalidate(recentlyPlayedProvider);
    ref.invalidate(friendsRecentRatingsProvider);
    ref.invalidate(statsProvider);
  });
});
