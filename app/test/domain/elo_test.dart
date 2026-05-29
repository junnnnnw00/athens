import 'package:flutter_test/flutter_test.dart';
import 'package:athens/domain/elo.dart';

void main() {
  group('Elo.expected', () {
    test('equal ratings → 0.5', () {
      expect(Elo.expected(1000, 1000), closeTo(0.5, 0.0001));
    });

    test('higher rating → greater expectation', () {
      final e = Elo.expected(1200, 1000);
      expect(e, greaterThan(0.5));
    });

    test('lower rating → lesser expectation', () {
      final e = Elo.expected(800, 1000);
      expect(e, lessThan(0.5));
    });

    test('sum of expected(a,b) + expected(b,a) = 1', () {
      final ab = Elo.expected(1200, 1000);
      final ba = Elo.expected(1000, 1200);
      expect(ab + ba, closeTo(1.0, 0.0001));
    });
  });

  group('Elo.update', () {
    test('winner gains elo, loser loses elo', () {
      const w = 1000.0;
      const l = 1000.0;
      final (wNew, lNew) = Elo.update(w, l);
      expect(wNew, greaterThan(w));
      expect(lNew, lessThan(l));
    });

    test('elo is conserved (sum unchanged)', () {
      const w = 1000.0;
      const l = 1000.0;
      final (wNew, lNew) = Elo.update(w, l);
      expect(wNew + lNew, closeTo(w + l, 0.0001));
    });

    test('upset (low beats high) gives bigger gain', () {
      const w = 800.0;
      const l = 1200.0;
      final (wNew, _) = Elo.update(w, l);
      final normalGain = Elo.update(1000, 1000).$1 - 1000;
      expect(wNew - w, greaterThan(normalGain));
    });

    test('expected win (high beats low) gives smaller gain', () {
      const w = 1200.0;
      const l = 800.0;
      final (wNew, _) = Elo.update(w, l);
      final normalGain = Elo.update(1000, 1000).$1 - 1000;
      expect(wNew - w, lessThan(normalGain));
    });

    test('custom k factor scales the change', () {
      const w = 1000.0;
      const l = 1000.0;
      final (wNew16, _) = Elo.update(w, l, k: 16);
      final (wNew32, _) = Elo.update(w, l, k: 32);
      expect(wNew32 - w, closeTo(2 * (wNew16 - w), 0.0001));
    });
  });
}
