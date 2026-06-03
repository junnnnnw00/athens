import 'package:athens/features/home/home_screen.dart';
import 'package:athens/features/library/item_detail_screen.dart';
import 'package:athens/features/library/library_screen.dart';
import 'package:athens/router.dart';
import 'package:athens/theme/app_theme.dart';
import 'package:athens/widgets/floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_harness.dart';

/// Section A regression coverage: the StatefulShellRoute keeps item detail inside
/// the tab it was opened from, the FloatingNav stays visible on detail with the
/// originating tab highlighted, and back returns within that tab's stack.
void main() {
  int navIndex(WidgetTester tester) =>
      tester.widget<FloatingNav>(find.byType(FloatingNav)).currentIndex;

  Future<(ProviderContainer, GoRouter)> pumpApp(WidgetTester tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    // Mount the real tab shell directly, bypassing the auth-redirect gate
    // (Supabase isn't initialized under flutter test).
    final router = GoRouter(
      initialLocation: '/home',
      routes: [buildAppShellRoute()],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ));
    // Avoid pumpAndSettle: loading skeletons animate continuously.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    return (container, router);
  }

  testWidgets('opens on Home with the floating nav (Home active)',
      (tester) async {
    await pumpApp(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FloatingNav), findsOneWidget);
    expect(navIndex(tester), 0);
  });

  testWidgets('item detail opened from Home stays in the Home tab',
      (tester) async {
    final (_, router) = await pumpApp(tester);

    router.push('/home/item/test-id');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(ItemDetailScreen), findsOneWidget);
    // Nav still visible over the detail page, Home still highlighted.
    expect(find.byType(FloatingNav), findsOneWidget);
    expect(navIndex(tester), 0);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);
  });

  testWidgets('item detail opened from the Me tab stays in the Me tab',
      (tester) async {
    final (_, router) = await pumpApp(tester);

    router.go('/library');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(navIndex(tester), 1);

    router.push('/library/item/test-id');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    // Me tab stays highlighted while viewing detail.
    expect(navIndex(tester), 1);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(navIndex(tester), 1);
  });

  testWidgets('switching tabs preserves the per-branch stack', (tester) async {
    final (_, router) = await pumpApp(tester);

    // Go to Me, then switch back to Home: Home is still its root.
    router.go('/library');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(navIndex(tester), 1);

    router.go('/home');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navIndex(tester), 0);
  });
}
