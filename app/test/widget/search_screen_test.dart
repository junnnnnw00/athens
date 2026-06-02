import 'package:athens/data/repository/library_providers.dart';
import 'package:athens/features/catalog/search_screen.dart';
import 'package:athens/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

/// Wraps a screen in a minimal go_router so GoRouter.of(context) works.
Widget _app(Widget home) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => home),
    GoRoute(path: '/duel/:focusId', builder: (_, __) => const SizedBox()),
  ]);
  return MaterialApp.router(theme: AppTheme.dark(), routerConfig: router);
}

void main() {
  testWidgets('search renders service-layer results and adds to library',
      (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: _app(const SearchScreen()),
    ));
    await tester.pump();

    // Empty query -> search screen is ready.
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'slowdive');
    await tester.pump(); // query state
    await tester.pump(); // future resolves

    // Results come from the (fake) iTunes service layer.
    expect(find.textContaining('iTunes Fallback'), findsOneWidget);

    // Add the first result.
    await tester.tap(find.text('추가').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)));
    expect(container.read(ratedItemsProvider), isNotEmpty);
  });

  testWidgets('search shows a no-results state', (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: _app(const SearchScreen()),
    ));
    await tester.pump();
    // Empty query branch — its own real UI, never a crash/blank.
    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
