import 'package:flutter_test/flutter_test.dart';
import 'package:athens/domain/score.dart';

void main() {
  group('scoreFromElo', () {
    test('elo 1000 → 5.0 (midpoint)', () {
      expect(scoreFromElo(1000), closeTo(5.0, 0.001));
    });

    test('result always between 0 and 10', () {
      for (final elo in [0.0, 400.0, 800.0, 1000.0, 1200.0, 1600.0, 2000.0]) {
        final s = scoreFromElo(elo);
        expect(s, greaterThanOrEqualTo(0));
        expect(s, lessThanOrEqualTo(10));
      }
    });

    test('monotonically increasing', () {
      final scores = [600.0, 800.0, 1000.0, 1200.0, 1400.0]
          .map(scoreFromElo)
          .toList();
      for (var i = 0; i < scores.length - 1; i++) {
        expect(scores[i], lessThan(scores[i + 1]));
      }
    });

    test('high elo (1400) → approximately 9', () {
      expect(scoreFromElo(1400), closeTo(9.0, 0.2));
    });

    test('low elo (600) → approximately 1', () {
      expect(scoreFromElo(600), closeTo(1.0, 0.2));
    });
  });
}
