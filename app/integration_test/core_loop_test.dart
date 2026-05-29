import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/library/library_screen.dart';
import 'package:athens/features/rank/duel_screen.dart';
import 'package:athens/features/share/share_screen.dart';
import 'package:athens/features/stats/stats_screen.dart';
import 'package:athens/main.dart';
import 'package:athens/widgets/score_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('core loop: search → add → duel → library → stats → share',
      (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: const AthensApp(),
    ));
    await tester.pumpAndSettle();

    // We start on Home.
    expect(find.text('Athens'), findsOneWidget);

    // --- SEARCH (via the centre Add button) ---
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'shoegaze');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Loveless'), findsOneWidget);
    expect(find.text('Souvlaki'), findsOneWidget);

    // --- ADD both results to the real library ---
    final addButtons = find.text('추가');
    expect(addButtons, findsNWidgets(2));
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('추가').first); // second remaining add
    await tester.pumpAndSettle();
    // Clear the "added" snackbars so they don't cover the floating nav.
    ScaffoldMessenger.of(tester.firstElement(find.byType(Scaffold)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(container.read(ratedItemsProvider).length, 2);

    // --- DUEL (Home → callout) ---
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('듀얼 시작하기'));
    await tester.pumpAndSettle();
    expect(find.byType(DuelScreen), findsOneWidget);
    expect(find.text('어떤 게 더 좋아요?'), findsOneWidget);

    // Pick the first card by tapping a title we know is loaded.
    final lovelessCard = find.text('Loveless');
    expect(lovelessCard, findsWidgets);
    await tester.tap(lovelessCard.first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // A comparison was recorded → both items have 1 duel.
    final lib = container.read(ratedItemsProvider);
    expect(lib.every((i) => i.comparisons >= 1), isTrue);

    // --- LIBRARY (Me) shows ranked rows with score rings ---
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(ScoreRing), findsWidgets);

    // --- STATS renders computed charts ---
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('점수 분포'), findsOneWidget);

    // --- SHARE card renders from live data ---
    // Back to library, then profile → share.
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취향 공유'));
    await tester.pumpAndSettle();
    expect(find.byType(ShareScreen), findsOneWidget);
    expect(find.byType(ShareCard), findsWidgets);
  });
}
