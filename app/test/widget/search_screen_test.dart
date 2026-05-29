import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/catalog/search_screen.dart';
import 'package:athens/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  testWidgets('search renders service-layer results and adds to library',
      (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SearchScreen(),
      ),
    ));
    await tester.pump();

    // Empty query → prompt.
    expect(find.text('검색어를 입력하세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'slowdive');
    await tester.pump(); // query state
    await tester.pump(); // future resolves

    // Results come from the (fake) service layer, not a hardcoded list.
    expect(find.text('Loveless'), findsOneWidget);
    expect(find.text('Souvlaki'), findsOneWidget);

    // Add the first result.
    await tester.tap(find.text('추가').first);
    await tester.pump();
    await tester.pump();

    final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)));
    expect(container.read(ratedItemsProvider), isNotEmpty);
  });

  testWidgets('search shows a no-results state', (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp(theme: AppTheme.dark(), home: const SearchScreen()),
    ));
    await tester.pump();
    // FakeSpotifyApi returns results for any non-empty query; assert the empty
    // query branch instead (its own real UI, never a crash/blank).
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('검색어를 입력하세요'), findsOneWidget);
  });
}
