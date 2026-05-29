import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/library_providers.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../catalog/catalog_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final recentAsync = ref.watch(recentlyPlayedProvider);
    final ratedIds = ref.watch(ratedItemsProvider).map((e) => e.id).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
        children: [
          Text('오늘은 무엇을 평가할까요?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          _DuelCallout(onTap: () => context.go('/duel')),
          const SizedBox(height: AppSpacing.xxl),
          Text('최근 들은 음악',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          recentAsync.when(
            loading: () => _skeletonList(p),
            error: (e, _) => _RecentEmpty(message: '최근 재생 목록을 불러오지 못했어요'),
            data: (items) {
              // Surface only tracks the user hasn't rated yet.
              final unrated =
                  items.where((it) => !ratedIds.contains(it.id)).toList();
              return unrated.isEmpty
                  ? const _RecentEmpty()
                  : Column(
                      children: unrated
                          .take(10)
                          .map((it) => _RecentCard(item: it))
                          .toList(),
                    );
            },
          ),
        ],
      ),
    );
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

class _DuelCallout extends StatelessWidget {
  const _DuelCallout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
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
                  Text('듀얼 시작하기',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: p.accentText)),
                  const SizedBox(height: 2),
                  Text('둘 중 더 좋은 걸 고르면 순위가 매겨져요',
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

class _RecentCard extends ConsumerWidget {
  const _RecentCard({required this.item});
  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
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
            onPressed: () async {
              await ref
                  .read(libraryControllerProvider.notifier)
                  .addItem(item);
              if (context.mounted) context.go('/duel');
            },
            child: const Text('평가'),
          ),
        ],
      ),
    );
  }
}

class _RecentEmpty extends StatelessWidget {
  const _RecentEmpty({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
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
          Icon(Icons.headphones_rounded, size: 40, color: p.faint),
          const SizedBox(height: AppSpacing.md),
          Text(message ?? 'Spotify를 연결하면 최근 들은 곡이 여기에 나와요',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted)),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.go('/spotify-connect'),
            child: const Text('Spotify 연결'),
          ),
        ],
      ),
    );
  }
}
