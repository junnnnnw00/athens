import 'package:athens/data/local/app_database.dart';
import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:athens/features/profile/profile_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fakes/fakes.dart';

/// A self-contained test environment: in-memory Drift + fake network boundary.
class TestHarness {
  TestHarness({
    List<CatalogItem> recentlyPlayed = const [],
    bool spotifyEnabled = false,
    String? lastfmUsername,
  })  : db = AppDatabase.forTesting(NativeDatabase.memory()),
        gateway = FakeSupabaseGateway() {
    overrides = [
      appDatabaseProvider.overrideWithValue(db),
      currentUserIdProvider.overrideWithValue('test-user'),
      myProfileProvider.overrideWith((ref) => Future.value(
            UserProfile(
              id: 'test-user',
              handle: 'test_user',
              displayName: 'Test User',
              isPublic: true,
              spotifyEnabled: spotifyEnabled,
              isPremium: true,
              lastfmUsername: lastfmUsername,
            ),
          )),
      spotifyApiProvider
          .overrideWithValue(FakeSpotifyApi(recentlyPlayed: recentlyPlayed)),
      itunesApiProvider.overrideWithValue(FakeItunesApi()),
      lastfmApiProvider.overrideWithValue(FakeLastfmApi()),
      musicBrainzApiProvider.overrideWithValue(FakeMusicBrainzApi()),
      supabaseGatewayProvider.overrideWithValue(gateway),
    ];
  }

  final AppDatabase db;
  final FakeSupabaseGateway gateway;
  late final List<Override> overrides;

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    addTearDownContainer(c);
    return c;
  }

  final _containers = <ProviderContainer>[];
  void addTearDownContainer(ProviderContainer c) => _containers.add(c);

  Future<void> dispose() async {
    for (final c in _containers) {
      c.dispose();
    }
    await db.close();
  }
}
