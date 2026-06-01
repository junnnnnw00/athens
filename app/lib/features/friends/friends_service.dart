import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/score.dart';
import '../catalog/catalog_service.dart';
import '../profile/profile_service.dart';



class FriendMatchResult {
  FriendMatchResult({
    required this.matchPercentage,
    required this.commonCount,
    required this.sharedFavorites,
    required this.tasteDifferences,
    required this.sharedGenres,
  });

  final double matchPercentage;
  final int commonCount;
  final List<MatchItemInfo> sharedFavorites;
  final List<MatchItemInfo> tasteDifferences;
  final List<String> sharedGenres;
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
        .select('following:profiles(id, handle, display_name, bio, avatar_url, is_public, spotify_enabled, is_premium)')
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
        .select('score, item_id, items!inner(title, primary_artist, image_url, tags)')
        .eq('user_id', otherUserId);

    final otherRatingsMap = <String, Map<String, dynamic>>{};
    final otherGenres = <String>{};

    for (final row in otherRows) {
      final itemId = row['item_id'] as String;
      final scoreVal = double.tryParse(row['score'].toString()) ?? 5.0;
      final item = row['items'] as Map<String, dynamic>;
      
      otherRatingsMap[itemId] = {
        'score': scoreVal,
        'title': item['title'] as String,
        'artist': item['primary_artist'] as String?,
        'image_url': item['image_url'] as String?,
      };

      // Extract genres
      final tags = item['tags'] as List<dynamic>? ?? [];
      for (final t in tags) {
        final tagMap = t as Map<String, dynamic>;
        otherGenres.add(tagMap['name'].toString().toLowerCase());
      }
    }

    // 2. Extract my ratings and genres
    final myRatingsMap = {for (final r in myRatings) r.id: r};
    final myGenres = <String>{};
    for (final r in myRatings) {
      for (final t in r.tags) {
        myGenres.add(t.name.toLowerCase());
      }
    }

    // 3. Find common items and calculate ratings difference
    final sharedFavorites = <MatchItemInfo>[];
    final tasteDifferences = <MatchItemInfo>[];
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

        if (myScore >= 7.0 && theirScore >= 7.0) {
          sharedFavorites.add(info);
        } else if (diff >= 3.0) {
          tasteDifferences.add(info);
        }
      }
    }

    // 4. Calculate shared genres (Jaccard similarity style)
    final intersection = myGenres.intersection(otherGenres);
    final union = myGenres.union(otherGenres);
    final double genreSim = union.isEmpty ? 50.0 : (intersection.length / union.length) * 100.0;

    // 5. Compute match score
    double ratingSim = 50.0;
    if (commonCount > 0) {
      final avgDiff = totalDiff / commonCount;
      ratingSim = (100.0 - (avgDiff * 12.0)).clamp(0.0, 100.0);
    }

    double matchPercentage = 50.0;
    if (commonCount >= 3) {
      // High weight on ratings similarity if there's enough overlap
      matchPercentage = ratingSim * 0.7 + genreSim * 0.3;
    } else if (commonCount > 0) {
      matchPercentage = ratingSim * 0.4 + genreSim * 0.6;
    } else {
      matchPercentage = genreSim;
    }

    // Return results
    return FriendMatchResult(
      matchPercentage: matchPercentage,
      commonCount: commonCount,
      sharedFavorites: sharedFavorites..sort((a, b) => (b.myScore + b.theirScore).compareTo(a.myScore + a.theirScore)),
      tasteDifferences: tasteDifferences..sort((a, b) => (b.myScore - b.theirScore).abs().compareTo((a.myScore - a.theirScore).abs())),
      sharedGenres: intersection.take(5).toList(),
    );
  }
}

final friendsServiceProvider = Provider<FriendsService>((ref) => FriendsService());

/// Friend list provider
final friendsProvider = FutureProvider<List<UserProfile>>((ref) async {
  return ref.watch(friendsServiceProvider).getFriends();
});
