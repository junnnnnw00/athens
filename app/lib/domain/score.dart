import 'dart:math' as math;

/// Maps an Elo rating to a 0–10 score using a logistic function.
/// elo 1000 → 5.0 (midpoint), elo 1400 → ~9.0, elo 600 → ~1.0.
double scoreFromElo(double elo) {
  return 10 / (1 + math.exp(-(elo - 1000) / 200));
}
