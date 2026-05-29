import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:athens/domain/pair_selector.dart';

void main() {
  group('PairSelector.selectPair', () {
    final selector = PairSelector(random: Random(42));

    test('returns null for empty list', () {
      expect(selector.selectPair([]), isNull);
    });

    test('returns null for single item', () {
      final items = [const RatedItem(id: 'a', elo: 1000, comparisons: 0)];
      expect(selector.selectPair(items), isNull);
    });

    test('returns two different items', () {
      final items = [
        const RatedItem(id: 'a', elo: 1000, comparisons: 0),
        const RatedItem(id: 'b', elo: 1000, comparisons: 0),
      ];
      final pair = selector.selectPair(items);
      expect(pair, isNotNull);
      final (first, second) = pair!;
      expect(first.id, isNot(equals(second.id)));
    });

    test('selects item with fewest comparisons as pivot', () {
      final items = [
        const RatedItem(id: 'a', elo: 1000, comparisons: 100),
        const RatedItem(id: 'b', elo: 1000, comparisons: 100),
        const RatedItem(id: 'c', elo: 1000, comparisons: 0),
        const RatedItem(id: 'd', elo: 1000, comparisons: 100),
      ];
      // Run many times — 'c' should be the pivot frequently
      int cAsPivot = 0;
      final sel = PairSelector(random: Random(0));
      for (var i = 0; i < 20; i++) {
        final pair = sel.selectPair(items);
        if (pair != null && pair.$1.id == 'c') cAsPivot++;
      }
      expect(cAsPivot, greaterThan(10));
    });

    test('opponent is nearest elo to pivot', () {
      final items = [
        const RatedItem(id: 'pivot', elo: 1000, comparisons: 0),
        const RatedItem(id: 'near', elo: 1010, comparisons: 5),
        const RatedItem(id: 'far', elo: 1500, comparisons: 5),
      ];
      final sel = PairSelector(random: Random(0));
      int nearAsOpponent = 0;
      for (var i = 0; i < 10; i++) {
        final pair = sel.selectPair(items);
        if (pair != null && pair.$1.id == 'pivot' && pair.$2.id == 'near') {
          nearAsOpponent++;
        }
      }
      expect(nearAsOpponent, greaterThan(0));
    });

    test('both items in pair are from the input list', () {
      final items = [
        const RatedItem(id: 'x', elo: 900, comparisons: 3),
        const RatedItem(id: 'y', elo: 1100, comparisons: 7),
        const RatedItem(id: 'z', elo: 1050, comparisons: 1),
      ];
      final ids = items.map((e) => e.id).toSet();
      final sel = PairSelector(random: Random(1));
      for (var i = 0; i < 10; i++) {
        final pair = sel.selectPair(items);
        expect(pair, isNotNull);
        expect(ids.contains(pair!.$1.id), isTrue);
        expect(ids.contains(pair.$2.id), isTrue);
      }
    });
  });
}
