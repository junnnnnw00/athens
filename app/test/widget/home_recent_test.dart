import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:athens/features/catalog/search_screen.dart';
import 'package:athens/features/home/home_screen.dart';
import 'package:athens/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

CatalogItem _track(String id, String title) => CatalogItem(
      id: id,
      kind: 'track',
      title: title,
      primaryArtist: 'Artist',
      source: 'lastfm',
      sourceId: id,
    );

void main() {
  testWidgets('home shows genre recommendations', (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
    ));
    await tester.pump();
    await tester.pumpAndSettle();

    // Recommendations now come from Last.fm tag.getTopTracks (genre-matched),
    // not a catalog text-search for the tag word. The fake returns tag tracks.
    expect(find.textContaining('Tracks'), findsOneWidget);
    expect(find.textContaining('Fake Tag Track 1'), findsOneWidget);
  });

  testWidgets('home surfaces only unrated recently-played tracks',
      (tester) async {
    final harness = TestHarness(
      recentlyPlayed: [
        _track('lastfm:rated', 'Already Rated'),
        _track('lastfm:fresh', 'Fresh Track'),
      ],
      lastfmUsername: 'testuser',
    );
    harness.overrides.add(
      genreRecommendationsProvider.overrideWith((ref) => (genre: 'Indie', items: <CatalogItem>[])),
    );
    addTearDown(harness.dispose);

    final container = harness.container();
    // Pre-rate one of the recently-played tracks.
    await container.read(libraryControllerProvider.future);
    await container
        .read(libraryControllerProvider.notifier)
        .addItem(_track('lastfm:rated', 'Already Rated'));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Fresh Track'), findsOneWidget);
    expect(find.text('Already Rated'), findsNothing);
  });

  testWidgets('user without Last.fm sees a graceful empty state', (tester) async {
    final harness = TestHarness(); // no lastfmUsername, no recentlyPlayed
    harness.overrides.add(
      genreRecommendationsProvider.overrideWith((ref) => (genre: 'Indie', items: <CatalogItem>[])),
    );
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: const HomeScreen()),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Connect Last.fm'), findsOneWidget);
  });
}
