import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stats_engine.dart' show ScoreBucket;
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/cover_art.dart';
import '../stats/community_stats_service.dart';
import '../../i18n.dart';

/// Community rating statistics for one item, shown on the detail screen:
/// average + distribution + community trend (all accounts), the signed-in
/// user's own score trend, and reviews from public accounts only.
class CommunityStatsSection extends ConsumerWidget {
  const CommunityStatsSection({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityItemDataProvider(itemId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) => _Content(data: data),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.data});
  final CommunityItemData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stats = data.stats;

    // Community aggregate is shown ONLY once the privacy threshold is met
    // (server returns avg + distribution → hasDetail). Below it, nothing about
    // the community is revealed — not even the rater count. The user's own
    // per-item trend and public reviews stay visible regardless.
    final showCommunity = stats.hasDetail;
    final showOwnTrend = data.ownTrend.isNotEmpty;
    final showReviews = data.reviews.isNotEmpty;
    if (!showCommunity && !showOwnTrend && !showReviews) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xxl),

        if (showCommunity) ...[
          Text(context.t('community_rating', ref: ref), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // Headline: average + rater count.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats.avg!.toStringAsFixed(1),
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(color: p.accentText, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child:
                    Text('/ 10', style: TextStyle(color: p.muted, fontSize: 14)),
              ),
              const Spacer(),
              Text(context.t('community_rated_count', args: ['${stats.count}'], ref: ref),
                  style: TextStyle(color: p.muted, fontSize: 13)),
            ],
          ),

          // Score distribution.
          const SizedBox(height: AppSpacing.xl),
          Text(context.t('stats_distribution', ref: ref), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: _DistBar(buckets: stats.distribution!),
          ),

          // Community average over time.
          if (data.trend.length >= 2) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(context.t('average_score_trend', ref: ref), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 150,
              child: _TrendLine(
                points: [
                  for (final t in data.trend) (t: t.day, y: t.avg),
                ],
                color: p.accent,
                minY: 0,
                maxY: 10,
                yInterval: 2,
                tooltipValue: (v) => context.t('score_suffix', args: [v.toStringAsFixed(1)], ref: ref),
              ),
            ),
          ],
        ],

        // The user's own Elo history for this item (Elo, not the compressed
        // 0–10 score, so small movements stay visible).
        if (showOwnTrend) ...[
          if (showCommunity) const SizedBox(height: AppSpacing.xl),
          Text(context.t('my_elo_trend', ref: ref), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _OwnEloChart(points: data.ownTrend, color: p.accentText),
        ],

        // Reviews from public accounts.
        if (showReviews) ...[
          const SizedBox(height: AppSpacing.xxl),
          Text(context.t('others_reviews', ref: ref),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          for (final r in data.reviews) _ReviewCard(review: r),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final PublicReview review;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = (review.displayName?.isNotEmpty ?? false)
        ? review.displayName!
        : '@${review.handle}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CoverArt(
                    title: name,
                    imageUrl: review.avatarUrl,
                    size: 26,
                    radius: 13,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (review.ratingSnapshot != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  review.ratingSnapshot!.toStringAsFixed(1),
                  style: TextStyle(
                      color: p.accentText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(review.body,
              style: TextStyle(color: p.text, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

/// Score-distribution bar chart (10 buckets, 0–10).
class _DistBar extends ConsumerWidget {
  const _DistBar({required this.buckets});
  final List<ScoreBucket> buckets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final maxY =
        buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
              context.t('score_points', args: [buckets[gi].label], ref: ref),
              TextStyle(
                  color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
              children: [
                TextSpan(
                  text: context.t('people_count', args: ['${buckets[gi].count}'], ref: ref),
                  style: TextStyle(
                      color: p.accentText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: math.max((maxY / 3).roundToDouble(), 1.0),
          getDrawingHorizontalLine: (v) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        barGroups: buckets
            .asMap()
            .entries
            .map((e) => BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    gradient: LinearGradient(
                      colors: [p.accent, p.accent.withValues(alpha: 0.5)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 14,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ]))
            .toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= buckets.length || idx % 2 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('$idx',
                      style: TextStyle(fontSize: 10, color: p.muted)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                if (v == 0 || v % 1 != 0) return const SizedBox.shrink();
                return Text('${v.toInt()}',
                    style: TextStyle(fontSize: 9, color: p.muted));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: p.line)),
        ),
      ),
    );
  }
}

/// The user's own Elo history. Auto-scales the Y axis to the Elo range so even
/// small swings are visible, then defers to [_TrendLine] for rendering.
class _OwnEloChart extends ConsumerWidget {
  const _OwnEloChart({required this.points, required this.color});
  final List<({DateTime t, double elo})> points;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ys = points.map((e) => e.elo);
    final lo = ys.reduce(math.min);
    final hi = ys.reduce(math.max);
    final (minY, maxY, interval) = _niceAxis(lo, hi);
    return SizedBox(
      height: 150,
      child: _TrendLine(
        points: [for (final e in points) (t: e.t, y: e.elo)],
        color: color,
        minY: minY,
        maxY: maxY,
        yInterval: interval,
        tooltipValue: (v) => 'Elo ${v.round()}',
        labelDecimals: 0,
      ),
    );
  }
}

/// Picks round axis bounds + tick interval that comfortably contain [lo, hi],
/// padded so the data never sits flush against the top/bottom frame and the
/// tick values are clean round numbers (…, 1000, 1050, 1100, …).
(double, double, double) _niceAxis(double lo, double hi) {
  var range = hi - lo;
  if (range <= 0) range = math.max(lo.abs() * 0.1, 40); // flat line window
  final rawStep = range / 3;
  final mag = math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
  final norm = rawStep / mag;
  final niceNorm = norm < 1.5
      ? 1.0
      : norm < 3
          ? 2.0
          : norm < 7
              ? 5.0
              : 10.0;
  final step = niceNorm * mag;
  var minY = (lo / step).floor() * step;
  var maxY = (hi / step).ceil() * step;
  // Guarantee a margin between the data and the frame so end ticks aren't crammed.
  if (lo - minY < step * 0.5) minY -= step;
  if (maxY - hi < step * 0.5) maxY += step;
  return (minY, maxY, step);
}

/// Generic time-series line chart. Y axis bounds + value formatting are supplied
/// by the caller so it can render either a 0–10 score or a raw Elo series.
class _TrendLine extends ConsumerWidget {
  const _TrendLine({
    required this.points,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    required this.tooltipValue,
    this.labelDecimals = 0,
  });

  final List<({DateTime t, double y})> points;
  final Color color;
  final double minY;
  final double maxY;
  final double yInterval;
  final String Function(double) tooltipValue;
  final int labelDecimals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    String axisLabel(DateTime d) => '${d.month}/${d.day}';
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            getTooltipItems: (spots) => spots.map((s) {
              final d = points[s.x.toInt()].t;
              return LineTooltipItem(
                context.t('date_format_tooltip', args: ['${d.month}', '${d.day}'], ref: ref),
                TextStyle(
                    color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
                children: [
                  TextSpan(
                    text: tooltipValue(s.y),
                    style: TextStyle(
                        color: p.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval <= 0 ? 1 : yInterval,
          getDrawingHorizontalLine: (v) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: points
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.y))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: color,
                strokeWidth: 1.5,
                strokeColor: p.bg,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Exactly one tick per point so the day-change check below sees
              // every index (fractional auto-intervals would alias two ticks to
              // the same index → the same date printed twice).
              interval: 1,
              getTitlesWidget: (v, _) {
                final idx = v.round();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final d = points[idx].t;
                // One label per distinct date: render only where the day differs
                // from the previous point (same-day re-ratings don't repeat it).
                if (idx > 0) {
                  final prev = points[idx - 1].t;
                  if (prev.year == d.year &&
                      prev.month == d.month &&
                      prev.day == d.day) {
                    return const SizedBox.shrink();
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(axisLabel(d),
                      style: TextStyle(fontSize: 9, color: p.muted)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: yInterval <= 0 ? 1 : yInterval,
              getTitlesWidget: (v, _) {
                // Drop labels hugging the top/bottom frame — they look cramped.
                final edge = (yInterval <= 0 ? 1 : yInterval) * 0.25;
                if (v - minY < edge || maxY - v < edge) {
                  return const SizedBox.shrink();
                }
                return Text(
                  v.toStringAsFixed(labelDecimals),
                  style: TextStyle(fontSize: 9, color: p.muted),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: p.line)),
        ),
      ),
    );
  }
}
