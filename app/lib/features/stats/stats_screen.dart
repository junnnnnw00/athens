import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stats_engine.dart';
import '../catalog/catalog_service.dart';

final statsProvider = Provider<LibraryStats>((ref) {
  final items = ref.watch(ratedItemsProvider);
  const engine = StatsEngine();
  final domainItems = items
      .map((i) => LibraryItem(
            id: i.id,
            kind: ItemKind.values.firstWhere(
              (k) => k.name == i.kind,
              orElse: () => ItemKind.track,
            ),
            elo: i.elo,
            comparisons: i.comparisons,
            tags: i.tags
                .map((t) => TagEntry(name: t.name, source: t.source))
                .toList(),
            updatedAt: i.updatedAt,
          ))
      .toList();
  return engine.compute(domainItems);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Score Distribution'),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: _ScoreDistributionChart(buckets: stats.scoreBuckets),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Top Genres'),
          ...stats.topGenres
              .take(5)
              .map((t) => _TagRow(tag: t, max: stats.topGenres.isNotEmpty ? stats.topGenres.first.count : 1)),
          const SizedBox(height: 24),
          _SectionTitle('Top Moods'),
          ...stats.topMoods
              .take(5)
              .map((t) => _TagRow(tag: t, max: stats.topMoods.isNotEmpty ? stats.topMoods.first.count : 1)),
          const SizedBox(height: 24),
          _SectionTitle('Activity'),
          SizedBox(
            height: 120,
            child: _ActivityChart(activity: stats.activityOverTime),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ScoreDistributionChart extends StatelessWidget {
  const _ScoreDistributionChart({required this.buckets});
  final List<ScoreBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxY = buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barGroups: buckets.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.count.toDouble(),
                color: Theme.of(context).colorScheme.primary,
                width: 16,
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag, required this.max});
  final TagCount tag;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : tag.count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(tag.name, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('${tag.count}'),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.activity});
  final List<ActivityPoint> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return const Center(child: Text('No activity yet.'));
    }
    final maxY = activity.fold<int>(0, (m, a) => a.comparisons > m ? a.comparisons : m).toDouble();
    return LineChart(
      LineChartData(
        maxY: maxY == 0 ? 1 : maxY,
        lineBarsData: [
          LineChartBarData(
            spots: activity.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.comparisons.toDouble());
            }).toList(),
            isCurved: true,
            color: Theme.of(context).colorScheme.secondary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
