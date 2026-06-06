import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../domain/score.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../catalog/catalog_service.dart';
import '../friends/friends_service.dart';
import '../../i18n.dart';
import '../../widgets/update_banner.dart';
import '../../widgets/initial_score_dialog.dart';
import '../catalog/search_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final recsAsync = ref.watch(genreRecommendationsProvider);
    final recentAsync = ref.watch(recentlyPlayedProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.valueOrNull;
    final lastfmEnabled = profile?.lastfmUsername != null && profile!.lastfmUsername!.trim().isNotEmpty;
    final friendsRecentAsync = ref.watch(friendsRecentRatingsProvider);
    final libraryAsync = ref.watch(libraryControllerProvider);
    final ratedItems = ref.watch(ratedItemsProvider);
    final ratedIds = ratedItems.map((e) => e.id).toSet();
    final ratedKeys = ratedItems
        .map((r) => catalogMatchKey(kind: r.kind, title: r.title, artist: r.primaryArtist))
        .toSet();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Athens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(genreRecommendationsProvider);
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(friendsRecentRatingsProvider);
                // Await each refresh only to hold the pull-to-refresh spinner
                // until they settle. Failures are swallowed here because each
                // provider's error is rendered by its own AsyncValue.when below.
                try {
                  await ref.read(genreRecommendationsProvider.future);
                } catch (_) {}
                try {
                  await ref.read(recentlyPlayedProvider.future);
                } catch (_) {}
                try {
                  await ref.read(friendsRecentRatingsProvider.future);
                } catch (_) {}
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm,
                    AppSpacing.xl, AppLayout.scrollBottomInset(context)),
                children: [
                  Text(context.t('home_title', ref: ref),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  // Don't decide onboarding vs. duel until the library has
                  // actually loaded — otherwise the "취향 찾기" card flashes on a
                  // cold (esp. offline) start before local data resolves.
                  if (!libraryAsync.hasValue)
                    const SizedBox.shrink()
                  else if (ratedItems.length < 3)
                    _OnboardingCard(currentCount: ratedItems.length)
                  else
                    const _DuelCallout(onTap: null), // Tap behavior is embedded inside _DuelCallout or can be passed
                  
                  // 1. Recommended tracks (추천곡)
                  recsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) {
                      if (data.items.isEmpty) return const SizedBox.shrink();
                      
                      final isDefault = ref.read(statsProvider).valueOrNull?.genrePreferences.isEmpty ?? true;
                      final title = isDefault 
                          ? '지금 가장 핫한 #${data.genre} 추천 트랙'
                          : '자주 듣는 #${data.genre} 취향 저격 곡';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          Row(
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(Icons.auto_awesome_rounded, color: p.accent, size: 16),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            children: data.items
                                .map((it) => _RecentCard(item: it))
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  Text(context.t('home_recent', ref: ref),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  recentAsync.when(
                    loading: () => _skeletonList(p),
                    error: (e, _) => _RecentEmpty(
                      message: context.t('home_recent_error', ref: ref),
                      lastfmEnabled: lastfmEnabled,
                    ),
                    data: (items) {
                      // Surface only tracks the user hasn't rated yet (match by ID or normalized title/artist/kind).
                      final unrated = items.where((it) {
                        final key = catalogMatchKey(
                            kind: it.kind, title: it.title, artist: it.primaryArtist);
                        return !ratedKeys.contains(key) && !ratedIds.contains(it.id);
                      }).toList();
                      return unrated.isEmpty
                          ? _RecentEmpty(lastfmEnabled: lastfmEnabled)
                          : Column(
                              children: unrated
                                  .take(10)
                                  .map((it) => _RecentCard(item: it))
                                  .toList(),
                            );
                    },
                  ),

                  // 2. Recommended Friend Ratings Section (친구 평가 음악)
                  friendsRecentAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (items) {
                      final unrated = items.where((it) {
                        final key = catalogMatchKey(
                            kind: it.kind, title: it.title, artist: it.primaryArtist);
                        return !ratedKeys.contains(key) && !ratedIds.contains(it.id);
                      }).toList();
                      if (unrated.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),
                          const Text('친구들이 평가한 음악', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: AppSpacing.md),
                          Column(
                            children: unrated
                                .take(5)
                                .map((it) => _RecentCard(item: it))
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _skeletonList(AppPalette p) => Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            height: 72,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: p.line),
            ),
          ),
        ),
      );
}

class _DuelCallout extends ConsumerWidget {
  const _DuelCallout({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap ?? () => context.push('/duel'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Row(
          children: [
            Icon(Icons.compare_arrows_rounded, color: p.accentText, size: 28),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('home_start_duel', ref: ref),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.accentText)),
                  const SizedBox(height: 2),
                  Text(context.t('home_start_duel_sub', ref: ref),
                      style: TextStyle(color: p.accentText, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: p.accentText, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentCard extends ConsumerStatefulWidget {
  const _RecentCard({required this.item});
  final CatalogItem item;

  @override
  ConsumerState<_RecentCard> createState() => _RecentCardState();
}

class _RecentCardState extends ConsumerState<_RecentCard> {
  bool _busy = false;

  Future<void> _rate() async {
    if (_busy) return;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final score = await showDialog<double>(
      context: context,
      builder: (c) => InitialScoreDialog(
        title: widget.item.kind == 'track'
            ? '이 곡은 어땠나요?'
            : widget.item.kind == 'album'
                ? '이 앨범은 어땠나요?'
                : '이 아티스트는 어땠나요?',
        itemTitle: widget.item.title,
        itemArtist: widget.item.kind == 'artist' ? null : widget.item.primaryArtist,
        imageUrl: widget.item.imageUrl,
        initialValue: 5.0,
        itemKind: widget.item.kind,
      ),
    );
    if (score == null) return;
    final startingElo = eloFromScore(score);

    if (!mounted) return;
    setState(() => _busy = true);
    // Mirror the search-screen add flow: enrich tags, then run *placement*
    // (duel against existing same-kind items) instead of a plain free duel.
    final item = widget.item;
    final service = ref.read(catalogServiceProvider);
    final controller = ref.read(libraryControllerProvider.notifier);
    final hasOpponents = ref
        .read(ratedItemsProvider)
        .any((i) => i.kind == item.kind && i.id != item.id);

    var enriched = item;
    try {
      enriched = item.copyWithTags(await service.enrichTags(item));
    } catch (_) {
      // Enrichment is best-effort; add without tags on failure.
    }
    await controller.addItem(enriched, startingElo: startingElo);
    // Do NOT invalidate recentlyPlayedProvider here — re-fetching drops the whole
    // list back into its loading/skeleton state (a spurious spinner the user sees
    // without acting, made worse by slow Last.fm calls). The just-rated track is
    // removed reactively by the ratedKeys/ratedIds filter once the library
    // updates, so the row disappears without a network round-trip.

    if (!mounted) return;
    if (hasOpponents) {
      router.push('/duel/${Uri.encodeComponent(enriched.id)}');
    } else {
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text('"${enriched.title}" 추가됨 — 같은 종류를 더 추가하면 순위를 매겨요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = widget.item;
    return InkWell(
      onTap: () {
        context.push('/home/item/${Uri.encodeComponent(item.id)}', extra: item);
      },
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            CoverArt(title: item.title, imageUrl: item.imageUrl, size: 48),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(item.primaryArtist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: _busy ? null : _rate,
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(context.t('home_rate', ref: ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentEmpty extends ConsumerWidget {
  const _RecentEmpty({this.message, this.lastfmEnabled = false});
  final String? message;
  final bool lastfmEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Icon(
            lastfmEnabled ? Icons.check_circle_outline_rounded : Icons.headphones_rounded,
            size: 40,
            color: lastfmEnabled ? p.accent : p.faint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            lastfmEnabled
                ? '최근 들은 음악을 모두 평가했습니다! 🎉\n음악을 들으면 여기에 나타납니다.'
                : (message ?? 'Last.fm을 연동하면 최근 들은 곡이 여기에 나타나요.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, height: 1.4),
          ),
          if (!lastfmEnabled) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => context.go('/profile/edit'),
              child: const Text('Last.fm 연동하기'),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.currentCount});
  final int currentCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = (currentCount / 3).clamp(0.0, 1.0);
    
    String statusText = '';
    if (currentCount == 0) {
      statusText = '좋아하는 첫 번째 노래를 검색하고 별점을 주세요. 🎧';
    } else if (currentCount == 1) {
      statusText = '좋은 시작입니다! 2곡만 더 담으면 첫 번째 듀얼을 붙일 수 있어요.';
    } else if (currentCount == 2) {
      statusText = '이제 딱 한 곡 남았어요! 한 곡만 더 추가하고 듀얼 매치를 완성해 보세요.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.stars_rounded, color: p.accent, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '내 취향 랭킹 시작하기 ($currentCount/3)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '곡 보관함이 완성되면 1:1 월드컵 듀얼을 시작하고, 내 음악 취향에 대한 상세한 분석 리포트를 얻을 수 있어요.',
            style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: p.line,
              color: p.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.accentText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          ElevatedButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('노래 찾으러 가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.accentSoft,
              foregroundColor: p.accentText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
