import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/stats_engine.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';

import '../../i18n.dart';

import '../catalog/catalog_service.dart';

part 'widgets/stats_charts.dart';

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
                                      child: CachedNetworkImage(
                                        imageUrl: data.imageUrl!,
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

