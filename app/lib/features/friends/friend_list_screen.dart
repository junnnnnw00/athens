import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_service.dart';
import 'friends_service.dart';
import '../../widgets/premium_lock_overlay.dart';
import '../../data/repository/library_providers.dart';

class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});

  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
      _isSearching = true;
    });

    try {
      final results = await ref.read(friendsServiceProvider).searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final friendsAsync = ref.watch(friendsProvider);
    final myProfileAsync = ref.watch(myProfileProvider);
    final isPremium = myProfileAsync.valueOrNull?.isPremium ?? false;

    // Build a set of followed friend IDs for quick lookup in search results
    final followedIds = friendsAsync.valueOrNull?.map((f) => f.id).toSet() ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 목록 및 검색'),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            child: TextField(
              controller: _searchController,
              cursorColor: p.accent,
              style: TextStyle(color: p.text),
              decoration: InputDecoration(
                hintText: '핸들 또는 닉네임 검색...',
                hintStyle: TextStyle(color: p.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: p.muted),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: p.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: BorderSide(color: p.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  borderSide: BorderSide(color: p.accent),
                ),
              ),
              onChanged: (val) => _performSearch(val),
            ),
          ),

          // Main View (Search Results OR Friends List)
          Expanded(
            child: _isSearching
                ? _buildSearchResults(followedIds)
                : _buildFriendsList(friendsAsync, isPremium),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(Set<String> followedIds) {
    final p = context.palette;

    if (_isLoadingSearch) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없거나 본인입니다.',
          style: TextStyle(color: p.muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: p.line),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isFollowed = followedIds.contains(user.id);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _buildAvatar(user),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName ?? user.handle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '@${user.handle}',
                          style: TextStyle(color: p.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: TextStyle(color: p.muted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Taste Compatibility / Match Rate
                    Consumer(
                      builder: (context, ref, _) {
                        final myRatings = ref.watch(ratedItemsProvider);
                        if (myRatings.isEmpty) {
                          return Text(
                            '평가한 곡이 없습니다. 먼저 평가해 보세요!',
                            style: TextStyle(color: p.faint, fontSize: 11),
                          );
                        }

                        return FutureBuilder<FriendMatchResult>(
                          future: ref.read(friendsServiceProvider).calculateMatch(user.id, myRatings),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: p.accent,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final match = snapshot.data!;
                            return Row(
                              children: [
                                Icon(Icons.bolt_rounded, size: 13, color: p.accentText),
                                const SizedBox(width: 2),
                                Text(
                                  '일치율 ${match.matchPercentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: p.accentText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '•  공통 ${match.commonCount}곡',
                                  style: TextStyle(
                                    color: p.faint,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Follow/Unfollow Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowed ? p.surface2 : p.accent,
                  foregroundColor: isFollowed ? p.text : p.bg,
                  elevation: 0,
                  side: isFollowed ? BorderSide(color: p.line) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(60, 32),
                ),
                onPressed: () => _toggleFollow(user.id, isFollowed),
                child: Text(isFollowed ? '삭제' : '추가', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsList(AsyncValue<List<UserProfile>> friendsAsync, bool isPremium) {
    final p = context.palette;

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('에러 발생: $err', style: TextStyle(color: p.text))),
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded, size: 48, color: p.faint),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '아직 등록된 친구가 없어요',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '위 검색창에서 친구의 핸들을 입력해 추가해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          itemCount: friends.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: p.line),
          itemBuilder: (context, index) {
            final friend = friends[index];
            return InkWell(
              onTap: () => context.go('/friends/compare/${friend.id}'),
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    _buildAvatar(friend),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.displayName ?? friend.handle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${friend.handle}',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Match percentage indicator (Locked or unlocked)
                    _buildMatchBadge(friend.id, isPremium),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right_rounded, color: p.faint),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(UserProfile user) {
    final p = context.palette;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: p.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: p.line),
      ),
      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                user.avatarUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: p.muted, size: 22),
              ),
            )
          : Icon(Icons.person_rounded, color: p.muted, size: 22),
    );
  }

  Widget _buildMatchBadge(String friendId, bool isPremium) {
    final p = context.palette;

    if (!isPremium) {
      return GestureDetector(
        onTap: () {
          // Show Premium activation trial pop up
          showDialog(
            context: context,
            builder: (context) => const Dialog(
              child: PremiumLockOverlay(
                featureName: '친구별 취향 일치율 확인',
                featureDescription: '등록된 친구들의 음악 취향 분석을 통한 매칭 일치율 및 상세 교집합 비교를 확인해 보세요!',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: p.surface2,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: p.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 12, color: p.muted),
              const SizedBox(width: 4),
              Text(
                '??% Match',
                style: TextStyle(color: p.muted, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Unlocked Premium match rate calculation
    return Consumer(
      builder: (context, ref, _) {
        final myRatings = ref.watch(ratedItemsProvider);
        return FutureBuilder<FriendMatchResult>(
          future: ref.read(friendsServiceProvider).calculateMatch(friendId, myRatings),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('...', style: TextStyle(color: p.muted, fontSize: 12));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final match = snapshot.data!;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.accentSoft,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '${match.matchPercentage.toStringAsFixed(0)}% Match',
                style: TextStyle(
                  color: p.accentText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleFollow(String userId, bool isFollowed) async {
    final service = ref.read(friendsServiceProvider);
    try {
      if (isFollowed) {
        await service.unfollowUser(userId);
      } else {
        await service.followUser(userId);
      }
      ref.invalidate(friendsProvider);
      // Re-trigger search to update state if search text is still there
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 설정 실패: $e')),
        );
      }
    }
  }
}
