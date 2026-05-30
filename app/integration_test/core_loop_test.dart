import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/library/library_screen.dart';
import 'package:athens/features/rank/duel_screen.dart';
import 'package:athens/features/share/share_screen.dart';
import 'package:athens/features/stats/stats_screen.dart';
import 'package:athens/main.dart';
import 'package:athens/router.dart';
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

    // --- ADD first result: no same-kind opponent yet → just added ---
    final addButtons = find.text('추가');
    expect(addButtons, findsNWidgets(2));
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(container.read(ratedItemsProvider).length, 1);

    // --- ADD second same-kind result → auto placement duel opens ---
    await tester.tap(find.text('추가').first);
    await tester.pumpAndSettle();
    expect(container.read(ratedItemsProvider).length, 2);
    expect(find.byType(DuelScreen), findsOneWidget);

    // Pick a card in the placement duel.
    final lovelessCard = find.text('Loveless');
    expect(lovelessCard, findsWidgets);
    await tester.tap(lovelessCard.first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    // A comparison was recorded → both items have 1 duel.
    final lib = container.read(ratedItemsProvider);
    expect(lib.every((i) => i.comparisons >= 1), isTrue);

    // Placement finishes (2 items → 1 round) → done screen → go to library.
    // Otherwise fall back to the Me nav tab.
    if (find.text('라이브러리 보기').evaluate().isNotEmpty) {
      await tester.tap(find.text('라이브러리 보기'));
      await tester.pumpAndSettle();
    } else {
      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pumpAndSettle();
    }

    // --- LIBRARY shows ranked rows with score rings ---
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(find.byType(ScoreRing), findsWidgets);

    // --- STATS renders computed charts ---
    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('점수 분포'), findsOneWidget);

    // --- SHARE card renders from live data ---
    // Navigate via the router (deterministic; avoids the floating nav being
    // overlapped by scroll content in the test viewport).
    container.read(routerProvider).go('/share');
    await tester.pumpAndSettle();
    expect(find.byType(ShareScreen), findsOneWidget);
    expect(find.byType(ShareCard), findsWidgets);
  });
}
