@Tags(['golden'])
library;

import 'dart:math';
import 'package:athens/domain/pair_selector.dart';
import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/dev_seed.dart';
import 'package:athens/features/home/home_screen.dart';
import 'package:athens/features/library/item_detail_screen.dart';
import 'package:athens/features/library/library_screen.dart';
import 'package:athens/features/rank/duel_screen.dart';
import 'package:athens/features/share/share_screen.dart';
import 'package:athens/features/stats/stats_screen.dart';
import 'package:athens/features/catalog/catalog_service.dart';
import 'package:athens/theme/app_theme.dart';
import 'package:athens/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

Future<void> _loadFonts() async {
  for (final family in ['Hanken Grotesk', 'Pretendard']) {
    final asset = family == 'Pretendard'
        ? 'assets/fonts/Pretendard.ttf'
        : 'assets/fonts/HankenGrotesk.ttf';
    final data = await rootBundle.load(asset);
    final loader = FontLoader(family)..addFont(Future.value(data.buffer.asByteData()));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    required ProviderContainer container,
    required ThemeData theme,
    required Widget child,
  }) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: child,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> seededContainer(TestHarness h) async {
    final c = h.container();
    c.read(localeProvider.notifier).state = AppLanguage.ko;
    await c.read(libraryControllerProvider.future);
    await seedDevData(c);
    return c;
  }

  final modes = {'dark': AppTheme.dark(), 'light': AppTheme.light()};

  for (final entry in modes.entries) {
    final mode = entry.key;
    final theme = entry.value;

    testWidgets('golden: home ($mode)', (tester) async {
      final h = TestHarness();
      addTearDown(h.dispose);
      final c = await seededContainer(h);
      await pumpScreen(tester,
          container: c, theme: theme, child: const HomeScreen());
      await expectLater(find.byType(HomeScreen),
          matchesGoldenFile('home_$mode.png'));
    });

    testWidgets('golden: library ($mode)', (tester) async {
      final h = TestHarness();
      addTearDown(h.dispose);
      final c = await seededContainer(h);
      await pumpScreen(tester,
          container: c, theme: theme, child: const LibraryScreen());
      await expectLater(find.byType(LibraryScreen),
          matchesGoldenFile('library_$mode.png'));
    });

    testWidgets('golden: stats ($mode)', (tester) async {
      final h = TestHarness();
      addTearDown(h.dispose);
      final c = await seededContainer(h);
      await pumpScreen(tester,
          container: c, theme: theme, child: const StatsScreen());
      await expectLater(find.byType(StatsScreen),
          matchesGoldenFile('stats_$mode.png'));
    });

    testWidgets('golden: item detail ($mode)', (tester) async {
      final h = TestHarness();
      addTearDown(h.dispose);
      final c = await seededContainer(h);
      await pumpScreen(tester,
          container: c,
          theme: theme,
          child: const ItemDetailScreen(itemId: 'seed:loveless'));
      await expectLater(find.byType(ItemDetailScreen),
          matchesGoldenFile('item_detail_$mode.png'));
    });

    testWidgets('golden: duel ($mode)', (tester) async {
      final h = TestHarness();
      addTearDown(h.dispose);
      final c = h.container();
      await c.read(libraryControllerProvider.future);
      final notifier = c.read(libraryControllerProvider.notifier);
      await notifier.addItem(const CatalogItem(
          id: 'd:a',
          kind: 'album',
          title: 'Loveless',
          primaryArtist: 'My Bloody Valentine',
          source: 'seed',
          sourceId: 'a'));
      await notifier.addItem(const CatalogItem(
          id: 'd:b',
          kind: 'album',
          title: 'Souvlaki',
          primaryArtist: 'Slowdive',
          source: 'seed',
          sourceId: 'b'));
      // One duel so elos differ → deterministic pair ordering.
      await notifier.recordComparison(winnerId: 'd:a', loserId: 'd:b');
      await pumpScreen(tester,
          container: c,
          theme: theme,
          child: DuelScreen(selector: PairSelector(random: Random(42))));
      await expectLater(find.byType(DuelScreen),
          matchesGoldenFile('duel_$mode.png'));
    });
  }

  testWidgets('golden: instagram share card', (tester) async {
    final h = TestHarness();
    addTearDown(h.dispose);
    final c = await seededContainer(h);
    final items = c.read(ratedItemsProvider).take(5).toList();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: ShareCard.top5(
              items: items,
              resolvedUrls: [for (final it in items) it.imageUrl],
              lang: AppLanguage.ko)),
    ));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(ShareCard), matchesGoldenFile('ig_card_top5.png'));
  });
}
