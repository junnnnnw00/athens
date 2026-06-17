import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../i18n.dart';
import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_service.dart';
import 'friends_service.dart';
import '../../data/repository/library_providers.dart';

enum _FriendSort { recent, match }

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
  _FriendSort _sort = _FriendSort.recent;

  AppLanguage get _lang => ref.read(localeProvider);

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
          SnackBar(content: Text(I18n.get('fr_search_failed', _lang, ['$e']))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider); // rebuild on locale change
    final p = context.palette;
    final friendsAsync = ref.watch(friendsProvider);
    final followersAsync = ref.watch(followersProvider);

    // Build a set of followed friend IDs for quick lookup in search results
    final followedIds = friendsAsync.valueOrNull?.map((f) => f.id).toSet() ?? {};
    final followerIds = followersAsync.valueOrNull?.map((f) => f.id).toSet() ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.get('fr_title', _lang)),
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
                hintText: I18n.get('fr_search_hint', _lang),
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
                : _buildFriendsList(friendsAsync, followersAsync, followedIds, followerIds),
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
          I18n.get('fr_no_search_results', _lang),
          style: TextStyle(color: p.muted),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl,
          AppLayout.scrollBottomInset(context)),
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
                child: _buildAvatar(user, 44),
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
                            I18n.get('fr_no_ratings', _lang),
                            style: TextStyle(color: p.faint, fontSize: 11),
                          );
                        }
                        final matchAsync = ref.watch(friendMatchProvider(user.id));
                        return matchAsync.when(
                          loading: () => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: p.accent,
                              ),
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (match) => Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 13, color: p.accentText),
                              const SizedBox(width: 2),
                              Text(
                                I18n.get('fr_match_rate', _lang, [match.matchPercentage.toStringAsFixed(0)]),
                                style: TextStyle(
                                  color: p.accentText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                I18n.get('fr_common_count', _lang, ['${match.commonCount}']),
                                style: TextStyle(
                                  color: p.faint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
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
                child: Text(isFollowed ? I18n.get('fr_delete', _lang) : I18n.get('fr_add', _lang), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Friends ordered by the active sort. Recent = server order (follows
  /// created_at desc). Match = by cached match percentage; rows still loading
  /// sink to the bottom and the list reorders as results arrive.
  List<UserProfile> _sortedFriends(List<UserProfile> friends) {
    if (_sort == _FriendSort.recent) return friends;
    final sorted = [...friends];
    sorted.sort((a, b) {
      final am = ref.watch(friendMatchProvider(a.id)).valueOrNull?.matchPercentage ?? -1;
      final bm = ref.watch(friendMatchProvider(b.id)).valueOrNull?.matchPercentage ?? -1;
      return bm.compareTo(am);
    });
    return sorted;
  }

  Widget _buildFriendsList(
    AsyncValue<List<UserProfile>> friendsAsync,
    AsyncValue<List<UserProfile>> followersAsync,
    Set<String> followedIds,
    Set<String> followerIds,
  ) {
    final p = context.palette;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(friendsProvider);
        ref.invalidate(followersProvider);
        try {
          await ref.read(friendsProvider.future);
          await ref.read(followersProvider.future);
        } catch (_) {
          // Hold the spinner until refresh settles; the error is shown by
          // friendsAsync.when's error branch below.
        }
      },
      child: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: ListView(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Center(
                child: Text(I18n.get('fr_error', _lang, ['$err']), style: TextStyle(color: p.text)),
              ),
            ],
          ),
        ),
        data: (friends) {
          final followers = followersAsync.valueOrNull ?? [];
          final followBackRecommendations =
              followers.where((f) => !followedIds.contains(f.id)).toList();

          final recommendationsWidget = <Widget>[];
          if (followBackRecommendations.isNotEmpty) {
            recommendationsWidget.addAll([
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.sm),
                child: Text(
                  I18n.get('fr_followers', _lang),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: p.accentText,
                  ),
                ),
              ),
              ...followBackRecommendations.map((user) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        _buildAvatar(user, 44),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            user.displayName ?? user.handle,
                            style: Theme.of(context).textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.bg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(60, 32),
                          ),
                          onPressed: () => _toggleFollow(user.id, false),
                          child: Text(I18n.get('fr_follow_back', _lang),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: Divider(height: 1, color: p.line),
              ),
            ]);
          }

          if (friends.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  0, AppSpacing.md, 0, AppLayout.scrollBottomInset(context)),
              children: [
                ...recommendationsWidget,
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: p.faint),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          I18n.get('fr_empty_title', _lang),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          I18n.get('fr_empty_desc', _lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final sortedFriends = _sortedFriends(friends);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                0, AppSpacing.md, 0, AppLayout.scrollBottomInset(context)),
            children: [
              ...recommendationsWidget,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        I18n.get('fr_friends_count', _lang, ['${friends.length}']),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    PopupMenuButton<_FriendSort>(
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      color: p.surface2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        side: BorderSide(color: p.line),
                      ),
                      itemBuilder: (c) => [
                        PopupMenuItem(
                          value: _FriendSort.recent,
                          child: Text(I18n.get('fr_sort_recent', _lang),
                              style: TextStyle(color: p.text, fontSize: 14)),
                        ),
                        PopupMenuItem(
                          value: _FriendSort.match,
                          child: Text(I18n.get('fr_sort_match', _lang),
                              style: TextStyle(color: p.text, fontSize: 14)),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_vert_rounded, size: 16, color: p.muted),
                            const SizedBox(width: 4),
                            Text(
                              _sort == _FriendSort.recent ? I18n.get('fr_sort_recent', _lang) : I18n.get('fr_sort_match', _lang),
                              style: TextStyle(color: p.muted, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...sortedFriends.map((friend) => _FriendCard(
                    friend: friend,
                    isMutual: followerIds.contains(friend.id),
                    onTap: () => context.go('/friends/compare/${friend.id}'),
                    onDelete: () => _confirmDelete(friend),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(UserProfile friend) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(I18n.get('fr_remove_title', _lang)),
        content: Text(I18n.get('fr_remove_confirm', _lang, [friend.displayName ?? friend.handle])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(I18n.get('fr_cancel', _lang), style: TextStyle(color: p.text)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleFollow(friend.id, true);
            },
            child: Text(I18n.get('fr_delete', _lang), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile user, double size) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: p.line),
      ),
      child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                user.avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person_rounded, color: p.muted, size: size / 2),
              ),
            )
          : Icon(Icons.person_rounded, color: p.muted, size: size / 2),
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
      ref.invalidate(followersProvider);
      // Re-trigger search to update state if search text is still there
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
      if (!isFollowed && mounted) {
        context.go('/friends/compare/$userId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(I18n.get('fr_follow_failed', _lang, ['$e']))),
        );
      }
    }
  }
}

/// Roomy friend card: avatar + name + match badge only. Tap → comparison,
/// long-press → delete dialog (clutter like inline delete buttons removed).
class _FriendCard extends ConsumerWidget {
  const _FriendCard({
    required this.friend,
    required this.isMutual,
    required this.onTap,
    required this.onDelete,
  });

  final UserProfile friend;
  final bool isMutual;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xs + 2),
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                _Avatar(friend: friend, size: 52),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              friend.displayName ?? friend.handle,
                              style: Theme.of(context).textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMutual) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.sync_alt_rounded,
                                size: 14, color: p.accentText),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${friend.handle}',
                        style: TextStyle(color: p.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _MatchBadge(friendId: friend.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.friend, required this.size});
  final UserProfile friend;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: p.line),
      ),
      child: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                friend.avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.person_rounded, color: p.muted, size: size / 2),
              ),
            )
          : Icon(Icons.person_rounded, color: p.muted, size: size / 2),
    );
  }
}

class _MatchBadge extends ConsumerWidget {
  const _MatchBadge({required this.friendId});
  final String friendId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final matchAsync = ref.watch(friendMatchProvider(friendId));
    return matchAsync.when(
      loading: () => Text('...', style: TextStyle(color: p.muted, fontSize: 12)),
      error: (_, __) => const SizedBox.shrink(),
      data: (match) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          '${match.matchPercentage.toStringAsFixed(0)}%',
          style: TextStyle(
            color: p.accentText,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
