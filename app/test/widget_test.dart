import 'package:athens/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_harness.dart';

void main() {
  testWidgets('App boots and renders the themed home shell', (tester) async {
    final harness = TestHarness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: harness.overrides,
      child: const AthensApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
    // Home title renders (not a default-Material placeholder screen).
    expect(find.text('Athens'), findsOneWidget);
  });
}
