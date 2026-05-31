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

    // Map items to pairs with comparison count + random noise to safely break ties.
    final itemsWithNoise = items
        .map((item) => (item, item.comparisons.toDouble() + _random.nextDouble()))
        .toList();
    itemsWithNoise.sort((a, b) => a.$2.compareTo(b.$2));
    
    final sorted = itemsWithNoise.map((e) => e.$1).toList();

    // Pick from bottom 20% of comparison counts.
    final candidateCount = (sorted.length * 0.2).ceil().clamp(1, sorted.length);
    final pivot = sorted[_random.nextInt(candidateCount)];

    // Find all opponents and their Elo differences.
    final candidates = <(RatedItem, double)>[];
    for (final item in items) {
      if (item.id == pivot.id) continue;
      final diff = (item.elo - pivot.elo).abs();
      candidates.add((item, diff));
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.$2.compareTo(b.$2));

    // Choose randomly from the top 3 closest opponents.
    final poolSize = min(3, candidates.length);
    final best = candidates[_random.nextInt(poolSize)].$1;

    return (pivot, best);
  }

  /// Placement: when a new item is added, it duels existing items of the same
  /// kind to find its rank. Picks the nearest-Elo opponent the focus item has
  /// not yet faced in this session (binary-insertion flavour). Returns null when
  /// every candidate has been faced.
  static RatedItem? nextPlacementOpponent({
    required RatedItem focus,
    required List<RatedItem> candidates,
    required Set<String> faced,
  }) {
    RatedItem? best;
    double bestDiff = double.infinity;
    for (final c in candidates) {
      if (c.id == focus.id || faced.contains(c.id)) continue;
      final diff = (c.elo - focus.elo).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = c;
      }
    }
    return best;
  }

  /// How many placement rounds to run for [candidateCount] opponents — a
  /// binary-search bound, capped so it never drags on.
  static int placementRounds(int candidateCount) {
    if (candidateCount <= 0) return 0;
    final bound = (log(candidateCount) / ln2).ceil() + 1;
    return bound.clamp(1, candidateCount).clamp(1, 6);
  }
}
