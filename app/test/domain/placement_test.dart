import 'package:athens/domain/pair_selector.dart';
import 'package:flutter_test/flutter_test.dart';

RatedItem _i(String id, double elo) =>
    RatedItem(id: id, elo: elo, comparisons: 0);

void main() {
  group('PairSelector.nextPlacementOpponent', () {
    final focus = _i('focus', 1000);
    final candidates = [_i('a', 990), _i('b', 1100), _i('c', 800)];

    test('picks the nearest-elo unfaced opponent', () {
      final opp = PairSelector.nextPlacementOpponent(
          focus: focus, candidates: candidates, faced: {});
      expect(opp!.id, 'a'); // 990 is closest to 1000
    });

    test('excludes already-faced opponents', () {
      final opp = PairSelector.nextPlacementOpponent(
          focus: focus, candidates: candidates, faced: {'a'});
      expect(opp!.id, 'b'); // 1100 (diff 100) beats 800 (diff 200)
    });

    test('never returns the focus item itself', () {
      final opp = PairSelector.nextPlacementOpponent(
        focus: focus,
        candidates: [focus, _i('x', 1001)],
        faced: {},
      );
      expect(opp!.id, 'x');
    });

    test('returns null when all candidates are faced', () {
      final opp = PairSelector.nextPlacementOpponent(
          focus: focus, candidates: candidates, faced: {'a', 'b', 'c'});
      expect(opp, isNull);
    });
  });

  group('PairSelector.placementRounds', () {
    test('is a binary-search bound, capped at 6', () {
      expect(PairSelector.placementRounds(0), 0);
      expect(PairSelector.placementRounds(1), 1);
      expect(PairSelector.placementRounds(3), lessThanOrEqualTo(3));
      expect(PairSelector.placementRounds(2), greaterThanOrEqualTo(1));
      expect(PairSelector.placementRounds(1000), 6); // capped
    });

    test('never exceeds the candidate count', () {
      for (final n in [1, 2, 3, 4, 5]) {
        expect(PairSelector.placementRounds(n), lessThanOrEqualTo(n));
      }
    });
  });
}
