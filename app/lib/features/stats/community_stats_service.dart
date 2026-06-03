import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/stats_engine.dart' show ScoreBucket;

/// Community rating aggregate for one catalog item, drawn from ALL accounts
/// (public + private). [avg]/[distribution] are null until enough accounts have
/// rated the item (server-side privacy threshold), in which case only [count]
/// is meaningful.
class CommunityStats {
  const CommunityStats({
    required this.count,
    this.avg,
    this.distribution,
  });

  final int count;
  final double? avg;
  final List<ScoreBucket>? distribution;

  bool get hasDetail => avg != null && distribution != null;
}

/// One daily point on the community-average trend line.
class CommunityTrendPoint {
  const CommunityTrendPoint({required this.day, required this.avg});
  final DateTime day;
  final double avg;
}

/// A review from a public account, with enough author info to attribute it.
class PublicReview {
  const PublicReview({
    required this.userId,
    required this.handle,
    this.displayName,
    this.avatarUrl,
    required this.body,
    this.ratingSnapshot,
    required this.updatedAt,
  });

  final String userId;
  final String handle;
  final String? displayName;
  final String? avatarUrl;
  final String body;
  final double? ratingSnapshot;
  final DateTime updatedAt;
}

/// Everything the item-detail community section renders, fetched in one shot.
class CommunityItemData {
  const CommunityItemData({
    required this.stats,
    required this.trend,
    required this.reviews,
    required this.ownTrend,
  });

  final CommunityStats stats;
  final List<CommunityTrendPoint> trend;
  final List<PublicReview> reviews;

  /// The signed-in user's own **Elo** history for this item (reconstructed from
  /// their local duel log). Empty when there aren't enough points to draw.
  final List<({DateTime t, double elo})> ownTrend;
}

/// Loads the user's own trend (always, from local data) plus the community
/// aggregate + public reviews (when a remote item id is available). The own
/// trend is purely local, so it must NOT depend on remote/community data — it
/// renders even when signed out, offline, or below the community threshold.
final communityItemDataProvider = FutureProvider.autoDispose
    .family<CommunityItemData, String>((ref, localItemId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final gateway = ref.watch(supabaseGatewayProvider);

  // Own trend first — local, never gated by community availability.
  final ownTrend = await repo.getOwnRatingTrend(localItemId);

  var stats = const CommunityStats(count: 0);
  var trend = const <CommunityTrendPoint>[];
  var reviews = const <PublicReview>[];

  final uuid =
      gateway == null ? null : await repo.resolveRemoteItemId(localItemId);
  if (gateway != null && uuid != null) {
    final results = await Future.wait([
      gateway.getItemRatingStats(uuid),
      gateway.getItemRatingTrend(uuid),
      gateway.getItemPublicReviews(uuid),
    ]);

    final statsRaw = results[0] as Map<String, dynamic>?;
    final trendRaw = results[1] as List<Map<String, dynamic>>;
    final reviewsRaw = results[2] as List<Map<String, dynamic>>;

    final count = (statsRaw?['count'] as num?)?.toInt() ?? 0;
    final avg = (statsRaw?['avg'] as num?)?.toDouble();
    final distRaw = statsRaw?['distribution'] as List<dynamic>?;
    final distribution = distRaw == null
        ? null
        : List.generate(
            distRaw.length,
            (i) => ScoreBucket(
              label: '$i-${i + 1}',
              count: (distRaw[i] as num).toInt(),
            ),
          );
    stats = CommunityStats(count: count, avg: avg, distribution: distribution);

    trend = trendRaw
        .map((r) => CommunityTrendPoint(
              day: DateTime.parse(r['day'] as String),
              avg: (r['avg_score'] as num).toDouble(),
            ))
        .toList();

    reviews = reviewsRaw
        .map((r) => PublicReview(
              userId: r['user_id'] as String,
              handle: r['handle'] as String,
              displayName: r['display_name'] as String?,
              avatarUrl: r['avatar_url'] as String?,
              body: r['body'] as String,
              ratingSnapshot: (r['rating_snapshot'] as num?)?.toDouble(),
              updatedAt: DateTime.parse(r['updated_at'] as String),
            ))
        .toList();
  }

  return CommunityItemData(
    stats: stats,
    trend: trend,
    reviews: reviews,
    ownTrend: ownTrend,
  );
});
