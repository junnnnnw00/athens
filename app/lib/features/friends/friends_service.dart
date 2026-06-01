import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/score.dart';
import '../catalog/catalog_service.dart';
import '../profile/profile_service.dart';

/// Describes which taste personality type a user is.
/// Derived from average score (picky vs. generous) × variance (consistent vs. eclectic).
enum TastePersonality {
  /// Low avg (< 5.0) + low stddev (< 1.5): Rarely impressed, always the same strict standard.
  coldCritic,

  /// Low avg (< 5.0) + high stddev (>= 1.5): Picky but has rare passionate obsessions.
  selectiveObsessive,

  /// Mid avg (5.0–7.1) + low stddev (< 1.5): Consistent, measured listener.
  calmConnoisseur,

  /// Mid avg (5.0–7.1) + high stddev (>= 1.5): Balanced but mood-driven — big highs and lows.
  moodDriven,

  /// High avg (>= 7.2) + low stddev (< 1.5): Enthusiastic but stable — loves most things equally.
  warmSteady,

  /// High avg (>= 7.2) + high stddev (>= 1.5): Emotional, hype-driven — some songs blow their mind.
  hyperReactioner,

  /// No data.
  noData,
}

TastePersonality tastePersonalityFrom(double avgScore, double stdDev) {
  if (avgScore == 0.0) return TastePersonality.noData;
  final highVariance = stdDev >= 1.5;
  if (avgScore < 5.0) {
    return highVariance ? TastePersonality.selectiveObsessive : TastePersonality.coldCritic;
  } else if (avgScore < 7.2) {
    return highVariance ? TastePersonality.moodDriven : TastePersonality.calmConnoisseur;
  } else {
    return highVariance ? TastePersonality.hyperReactioner : TastePersonality.warmSteady;
  }
}

String tastePersonalityLabel(TastePersonality p) {
  switch (p) {
    case TastePersonality.coldCritic:
      return '🧊 냉정한 심판관';
    case TastePersonality.selectiveObsessive:
      return '🎯 까다로운 마니아';
    case TastePersonality.calmConnoisseur:
      return '⚖️ 균형잡힌 감상가';
    case TastePersonality.moodDriven:
      return '🌊 감성적 무드메이커';
    case TastePersonality.warmSteady:
      return '☀️ 따뜻한 지지자';
    case TastePersonality.hyperReactioner:
      return '🔥 열정적 리액셔너';
    case TastePersonality.noData:
      return '기록 없음';
  }
}

String tastePersonalityDescription(TastePersonality p) {
  switch (p) {
    case TastePersonality.coldCritic:
      return '평점이 낮고 일관적으로 인색해요. 기준이 엄격하고 흔들리지 않는 심판관 타입. 높은 점수를 받으면 진짜 명반이라는 증거입니다.';
    case TastePersonality.selectiveObsessive:
      return '평소엔 까다롭지만 가끔 특정 곡에는 폭발적으로 반응해요. 숨겨진 덕후 기질이 있는 타입. 최애 리스트는 강렬합니다.';
    case TastePersonality.calmConnoisseur:
      return '균형 잡힌 시각으로 음악을 평가해요. 과하게 흥분하지도, 혹평하지도 않는 신뢰할 수 있는 감상가 타입입니다.';
    case TastePersonality.moodDriven:
      return '그날의 기분에 따라 점수가 크게 달라지는 감성파예요. 기분 좋을 때는 후하고 아닐 땐 박해요. 취향의 폭이 넓습니다.';
    case TastePersonality.warmSteady:
      return '대부분의 음악을 따뜻하게 받아들여요. 함께 음악 듣기 좋은 긍정 에너지 타입. 분위기 메이커입니다.';
    case TastePersonality.hyperReactioner:
      return '좋아하는 곡엔 극적으로 반응하고, 아닌 곡엔 확실히 거르는 타입이에요. 플레이리스트가 곧 자신의 정체성입니다.';
    case TastePersonality.noData:
      return '아직 평가한 음악이 없어서 성향을 파악할 수 없습니다.';
  }
}

/// Returns a compatibility description based on two personalities.
String personalityCompatibility(TastePersonality a, TastePersonality b) {
  // Same type
  if (a == b) return '같은 성향끼리! 서로의 취향을 직관적으로 이해하는 드문 조합입니다.';

  final set = {a, b};

  if (set.containsAll([TastePersonality.coldCritic, TastePersonality.hyperReactioner]) ||
      set.containsAll([TastePersonality.selectiveObsessive, TastePersonality.warmSteady])) {
    return '정반대의 감성을 가진 두 사람! 서로에게서 완전히 새로운 음악 세계를 발견할 수 있습니다.';
  }

  if (set.containsAll([TastePersonality.coldCritic, TastePersonality.selectiveObsessive]) ||
      set.containsAll([TastePersonality.warmSteady, TastePersonality.hyperReactioner]) ||
      set.containsAll([TastePersonality.calmConnoisseur, TastePersonality.moodDriven])) {
    return '비슷한 듯 다른 두 성향. 같은 곡도 다른 이유로 좋아할 수 있는 흥미로운 조합입니다.';
  }

  if (set.contains(TastePersonality.calmConnoisseur) ||
      set.contains(TastePersonality.warmSteady)) {
    return '한 사람이 중심을 잡아주는 안정적인 조합이에요. 음악 취향 대화가 자연스럽게 이어집니다.';
  }

  return '서로 다른 취향이 만나 더 풍부한 음악 탐험이 가능한 조합입니다.';
}


class FriendMatchResult {
  FriendMatchResult({
    required this.matchPercentage,
    required this.commonCount,
    required this.sharedFavorites,
    required this.tasteDifferences,
    required this.commonItems,
    this.myBetterFavorites = const [],
    this.theirBetterFavorites = const [],
    this.sharedGenres = const [],
    this.sharedMoods = const [],
    this.myUniqueGenres = const [],
    this.theirUniqueGenres = const [],
    this.myUniqueMoods = const [],
    this.theirUniqueMoods = const [],
    this.myAverageScore = 0.0,
    this.theirAverageScore = 0.0,
    this.myTotalCount = 0,
    this.theirTotalCount = 0,
    this.myScoreStdDev = 0.0,
    this.theirScoreStdDev = 0.0,
    this.sharedArtists = const [],
    this.splitArtists = const [],
    this.myTopSongTheirScore,
    this.theirTopSongMyScore,
    // New rich fields
    this.sharedArtistCount = 0,
    this.myTopArtists = const [],
    this.theirTopArtists = const [],
    this.myScoreDistribution = const {},
    this.theirScoreDistribution = const {},
    this.agreementRate = 0.0,
    this.controversialSongs = const [],
  });

  final double matchPercentage;
  final int commonCount;
  final List<MatchItemInfo> sharedFavorites;
  final List<MatchItemInfo> tasteDifferences;
  final List<MatchItemInfo> commonItems;
  final List<MatchItemInfo> myBetterFavorites;
  final List<MatchItemInfo> theirBetterFavorites;
  final List<String> sharedGenres;
  final List<String> sharedMoods;
  final List<String> myUniqueGenres;
  final List<String> theirUniqueGenres;
  final List<String> myUniqueMoods;
  final List<String> theirUniqueMoods;
  final double myAverageScore;
  final double theirAverageScore;
  final int myTotalCount;
  final int theirTotalCount;
  final double myScoreStdDev;
  final double theirScoreStdDev;
  final List<String> sharedArtists;
  final List<String> splitArtists;
  final MatchItemInfo? myTopSongTheirScore;
  final MatchItemInfo? theirTopSongMyScore;

  // ─── New rich analytics fields ───
  /// Number of artists both users have rated at least one song from.
  final int sharedArtistCount;
  /// Top 5 artists by number of rated songs for each user.
  final List<String> myTopArtists;
  final List<String> theirTopArtists;
  /// Distribution of scores: key = bucket label ('1-2', '3-4', ..., '9-10'),
  /// value = count.
  final Map<String, int> myScoreDistribution;
  final Map<String, int> theirScoreDistribution;
  /// % of shared songs where both agreed (diff < 2.0).
  final double agreementRate;
  /// Songs with the biggest score disagreement (diff >= 3).
  final List<MatchItemInfo> controversialSongs;

  TastePersonality get myPersonality => tastePersonalityFrom(myAverageScore, myScoreStdDev);
  TastePersonality get theirPersonality => tastePersonalityFrom(theirAverageScore, theirScoreStdDev);
}

class MatchItemInfo {
  MatchItemInfo({
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.myScore,
    required this.theirScore,
  });

  final String title;
  final String? artist;
  final String? imageUrl;
  final double myScore;
  final double theirScore;
}

class FriendsService {
  FriendsService({SupabaseClient? client}) : _providedClient = client;

  final SupabaseClient? _providedClient;
  SupabaseClient get _client => _providedClient ?? Supabase.instance.client;

  /// Search public profiles by handle or display name.
  Future<List<UserProfile>> searchUsers(String query) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    if (query.trim().isEmpty) return [];

    final rows = await _client
        .from('profiles')
        .select('id, handle, display_name, bio, avatar_url, is_public, spotify_enabled, is_premium')
        .eq('is_public', true)
        .neq('id', user.id)
        .or('handle.ilike.%$query%,display_name.ilike.%$query%')
        .limit(20);

    return rows.map((r) => UserProfile.fromMap(r)).toList();
  }

  /// Follow/Add a user as a friend.
  Future<void> followUser(String followingId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not logged in');
    await _client.from('follows').insert({
      'follower_id': user.id,
      'following_id': followingId,
    });
  }

  /// Unfollow/Remove a user as a friend.
  Future<void> unfollowUser(String followingId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not logged in');
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('following_id', followingId);
  }

  /// Get the list of profiles of friends (users the current user is following).
  Future<List<UserProfile>> getFriends() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('follows')
        .select('following:profiles!follows_following_id_fkey(id, handle, display_name, bio, avatar_url, is_public, spotify_enabled, is_premium)')
        .eq('follower_id', user.id);

    return rows
        .map((r) => r['following'])
        .where((f) => f != null)
        .map((f) => UserProfile.fromMap(f as Map<String, dynamic>))
        .toList();
  }

  /// Check if following a specific user.
  Future<bool> isFollowing(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final row = await _client
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', userId)
        .maybeSingle();
    return row != null;
  }

  /// Calculates a music taste match percentage and comparison insights.
  Future<FriendMatchResult> calculateMatch(
    String otherUserId,
    List<RatedCatalogItem> myRatings,
  ) async {
    // 1. Fetch other user's ratings
    final otherRows = await _client
        .from('ratings')
        .select('score, item_id, items!inner(source, source_id, title, primary_artist, image_url, tags)')
        .eq('user_id', otherUserId);

    final otherRatingsMap = <String, Map<String, dynamic>>{};
    final otherGenres = <String>{};
    final otherMoods = <String>{};

    for (final row in otherRows) {
      final item = row['items'] as Map<String, dynamic>;
      final source = item['source'] as String;
      final sourceId = item['source_id'] as String;
      final localId = '$source:$sourceId';
      
      final scoreVal = double.tryParse(row['score'].toString()) ?? 5.0;
      
      otherRatingsMap[localId] = {
        'score': scoreVal,
        'title': item['title'] as String,
        'artist': item['primary_artist'] as String?,
        'image_url': item['image_url'] as String?,
      };

      // Extract genres & moods
      final tags = item['tags'] as List<dynamic>? ?? [];
      for (final t in tags) {
        final tagMap = t as Map<String, dynamic>;
        final name = tagMap['name'].toString().toLowerCase();
        final tagSource = tagMap['source']?.toString().toLowerCase() ?? 'genre';
        if (tagSource == 'mood') {
          otherMoods.add(name);
        } else {
          otherGenres.add(name);
        }
      }
    }

    // 2. Extract my ratings, genres, and moods
    final myRatingsMap = {for (final r in myRatings) r.id: r};
    final myGenres = <String>{};
    final myMoods = <String>{};
    for (final r in myRatings) {
      for (final t in r.tags) {
        final name = t.name.toLowerCase();
        final tagSource = t.source.toLowerCase();
        if (tagSource == 'mood') {
          myMoods.add(name);
        } else {
          myGenres.add(name);
        }
      }
    }

    // 3. Find common items and calculate ratings difference
    final sharedFavorites = <MatchItemInfo>[];
    final tasteDifferences = <MatchItemInfo>[];
    final myBetterFavorites = <MatchItemInfo>[];
    final theirBetterFavorites = <MatchItemInfo>[];
    final commonItems = <MatchItemInfo>[];
    double totalDiff = 0.0;
    int commonCount = 0;

    for (final myId in myRatingsMap.keys) {
      if (otherRatingsMap.containsKey(myId)) {
        commonCount++;
        final myItem = myRatingsMap[myId]!;
        final otherItem = otherRatingsMap[myId]!;
        
        final myScore = scoreFromElo(myItem.elo);
        final theirScore = otherItem['score'] as double;
        final diff = (myScore - theirScore).abs();
        totalDiff += diff;

        final info = MatchItemInfo(
          title: myItem.title,
          artist: myItem.primaryArtist,
          imageUrl: myItem.imageUrl,
          myScore: myScore,
          theirScore: theirScore,
        );

        commonItems.add(info);

        if (myScore >= 7.0 && theirScore >= 7.0) {
          sharedFavorites.add(info);
        } else if (diff >= 3.0) {
          tasteDifferences.add(info);
        }

        final myBetter = myScore - theirScore;
        if (myBetter >= 2.0) {
          myBetterFavorites.add(info);
        } else if (myBetter <= -2.0) {
          theirBetterFavorites.add(info);
        }
      }
    }

    // 4. Calculate shared genres & moods (Jaccard similarity style)
    final genreIntersection = myGenres.intersection(otherGenres);
    final genreUnion = myGenres.union(otherGenres);
    final double genreSim = genreUnion.isEmpty ? 50.0 : (genreIntersection.length / genreUnion.length) * 100.0;

    final moodIntersection = myMoods.intersection(otherMoods);
    final moodUnion = myMoods.union(otherMoods);
    final double moodSim = moodUnion.isEmpty ? 50.0 : (moodIntersection.length / moodUnion.length) * 100.0;

    final double tagsSim = (genreSim + moodSim) / 2.0;

    // Calculate unique genres & moods
    final myUniqueGenres = myGenres.difference(otherGenres).toList();
    final theirUniqueGenres = otherGenres.difference(myGenres).toList();
    final myUniqueMoods = myMoods.difference(otherMoods).toList();
    final theirUniqueMoods = otherMoods.difference(myMoods).toList();

    // Calculate averages & totals
    final myScores = myRatings.map((r) => scoreFromElo(r.elo)).toList();
    final double myAverageScore = myScores.isEmpty ? 0.0 : myScores.reduce((a, b) => a + b) / myScores.length;
    final int myTotalCount = myRatings.length;

    final theirScores = otherRatingsMap.values.map((v) => v['score'] as double).toList();
    final double theirAverageScore = theirScores.isEmpty ? 0.0 : theirScores.reduce((a, b) => a + b) / theirScores.length;
    final int theirTotalCount = otherRatingsMap.length;

    // 5. Compute match score
    double ratingSim = 50.0;
    if (commonCount > 0) {
      final avgDiff = totalDiff / commonCount;
      ratingSim = (100.0 - (avgDiff * 12.0)).clamp(0.0, 100.0);
    }

    double matchPercentage = 50.0;
    if (commonCount >= 3) {
      // High weight on ratings similarity if there's enough overlap
      matchPercentage = ratingSim * 0.7 + tagsSim * 0.3;
    } else if (commonCount > 0) {
      matchPercentage = ratingSim * 0.4 + tagsSim * 0.6;
    } else {
      matchPercentage = tagsSim;
    }

    // 6. Standard deviation
    double stdDev(List<double> scores) {
      if (scores.length < 2) return 0.0;
      final mean = scores.reduce((a, b) => a + b) / scores.length;
      final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
      return math.sqrt(variance);
    }
    final myStdDev = stdDev(myScores);
    final theirStdDev = stdDev(theirScores);

    // 7. Artist analysis
    final myArtists = <String, int>{};
    for (final r in myRatings) {
      if (r.primaryArtist != null && r.primaryArtist!.isNotEmpty) {
        myArtists[r.primaryArtist!] = (myArtists[r.primaryArtist!] ?? 0) + 1;
      }
    }
    final theirArtists = <String, int>{};
    for (final v in otherRatingsMap.values) {
      final artist = v['artist'] as String?;
      if (artist != null && artist.isNotEmpty) {
        theirArtists[artist] = (theirArtists[artist] ?? 0) + 1;
      }
    }
    final sharedArtistNames = myArtists.keys.toSet().intersection(theirArtists.keys.toSet());
    final myTopArtists = (myArtists.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();
    final theirTopArtists = (theirArtists.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => e.key)
        .toList();

    // 8. Score distribution buckets
    Map<String, int> scoreDist(List<double> scores) {
      final buckets = <String, int>{
        '1-2': 0, '3-4': 0, '5-6': 0, '7-8': 0, '9-10': 0,
      };
      for (final s in scores) {
        if (s <= 2) {
          buckets['1-2'] = buckets['1-2']! + 1;
        } else if (s <= 4) {
          buckets['3-4'] = buckets['3-4']! + 1;
        } else if (s <= 6) {
          buckets['5-6'] = buckets['5-6']! + 1;
        } else if (s <= 8) {
          buckets['7-8'] = buckets['7-8']! + 1;
        } else {
          buckets['9-10'] = buckets['9-10']! + 1;
        }
      }
      return buckets;
    }

    // 9. Agreement rate & controversial songs
    final agreeCount = commonItems.where((i) => (i.myScore - i.theirScore).abs() < 2.0).length;
    final agreementRate = commonCount > 0 ? (agreeCount / commonCount) * 100.0 : 0.0;
    final controversialSongs = commonItems
        .where((i) => (i.myScore - i.theirScore).abs() >= 3.0)
        .toList()
      ..sort((a, b) => (b.myScore - b.theirScore).abs().compareTo((a.myScore - a.theirScore).abs()));

    // Return results
    return FriendMatchResult(
      matchPercentage: matchPercentage,
      commonCount: commonCount,
      sharedFavorites: sharedFavorites..sort((a, b) => (b.myScore + b.theirScore).compareTo(a.myScore + a.theirScore)),
      tasteDifferences: tasteDifferences..sort((a, b) => (b.myScore - b.theirScore).abs().compareTo((a.myScore - a.theirScore).abs())),
      commonItems: commonItems..sort((a, b) => (b.myScore + b.theirScore).compareTo(a.myScore + a.theirScore)),
      myBetterFavorites: myBetterFavorites..sort((a, b) => (b.myScore - b.theirScore).compareTo(a.myScore - a.theirScore)),
      theirBetterFavorites: theirBetterFavorites..sort((a, b) => (b.theirScore - b.myScore).compareTo(a.theirScore - a.myScore)),
      sharedGenres: genreIntersection.take(8).toList(),
      sharedMoods: moodIntersection.take(8).toList(),
      myUniqueGenres: myUniqueGenres.take(6).toList(),
      theirUniqueGenres: theirUniqueGenres.take(6).toList(),
      myUniqueMoods: myUniqueMoods.take(6).toList(),
      theirUniqueMoods: theirUniqueMoods.take(6).toList(),
      myAverageScore: myAverageScore,
      theirAverageScore: theirAverageScore,
      myTotalCount: myTotalCount,
      theirTotalCount: theirTotalCount,
      myScoreStdDev: myStdDev,
      theirScoreStdDev: theirStdDev,
      sharedArtistCount: sharedArtistNames.length,
      myTopArtists: myTopArtists,
      theirTopArtists: theirTopArtists,
      myScoreDistribution: scoreDist(myScores),
      theirScoreDistribution: scoreDist(theirScores),
      agreementRate: agreementRate,
      controversialSongs: controversialSongs.take(5).toList(),
    );
  }
}

final friendsServiceProvider = Provider<FriendsService>((ref) => FriendsService());

/// Friend list provider
final friendsProvider = FutureProvider<List<UserProfile>>((ref) async {
  return ref.watch(friendsServiceProvider).getFriends();
});
