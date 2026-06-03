import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/stats_engine.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';

import '../../i18n.dart';

import '../../widgets/premium_lock_overlay.dart';
import '../catalog/catalog_service.dart';
import '../profile/profile_service.dart';

final statsProvider = FutureProvider<LibraryStats>((ref) async {
  final items = ref.watch(ratedItemsProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  final dates = await repo.getComparisonDates();

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
  return engine.compute(domainItems, dates);
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final statsAsync = ref.watch(statsProvider);
    final isKo = ref.watch(localeProvider) == AppLanguage.ko;
    final profileAsync = ref.watch(myProfileProvider);
    final isPremium = profileAsync.valueOrNull?.isPremium ?? false;

    return statsAsync.when(
      data: (stats) {
        final total =
            stats.totalByKind.values.fold<int>(0, (a, b) => a + b);

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
        final mostComparedItem = ratedItems.isNotEmpty 
            ? ratedItems.reduce((a, b) => a.comparisons > b.comparisons ? a : b) 
            : null;

        final topItemsWithMetadata = stats.topItems.map((item) {
          final catalogItem = ratedItems.firstWhere(
            (i) => i.id == item.id, 
            orElse: () => RatedCatalogItem(
              id: item.id,
              kind: item.kind.name,
              title: 'Unknown',
              elo: item.elo,
              comparisons: item.comparisons,
              tags: const [],
              updatedAt: item.updatedAt,
            ),
          );
          return (
            item: item,
            title: catalogItem.title,
            artist: catalogItem.primaryArtist,
            imageUrl: catalogItem.imageUrl,
          );
        }).toList();

        return Scaffold(
          appBar: AppBar(title: Text(context.t('stats_title', ref: ref))),
          body: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm,
                AppSpacing.xl, AppLayout.scrollBottomInset(context)),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  // Actual charts content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Insights Report Grid
                      _SectionTitle(isKo ? '💡 나의 음악 취향 분석 리포트' : '💡 Music Taste Insights'),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _InsightCard(
                              title: isKo ? '평균 점수' : 'Average Score',
                              value: '${stats.averageScore.toStringAsFixed(1)}점',
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              description: isKo ? '내 라이브러리 전체 평균' : 'Your library average',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _InsightCard(
                              title: isKo ? '최다 듀얼 곡' : 'Most Dueling Item',
                              value: mostComparedItem != null ? mostComparedItem.title : '-',
                              icon: Icons.local_fire_department_rounded,
                              iconColor: Colors.orange,
                              description: mostComparedItem != null ? '${mostComparedItem.comparisons}회 격돌' : '-',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _InsightCard(
                              title: isKo ? '원픽 장르' : 'Favorite Genre',
                              value: stats.genrePreferences.isNotEmpty ? stats.genrePreferences.first.name : '-',
                              icon: Icons.music_note_rounded,
                              iconColor: Colors.purple,
                              description: stats.genrePreferences.isNotEmpty 
                                  ? '평균 ${stats.genrePreferences.first.averageScore.toStringAsFixed(1)}점' 
                                  : '-',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _InsightCard(
                              title: isKo ? '선호 분위기' : 'Favorite Mood',
                              value: stats.moodPreferences.isNotEmpty ? stats.moodPreferences.first.name : '-',
                              icon: Icons.wb_sunny_rounded,
                              iconColor: Colors.teal,
                              description: stats.moodPreferences.isNotEmpty 
                                  ? '평균 ${stats.moodPreferences.first.averageScore.toStringAsFixed(1)}점' 
                                  : '-',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 2. Score Distribution Chart
                      _SectionTitle(context.t('stats_distribution', ref: ref)),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 180,
                        child: _ScoreDistributionChart(buckets: stats.scoreBuckets),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // 3. Top Favorites List
                      if (topItemsWithMetadata.isNotEmpty) ...[
                        _SectionTitle(isKo ? '🏆 나의 원픽 음악 Top 5' : '🏆 My Top 5 Favorites'),
                        const SizedBox(height: AppSpacing.md),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topItemsWithMetadata.take(5).length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final data = topItemsWithMetadata[index];
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: p.surface2,
                                borderRadius: BorderRadius.circular(AppRadii.card),
                                border: Border.all(color: p.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: index == 0 ? p.accent : p.line,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: index == 0 ? p.bg : p.text,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  if (data.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadii.cover),
                                      child: Image.network(
                                        data.imageUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: p.line,
                                        borderRadius: BorderRadius.circular(AppRadii.cover),
                                      ),
                                      child: Icon(Icons.music_note_rounded, color: p.faint),
                                    ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (data.artist != null)
                                          Text(
                                            data.artist!,
                                            style: TextStyle(color: p.muted, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${data.item.score.toStringAsFixed(1)}점',
                                        style: TextStyle(
                                          color: p.accentText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${data.item.comparisons}회 대결',
                                        style: TextStyle(color: p.muted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      // 4. Genres & Moods
                      if (stats.topGenres.isNotEmpty) ...[
                        _SectionTitle(context.t('stats_genres', ref: ref)),
                        const SizedBox(height: AppSpacing.sm),
                        ...stats.topGenres.take(5).map((t) =>
                            _TagBar(tag: t, max: stats.topGenres.first.count, isKo: isKo)),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _SectionTitle(context.t('stats_genre_preference', ref: ref)),
                      const SizedBox(height: AppSpacing.sm),
                      if (stats.genrePreferences.isNotEmpty)
                        ...stats.genrePreferences.take(5).map((p) =>
                            _PreferenceBar(pref: p, isKo: isKo))
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            context.t('stats_preference_not_enough', ref: ref),
                            style: TextStyle(color: p.muted, fontSize: 14),
                          ),
                        ),
                      if (stats.topMoods.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _SectionTitle(context.t('stats_moods', ref: ref)),
                        const SizedBox(height: AppSpacing.sm),
                        ...stats.topMoods.take(5).map((t) =>
                            _TagBar(tag: t, max: stats.topMoods.first.count, isKo: isKo)),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _SectionTitle(context.t('stats_mood_preference', ref: ref)),
                      const SizedBox(height: AppSpacing.sm),
                      if (stats.moodPreferences.isNotEmpty)
                        ...stats.moodPreferences.take(5).map((p) =>
                            _PreferenceBar(pref: p, isKo: isKo))
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            context.t('stats_preference_not_enough', ref: ref),
                            style: TextStyle(color: p.muted, fontSize: 14),
                          ),
                        ),
                      if (stats.activityOverTime.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _SectionTitle(context.t('stats_activity', ref: ref)),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                            height: 150,
                            child: _ActivityChart(activity: stats.activityOverTime)),
                      ],
                    ],
                  ),
                  if (!isPremium)
                    const Positioned.fill(
                      child: PremiumLockOverlay(
                        featureName: '상세 취향 통계 분석',
                        featureDescription: '장르/무드 선호도 차트 및 활동 로그 등 깊이 있는 취향 분석 보고서를 잠금 해제하세요.',
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text(context.t('stats_title', ref: ref))),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: Text(context.t('stats_title', ref: ref))),
        body: Center(
          child: Text('Error: $err'),
        ),
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.description,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 110,
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(color: p.muted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucket = buckets[groupIndex];
              return BarTooltipItem(
                '${bucket.label}점\n',
                TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${bucket.count}곡',
                    style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3 > 0 ? (maxY / 3).roundToDouble() : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        barGroups: buckets.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
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
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= buckets.length) return const SizedBox.shrink();
                if (idx % 2 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[idx].label,
                    style: TextStyle(fontSize: 10, color: p.muted, fontWeight: FontWeight.w500),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox.shrink();
                if (v % 1 != 0) return const SizedBox.shrink();
                return Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: p.muted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: p.line),
          ),
        ),
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
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => p.surface2,
            tooltipBorder: BorderSide(color: p.line),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = activity[spot.x.toInt()].date;
                return LineTooltipItem(
                  '${date.month}월 ${date.day}일\n',
                  TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${spot.y.toInt()}회 비교',
                      style: TextStyle(color: p.accentText, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3 > 0 ? (maxY / 3).roundToDouble() : 1.0,
          getDrawingHorizontalLine: (value) => FlLine(
            color: p.line.withValues(alpha: 0.5),
            strokeWidth: 0.8,
            dashArray: [4, 4],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: activity.length == 1
                ? [
                    const FlSpot(0, 0),
                    FlSpot(1, activity[0].comparisons.toDouble()),
                  ]
                : activity
                    .asMap()
                    .entries
                    .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.comparisons.toDouble()))
                    .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [p.accent, p.accent.withValues(alpha: 0.7)],
            ),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: p.accent,
                strokeWidth: 1.5,
                strokeColor: p.bg,
              ),
            ),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [p.accent.withValues(alpha: 0.2), p.accent.withValues(alpha: 0.0)],
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
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= activity.length) return const SizedBox.shrink();
                if (activity.length > 5 && idx % (activity.length ~/ 3) != 0 && idx != activity.length - 1) {
                  return const SizedBox.shrink();
                }
                final date = activity[idx].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 9, color: p.muted),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) {
                if (v == 0) return const SizedBox.shrink();
                if (v % 1 != 0) return const SizedBox.shrink();
                return Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 9, color: p.muted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: p.line),
          ),
        ),
      ),
    );
  }
}
