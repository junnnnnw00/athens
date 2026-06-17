import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../i18n.dart';
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
  int _selectedTrackCategory = -1;

  late final TabController _tabController;
  Future<FriendMatchResult>? _matchFuture;
  List<RatedCatalogItem>? _lastRatings;

  AppLanguage get _lang => ref.read(localeProvider);

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
          .select('id, handle, display_name, bio, avatar_url, is_public, lastfm_username')
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
    ref.watch(localeProvider); // rebuild on locale change
    final p = context.palette;
    final myProfileAsync = ref.watch(myProfileProvider);
    final myRatings = ref.watch(ratedItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_friendProfile != null
            ? I18n.get('cmp_title_with_name', _lang, [_friendProfile!.displayName ?? _friendProfile!.handle])
            : I18n.get('cmp_title', _lang)),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _friendProfile == null
              ? Center(child: Text(I18n.get('cmp_profile_not_found', _lang), style: TextStyle(color: p.text)))
              : _buildComparisonContent(myRatings, myProfileAsync.valueOrNull),
    );
  }

  Widget _buildComparisonContent(
    List<RatedCatalogItem> myRatings,
    UserProfile? myProfile,
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
              I18n.get('cmp_error', _lang, ['${snapshot.error}']),
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
              tabs: [
                Tab(text: I18n.get('cmp_tab_overview', _lang)),
                Tab(text: I18n.get('cmp_tab_tracks', _lang)),
                Tab(text: I18n.get('cmp_tab_genres', _lang)),
              ],
            ),

            // Tab contents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(match, myProfile),
                  _buildTracksTab(match),
                  _buildTagsTab(match),
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
                  myProfile?.displayName ?? myProfile?.handle ?? I18n.get('cmp_me', _lang),
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
                  I18n.get('cmp_match_percent', _lang, [match.matchPercentage.toStringAsFixed(0)]),
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
                  _friendProfile?.displayName ?? _friendProfile?.handle ?? I18n.get('cmp_friend', _lang),
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

  Widget _buildOverviewTab(FriendMatchResult match, UserProfile? myProfile) {
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md,
          AppLayout.scrollBottomInset(context)),
      children: [
        _buildBasicStatsSection(match, myProfile),

        const SizedBox(height: AppSpacing.xl),

        _buildSectionTitle(I18n.get('cmp_section_personality', _lang)),
        const SizedBox(height: AppSpacing.sm),
        _buildPersonalityCards(match),

        const SizedBox(height: AppSpacing.xl),

        _buildSectionTitle(I18n.get('cmp_section_score_dist', _lang)),
        const SizedBox(height: 4),
        Text(
          I18n.get('cmp_section_score_dist_desc', _lang),
          style: TextStyle(color: p.muted, fontSize: 11),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildScoreDistributionChart(match),

        const SizedBox(height: AppSpacing.xl),

        _buildSectionTitle(I18n.get('cmp_section_agreement', _lang)),
        const SizedBox(height: AppSpacing.sm),
        _buildAgreementSection(match),

        const SizedBox(height: AppSpacing.xl),

        if (match.myTopArtists.isNotEmpty || match.theirTopArtists.isNotEmpty) ...[
          _buildSectionTitle(I18n.get('cmp_section_artists', _lang)),
          const SizedBox(height: AppSpacing.sm),
          _buildArtistOverlapSection(match),
          const SizedBox(height: AppSpacing.xl),
        ],

        if (match.controversialSongs.isNotEmpty) ...[
          _buildSectionTitle(I18n.get('cmp_controversial_title', _lang, ['${match.controversialSongs.length}'])),
          const SizedBox(height: 4),
          Text(
            I18n.get('cmp_controversial_desc', _lang),
            style: TextStyle(color: p.muted, fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.md),
          ...match.controversialSongs.map((item) => _buildUnifiedComparisonRow(item)),
        ],
      ],
    );
  }

  Widget _buildBasicStatsSection(FriendMatchResult match, UserProfile? myProfile) {
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
              Text(I18n.get('cmp_basic_info', _lang), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.accentText)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildStatRow(Icons.library_music_rounded, I18n.get('cmp_rated_count_label', _lang),
              I18n.get('cmp_tracks_unit', _lang, ['${match.myTotalCount}']),
              I18n.get('cmp_tracks_unit', _lang, ['${match.theirTotalCount}'])),
          const SizedBox(height: 8),
          _buildStatRow(Icons.star_rounded, I18n.get('cmp_avg_score_label', _lang),
              I18n.get('cmp_pts_unit', _lang, [match.myAverageScore.toStringAsFixed(1)]),
              I18n.get('cmp_pts_unit', _lang, [match.theirAverageScore.toStringAsFixed(1)])),
          const SizedBox(height: 8),
          _buildStatRow(Icons.music_note_rounded, I18n.get('cmp_common_rated_label', _lang),
              '', I18n.get('cmp_tracks_unit', _lang, ['${match.commonCount}']), centerVal: true),
          const SizedBox(height: 8),
          _buildStatRow(Icons.people_rounded, I18n.get('cmp_shared_artists_label', _lang),
              '', I18n.get('cmp_people_unit', _lang, ['${match.sharedArtistCount}']), centerVal: true),
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
                        ? I18n.get('cmp_score_based_note', _lang)
                        : I18n.get('cmp_genre_based_note', _lang),
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

  Widget _buildPersonalityCards(FriendMatchResult match) {
    final p = context.palette;
    final myP = match.myPersonality;
    final theirP = match.theirPersonality;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildPersonalityCard(
              label: tastePersonalityLabel(myP, _lang),
              description: tastePersonalityDescription(myP, _lang),
              isMe: true,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildPersonalityCard(
              label: tastePersonalityLabel(theirP, _lang),
              description: tastePersonalityDescription(theirP, _lang),
              isMe: false,
            )),
          ],
        ),
        if (myP != TastePersonality.noData && theirP != TastePersonality.noData) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: p.accentSoft.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('🔗', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    personalityCompatibility(myP, theirP, _lang),
                    style: TextStyle(color: p.text, fontSize: 11, height: 1.4),
                  ),
                ),
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
            I18n.get(isMe ? 'cmp_me' : 'cmp_friend', _lang),
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
              _legendDot(p.accentText, I18n.get('cmp_me', _lang)),
              const SizedBox(width: AppSpacing.md),
              _legendDot(p.muted, I18n.get('cmp_friend', _lang)),
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
                Expanded(child: _stdDevChip(I18n.get('cmp_me', _lang), match.myScoreStdDev, p)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _stdDevChip(I18n.get('cmp_friend', _lang), match.theirScoreStdDev, p)),
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
      interpretation = I18n.get('cmp_std_even', _lang);
    } else if (stdDev < 2.2) {
      interpretation = I18n.get('cmp_std_moderate', _lang);
    } else {
      interpretation = I18n.get('cmp_std_strong', _lang);
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
        child: Text(I18n.get('cmp_no_common_analysis', _lang), style: TextStyle(color: p.muted, fontSize: 12)),
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
              Expanded(child: _buildAgreementStat(I18n.get('cmp_agreement_rate_label', _lang), '${agreePct.toStringAsFixed(0)}%',
                  agreePct >= 70 ? I18n.get('cmp_agreement_high', _lang) : agreePct >= 40 ? I18n.get('cmp_agreement_mid', _lang) : I18n.get('cmp_agreement_low', _lang), p)),
              Container(width: 1, height: 40, color: p.line),
              Expanded(child: _buildAgreementStat(I18n.get('cmp_common_eval_label', _lang), I18n.get('cmp_n_tracks_section', _lang, ['${match.commonCount}']), I18n.get('cmp_listened_together', _lang), p)),
              Container(width: 1, height: 40, color: p.line),
              Expanded(child: _buildAgreementStat(I18n.get('cmp_clash_label', _lang), I18n.get('cmp_n_tracks_section', _lang, ['$disagreeCount']), I18n.get('cmp_clash_sub', _lang), p)),
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
                ? I18n.get('cmp_agree_high_text', _lang)
                : agreePct >= 40
                    ? I18n.get('cmp_agree_mid_text', _lang)
                    : I18n.get('cmp_agree_low_text', _lang),
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
                I18n.get('cmp_shared_artists_count', _lang, ['${match.sharedArtistCount}']),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: p.accentText),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildArtistColumn(I18n.get('cmp_my_top_artists', _lang), match.myTopArtists)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildArtistColumn(I18n.get('cmp_their_top_artists', _lang), match.theirTopArtists)),
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
          Text(I18n.get('cmp_no_data', _lang), style: TextStyle(color: p.faint, fontSize: 11)),
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

  Widget _buildTracksTab(FriendMatchResult match) {
    final p = context.palette;

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
                I18n.get('cmp_no_common_tracks', _lang),
                style: TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                I18n.get('cmp_no_common_tracks_desc', _lang),
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
      _TrackCategory(id: -1, label: I18n.get('cmp_cat_all', _lang),         emoji: '📋', count: match.commonItems.length, color: p.muted,               bgColor: p.chip),
      _TrackCategory(id:  0, label: I18n.get('cmp_cat_both_love', _lang),   emoji: '💖', count: bothLove.length,          color: p.accentText,          bgColor: p.accentSoft.withValues(alpha: 0.18)),
      _TrackCategory(id:  1, label: I18n.get('cmp_cat_i_prefer', _lang),    emoji: '👍', count: iPrefer.length,           color: const Color(0xFF6C9BFF),bgColor: const Color(0xFF6C9BFF).withValues(alpha: 0.12)),
      _TrackCategory(id:  2, label: I18n.get('cmp_cat_they_prefer', _lang), emoji: '🫶', count: theyPrefer.length,         color: const Color(0xFFFF8C69),bgColor: const Color(0xFFFF8C69).withValues(alpha: 0.12)),
      _TrackCategory(id:  3, label: I18n.get('cmp_cat_agree', _lang),       emoji: '💬', count: agree.length,             color: p.muted,               bgColor: p.chip),
      _TrackCategory(id:  4, label: I18n.get('cmp_cat_clash', _lang),       emoji: '⚡', count: clash.length,             color: const Color(0xFFE3B341),bgColor: const Color(0xFFE3B341).withValues(alpha: 0.12)),
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
    _kBothLove   => I18n.get('cmp_cat_both_love', _lang),
    _kIPrefer    => I18n.get('cmp_cat_i_prefer', _lang),
    _kTheyPrefer => I18n.get('cmp_cat_they_prefer', _lang),
    _kAgree      => I18n.get('cmp_cat_agree', _lang),
    _                => I18n.get('cmp_cat_clash', _lang),
  };

  String _categorySubtitle(int cat) => switch (cat) {
    _kBothLove   => I18n.get('cmp_sub_both_love', _lang),
    _kIPrefer    => I18n.get('cmp_sub_i_prefer', _lang),
    _kTheyPrefer => I18n.get('cmp_sub_they_prefer', _lang),
    _kAgree      => I18n.get('cmp_sub_agree', _lang),
    _                => I18n.get('cmp_sub_clash', _lang),
  };

  Color _categoryColor(int cat, AppPalette p) => switch (cat) {
    _kBothLove   => p.accentText,
    _kIPrefer    => const Color(0xFF6C9BFF),
    _kTheyPrefer => const Color(0xFFFF8C69),
    _kAgree      => p.muted,
    _                => const Color(0xFFE3B341),
  };

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
        Text(I18n.get('cmp_n_tracks_section', _lang, ['$count']), style: TextStyle(color: p.faint, fontSize: 11)),
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
          context.push(
              '/friends/compare/${widget.friendId}/item/${Uri.encodeComponent(item.id)}',
              extra: catalogItem);
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
                  CoverArt(title: item.title, imageUrl: item.imageUrl, size: 44, artist: item.artist, kind: 'track'),
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
                      _scoreChip(I18n.get('cmp_me', _lang), myScore, p, category == _kIPrefer || category == _kBothLove),
                      const SizedBox(height: 3),
                      _scoreChip(I18n.get('cmp_friend', _lang), theirScore, p, category == _kTheyPrefer || category == _kBothLove),
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
                        I18n.get('cmp_pt_gap', _lang, [diff.toStringAsFixed(1)]),
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



  Widget _buildTagsTab(FriendMatchResult match) {
    final p = context.palette;

    return ListView(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md,
          AppLayout.scrollBottomInset(context)),
      children: [
        // 1. Shared Genres
        if (match.sharedGenres.isNotEmpty) ...[
          _buildSectionTitle(I18n.get('cmp_shared_genres', _lang)),
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
          _buildSectionTitle(I18n.get('cmp_shared_moods', _lang)),
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

        // 3. Unique sections
        if (match.myUniqueGenres.isNotEmpty || match.myUniqueMoods.isNotEmpty) ...[
          _buildSectionTitle(I18n.get('cmp_my_unique_taste', _lang)),
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
                    child: Text(I18n.get('cmp_genre_prefix', _lang, [g]), style: TextStyle(color: p.muted, fontSize: 10)),
                  )),
              ...match.myUniqueMoods.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.line),
                    ),
                    child: Text(I18n.get('cmp_mood_prefix', _lang, [m]), style: TextStyle(color: p.muted, fontSize: 10)),
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (match.theirUniqueGenres.isNotEmpty || match.theirUniqueMoods.isNotEmpty) ...[
          _buildSectionTitle(I18n.get('cmp_their_unique_taste', _lang)),
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
                    child: Text(I18n.get('cmp_genre_prefix', _lang, [g]), style: TextStyle(color: p.muted, fontSize: 10)),
                  )),
              ...match.theirUniqueMoods.map((m) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.line),
                    ),
                    child: Text(I18n.get('cmp_mood_prefix', _lang, [m]), style: TextStyle(color: p.muted, fontSize: 10)),
                  )),
            ],
          ),
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
