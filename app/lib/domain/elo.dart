import 'dart:math' as math;

class Elo {
  const Elo._();

  static const double defaultK = 32;
  static const double startingElo = 1000;
  static const double startingEloGood = 1200;
  static const double startingEloSlightlyGood = 1100;
  static const double startingEloAverage = 1000;
  static const double startingEloSlightlyBad = 900;
  static const double startingEloBad = 800;

  /// Expected score for player A against player B.
  static double expected(double a, double b) {
    return 1 / (1 + math.pow(10, (b - a) / 400));
  }

  /// Returns updated elos as (winnerElo, loserElo).
  static (double, double) update(
    double winnerElo,
    double loserElo, {
    double k = defaultK,
  }) {
    final expectedWin = expected(winnerElo, loserElo);
    final expectedLoss = expected(loserElo, winnerElo);
    return (
      winnerElo + k * (1 - expectedWin),
      loserElo + k * (0 - expectedLoss),
    );
  }
}
