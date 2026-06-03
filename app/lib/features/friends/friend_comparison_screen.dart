import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_art.dart';
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

class _FriendComparisonScreenState extends ConsumerState<FriendComparisonScreen>
    with SingleTickerProviderStateMixin {
  UserProfile? _friendProfile;
  bool _isLoadingProfile = true;
  // -1 = 전체, 0~4 = specific category
  int _selectedTrackCategory = -1;

  late final TabController _tabController;
  // Cached future — recreated only when friendId changes
  Future<FriendMatchResult>? _matchFuture;
  List<RatedCatalogItem>? _lastRatings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns cached Future, only recalculates when ratings list reference changes.
  Future<FriendMatchResult> _getMatchFuture(List<RatedCatalogItem> myRatings) {
    if (_matchFuture == null || !identical(_lastRatings, myRatings)) {
      _lastRatings = myRatings;
      _matchFuture = ref.read(friendsServiceProvider)
          .calculateMatch(widget.friendId, myRatings);
    }
    return _matchFuture!;
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    try {
      final row = await client
          .from('profiles')
          .select('id, handle, display_name, bio, avatar_url, is_public,  is_premium')
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
              : _buildComparisonContent(myRatings, myProfileAsync.valueOrNull, isPremium),
    );
  }

  Widget _buildComparisonContent(
    List<RatedCatalogItem> myRatings,
    UserProfile? myProfile,
    bool isPremium,
  ) {
    final p = context.palette;

    return FutureBuilder<FriendMatchResult>(
      future: _getMatchFuture(myRatings),
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

        return Column(
          children: [
            // Hero Section: VS profiles & match dial
            _buildComparisonHero(match, myProfile),

            // TabBar backed by stored controller (survives setState)
            TabBar(
              controller: _tabController,
              labelColor: p.accentText,
              unselectedLabelColor: p.muted,
              indicatorColor: p.accent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: '종합 분석'),
                Tab(text: '대조 (곡)'),
                Tab(text: '대조 (장르)'),
              ],
            ),

            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(match, myProfile, isPremium),
                  _buildTracksTab(match, isPremium),
                  _buildTagsTab(match, isPremium),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonHero(FriendMatchResult match, UserProfile? myProfile) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Me profile info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myProfile?.displayName ?? myProfile?.handle ?? '나',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${myProfile?.handle ?? 'me'}',
                  style: TextStyle(color: p.muted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Match rate in the middle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: p.accentText),
                const SizedBox(width: 4),
                Text(
                  '${match.matchPercentage.toStringAsFixed(0)}% 일치',
                  style: TextStyle(
                    color: p.accentText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Friend profile info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _friendProfile?.displayName ?? _friendProfile?.handle ?? '친구',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
                Text(
                  '@${_friendProfile?.handle ?? 'friend'}',
                  style: TextStyle(color: p.muted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(FriendMatchResult match, UserProfile? myProfile, bool isPremium) {
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md,
          AppLayout.scrollBottomInset(context)),
      children: [
        // ── 1. Basic stats (Free) ───────────────────────────────────────────
        _buildBasicStatsSection(match, myProfile, isPremium),

        const SizedBox(height: AppSpacing.xl),

        // ── 2. Personality Cards (Free: labels only, Premium: full desc) ────
        _buildSectionTitle('음악 취향 성향'),
        const SizedBox(height: AppSpacing.sm),
        _buildPersonalityCards(match, isPremium),

        const SizedBox(height: AppSpacing.xl),

        if (isPremium) ...[
          // ── 3. Score Distribution (Premium) ──────────────────────────────
          _buildSectionTitle('점수 분포 비교'),
          const SizedBox(height: 4),
          Text(
            '각자 어떤 점수대를 얼마나 주는지 한눈에 비교',
            style: TextStyle(color: p.muted, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildScoreDistributionChart(match),

          const SizedBox(height: AppSpacing.xl),

          // ── 4. Agreement Stats (Premium) ─────────────────────────────────
          _buildSectionTitle('공동 평가 분석'),
          const SizedBox(height: AppSpacing.sm),
          _buildAgreementSection(match),

          const SizedBox(height: AppSpacing.xl),

          // ── 5. Artist Overlap (Premium) ───────────────────────────────────
          if (match.myTopArtists.isNotEmpty || match.theirTopArtists.isNotEmpty) ...[
            _buildSectionTitle('선호 아티스트'),
            const SizedBox(height: AppSpacing.sm),
            _buildArtistOverlapSection(match),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ── 6. Controversial Songs (Premium) ─────────────────────────────
          if (match.controversialSongs.isNotEmpty) ...[
            _buildSectionTitle('의견 갈린 곡 Top ${match.controversialSongs.length}'),
            const SizedBox(height: 4),
            Text(
              '두 사람이 같은 곡에 가장 다른 점수를 준 경우',
              style: TextStyle(color: p.muted, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.md),
            ...match.controversialSongs.map((item) => _buildUnifiedComparisonRow(item)),
          ],
        ] else ...[
          // ── Premium teaser ──────────────────────────────────────────────
          _buildPremiumTeaser(),
        ],
      ],
    );
  }

  Widget _buildBasicStatsSection(FriendMatchResult match, UserProfile? myProfile, bool isPremium) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: p.accentText, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text('기본 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.accentText)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow(Icons.library_music_rounded, '평가한 음악 수',
              '${match.myTotalCount}곡', '${match.theirTotalCount}곡'),
          const SizedBox(height: 8),
          _buildStatRow(Icons.star_rounded, '평균 평점',
              '${match.myAverageScore.toStringAsFixed(1)}점', '${match.theirAverageScore.toStringAsFixed(1)}점'),
          const SizedBox(height: 8),
          _buildStatRow(Icons.music_note_rounded, '공동 평가한 곡',
              '', '${match.commonCount}곡', centerVal: true),
          if (isPremium) ...[
            const SizedBox(height: 8),
            _buildStatRow(Icons.people_rounded, '공통 아티스트',
                '', '${match.sharedArtistCount}명', centerVal: true),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
            decoration: BoxDecoration(
              color: match.commonCount > 0 ? p.accentSoft.withValues(alpha: 0.12) : p.chip,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  match.commonCount > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 13,
                  color: match.commonCount > 0 ? p.accentText : p.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.commonCount > 0
                        ? '같은 곡에 매긴 점수를 기반으로 분석되었습니다.'
                        : '공통 평가 곡이 없어 장르/분위기 위주로 분석되었습니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: match.commonCount > 0 ? p.accentText : p.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String myVal, String theirVal, {bool centerVal = false}) {
    final p = context.palette;
    return Row(
      children: [
        Icon(icon, size: 13, color: p.muted),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: p.muted, fontSize: 11)),
        const Spacer(),
        if (centerVal)
          Text(theirVal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.text))
        else ...[
          Text(myVal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.text)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('·', style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          Text(theirVal, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.text)),
        ],
      ],
    );
  }

  Widget _buildPersonalityCards(FriendMatchResult match, bool isPremium) {
    final p = context.palette;
    final myP = match.myPersonality;
    final theirP = match.theirPersonality;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildPersonalityCard(
              label: tastePersonalityLabel(myP),
              description: isPremium ? tastePersonalityDescription(myP) : null,
              isMe: true,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildPersonalityCard(
              label: tastePersonalityLabel(theirP),
              description: isPremium ? tastePersonalityDescription(theirP) : null,
              isMe: false,
            )),
          ],
        ),
        if (myP != TastePersonality.noData && theirP != TastePersonality.noData) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: p.accentSoft.withValues(alpha: isPremium ? 0.1 : 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.accent.withValues(alpha: isPremium ? 0.2 : 0.1)),
            ),
            child: Row(
              children: [
                Text('🔗', style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: isPremium
                      ? Text(
                          personalityCompatibility(myP, theirP),
                          style: TextStyle(color: p.text, fontSize: 11, height: 1.4),
                        )
                      : Text(
                          '성향 궁합 분석은 Premium에서 확인하세요.',
                          style: TextStyle(color: p.muted, fontSize: 11),
                        ),
                ),
                if (!isPremium)
                  Icon(Icons.lock_rounded, size: 13, color: p.muted),
              ],
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildPersonalityCard({
    required String label,
    String? description,
    required bool isMe,
  }) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMe ? '나' : '친구',
            style: TextStyle(color: p.muted, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: p.text),
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(color: p.muted, fontSize: 10.5, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreDistributionChart(FriendMatchResult match) {
    final p = context.palette;
    final buckets = ['1-2', '3-4', '5-6', '7-8', '9-10'];
    final myDist = match.myScoreDistribution;
    final theirDist = match.theirScoreDistribution;

    final myMax = myDist.values.fold(0, (a, b) => a > b ? a : b);
    final theirMax = theirDist.values.fold(0, (a, b) => a > b ? a : b);
    final overallMax = (myMax > theirMax ? myMax : theirMax).toDouble();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            children: [
              _legendDot(p.accentText, '나'),
              const SizedBox(width: AppSpacing.md),
              _legendDot(p.muted, '친구'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Bars
          ...buckets.map((bucket) {
            final myCount = myDist[bucket] ?? 0;
            final theirCount = theirDist[bucket] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(bucket, style: TextStyle(color: p.muted, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      children: [
                        _barRow(myCount, overallMax, p.accentText, p),
                        const SizedBox(height: 2),
                        _barRow(theirCount, overallMax, p.muted, p),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$myCount / $theirCount',
                      style: TextStyle(color: p.faint, fontSize: 9),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
          // Std dev note
          if (match.myScoreStdDev > 0 || match.theirScoreStdDev > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _stdDevChip('나', match.myScoreStdDev, p)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _stdDevChip('친구', match.theirScoreStdDev, p)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: p.muted, fontSize: 10)),
      ],
    );
  }

  Widget _barRow(int count, double max, Color color, AppPalette p) {
    final fraction = max == 0 ? 0.0 : (count / max).clamp(0.0, 1.0);
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: [
          Container(
            height: 8,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: p.chip,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          if (fraction > 0)
            Container(
              height: 8,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );
    });
  }

  Widget _stdDevChip(String label, double stdDev, AppPalette p) {
    String interpretation;
    if (stdDev < 1.2) {
      interpretation = '고른 평가';
    } else if (stdDev < 2.2) {
      interpretation = '적당한 호불호';
    } else {
      interpretation = '강한 호불호';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: p.muted, fontSize: 9, fontWeight: FontWeight.bold)),
                Text(interpretation, style: TextStyle(color: p.text, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(
            '±${stdDev.toStringAsFixed(1)}',
            style: TextStyle(color: p.faint, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementSection(FriendMatchResult match) {
    final p = context.palette;
    if (match.commonCount == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: p.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.line)),
        child: Text('공동 평가 곡이 없어 분석이 불가합니다.', style: TextStyle(color: p.muted, fontSize: 12)),
      );
    }

    final agreePct = match.agreementRate;
    final disagreeCount = match.controversialSongs.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAgreementStat('의견 일치율', '${agreePct.toStringAsFixed(0)}%',
                  agreePct >= 70 ? '높음' : agreePct >= 40 ? '보통' : '낮음', p)),
              Container(width: 1, height: 40, color: p.line),
              Expanded(child: _buildAgreementStat('공통 평가', '${match.commonCount}곡', '함께 들은 곡', p)),
              Container(width: 1, height: 40, color: p.line),
              Expanded(child: _buildAgreementStat('의견 충돌', '$disagreeCount곡', '3점 이상 차이', p)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Agreement bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: agreePct / 100,
              minHeight: 6,
              backgroundColor: p.chip,
              valueColor: AlwaysStoppedAnimation<Color>(
                agreePct >= 70 ? p.accentText : agreePct >= 40 ? const Color(0xFFE3B341) : const Color(0xFFE5604D),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            agreePct >= 70
                ? '같은 곡에 비슷한 점수를 주는 편입니다.'
                : agreePct >= 40
                    ? '절반 정도의 곡에서 비슷한 감상을 나눕니다.'
                    : '같은 곡에도 꽤 다른 평가를 내리는 편입니다.',
            style: TextStyle(color: p.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementStat(String label, String value, String sub, AppPalette p) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: p.text)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: p.muted, fontSize: 10)),
        Text(sub, style: TextStyle(color: p.faint, fontSize: 9)),
      ],
    );
  }

  Widget _buildArtistOverlapSection(FriendMatchResult match) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_rounded, size: 14, color: p.accentText),
              const SizedBox(width: 6),
              Text(
                '공통 아티스트 ${match.sharedArtistCount}명',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.accentText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildArtistColumn('나의 TOP 아티스트', match.myTopArtists)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildArtistColumn('친구의 TOP 아티스트', match.theirTopArtists)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtistColumn(String title, List<String> artists) {
    final p = context.palette;
    if (artists.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: p.muted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('데이터 없음', style: TextStyle(color: p.faint, fontSize: 11)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: p.muted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...artists.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text('${e.key + 1}. ', style: TextStyle(color: p.faint, fontSize: 10)),
              Expanded(
                child: Text(
                  e.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPremiumTeaser() {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.surface2, p.accentSoft.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 28, color: p.accentText),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Premium 심층 분석',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '점수 분포 차트 · 의견 일치율 · 선호 아티스트 비교\n취향 충돌 곡 분석 · 성향 상세 설명',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => context.push('/premium-upgrade'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Premium으로 업그레이드',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ── Track classification helpers ──────────────────────────────────────────

  static const _kBothLove = 0;
  static const _kIPrefer  = 1;
  static const _kTheyPrefer = 2;
  static const _kAgree = 3;
  static const _kClash = 4;

  int _classifyTrack(MatchItemInfo item) {
    final diff = item.myScore - item.theirScore;
    if (item.myScore >= 7.0 && item.theirScore >= 7.0) return _kBothLove;
    if (diff.abs() >= 3.0) return _kClash;
    if (diff >= 2.0) return _kIPrefer;
    if (diff <= -2.0) return _kTheyPrefer;
    return _kAgree;
  }

  Widget _buildTracksTab(FriendMatchResult match, bool isPremium) {
    final p = context.palette;

    // ── Premium gate ────────────────────────────────────────────────────────────────
    if (!isPremium) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.accentSoft.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_rounded, size: 32, color: p.accentText),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                '곡별 대조 리포트',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '공통 최애 · 내가 더 선호 · 친구가 더 선호\n비슷한 취향 · 취향 충돌 곡을 카테고리별로\n전부 볼 수 있습니다.',
                style: TextStyle(color: p.muted, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '공통 평가 곡 ${match.commonCount}곡 대기 중',
                style: TextStyle(color: p.faint, fontSize: 11),
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () => context.push('/premium-upgrade'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Premium으로 업그레이드',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (match.commonItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_off_rounded, size: 36, color: p.muted),
              const SizedBox(height: AppSpacing.md),
              Text(
                '공동 평가한 음악이 없습니다',
                style: TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '두 사람이 같은 곡을 평가해야\n비교가 가능합니다.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Partition all tracks
    final bothLove   = match.commonItems.where((i) => _classifyTrack(i) == _kBothLove).toList();
    final iPrefer    = match.commonItems.where((i) => _classifyTrack(i) == _kIPrefer).toList();
    final theyPrefer = match.commonItems.where((i) => _classifyTrack(i) == _kTheyPrefer).toList();
    final agree      = match.commonItems.where((i) => _classifyTrack(i) == _kAgree).toList();
    final clash      = (match.commonItems.where((i) => _classifyTrack(i) == _kClash).toList()
      ..sort((a, b) => (b.myScore - b.theirScore).abs().compareTo((a.myScore - a.theirScore).abs())));

    // Categories definition (order matters for toggle UI)
    final categories = [
      _TrackCategory(id: -1, label: '전체',          emoji: '📋', count: match.commonItems.length, color: p.muted,               bgColor: p.chip),
      _TrackCategory(id:  0, label: '공통 최애',      emoji: '💖', count: bothLove.length,          color: p.accentText,          bgColor: p.accentSoft.withValues(alpha: 0.18)),
      _TrackCategory(id:  1, label: '내가 더 선호',   emoji: '👍', count: iPrefer.length,           color: const Color(0xFF6C9BFF),bgColor: const Color(0xFF6C9BFF).withValues(alpha: 0.12)),
      _TrackCategory(id:  2, label: '친구가 더 선호', emoji: '🫶', count: theyPrefer.length,         color: const Color(0xFFFF8C69),bgColor: const Color(0xFFFF8C69).withValues(alpha: 0.12)),
      _TrackCategory(id:  3, label: '비슷한 취향',    emoji: '💬', count: agree.length,             color: p.muted,               bgColor: p.chip),
      _TrackCategory(id:  4, label: '취향 충돌',      emoji: '⚡', count: clash.length,             color: const Color(0xFFE3B341),bgColor: const Color(0xFFE3B341).withValues(alpha: 0.12)),
    ].where((c) => c.id == -1 || c.count > 0).toList();

    // Which items to render
    List<_CategorizedItems> sections;
    if (_selectedTrackCategory == -1) {
      sections = [
        if (bothLove.isNotEmpty)   _CategorizedItems(_kBothLove,   bothLove),
        if (iPrefer.isNotEmpty)    _CategorizedItems(_kIPrefer,    iPrefer),
        if (theyPrefer.isNotEmpty) _CategorizedItems(_kTheyPrefer, theyPrefer),
        if (agree.isNotEmpty)      _CategorizedItems(_kAgree,      agree),
        if (clash.isNotEmpty)      _CategorizedItems(_kClash,      clash),
      ];
    } else {
      final items = switch (_selectedTrackCategory) {
        0 => bothLove,
        1 => iPrefer,
        2 => theyPrefer,
        3 => agree,
        _ => clash,
      };
      sections = [_CategorizedItems(_selectedTrackCategory, items)];
    }

    return Column(
      children: [
        // ── Toggle filter bar ─────────────────────────────────────────────
        Container(
          color: p.surface,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final selected = _selectedTrackCategory == cat.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTrackCategory = cat.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? cat.color : cat.bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? cat.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cat.emoji} ${cat.label}',
                          style: TextStyle(
                            color: selected ? Colors.black : cat.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cat.id != -1) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.black.withValues(alpha: 0.18)
                                  : cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${cat.count}',
                              style: TextStyle(
                                color: selected ? Colors.black : cat.color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // ── Song list ────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
                AppSpacing.md, AppLayout.scrollBottomInset(context)),
            children: [
              for (final section in sections) ...[
                if (_selectedTrackCategory == -1) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildTrackSectionHeader(
                    '${_categoryEmoji(section.category)} ${_categoryLabel(section.category)}',
                    _categorySubtitle(section.category),
                    section.items.length,
                    _categoryColor(section.category, p),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                ...section.items.map((item) => _buildTrackRow(item, section.category)),
                if (_selectedTrackCategory == -1) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Category metadata helpers ─────────────────────────────────────────────

  String _categoryEmoji(int cat) => switch (cat) {
    _kBothLove   => '💖',
    _kIPrefer    => '👍',
    _kTheyPrefer => '🫶',
    _kAgree      => '💬',
    _                => '⚡',
  };

  String _categoryLabel(int cat) => switch (cat) {
    _kBothLove   => '공통 최애',
    _kIPrefer    => '내가 더 선호',
    _kTheyPrefer => '친구가 더 선호',
    _kAgree      => '비슷한 취향',
    _                => '취향 충돌',
  };

  String _categorySubtitle(int cat) => switch (cat) {
    _kBothLove   => '둘 다 7점 이상',
    _kIPrefer    => '나 ≥ 친구 + 2점',
    _kTheyPrefer => '친구 ≥ 나 + 2점',
    _kAgree      => '점수 차이 2점 미만',
    _                => '점수 차이 3점 이상',
  };

  Color _categoryColor(int cat, AppPalette p) => switch (cat) {
    _kBothLove   => p.accentText,
    _kIPrefer    => const Color(0xFF6C9BFF),
    _kTheyPrefer => const Color(0xFFFF8C69),
    _kAgree      => p.muted,
    _                => const Color(0xFFE3B341),
  };

  // List<MatchItemInfo> _sliceForTier(List<MatchItemInfo> items, bool isPremium, int freeMax) {
  //   return isPremium ? items : items.take(freeMax).toList();
  // }

  // Widget _buildCategoryChip(String label, int count, Color textColor, Color bgColor) {
  //   return Container(
  //     margin: const EdgeInsets.only(right: 8, bottom: 12),
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     decoration: BoxDecoration(
  //       color: bgColor,
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
  //         const SizedBox(width: 4),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
  //           decoration: BoxDecoration(
  //             color: textColor.withValues(alpha: 0.15),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Text('$count', style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTrackSectionHeader(String title, String subtitle, int count, Color accent) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: p.text)),
              Text(subtitle, style: TextStyle(color: p.muted, fontSize: 10)),
            ],
          ),
        ),
        Text('$count곡', style: TextStyle(color: p.faint, fontSize: 11)),
      ],
    );
  }

  // Widget _buildLockedMoreRow(int count) {
  //   final p = context.palette;
  //   return Container(
  //     margin: const EdgeInsets.only(top: 6),
  //     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppSpacing.md),
  //     decoration: BoxDecoration(
  //       color: p.surface2,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: p.line),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(Icons.lock_outline_rounded, size: 13, color: p.muted),
  //         const SizedBox(width: 6),
  //         Text('$count곡 더 — Premium에서 전체 보기', style: TextStyle(color: p.muted, fontSize: 11)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTrackRow(MatchItemInfo item, int category) {
    final p = context.palette;
    final myScore = item.myScore;
    final theirScore = item.theirScore;
    final diff = (myScore - theirScore).abs();
    final maxScore = 10.0;

    // Category accent
    Color accentColor;
    switch (category) {
      case _kBothLove:   accentColor = p.accentText; break;
      case _kIPrefer:    accentColor = const Color(0xFF6C9BFF); break;
      case _kTheyPrefer: accentColor = const Color(0xFFFF8C69); break;
      case _kClash:      accentColor = const Color(0xFFE3B341); break;
      default:           accentColor = p.muted; break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: InkWell(
        onTap: () {
          final catalogItem = CatalogItem(
            id: item.id,
            kind: 'track',
            title: item.title,
            primaryArtist: item.artist,
            imageUrl: item.imageUrl,
          );
          context.push('item/${item.id}', extra: catalogItem);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: art + title + scores
              Row(
                children: [
                  CoverArt(title: item.title, imageUrl: item.imageUrl, size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          item.artist ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Score side-by-side
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _scoreChip('나', myScore, p, category == _kIPrefer || category == _kBothLove),
                      const SizedBox(height: 3),
                      _scoreChip('친구', theirScore, p, category == _kTheyPrefer || category == _kBothLove),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Score bar comparison
              _buildScoreComparisonBar(myScore, theirScore, maxScore, accentColor, p),
              // Diff label
              if (diff >= 2.0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${diff.toStringAsFixed(1)}점 차이',
                        style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String label, double score, AppPalette p, bool highlight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: TextStyle(color: p.muted, fontSize: 9)),
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: highlight ? p.text : p.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreComparisonBar(double myScore, double theirScore, double max, Color accent, AppPalette p) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final myFrac = (myScore / max).clamp(0.0, 1.0);
      final theirFrac = (theirScore / max).clamp(0.0, 1.0);
      return Column(
        children: [
          Stack(
            children: [
              Container(height: 6, width: w, decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(3))),
              Container(height: 6, width: w * myFrac, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
            ],
          ),
          const SizedBox(height: 3),
          Stack(
            children: [
              Container(height: 6, width: w, decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(3))),
              Container(height: 6, width: w * theirFrac, decoration: BoxDecoration(color: p.muted.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(3))),
            ],
          ),
        ],
      );
    });
  }

  // Legacy fallback (used by controversial songs in overview tab)
  Widget _buildUnifiedComparisonRow(MatchItemInfo item) {
    return _buildTrackRow(item, _classifyTrack(item));
  }



  Widget _buildTagsTab(FriendMatchResult match, bool isPremium) {
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md,
          AppLayout.scrollBottomInset(context)),
      children: [
        // 1. Shared Genres
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
                        g.toUpperCase(),
                        style: TextStyle(color: p.text, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 2. Shared Moods
        if (match.sharedMoods.isNotEmpty) ...[
          _buildSectionTitle('공통 선호 분위기'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: match.sharedMoods
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: p.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        m,
                        style: TextStyle(color: p.accentText, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // 3. Unique sections (Premium Lock for free users)
        if (isPremium) ...[
          // Unique to Me
          if (match.myUniqueGenres.isNotEmpty || match.myUniqueMoods.isNotEmpty) ...[
            _buildSectionTitle('나만 평가한 독특한 취향'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...match.myUniqueGenres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        '장르: $g',
                        style: TextStyle(color: p.muted, fontSize: 10),
                      ),
                    )),
                ...match.myUniqueMoods.map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        '분위기: $m',
                        style: TextStyle(color: p.muted, fontSize: 10),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Unique to Friend
          if (match.theirUniqueGenres.isNotEmpty || match.theirUniqueMoods.isNotEmpty) ...[
            _buildSectionTitle('친구만 평가한 독특한 취향'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...match.theirUniqueGenres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        '장르: $g',
                        style: TextStyle(color: p.muted, fontSize: 10),
                      ),
                    )),
                ...match.theirUniqueMoods.map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        '분위기: $m',
                        style: TextStyle(color: p.muted, fontSize: 10),
                      ),
                    )),
              ],
            ),
          ],
        ] else ...[
          // Lock message for unique preferences
          if (match.myUniqueGenres.isNotEmpty || match.myUniqueMoods.isNotEmpty ||
              match.theirUniqueGenres.isNotEmpty || match.theirUniqueMoods.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 28, color: p.accent),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    '개별 고유 취향 분석 (Premium)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '나만 좋아하는 장르/분위기와 친구만 좋아하는 유니크한 선호 곡 분석을 보시려면 Premium으로 가입하세요.',
                    style: TextStyle(color: p.muted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => context.push('/premium-upgrade'),
                    child: const Text('Premium 활성화', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ── Helper data classes ────────────────────────────────────────────────────

class _TrackCategory {
  const _TrackCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.count,
    required this.color,
    required this.bgColor,
  });
  final int id;
  final String label;
  final String emoji;
  final int count;
  final Color color;
  final Color bgColor;
}

class _CategorizedItems {
  const _CategorizedItems(this.category, this.items);
  final int category;
  final List<MatchItemInfo> items;
}
