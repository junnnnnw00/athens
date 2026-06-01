import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../profile/profile_service.dart';
import '../../data/repository/library_providers.dart';
import '../catalog/catalog_service.dart';
import 'friends_service.dart';

class FriendComparisonScreen extends ConsumerStatefulWidget {
  const FriendComparisonScreen({super.key, required this.friendId});
  final String friendId;

  @override
  ConsumerState<FriendComparisonScreen> createState() => _FriendComparisonScreenState();
}

class _FriendComparisonScreenState extends ConsumerState<FriendComparisonScreen> {
  UserProfile? _friendProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    try {
      final row = await client
          .from('profiles')
          .select('id, handle, display_name, bio, avatar_url, is_public, spotify_enabled, is_premium')
          .eq('id', widget.friendId)
          .single();
      setState(() {
        _friendProfile = UserProfile.fromMap(row);
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {

        _isLoadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final myProfileAsync = ref.watch(myProfileProvider);
    final isPremium = myProfileAsync.valueOrNull?.isPremium ?? false;
    final myRatings = ref.watch(ratedItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_friendProfile != null
            ? '${_friendProfile!.displayName ?? _friendProfile!.handle}님과 비교'
            : '취향 일치율 비교'),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _friendProfile == null
              ? Center(child: Text('프로필을 찾을 수 없습니다.', style: TextStyle(color: p.text)))
              : !isPremium
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: PremiumLockOverlay(
                        featureName: '${_friendProfile!.displayName ?? _friendProfile!.handle}님과의 취향 비교',
                        featureDescription: '두 사람의 겹치는 최애 음악 취향 분석과 다른 점을 심층 분석 보고서로 잠금 해제하세요.',
                      ),
                    )
                  : _buildComparisonContent(myRatings),
    );
  }

  Widget _buildComparisonContent(List<RatedCatalogItem> myRatings) {
    final p = context.palette;

    return FutureBuilder<FriendMatchResult>(
      future: ref.read(friendsServiceProvider).calculateMatch(widget.friendId, myRatings),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              '취향 분석 매칭 중 에러가 발생했습니다: ${snapshot.error}',
              style: TextStyle(color: p.text),
            ),
          );
        }

        final match = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 110),
          children: [
            // Match Dial
            Center(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.accent, width: 4),
                      color: p.surface2,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${match.matchPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: p.accentText,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '뮤직 취향 매칭률',
                    style: TextStyle(color: p.muted, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '총 ${match.commonCount}개의 곡을 공동 평가함',
                    style: TextStyle(color: p.faint, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Shared Genres
            if (match.sharedGenres.isNotEmpty) ...[
              _buildSectionTitle('공통 선호 장르'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.sharedGenres
                    .map((g) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: p.chip,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: p.line),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(color: p.text, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],

            // Shared Favorites
            _buildSectionTitle('서로 공통된 취향 (최애 음악)'),
            const SizedBox(height: AppSpacing.sm),
            if (match.sharedFavorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('서로가 동시에 7점 이상 매긴 음악이 아직 없어요.', style: TextStyle(color: p.muted, fontSize: 13)),
              )
            else
              ...match.sharedFavorites.take(5).map((item) => _buildComparisonRow(item)),

            const SizedBox(height: AppSpacing.xxl),

            // Taste Differences
            _buildSectionTitle('가장 다른 취향 (취향 차이)'),
            const SizedBox(height: AppSpacing.sm),
            if (match.tasteDifferences.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('서로 평가 점수 차이가 큰 음악이 아직 없어요.', style: TextStyle(color: p.muted, fontSize: 13)),
              )
            else
              ...match.tasteDifferences.take(5).map((item) => _buildComparisonRow(item)),
          ],
        );
      },
    );
  }

  Widget _buildComparisonRow(MatchItemInfo item) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
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
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.artist ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // My score vs Their score
            Column(
              children: [
                Row(
                  children: [
                    const Text('나: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(item.myScore.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: p.text)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('친구: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(item.theirScore.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: p.accentText)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
