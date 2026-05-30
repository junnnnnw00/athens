import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/stats_engine.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';

import '../../i18n.dart';

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
    final p = context.palette;
    final stats = ref.watch(statsProvider);
    final total =
        stats.totalByKind.values.fold<int>(0, (a, b) => a + b);
    final isKo = ref.watch(localeProvider) == AppLanguage.ko;

    if (total == 0) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('stats_title', ref: ref))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded, size: 56, color: p.faint),
                const SizedBox(height: AppSpacing.lg),
                Text(context.t('stats_empty_title', ref: ref),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(context.t('stats_empty_desc', ref: ref),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted)),
              ],
            ),
          ),
        ),
      );
    }

    final ratedItems = ref.watch(ratedItemsProvider);
    final totalComparisons = ratedItems.fold<int>(0, (sum, i) => sum + i.comparisons);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('stats_title', ref: ref))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
        children: [
          Row(
            children: [
              _BigStat(value: '$total${isKo ? '개' : ''}', label: context.t('stats_rated_items', ref: ref)),
              const SizedBox(width: AppSpacing.xxl),
              _BigStat(
                  value: '$totalComparisons${isKo ? '개' : ''}',
                  label: context.t('stats_comparisons', ref: ref),
                  accent: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTitle(context.t('stats_distribution', ref: ref)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 170,
            child: _ScoreDistributionChart(buckets: stats.scoreBuckets),
          ),
          if (stats.topGenres.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(context.t('stats_genres', ref: ref)),
            const SizedBox(height: AppSpacing.sm),
            ...stats.topGenres.take(5).map((t) =>
                _TagBar(tag: t, max: stats.topGenres.first.count, isKo: isKo)),
          ],
          if (stats.genrePreferences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(context.t('stats_genre_preference', ref: ref)),
            const SizedBox(height: AppSpacing.sm),
            ...stats.genrePreferences.take(5).map((p) =>
                _PreferenceBar(pref: p, isKo: isKo)),
          ],
          if (stats.topMoods.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(context.t('stats_moods', ref: ref)),
            const SizedBox(height: AppSpacing.sm),
            ...stats.topMoods.take(5).map((t) =>
                _TagBar(tag: t, max: stats.topMoods.first.count, isKo: isKo)),
          ],
          if (stats.moodPreferences.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(context.t('stats_mood_preference', ref: ref)),
            const SizedBox(height: AppSpacing.sm),
            ...stats.moodPreferences.take(5).map((p) =>
                _PreferenceBar(pref: p, isKo: isKo)),
          ],
          if (stats.activityOverTime.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _SectionTitle(context.t('stats_activity', ref: ref)),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
                height: 120,
                child: _ActivityChart(activity: stats.activityOverTime)),
          ],
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat(
      {required this.value, required this.label, this.accent = false});
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(color: accent ? p.accentText : p.text)),
        Text(label, style: TextStyle(color: p.muted, fontSize: 13)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);
}

class _ScoreDistributionChart extends StatelessWidget {
  const _ScoreDistributionChart({required this.buckets});
  final List<ScoreBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxY =
        buckets.fold<int>(0, (m, b) => b.count > m ? b.count : m).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 1 : maxY,
        barGroups: buckets.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
              toY: e.value.count.toDouble(),
              color: p.accent,
              width: 14,
              borderRadius: BorderRadius.circular(3),
            ),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: TextStyle(fontSize: 10, color: p.faint)),
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

class _TagBar extends StatelessWidget {
  const _TagBar({required this.tag, required this.max, required this.isKo});
  final TagCount tag;
  final int max;
  final bool isKo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = max == 0 ? 0.0 : tag.count / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(tag.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: p.line,
                color: p.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${tag.count}${isKo ? '개' : ''}', style: TextStyle(color: p.muted)),
        ],
      ),
    );
  }
}

class _PreferenceBar extends StatelessWidget {
  const _PreferenceBar({required this.pref, required this.isKo});
  final TagPreference pref;
  final bool isKo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scoreString = pref.averageScore.toStringAsFixed(1);
    final countSuffix = isKo ? '${pref.count}개' : '${pref.count} items';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(pref.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pref.averageScore / 10.0,
                minHeight: 8,
                backgroundColor: p.line,
                color: p.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(isKo ? '$scoreString점 ($countSuffix)' : '$scoreString ($countSuffix)',
              style: TextStyle(color: p.muted, fontSize: 12)),
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
    final p = context.palette;
    final maxY = activity
        .fold<int>(0, (m, a) => a.comparisons > m ? a.comparisons : m)
        .toDouble();
    return LineChart(
      LineChartData(
        maxY: maxY == 0 ? 1 : maxY,
        lineBarsData: [
          LineChartBarData(
            spots: activity
                .asMap()
                .entries
                .map((e) =>
                    FlSpot(e.key.toDouble(), e.value.comparisons.toDouble()))
                .toList(),
            isCurved: true,
            color: p.accent,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: p.accent.withValues(alpha: 0.12)),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }
}
