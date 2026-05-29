import 'dart:math';

class RatedItem {
  const RatedItem({
    required this.id,
    required this.elo,
    required this.comparisons,
  });

  final String id;
  final double elo;
  final int comparisons;
}

class PairSelector {
  PairSelector({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Selects a pair for comparison.
  ///
  /// Strategy:
  /// 1. Pick the item with fewest comparisons (with 20% random noise to avoid
  ///    always picking the same item when counts are equal).
  /// 2. Find its nearest-Elo opponent (excluding itself).
  ///
  /// Returns null if fewer than 2 items exist.
  (RatedItem, RatedItem)? selectPair(List<RatedItem> items) {
    if (items.length < 2) return null;

    final sorted = List<RatedItem>.from(items)
      ..sort((a, b) => a.comparisons.compareTo(b.comparisons));

    // Pick from bottom 20% of comparison counts with some randomness.
    final candidateCount = (sorted.length * 0.2).ceil().clamp(1, sorted.length);
    final pivot = sorted[_random.nextInt(candidateCount)];

    // Find nearest-elo opponent.
    RatedItem? best;
    double bestDiff = double.infinity;
    for (final item in items) {
      if (item.id == pivot.id) continue;
      final diff = (item.elo - pivot.elo).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = item;
      }
    }

    if (best == null) return null;
    return (pivot, best);
  }
}
